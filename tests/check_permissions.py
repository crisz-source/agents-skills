#!/usr/bin/env python3
"""Simula as regras allow/deny (curinga * = qualquer texto; deny vence allow) do
permissoes.json da raiz (união) e de CADA permissoes/<agente>.json.

Para cada agente verifica:
  - o que ele precisa fazer é PERMITIDO;
  - escrita, segredos e comandos perigosos são NEGADOS (comum a todos);
  - ferramentas fora do escopo dele são NEGADAS (ex.: k8s-auditor não roda az);
  - scripts e arquivos das skills dos OUTROS agentes são NEGADOS (isolamento).
"""
import json, re, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
BASE = json.loads((ROOT / "permissoes" / "fonte.json").read_text(encoding="utf-8"))["raiz_plugin"].rstrip("/")

def carregar(p):
    P = json.loads(p.read_text(encoding="utf-8"))["permissions"]
    def rx(r):
        m = re.match(r"Bash\((.*)\)$", r)
        return re.compile("^" + ".*".join(map(re.escape, m.group(1).split("*"))) + "$", re.S) if m else None
    return [(r, rx(r)) for r in P["allow"] if rx(r)], [(r, rx(r)) for r in P["deny"] if rx(r)]

def verdict(regras, cmd):
    allow, deny = regras
    for p, r in deny:
        if r.match(cmd):
            return "NEGADO", p
    for p, r in allow:
        if r.match(cmd):
            return "PERMITIDO", p
    return "PERGUNTA", ""

SKILL_DE = {"finops-azure": "azure-cost-finops", "finops-maturidade": "finops-framework",
            "azure-architect": "azure-arch-audit", "cloud-security-analyst": "cloud-security-audit",
            "k8s-auditor": "k8s-cluster-audit", "log-hunter": "log-hunter"}
SCRIPT = {"azure-cost-finops": "cost_collector.sh", "finops-framework": "finops_collector.sh",
          "azure-arch-audit": "azure_collector.sh", "cloud-security-audit": "cloud_sec_collector.sh",
          "k8s-cluster-audit": "audit_collector.sh", "log-hunter": "mask.sh"}
def roda(skill):
    return f"sh {BASE}/skills/{skill}/scripts/{SCRIPT[skill]}"

# Negado para TODOS (escrita, segredos, comandos perigosos)
NEGAR_SEMPRE = [
    'az group delete -n rg-supp-hml --yes', 'az vm deallocate -g rg -n vm1',
    'az storage account keys list -n conta', 'az webapp config appsettings list -g rg -n app',
    'az redis list-keys -g rg -n r', 'az advisor recommendation disable --ids x',
    'az storage account show-connection-string -n conta', 'az keyvault secret show --vault-name cofre -n senha',
    'az webapp deployment list-publishing-profiles -g rg -n app', 'az acr credential show -n acr',
    'az aks command invoke -g rg -n aks --command "kubectl get secrets -o yaml"',
    'az vm run-command invoke -g rg -n vm --command-id RunShellScript',
    'az rest --method delete --url https://management.azure.com/x',
    'az aks get-credentials -g rg -n aks --admin', 'az storage container generate-sas --account-name x -n c',
    'az role assignment create --assignee x --role Owner', 'az aks update -g rg -n aks --enable-app-routing-istio',
    'kubectl delete pod api-1', 'kubectl --context aks-prod delete pod api-1',
    'kubectl --context aks-prod exec -it api-1 -- sh', 'kubectl get secret db -o yaml',
    'kubectl get secret db -ojson', 'kubectl get secret db --output=yaml',
    'kubectl get secrets -n app -o=jsonpath={.items}', 'kubectl get --raw /api/v1/namespaces/app/secrets',
    'kubectl debug node/n1 -it --image=busybox', 'kubectl run x --image=busybox',
    'docker exec api env', 'systemctl restart nginx', 'rm -rf reports', 'git push origin main',
]

