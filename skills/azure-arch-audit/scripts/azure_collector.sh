#!/bin/sh
# Azure Architecture Audit Collector (SOMENTE LEITURA: list / show).
#
# Uso: sh azure_collector.sh <subscription-id> [tags,obrigatórias]
#   Tags padrão: Environment,Owner,CostCenter,Application (comparação sem diferenciar maiúsculas).
# Não calcula custo (isso é do finops-azure).

SUB="$1"
TAGS="${2:-Environment,Owner,CostCenter,Application}"
LIMIT="${ARCH_LIMIT:-60}"
set -f

if [ -z "$SUB" ]; then
  echo "Uso: sh $0 <subscription-id> [tags,obrigatórias]" >&2
  exit 2
fi
command -v az >/dev/null 2>&1 || { echo "ERRO: Azure CLI (az) não encontrada." >&2; exit 1; }
az account show -o none 2>/dev/null || { echo "ERRO: Azure CLI não autenticada. Rode 'az login'." >&2; exit 1; }

S="--subscription $SUB"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

run() {
  title="$1"; shift
  echo ""
  echo "--- $title ---"
  if "$@" > "$TMP/out" 2> "$TMP/err"; then
    tr -d '\r' < "$TMP/out" > "$TMP/o2"
    if [ -s "$TMP/o2" ]; then head -n "$LIMIT" "$TMP/o2"; else echo "(nenhum item)"; fi
  else
    echo "Inconclusivo: $(tr -d '\r' < "$TMP/err" | head -n 2 | tr '\n' ' ' | cut -c1-200)"
  fi
}

echo "=== [1/9] Conta e Subscription ==="
az account show $S --query "{Subscription:name, Id:id, Tenant:tenantId}" -o table

echo ""
echo "=== [2/9] Hierarquia: Resource Groups ==="
run "Resource groups (nome, região, tag Environment)" \
  az group list $S --query "sort_by([], &name)[].{Nome:name, Regiao:location, Environment:tags.Environment || tags.environment || tags.Ambiente || tags.ambiente}" -o table
echo "(MC_* = grupo gerenciado do AKS; NetworkWatcherRG = gerenciado pela Azure. Não recomende alterar diretamente.)"

echo ""
echo "=== [3/9] Governança: Locks e Azure Policy ==="
run "Locks (CanNotDelete / ReadOnly)" \
  az lock list $S --query "[].{Nome:name, Nivel:level, Escopo:id}" -o table
run "Total de atribuições de Azure Policy (inclui herdadas)" \
  az policy assignment list $S --disable-scope-strict-match --query "length(@)" -o tsv
run "Atribuições ligadas a tags, região, SKU ou recursos permitidos" \
  az policy assignment list $S --disable-scope-strict-match --query "[?contains(to_string(displayName), 'Tag') || contains(to_string(displayName), 'tag') || contains(to_string(displayName), 'ocation') || contains(to_string(displayName), 'SKU') || contains(to_string(displayName), 'llowed')].{Nome:displayName, Modo:enforcementMode}" -o table

echo ""
echo "=== [4/9] Discos não anexados (com há quanto tempo foram desanexados) ==="
run "Managed disks com managedBy vazio" \
  az disk list $S --query "[?managedBy==null].{Nome:name, RG:resourceGroup, Estado:diskState, GB:diskSizeGb, Sku:sku.name, Criado:timeCreated, UltimaMudancaDono:lastOwnershipUpdateTime}" -o table

echo ""
echo "=== [5/9] IPs públicos sem associação ==="
run "Public IPs com ipConfiguration vazio" \
  az network public-ip list $S --query "[?ipConfiguration==null && natGateway==null].{Nome:name, RG:resourceGroup, IP:ipAddress, Alocacao:publicIPAllocationMethod, DNS:dnsSettings.fqdn, Sku:sku.name}" -o table
echo "(IP Static pode estar liberado em firewall de parceiro ou em DNS externo: removido, ele se perde. Sempre 'Requer Validação'.)"

echo ""
echo "=== [6/9] NICs e NSGs sem associação ==="
run "NICs sem VM e sem Private Endpoint" \
  az network nic list $S --query "[?virtualMachine==null && privateEndpoint==null].{Nome:name, RG:resourceGroup, PrivateLinkService:privateLinkService.id}" -o table
run "NSGs sem subnet e sem NIC" \
  az network nsg list $S --query "[?subnets==null && networkInterfaces==null].{Nome:name, RG:resourceGroup}" -o table

echo ""
echo "=== [7/9] App Service Plans sem aplicações ==="
run "Planos com numberOfSites = 0" \
  az appservice plan list $S --query "[?numberOfSites==\`0\`].{Nome:name, RG:resourceGroup, Sku:sku.name}" -o table

echo ""
echo "=== [8/9] Cobertura de tags obrigatórias ($TAGS) ==="
# tsv: RG <tab> tipo <tab> chaves de tag separadas por vírgula. Comparação sem diferenciar maiúsculas.
az resource list $S --query "[].[resourceGroup, type, join(',', keys(tags || \`{}\`))]" -o tsv 2>"$TMP/err" | tr -d '\r' > "$TMP/res"
if [ ! -s "$TMP/res" ] && [ -s "$TMP/err" ]; then
  echo "Inconclusivo: $(head -n 1 "$TMP/err" | cut -c1-200)"
else
  awk -F'\t' -v req="$TAGS" '
    BEGIN { n = split(tolower(req), R, ",") }
    { rg = $1; low = "," tolower($3) ","
      if (tolower(rg) ~ /^mc_/ || tolower(rg) == "networkwatcherrg") { gerenciado++; next }
      total++; T[rg]++
      if ($3 == "") { semtag++; S0[rg]++ }
      falta = 0
      for (i = 1; i <= n; i++) if (index(low, "," R[i] ",") == 0) { falta = 1; F[R[i]]++ }
      if (falta) { fora++; FR[rg]++ } else ok++ }
    END {
      if (!total) { print "Nenhum recurso (fora de grupos gerenciados)."; exit }
      printf "Recursos avaliados: %d (ignorados em grupos gerenciados MC_*/NetworkWatcherRG: %d)\n", total, gerenciado
      printf "Com TODAS as tags obrigatórias: %d (%.1f%%)\n", ok, ok * 100 / total
      printf "Sem nenhuma tag: %d (%.1f%%)\n", semtag, semtag * 100 / total
      for (i = 1; i <= n; i++) printf "  falta \"%s\": %d recursos\n", R[i], F[R[i]]
      print ""
      print "Fora do padrão por resource group (fora/total):"
      for (g in FR) printf "  %s\t%d/%d\n", g, FR[g], T[g]
    }' "$TMP/res" | head -n "$LIMIT"
fi

echo ""
echo "=== [9/9] Dependências para checar antes de qualquer remoção ==="
run "Private Endpoints (dependem de NIC e subnet)" \
  az network private-endpoint list $S --query "[].{Nome:name, RG:resourceGroup, Recurso:privateLinkServiceConnections[0].privateLinkServiceId}" -o table
run "Snapshots (podem ser o backup de um disco 'órfão')" \
  az snapshot list $S --query "[].{Nome:name, RG:resourceGroup, DiscoOrigem:creationData.sourceResourceId, Criado:timeCreated}" -o table

echo ""
echo "=== Coleta Concluída ==="
