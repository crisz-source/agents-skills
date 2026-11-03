#!/bin/sh
# finops_collector.sh — Varredura somente leitura de evidências FinOps em repositório/IaC.
# Uso: sh finops_collector.sh [diretório]   (padrão: diretório atual)
# Não altera nenhum arquivo. Saída limitada para não poluir o contexto.

set -f  # evita que os globs (*.tf) sejam expandidos pelo shell
ROOT="${1:-.}"
LIMIT="${FINOPS_LIMIT:-25}"

if [ ! -d "$ROOT" ]; then
  echo "ERRO: diretório '$ROOT' não existe." >&2
  exit 1
fi

HAS_RG=0
command -v rg >/dev/null 2>&1 && HAS_RG=1

# search <título> <regex ERE> [glob-de-arquivo...]
# Lista arquivo:linha das ocorrências (case-insensitive), ignorando .git, node_modules, .terraform e vendor.
search() {
  title="$1"; pattern="$2"; shift 2
  echo ""
  echo "--- $title ---"
  if [ "$HAS_RG" -eq 1 ]; then
    globs=""
    for g in "$@"; do globs="$globs --glob $g"; done
    # shellcheck disable=SC2086
    out=$(rg -n -i -e "$pattern" $globs \
      --glob '!.git/**' --glob '!**/node_modules/**' --glob '!**/.terraform/**' --glob '!**/vendor/**' \
      "$ROOT" 2>/dev/null | cut -c1-200 | head -n "$LIMIT")
  else
    includes=""
    for g in "$@"; do includes="$includes --include=$g"; done
    # shellcheck disable=SC2086
    out=$(grep -r -n -i -E "$pattern" $includes \
      --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.terraform --exclude-dir=vendor \
      "$ROOT" 2>/dev/null | cut -c1-200 | head -n "$LIMIT")
  fi
  if [ -n "$out" ]; then echo "$out"; else echo "(nenhuma ocorrência)"; fi
}

count_files() {
  find "$ROOT" -type d \( -name .git -o -name node_modules -o -name .terraform -o -name vendor \) -prune -o \
    -type f -name "$1" -print 2>/dev/null | wc -l | tr -d ' '
}

echo "=== FinOps Collector — evidências em repositório (somente leitura) ==="
echo "Diretório: $ROOT"
echo "Data: $(date +%Y-%m-%d)"

echo ""
echo "=== [1/7] Inventário de IaC ==="
echo "Terraform (*.tf):     $(count_files '*.tf')"
echo "Bicep (*.bicep):      $(count_files '*.bicep')"
echo "ARM (azuredeploy*):   $(count_files 'azuredeploy*.json')"
echo "Kubernetes/Helm yaml: $(count_files '*.yaml') (+ $(count_files '*.yml') .yml)"
echo "Pipelines:            $(count_files 'azure-pipelines*.yml') Azure DevOps | $(find "$ROOT" -path '*/.github/workflows/*' -type f 2>/dev/null | wc -l | tr -d ' ') GitHub Actions"

echo ""
echo "=== [2/7] Allocation — tags e metadados de custo ==="
search "Blocos de tags em IaC" '(^|[^a-z_])tags[[:space:]]*[=:]' '*.tf' '*.bicep' '*.json'
search "Chaves de tag de custo/dono/ambiente" '(cost[_-]?cent(er|re)|centro[_-]?de[_-]?custo|owner|respons[aá]vel|environment|ambiente|business[_-]?unit|secretaria|application)[^[:space:]=:]?[[:space:]]*[=:]' '*.tf' '*.bicep' '*.json' '*.yaml' '*.yml'

echo ""
echo "=== [3/7] Budgeting e Anomaly Management em IaC ==="
search "Budgets" '(azurerm_consumption_budget|Microsoft\.Consumption/budgets|consumption budget)' '*.tf' '*.bicep' '*.json' '*.sh' '*.yml' '*.yaml'
search "Alertas de anomalia / scheduled actions" '(azurerm_cost_anomaly_alert|scheduledActions|InsightAlert|anomaly)' '*.tf' '*.bicep' '*.json' '*.sh'

echo ""
echo "=== [4/7] Governance, Policy & Risk ==="
search "Azure Policy em IaC" '(azurerm_(subscription_|management_group_|resource_group_)?policy_(assignment|definition)|azurerm_policy_set_definition|Microsoft\.Authorization/policy(Assignments|Definitions|SetDefinitions))' '*.tf' '*.bicep' '*.json'
search "Políticas ligadas a tags/SKU/região" '(require.*tag|inherit.*tag|allowed.*(sku|location|locations)|tag.*(require|inherit))' '*.tf' '*.bicep' '*.json'

echo ""
echo "=== [5/7] Data Ingestion e Usage Optimization (automação) ==="
search "Exports do Cost Management / FOCUS" '(cost_management_export|Microsoft\.CostManagement/exports|costmanagement export|FOCUS|finops[_-]?hub)' '*.tf' '*.bicep' '*.json' '*.sh' '*.md' '*.py'
search "Agendas de desligamento / autoscale" '(dev_test_global_vm_shutdown_schedule|shutdown-computevm|auto_?shutdown|enable_auto_scaling|auto_scaling_enabled|autoscale|az aks stop|cluster-autoscaler)' '*.tf' '*.bicep' '*.json' '*.yml' '*.yaml' '*.sh'
search "Estimativa de custo no fluxo (Infracost etc.)" '(infracost|pricing[_-]?calculator|cost[_-]?estimate|estimativa de custo)' '*.yml' '*.yaml' '*.md' '*.tf' '*.json'

echo ""
echo "=== [6/7] Documentação e prática ==="
search "Documentos sobre custo/FinOps" '(finops|showback|chargeback|unit economics|custo por|cost per|or[cç]amento|budget|forecast)' '*.md' '*.txt' '*.adoc'

echo ""
echo "=== [7/7] Relatórios de outros agentes (finops-azure e azure-architect) ==="
reports=$(find "$ROOT" -type d \( -name .git -o -name node_modules \) -prune -o -type f -path '*reports/*' \( -name 'finops-*.json' -o -name 'arch-*.json' -o -name 'finops-*.html' -o -name 'arch-*.html' \) ! -name 'finops-maturidade-*' -print 2>/dev/null | sort | tail -n 10)
if [ -n "$reports" ]; then
  echo "$reports"
  echo "(Prefira o .json. finops-*: Usage/Rate Optimization, Architecting e Licensing. arch-*: cobertura de tags, locks e policies.)"
else
  echo "(nenhum relatório finops-* ou arch-* encontrado em reports/)"
fi

echo ""
echo "=== Aviso de segurança ==="
echo "Se alguma linha acima contiver segredo (chave, connection string, token), NÃO reproduza o valor:"
echo "cite apenas arquivo:linha e recomende rotação."
echo ""
echo "=== Coleta concluída ==="
