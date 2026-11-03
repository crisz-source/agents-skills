#!/usr/bin/env python3
"""Simula as regras de permissions.allow/deny do permissoes.json (curinga * = qualquer texto;
deny vence allow) contra comandos que DEVEM ser permitidos e que DEVEM ser negados."""
import json, re, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
P = json.loads((ROOT / "permissoes.json").read_text(encoding="utf-8"))["permissions"]

def rx(p):
    m = re.match(r"Bash\((.*)\)$", p)
    return re.compile("^" + ".*".join(map(re.escape, m.group(1).split("*"))) + "$", re.S) if m else None

ALLOW = [(p, rx(p)) for p in P["allow"] if rx(p)]
DENY = [(p, rx(p)) for p in P["deny"] if rx(p)]

def verdict(cmd):
    for p, r in DENY:
        if r.match(cmd):
            return "NEGADO", p
    for p, r in ALLOW:
        if r.match(cmd):
            return "PERMITIDO", p
    return "PERGUNTA", ""

DEVE_PERMITIR = [
    'az account show',
    'az aks nodepool list -g rg --cluster-name aks --query "[].{Pool:name, Autoscale:enableAutoScaling}" -o table',
    'az monitor log-analytics query -w 123 --analytics-query "Usage | where TimeGenerated > ago(30d) | summarize sum(Quantity) by DataType" -o table',
    'az costmanagement query --type ActualCost --timeframe MonthToDate --scope "/subscriptions/x" --dataset-grouping name="MeterCategory" type="Dimension"',
    'az storage account management-policy show --account-name x -g rg',
    'az monitor metrics list --resource id --metric "Percentage CPU" --start-time 2026-10-01 --interval PT1H',
    'az keyvault secret list --vault-name cofre --query "[].name"',
    'az advisor recommendation list --category Cost',
    'kubectl config current-context',
    'kubectl get pods -A',
    'kubectl --context aks-hml get pods -A',
    'kubectl get secrets -n app',
    'kubectl get ingressclass',
    'kubectl describe pod -n app api-1',
    'kubectl logs -n app api-1 --all-containers --tail=500 --timestamps',
    'kubectl get events -n app --sort-by=.lastTimestamp',
    "docker inspect --format '{{.State.Status}} restarts={{.RestartCount}}' api",
    'docker logs --tail 500 --timestamps api',
    'journalctl -u nginx --since "1 hour ago" --no-pager',
    'sh C:/meus-agentes/skills/k8s-cluster-audit/scripts/audit_collector.sh aks-hml',
]
DEVE_NEGAR = [
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
# Pede confirmação (não é aprovado sozinho nem negado): aceitável.
DEVE_PERGUNTAR = ['docker inspect api']

falhas = 0
for c in DEVE_PERMITIR:
    v, p = verdict(c)
    if v != "PERMITIDO":
        falhas += 1; print(f"  FALHA: esperado PERMITIDO, veio {v} [{p}] :: {c[:110]}")
for c in DEVE_NEGAR:
    v, _ = verdict(c)
    if v != "NEGADO":
        falhas += 1; print(f"  FALHA: esperado NEGADO, veio {v} :: {c}")
for c in DEVE_PERGUNTAR:
    v, _ = verdict(c)
    if v == "PERMITIDO":
        falhas += 1; print(f"  FALHA: não deveria ser aprovado sozinho :: {c}")
total = len(DEVE_PERMITIR) + len(DEVE_NEGAR) + len(DEVE_PERGUNTAR)
print(f"  {total} comandos simulados, {falhas} falha(s)")
sys.exit(1 if falhas else 0)
