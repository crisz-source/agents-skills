#!/bin/sh
# cost_collector.sh — Coleta FinOps na Azure (SOMENTE LEITURA: list / show / query).
#
# Uso: sh cost_collector.sh <subscription-id[,subscription-id...]>
#   COST_LIMIT  linhas por seção (padrão 40)
#   LA_QUERY=0  pula as consultas KQL nos workspaces de Log Analytics (mais rápido)
#
# Não calcula preço: o agente usa a Retail Prices API / Cost Management sobre estes dados.
# Verificações que falham por permissão ou extensão ausente aparecem como "Inconclusivo".

SUBS="$1"
LIMIT="${COST_LIMIT:-40}"
set -f

if [ -z "$SUBS" ]; then
  echo "Uso: sh $0 <subscription-id[,subscription-id...]>" >&2
  exit 2
fi
command -v az >/dev/null 2>&1 || { echo "ERRO: Azure CLI (az) não encontrada." >&2; exit 1; }
az account show -o none 2>/dev/null || { echo "ERRO: Azure CLI não autenticada. Rode 'az login'." >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
H90=$(date -u -d '-90 days' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")

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
tsv() { "$@" -o tsv 2>/dev/null | tr -d '\r'; }

coletar() {
  SUB="$1"
  S="--subscription $SUB"
  echo ""
  echo "################################################################"
  echo "### Subscription: $SUB"
  echo "################################################################"
  run "Contexto" az account show $S --query "{Subscription:name, Id:id, Tenant:tenantId}" -o table
  run "Resource groups e tag de ambiente (para classificar Produção / Não Produção)" \
    az group list $S --query "sort_by([], &name)[].{RG:name, Environment:tags.Environment || tags.environment || tags.Ambiente || tags.ambiente}" -o table

  echo ""
  echo "=== [A] Recursos órfãos ==="
  run "Discos não anexados" \
    az disk list $S --query "[?managedBy==null].{Nome:name, RG:resourceGroup, Estado:diskState, GB:diskSizeGb, Sku:sku.name, Desanexado:lastOwnershipUpdateTime}" -o table
  run "IPs públicos sem associação" \
    az network public-ip list $S --query "[?ipConfiguration==null && natGateway==null].{Nome:name, RG:resourceGroup, Sku:sku.name, Alocacao:publicIPAllocationMethod}" -o table
  if [ -n "$H90" ]; then
    run "Snapshots com mais de 90 dias" \
      az snapshot list $S --query "[?timeCreated < '$H90'].{Nome:name, RG:resourceGroup, GB:diskSizeGb, Incremental:incremental, Criado:timeCreated}" -o table
  fi
  run "Virtual Network Gateways (verificar se têm conexões ativas)" \
    az resource list $S --resource-type Microsoft.Network/virtualNetworkGateways --query "[].{Nome:name, RG:resourceGroup}" -o table

  echo ""
  echo "=== [A2] SKUs Basic aposentados (IP público e Load Balancer Basic: sem suporte e sem SLA desde 30/09/2025) ==="
  run "IPs públicos Basic (todos, associados ou não)" \
    az network public-ip list $S --query "[?sku.name=='Basic'].{Nome:name, RG:resourceGroup, Associado:ipConfiguration.id != null}" -o table
  run "Load Balancers Basic" \
    az network lb list $S --query "[?sku.name=='Basic'].{Nome:name, RG:resourceGroup}" -o table

  echo ""
  echo "=== [B] Ociosos e parados ==="
  run "VMs paradas SEM desalocar (continuam cobrando compute)" \
    az vm list $S -d --query "[?powerState=='VM stopped'].{Nome:name, RG:resourceGroup, Tamanho:hardwareProfile.vmSize}" -o table
  run "VMs desalocadas (só disco cobra)" \
    az vm list $S -d --query "[?powerState=='VM deallocated'].{Nome:name, RG:resourceGroup, Tamanho:hardwareProfile.vmSize}" -o table
  run "App Service Plans sem aplicações" \
    az appservice plan list $S --query "[?numberOfSites==\`0\`].{Nome:name, RG:resourceGroup, Sku:sku.name, Instancias:sku.capacity}" -o table

  echo ""
  echo "=== [C] Right-sizing e geração de VM ==="
  echo "--- VMs ligadas por tamanho (geração antiga = candidata a modernização) ---"
  tsv az vm list $S -d --query "[?powerState=='VM running'].[name, resourceGroup, hardwareProfile.vmSize, storageProfile.osDisk.osType]" \
    | awk -F'\t' '{ tam = $3; ger = "atual";
        if (tam ~ /_v[23]$/ || tam ~ /^Standard_[DEFGHLM][0-9]+s?$/ || tam ~ /^Standard_[DG]S[0-9]+/ || tam ~ /^Basic_/ || tam ~ /^Standard_A[0-9]/) ger = "ANTIGA (avaliar v5/v6)";
        printf "%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, ger }' | head -n "$LIMIT"
  echo "(Para right-sizing, colete CPU/memória dos candidatos com: az monitor metrics list --resource <id> --metric \"Percentage CPU\" --interval PT1H --aggregation Average Maximum --start-time <30 dias atrás>)"
  run "Recomendações de custo do Azure Advisor (right-sizing, desligamento, reservas, savings plans)" \
    az advisor recommendation list $S --category Cost --query "[].{Problema:shortDescription.problem, Recurso:impactedValue, Tipo:impactedField, EconomiaAnual:extendedProperties.annualSavingsAmount, Moeda:extendedProperties.savingsCurrency, Termo:extendedProperties.term}" -o table

  echo ""
  echo "=== [D] Compromissos (Reservas e Savings Plans) ==="
  run "Reservation orders (exige leitura de billing e extensão 'reservation')" \
    az reservations reservation-order list --query "[].{Nome:displayName, Termo:term, Expira:expiryDateTime, Estado:provisioningState}" -o table
  run "Savings plan orders (exige leitura de billing e extensão 'billing-benefits')" \
    az billing-benefits savings-plan-order list --query "[].{Nome:displayName, Termo:term, Expira:expiryDateTime}" -o table
  echo "Atenção: reservas compradas a partir de 01/02/2027 para serviços cobertos por Savings Plan não poderão ser trocadas (ver SKILL.md, Categoria D)."

  echo ""
  echo "=== [E1] Elasticidade: AKS, node pools e agendas ==="
  run "Clusters AKS" \
    az aks list $S --query "[].{Nome:name, RG:resourceGroup, Tier:sku.tier, Versao:kubernetesVersion, Estado:powerState.code}" -o table
  echo ""
  echo "--- Node pools ---"
  printf 'Cluster\tPool\tModo\tVM\tNos\tAutoscale\tMin\tMax\tPrioridade\tOS\tK8s\n'
  tsv az aks list $S --query "[].[resourceGroup, name]" | head -n "$LIMIT" | while IFS="$(printf '\t')" read -r rg cl; do
    [ -z "$cl" ] && continue
    tsv az aks nodepool list $S -g "$rg" --cluster-name "$cl" \
      --query "[].[name, mode, vmSize, count, enableAutoScaling, minCount, maxCount, scaleSetPriority, osSku, orchestratorVersion]" | sed "s/^/$cl\t/"
  done
  run "Agendas de auto-shutdown (DevTest Labs schedules)" \
    az resource list $S --resource-type Microsoft.DevTestLab/schedules --query "[].{Nome:name, RG:resourceGroup}" -o table

  echo ""
  echo "=== [E2] Armazenamento ==="
  run "Discos Premium (avaliar em Não Produção)" \
    az disk list $S --query "[?starts_with(sku.name, 'Premium')].{Nome:name, RG:resourceGroup, Sku:sku.name, GB:diskSizeGb, Anexado:managedBy != null}" -o table
  run "Snapshots completos (não incrementais)" \
    az snapshot list $S --query "[?incremental!=\`true\`].{Nome:name, RG:resourceGroup, GB:diskSizeGb}" -o table
  run "Storage Accounts: redundância e access tier" \
    az storage account list $S --query "[].{Nome:name, RG:resourceGroup, Tipo:kind, Sku:sku.name, Tier:accessTier}" -o table
  echo ""
  echo "--- Lifecycle management por conta (Sem policy = nenhuma regra de mover para Cool/Cold/Archive) ---"
  tsv az storage account list $S --query "[?kind=='StorageV2' || kind=='BlobStorage'].[resourceGroup, name]" | head -n "$LIMIT" | while IFS="$(printf '\t')" read -r rg sa; do
    [ -z "$sa" ] && continue
    if az storage account management-policy show $S --account-name "$sa" -g "$rg" -o none 2>/dev/null; then
      printf '%s\tcom lifecycle policy\n' "$sa"
    else
      printf '%s\tSEM lifecycle policy (ou sem permissão)\n' "$sa"
    fi
  done

  echo ""
  echo "=== [E3] Observabilidade (Log Analytics) ==="
  run "Workspaces" \
    az monitor log-analytics workspace list $S --query "[].{Nome:name, RG:resourceGroup, Sku:sku.name, Retencao:retentionInDays, CapDiarioGB:workspaceCapping.dailyQuotaGb}" -o table
  if [ "${LA_QUERY:-1}" = "1" ]; then
    tsv az monitor log-analytics workspace list $S --query "[].[resourceGroup, name, customerId]" | head -n 10 | while IFS="$(printf '\t')" read -r rg ws cid; do
      [ -z "$cid" ] && continue
      run "[$ws] Top 10 tabelas faturáveis em 30 dias (GB)" \
        az monitor log-analytics query -w "$cid" --analytics-query "Usage | where TimeGenerated > ago(30d) | where IsBillable == true | summarize IngestedGB = round(sum(Quantity) / 1000, 2) by DataType | top 10 by IngestedGB desc" -o table
      run "[$ws] Tabela legada ContainerLog (aposentada em 30/09/2026: deveria estar vazia)" \
        az monitor log-analytics query -w "$cid" --analytics-query "Usage | where TimeGenerated > ago(60d) | where DataType in ('ContainerLog','ContainerLogV2') | summarize GB = round(sum(Quantity) / 1000, 2), Ultimo = max(TimeGenerated) by DataType" -o table
      run "[$ws] Planos e retenção das tabelas com dados" \
        az monitor log-analytics workspace table list -g "$rg" --workspace-name "$ws" $S --query "[?contains(['ContainerLogV2','ContainerLog','AzureDiagnostics','Perf','KubeEvents','InsightsMetrics','Syslog','AppTraces','AppRequests','AzureActivity'], name)].{Tabela:name, Plano:plan, Retencao:retentionInDays, Total:totalRetentionInDays}" -o table
    done
  else
    echo "(Consultas KQL puladas: LA_QUERY=0)"
  fi

  echo ""
  echo "=== [E4] Rede ==="
  run "NAT Gateways" \
    az network nat gateway list $S --query "[].{Nome:name, RG:resourceGroup, Subnets:length(subnets || \`[]\`)}" -o table
  run "Application Gateways" \
    az network application-gateway list $S --query "[].{Nome:name, RG:resourceGroup, Sku:sku.name, Capacidade:sku.capacity, AutoMin:autoscaleConfiguration.minCapacity, AutoMax:autoscaleConfiguration.maxCapacity}" -o table
  run "Load Balancers Standard e nº de backend pools" \
    az network lb list $S --query "[?sku.name=='Standard'].{Nome:name, RG:resourceGroup, Pools:length(backendAddressPools || \`[]\`)}" -o table
  run "Custo do mês por categoria de medidor (exige extensão costmanagement)" \
    az costmanagement query --type ActualCost --timeframe MonthToDate --scope "/subscriptions/$SUB" --dataset-grouping name="MeterCategory" type="Dimension" -o table

  echo ""
  echo "=== [E5] Licenciamento ==="
  run "VMs Windows (License vazio = licença paga pela Azure; avaliar Azure Hybrid Benefit)" \
    az vm list $S --query "[?storageProfile.osDisk.osType=='Windows'].{Nome:name, RG:resourceGroup, Tamanho:hardwareProfile.vmSize, Licenca:licenseType}" -o table
  run "SQL Server em VM" \
    az sql vm list $S --query "[].{Nome:name, RG:resourceGroup, Licenca:sqlServerLicenseType}" -o table
}

echo "=== Cost Collector — Azure (somente leitura) ==="
echo "Data: $(date +%Y-%m-%d)"
for SUB in $(echo "$SUBS" | tr ',' ' '); do
  coletar "$SUB"
done
echo ""
echo "=== Coleta concluída. Itens 'Inconclusivo' vão para a seção Limitações do relatório. ==="
