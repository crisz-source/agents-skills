#!/bin/sh
# azure_governance_evidence.sh — Evidências de governança FinOps na Azure (SOMENTE LEITURA).
# Uso: sh azure_governance_evidence.sh <subscription-id> [tags,obrigatórias]
#   Tags padrão: Environment,Owner,CostCenter,Application (igual ao azure-architect; sem diferenciar maiúsculas).
# Usa apenas verbos de leitura: show, list, query e GET via 'az rest'.
# Não coleta desperdício (isso é a skill azure-cost-finops).

SUB="$1"
TAGS="${2:-Environment,Owner,CostCenter,Application}"

if [ -z "$SUB" ]; then
  echo "Uso: sh $0 <subscription-id> [tags,obrigatórias]" >&2
  exit 1
fi

if ! command -v az >/dev/null 2>&1; then
  echo "ERRO: Azure CLI (az) não encontrada. Evidências da Azure: Não avaliado." >&2
  exit 1
fi

if ! az account show -o none 2>/dev/null; then
  echo "ERRO: Azure CLI não autenticada. Peça ao usuário para rodar 'az login'. Evidências da Azure: Não avaliado." >&2
  exit 1
fi

SCOPE="/subscriptions/$SUB"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# run <título> <comando...> : executa, mostra saída ou registra "Não avaliado"
run() {
  title="$1"; shift
  echo ""
  echo "--- $title ---"
  if "$@" > "$TMP/out" 2> "$TMP/err"; then
    if [ -s "$TMP/out" ]; then head -n 40 "$TMP/out"; else echo "(nenhum item)"; fi
  else
    echo "Não avaliado: $(head -n 2 "$TMP/err" | tr '\n' ' ' | cut -c1-200)"
  fi
}

echo "=== Evidências de governança FinOps — Azure (somente leitura) ==="
echo "Data: $(date +%Y-%m-%d)"
az account show --subscription "$SUB" --query "{Subscription:name, Id:id, Tenant:tenantId}" -o table 2>/dev/null \
  || { echo "ERRO: sem acesso à subscription $SUB."; exit 1; }

# ---------- 1.2 Allocation: cobertura de tags ----------
echo ""
echo "=== [1/6] Allocation — cobertura de tags obrigatórias ($TAGS) ==="
if az resource list --subscription "$SUB" --query "[].{t:tags, g:resourceGroup}" -o json > "$TMP/res.json" 2> "$TMP/err"; then
  # No Windows, "python3" pode ser só o atalho da Microsoft Store: testa se roda de verdade.
  if python3 -c "import json" >/dev/null 2>&1; then
    python3 -I - "$TMP/res.json" "$TAGS" <<'PY'
import json, sys
res = json.load(open(sys.argv[1]))
req = [t.strip().lower() for t in sys.argv[2].split(",") if t.strip()]
total = len(res)
if total == 0:
    print("Nenhum recurso na subscription."); sys.exit(0)
full = 0
per_tag = {t: 0 for t in req}
untagged = 0
for r in res:
    keys = {k.lower() for k in (r.get("t") or {}).keys()}
    if not keys:
        untagged += 1
    for t in req:
        if t in keys:
            per_tag[t] += 1
    if all(t in keys for t in req):
        full += 1
print(f"Recursos: {total}")
print(f"Sem nenhuma tag: {untagged} ({untagged*100/total:.1f}%)")
print(f"Com TODAS as tags obrigatórias: {full} ({full*100/total:.1f}%)")
for t, n in per_tag.items():
    print(f"  tag '{t}': {n*100/total:.1f}%")
print("Obs.: cobertura por contagem de recursos, não por custo. % do custo alocado exige Cost Management.")
PY
  else
    echo "python3 indisponível: total de recursos = $(grep -c '"g"' "$TMP/res.json")"
  fi
else
  echo "Não avaliado: $(head -n 1 "$TMP/err" | cut -c1-200)"
fi

# ---------- 2.3 Budgeting ----------
echo ""
echo "=== [2/6] Budgeting ==="
run "Budgets na subscription" \
  az consumption budget list --subscription "$SUB" \
  --query "[].{Nome:name, Valor:amount, Periodo:timeGrain, Gasto:currentSpend.amount}" -o table

# ---------- 1.1 Data Ingestion ----------
echo ""
echo "=== [3/6] Data Ingestion — exports do Cost Management ==="
run "Exports (requer extensão costmanagement)" \
  az costmanagement export list --scope "$SCOPE" \
  --query "value[].{Nome:name, Tipo:properties.definition.type, Recorrencia:properties.schedule.recurrence, Status:properties.schedule.status}" -o table

# ---------- 1.4 Anomaly Management ----------
echo ""
echo "=== [4/6] Anomaly Management — alertas agendados ==="
run "Scheduled actions (alertas de anomalia = kind InsightAlert)" \
  az rest --method get \
  --url "https://management.azure.com$SCOPE/providers/Microsoft.CostManagement/scheduledActions?api-version=2022-10-01" \
  --query "value[].{Nome:name, Tipo:kind, Status:properties.status}" -o table

# ---------- 4.2 Governance, Policy & Risk ----------
echo ""
echo "=== [5/6] Governance, Policy & Risk — Azure Policy ==="
run "Total de atribuições de policy (inclui herdadas de management group)" \
  az policy assignment list --subscription "$SUB" --disable-scope-strict-match --query "length(@)" -o tsv
run "Atribuições ligadas a tags, SKU, região ou custo" \
  az policy assignment list --subscription "$SUB" --disable-scope-strict-match \
  --query "[?contains(to_string(displayName), 'Tag') || contains(to_string(displayName), 'tag') || contains(to_string(displayName), 'SKU') || contains(to_string(displayName), 'ocation') || contains(to_string(displayName), 'Cost') || contains(to_string(displayName), 'cost') || contains(to_string(displayName), 'usto')].{Nome:displayName, Modo:enforcementMode}" -o table

# ---------- 3.3 Usage Optimization (processo) ----------
echo ""
echo "=== [6/6] Usage Optimization — recomendações de custo do Advisor em aberto ==="
echo "(Apenas a contagem, como sinal de processo. O detalhamento é da skill azure-cost-finops.)"
run "Quantidade de recomendações de custo" \
  az advisor recommendation list --subscription "$SUB" --category Cost --query "length(@)" -o tsv

echo ""
echo "=== Coleta concluída. Itens 'Não avaliado' devem aparecer na seção Limitações do relatório. ==="