AZ_LEITURA = ['az account show', 'az aks nodepool list -g rg --cluster-name aks --query "[].{Pool:name}" -o table',
              'az advisor recommendation list --category Cost', 'az keyvault secret list --vault-name cofre --query "[].name"']
KUBECTL = ['kubectl config current-context', 'kubectl get pods -A', 'kubectl --context aks-hml get pods -A',
           'kubectl get secrets -n app', 'kubectl get ingressclass', 'kubectl describe pod -n app api-1']

PERMITIR = {
    "finops-azure": AZ_LEITURA + [
        'az monitor log-analytics query -w 1 --analytics-query "Usage | summarize sum(Quantity) by DataType" -o table',
        'az costmanagement query --type ActualCost --timeframe MonthToDate --scope "/subscriptions/x" --dataset-grouping name="MeterCategory" type="Dimension"',
        'az monitor metrics list --resource id --metric "Percentage CPU" --start-time 2026-10-01 --interval PT1H'],
    "finops-maturidade": ['az account show', 'grep -rn budget .', 'rg -i finops'],
    "azure-architect": AZ_LEITURA + ['az graph query -q "Resources | count"'],
    "cloud-security-analyst": AZ_LEITURA + ['grep -rnI password .', 'rg -n AccountKey'],
    "k8s-auditor": KUBECTL + ['kubectl top pods -A'],
    "log-hunter": ['kubectl logs -n app api-1 --tail=500', 'kubectl describe pod -n app api-1',
                   'kubectl get events -n app --sort-by=.lastTimestamp', 'docker logs --tail 500 api',
                   "docker inspect --format '{{.State.Status}}' api", 'journalctl -u nginx --no-pager',
                   'az account show', 'az monitor log-analytics query -w 1 --analytics-query "ContainerLogV2 | take 10"',
                   'grep -rn ERROR /var/log/app'],
}
# Fora do escopo de cada agente
NEGAR_ESCOPO = {
    "finops-azure": ['kubectl get pods -A', 'docker logs api', 'journalctl -u x'],
    "finops-maturidade": ['kubectl get pods -A', 'docker logs api'],
    "azure-architect": ['kubectl get pods -A', 'docker logs api'],
    "cloud-security-analyst": ['kubectl get pods -A', 'docker logs api'],
    "k8s-auditor": ['az account show', 'az aks list', 'docker logs api', 'journalctl -u x'],
    "log-hunter": [],
}

falhas = total = 0
def esperar(regras, cmd, esperado, rotulo):
    global falhas, total
    total += 1
    v, p = verdict(regras, cmd)
    if v != esperado:
        falhas += 1
        print(f"  FALHA [{rotulo}] esperado {esperado}, veio {v} [{p}] :: {cmd[:110]}")

# 1) Arquivo único (união)
uniao = carregar(ROOT / "permissoes.json")
for c in NEGAR_SEMPRE:
    esperar(uniao, c, "NEGADO", "união")
for ag, cmds in PERMITIR.items():
    for c in cmds:
        esperar(uniao, c, "PERMITIDO", "união")

# 2) Cada agente
for ag, skill in SKILL_DE.items():
    regras = carregar(ROOT / "permissoes" / f"{ag}.json")
    for c in NEGAR_SEMPRE:
        esperar(regras, c, "NEGADO", ag)
    for c in PERMITIR[ag]:
        esperar(regras, c, "PERMITIDO", ag)
    for c in NEGAR_ESCOPO[ag]:
        esperar(regras, c, "NEGADO", ag)
    esperar(regras, roda(skill), "PERMITIDO", ag)
    for outra in SKILL_DE.values():
        if outra != skill:
            esperar(regras, roda(outra), "NEGADO", f"{ag}: script de {outra}")
            esperar(regras, f"cat {BASE}/skills/{outra}/SKILL.md", "NEGADO", f"{ag}: ler {outra}")
    esperar(regras, "docker inspect api", "NEGADO" if ag != "log-hunter" else "PERGUNTA", ag)

print(f"  {total} verificações (união + 6 agentes), {falhas} falha(s)")
sys.exit(1 if falhas else 0)
