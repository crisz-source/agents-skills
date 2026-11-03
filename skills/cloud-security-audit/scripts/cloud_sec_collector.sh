#!/bin/sh
# cloud_sec_collector.sh — Coleta de postura de segurança Azure (SOMENTE LEITURA).
#
# Uso: sh cloud_sec_collector.sh <subscription-id> [diretório-de-IaC]
#   ENTRA=1  -> inclui checagens de Entra ID via Microsoft Graph (MFA de admins,
#               Conditional Access, apps com segredo vencido). Exigem permissões de
#               leitura no diretório; sem elas, ficam "Inconclusivo".
#
# Regras deste script:
#   - Só verbos de leitura: list, show, query e GET via 'az rest'.
#   - NUNCA chama comandos que devolvem chaves ou segredos (keys list, list-keys,
#     appsettings, connection-string, secret show, publishing-profiles).
#   - Valores parecidos com segredo encontrados em IaC são mascarados (4 caracteres + ***).

SUB="$1"
IAC_DIR="${2:-.}"
LIMIT="${SEC_LIMIT:-30}"
set -f

if [ -z "$SUB" ]; then
  echo "Uso: sh $0 <subscription-id> [diretório-de-IaC]" >&2
  exit 2
fi
command -v az >/dev/null 2>&1 || { echo "ERRO: Azure CLI (az) não encontrada." >&2; exit 1; }
az account show -o none 2>/dev/null || { echo "ERRO: Azure CLI não autenticada. Rode 'az login'." >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
AZ="az"
S="--subscription $SUB"

# run <título> <comando...>: mostra a saída (limitada) ou registra Inconclusivo.
run() {
  title="$1"; shift
  echo ""
  echo "--- $title ---"
  if "$@" > "$TMP/out" 2> "$TMP/err"; then
    tr -d '\r' < "$TMP/out" > "$TMP/out2"
    if [ -s "$TMP/out2" ]; then head -n 60 "$TMP/out2"; else echo "(nenhum item)"; fi
  else
    echo "Inconclusivo: $(tr -d '\r' < "$TMP/err" | head -n 2 | tr '\n' ' ' | cut -c1-220)"
  fi
}

# tsv <comando...>: saída tsv sem CR (Windows), vazia em caso de erro.
tsv() { "$@" -o tsv 2>/dev/null | tr -d '\r'; }

# mask: mascara valores após '=' ou ':' (mantém 4 caracteres) e blocos conhecidos.
mask() {
  sed -E \
    -e 's/(AccountKey|SharedAccessKey|Password|Pwd|sig)=([^;&" ]{0,4})[^;&" ]*/\1=\2***/Ig' \
    -e 's/(eyJ[A-Za-z0-9_-]{4})[A-Za-z0-9._-]{10,}/\1***/g' \
    -e 's/((ghp|gho|github_pat|xox[bp])_?[A-Za-z0-9]{0,4})[A-Za-z0-9_]{8,}/\1***/g' \
    -e 's/([=][[:space:]]*["'"'"']?|:[[:space:]]+["'"'"']?|:["'"'"'])([^"'"'"'[:space:],;:]{4})[^"'"'"'[:space:],;]{4,}/\1\2***/g'
}

echo "=== Cloud Security Collector — Azure (somente leitura) ==="
echo "Data: $(date +%Y-%m-%d)"
run "Contexto" $AZ account show $S --query "{Subscription:name, Id:id, Tenant:tenantId, Usuario:user.type}" -o table

# ---------------------------------------------------------------- 1. Defender
echo ""
echo "=== [1/10] Microsoft Defender for Cloud ==="
run "Planos do Defender (Free = desligado)" \
  $AZ security pricing list $S --query "value[].{Plano:name, Tier:pricingTier}" -o table
run "Secure Score" \
  $AZ security secure-scores list $S --query "[].{Nome:displayName, Atual:score.current, Max:score.max, Pct:score.percentage}" -o table
echo ""
echo "--- Recomendações não atendidas (Unhealthy), mais frequentes ---"
tsv $AZ security assessment list $S --query "[?status.code=='Unhealthy'].displayName" \
  | sort | uniq -c | sort -rn | head -n 25

# ---------------------------------------------------------------- 2. Storage
echo ""
echo "=== [2/10] Storage Accounts ==="
run "Configuração de acesso e criptografia em trânsito" \
  $AZ storage account list $S --query "[].{Nome:name, RG:resourceGroup, BlobPublico:allowBlobPublicAccess, RedePublica:publicNetworkAccess, FirewallPadrao:networkRuleSet.defaultAction, TLSmin:minimumTlsVersion, SoHTTPS:enableHttpsTrafficOnly, ChaveCompartilhada:allowSharedKeyAccess}" -o table
echo "(Chaves e SAS NÃO são consultadas por este script.)"

# ---------------------------------------------------------------- 3. NSG
echo ""
echo "=== [3/10] NSGs — regras de entrada abertas para a Internet ==="
run "Inbound Allow com origem *, Internet ou 0.0.0.0/0" \
  $AZ network nsg list $S --query "[].securityRules[] | [?direction=='Inbound' && access=='Allow' && (contains(['*','Internet','0.0.0.0/0','Any'], sourceAddressPrefix || '') || length((sourceAddressPrefixes || \`[]\`)[?contains(['*','Internet','0.0.0.0/0'], @)]) > \`0\`)].{Regra:name, Porta:destinationPortRange, Portas:join(',', destinationPortRanges || \`[]\`), Origem:sourceAddressPrefix, Prioridade:priority, Id:id}" -o table
echo "Portas de gestão/dados a destacar: 22, 3389, 5985-5986, 1433, 3306, 5432, 6379, 27017, 9200, 2375-2376, 10250, * ."

# ---------------------------------------------------------------- 4. Key Vault
echo ""
echo "=== [4/10] Key Vaults ==="
echo "--- Configuração (sem listar segredos) ---"
printf 'Nome\tRBAC\tSoftDelete\tPurgeProtection\tRedePublica\tFirewallPadrao\n'
tsv $AZ keyvault list $S --query "[].name" | head -n "$LIMIT" | while read -r kv; do
  [ -z "$kv" ] && continue
  line=$(tsv $AZ keyvault show $S --name "$kv" --query "[properties.enableRbacAuthorization, properties.enableSoftDelete, properties.enablePurgeProtection, properties.publicNetworkAccess, properties.networkAcls.defaultAction]" | tr '\n' '\t')
  printf '%s\t%s\n' "$kv" "${line:-Inconclusivo}"
done

# ---------------------------------------------------------------- 5. ACR
echo ""
echo "=== [5/10] Container Registries ==="
run "ACR" \
  $AZ acr list $S --query "[].{Nome:name, RG:resourceGroup, Sku:sku.name, AdminUser:adminUserEnabled, RedePublica:publicNetworkAccess, PullAnonimo:anonymousPullEnabled}" -o table

# ---------------------------------------------------------------- 6. SQL
echo ""
echo "=== [6/10] Azure SQL ==="
run "Servidores" \
  $AZ sql server list $S --query "[].{Nome:name, RG:resourceGroup, RedePublica:publicNetworkAccess, TLSmin:minimalTlsVersion, AdminEntra:administrators.login}" -o table
echo ""
echo "--- Regras de firewall amplas (0.0.0.0 = 'serviços Azure'; até 255.255.255.255 = Internet) ---"
tsv $AZ sql server list $S --query "[].[resourceGroup, name]" | head -n "$LIMIT" | while IFS="$(printf '\t')" read -r rg srv; do
  [ -z "$srv" ] && continue
  tsv $AZ sql server firewall-rule list $S -g "$rg" -s "$srv" \
    --query "[?startIpAddress=='0.0.0.0' || endIpAddress=='255.255.255.255'].[name, startIpAddress, endIpAddress]" \
    | sed "s/^/$srv\t/"
done

# ---------------------------------------------------------------- 7. App Service
echo ""
echo "=== [7/10] App Services / Function Apps ==="
run "HTTPS e acesso público" \
  $AZ webapp list $S --query "[].{Nome:name, RG:resourceGroup, SoHTTPS:httpsOnly, RedePublica:publicNetworkAccess, ClientCert:clientCertEnabled}" -o table
echo ""
echo "--- TLS mínimo, FTP e depuração remota (sem ler app settings) ---"
printf 'App\tTLSmin\tFTPS\tDebugRemoto\n'
tsv $AZ webapp list $S --query "[].[resourceGroup, name]" | head -n "$LIMIT" | while IFS="$(printf '\t')" read -r rg app; do
  [ -z "$app" ] && continue
  line=$(tsv $AZ webapp config show $S -g "$rg" -n "$app" --query "[minTlsVersion, ftpsState, remoteDebuggingEnabled]" | tr '\n' '\t')
  printf '%s\t%s\n' "$app" "${line:-Inconclusivo}"
done

# ---------------------------------------------------------------- 8. AKS
echo ""
echo "=== [8/10] AKS — camada Azure (o interior do cluster é do k8s-auditor) ==="
run "Clusters" \
  $AZ aks list $S --query "[].{Nome:name, RG:resourceGroup, Versao:kubernetesVersion, EntraID:aadProfile.managed, RBACdoAzure:aadProfile.enableAzureRbac, ContasLocaisDesligadas:disableLocalAccounts, Privado:apiServerAccessProfile.enablePrivateCluster, IPsAutorizados:length(apiServerAccessProfile.authorizedIpRanges || \`[]\`), NetworkPolicy:networkProfile.networkPolicy, Defender:securityProfile.defender.securityMonitoring.enabled}" -o table

# ---------------------------------------------------------------- 9. RBAC
echo ""
echo "=== [9/10] RBAC do Azure — papéis privilegiados ==="
run "Owner / Contributor / User Access Administrator / RBAC Administrator" \
  $AZ role assignment list $S --all --include-inherited --query "[?contains(['Owner','Contributor','User Access Administrator','Role Based Access Control Administrator'], roleDefinitionName)].{Papel:roleDefinitionName, Tipo:principalType, Principal:principalName, Escopo:scope}" -o table
run "Atribuições a principais excluídos (órfãs)" \
  $AZ role assignment list $S --all --include-inherited --query "length([?principalType=='Unknown' || principalName==''])" -o tsv

# ---------------------------------------------------------------- 10. Entra ID (opcional)
echo ""
echo "=== [10/10] Entra ID (ENTRA=${ENTRA:-0}) ==="
if [ "${ENTRA:-0}" = "1" ]; then
  G="https://graph.microsoft.com/v1.0"
  run "Administradores SEM MFA registrado (contagem)" \
    $AZ rest --method get --url "$G/reports/authenticationMethods/userRegistrationDetails?\$filter=isAdmin eq true&\$top=999" \
    --query "length(value[?isMfaRegistered==\`false\`])" -o tsv
  run "Políticas de Conditional Access" \
    $AZ rest --method get --url "$G/identity/conditionalAccess/policies" \
    --query "value[].{Politica:displayName, Estado:state}" -o table
  HOJE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  EM30=$(date -u -d '+30 days' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "$HOJE")
  run "App registrations com segredo VENCIDO (contagem)" \
    $AZ ad app list --all --query "length([?passwordCredentials[?endDateTime < '$HOJE']])" -o tsv
  run "App registrations com segredo vencendo em 30 dias" \
    $AZ ad app list --all --query "[?passwordCredentials[?endDateTime >= '$HOJE' && endDateTime < '$EM30']].{App:displayName, AppId:appId}" -o table
else
  echo "Pulado. Para incluir: ENTRA=1 sh $0 $SUB $IAC_DIR"
fi

# ---------------------------------------------------------------- 11. IaC e segredos
echo ""
echo "=== [IaC] Segredos e configurações inseguras em $IAC_DIR ==="
if [ -d "$IAC_DIR" ]; then
  ex="--exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.terraform --exclude-dir=reports"
  inc="--include=*.tf --include=*.tfvars --include=*.bicep --include=*.bicepparam --include=*.json --include=*.yaml --include=*.yml --include=*.ps1 --include=*.sh --include=*.config --include=*.properties"
  echo ""
  echo "--- Arquivos que não deveriam estar versionados (só o nome) ---"
  find "$IAC_DIR" -type d \( -name .git -o -name node_modules -o -name .terraform \) -prune -o \
    -type f \( -name '.env' -o -name '.env.*' -o -name '*.tfstate' -o -name '*.tfstate.backup' -o -name '*.pfx' -o -name '*.p12' -o -name '*.pem' -o -name '*.key' -o -name 'kubeconfig*' \) -print 2>/dev/null | head -n "$LIMIT"
  echo ""
  echo "--- Possíveis segredos hardcoded (mascarados) ---"
  # shellcheck disable=SC2086
  grep -rnIE $ex $inc \
    -e '(password|passwd|senha|secret|client_secret|api[_-]?key|access[_-]?key|token|connectionstring|connection_string)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'$\{]{6,}' \
    -e '(password|passwd|senha|secret|token|api[_-]?key)[^=]{0,40}default[[:space:]]*=[[:space:]]*"[^"$\{]{6,}"' \
    -e 'AccountKey=[A-Za-z0-9+/=]{20,}' \
    -e 'SharedAccessSignature|[?&]sig=[A-Za-z0-9%]{20,}' \
    -e '-----BEGIN ([A-Z]+ )?PRIVATE KEY-----' \
    -e 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' \
    -e '(ghp|gho|github_pat)_[A-Za-z0-9_]{20,}' \
    "$IAC_DIR" 2>/dev/null | cut -c1-240 | mask | head -n "$LIMIT"
  echo ""
  echo "--- Configurações inseguras em IaC ---"
  # shellcheck disable=SC2086
  grep -rnIiE $ex --include=*.tf --include=*.bicep --include=*.json \
    -e '(allow_nested_items_to_be_public|allow_blob_public_access|allowBlobPublicAccess)["'"'"']?[[:space:]]*[:=][[:space:]]*true' \
    -e '(public_network_access_enabled|publicNetworkAccess)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?(true|Enabled)' \
    -e '(min_tls_version|minimumTlsVersion|minTlsVersion)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?(TLS1_0|TLS1_1|1\.0|1\.1)' \
    -e '(https_only|httpsOnly|enableHttpsTrafficOnly|https_traffic_only_enabled)["'"'"']?[[:space:]]*[:=][[:space:]]*false' \
    -e '(admin_enabled|adminUserEnabled)["'"'"']?[[:space:]]*[:=][[:space:]]*true' \
    -e 'source_address_prefix[[:space:]]*=[[:space:]]*"(\*|0\.0\.0\.0/0|Internet)"' \
    -e '(purge_protection_enabled|enablePurgeProtection)["'"'"']?[[:space:]]*[:=][[:space:]]*false' \
    "$IAC_DIR" 2>/dev/null | cut -c1-200 | head -n "$LIMIT"
else
  echo "Diretório '$IAC_DIR' não existe; varredura de IaC pulada."
fi

echo ""
echo "=== Coleta concluída. Itens 'Inconclusivo' vão para a seção Limitações do relatório. ==="
