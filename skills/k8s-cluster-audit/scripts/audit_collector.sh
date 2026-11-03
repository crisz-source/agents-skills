#!/bin/sh
# Audit Collector Script for Kubernetes Cluster Audit Skill
# Executa apenas comandos de leitura (get / top / version) e exporta diagnóstico leve.
# Não lê o conteúdo de Secrets.
#
# Uso: audit_collector.sh <contexto-do-kubectl>
# O contexto é obrigatório: o contexto atual da máquina pode ser de administrador.

CTX="$1"
if [ -z "$CTX" ]; then
  echo "Uso: audit_collector.sh <contexto-do-kubectl>  (ex.: aks-supp-prod-leitura)"
  echo "O contexto é obrigatório: este script não usa o contexto atual da máquina."
  exit 2
fi
LIMIT="${K8S_LIMIT:-60}"
k() { kubectl --context "$CTX" "$@"; }

# Tabela por pod com todos os containers (valores separados por vírgula).
# Uma única chamada alimenta as seções 3 e 4.
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "=== Contexto: $CTX ==="
k version 2>&1 | head -n 3

echo "
=== [1/11] Cluster e Nodes ==="
k cluster-info 2>&1 | head -n 3
k get nodes -o wide
echo "
--- Nodes com condição de pressão ou não prontos ---"
k get nodes --no-headers -o custom-columns='NODE:.metadata.name,READY:.status.conditions[?(@.type=="Ready")].status,MEM:.status.conditions[?(@.type=="MemoryPressure")].status,DISK:.status.conditions[?(@.type=="DiskPressure")].status,PID:.status.conditions[?(@.type=="PIDPressure")].status' \
  | awk '$2!="True" || $3=="True" || $4=="True" || $5=="True" {print; n++} END {if (!n) print "Todos os nodes Ready e sem pressão."}'

echo "
=== [2/11] Pods fora de Running/Succeeded (Pending, Failed, Unknown) ==="
k get pods --all-namespaces --field-selector 'status.phase!=Running,status.phase!=Succeeded' 2>&1 | head -n "$LIMIT"

k get pods --all-namespaces --no-headers \
  -o custom-columns='NS:.metadata.namespace,POD:.metadata.name,RESTARTS:.status.containerStatuses[*].restartCount,WAITING:.status.containerStatuses[*].state.waiting.reason,LASTTERM:.status.containerStatuses[*].lastState.terminated.reason,IRESTARTS:.status.initContainerStatuses[*].restartCount,IWAITING:.status.initContainerStatuses[*].state.waiting.reason,ILASTTERM:.status.initContainerStatuses[*].lastState.terminated.reason' \
  2>/dev/null | awk '{ print $1 "\t" $2 "\t" $3 "," $6 "\t" $4 "," $7 "\t" $5 "," $8 }' > "$TMP/pods"
# Colunas 3-5 juntam containers normais e init containers (inclui sidecars nativos, restartPolicy: Always).

echo "
=== [3/11] Containers em espera com erro (CrashLoopBackOff, ImagePull, Config, OOMKilled recente) ==="
# Pods em CrashLoopBackOff ficam na fase Running: por isso não aparecem na seção 2.
awk -F'\t' '$4 ~ /CrashLoopBackOff|ImagePullBackOff|ErrImagePull|CreateContainerConfigError|CreateContainerError|InvalidImageName/ || $5 ~ /OOMKilled|Error/ {
       printf "%s\t%s\tespera=%s\tultimo_termino=%s\n", $1, $2, $4, $5; n++ }
     END { if (!n) print "Nenhum container em espera com erro." }' "$TMP/pods" | head -n "$LIMIT"

echo "
=== [4/11] Reinicializações frequentes (algum container com mais de 5) ==="
# custom-columns junta os containers do pod por vírgula; antes só o 1º container era lido.
awk -F'\t' '{ split($3, r, ","); max = 0; for (i in r) if (r[i] + 0 > max) max = r[i] + 0;
       if (max > 5) { printf "%s\t%s\trestarts(containers,init/sidecars)=%s\n", $1, $2, $3; n++ } }
     END { if (!n) print "Nenhum container com mais de 5 restarts." }' "$TMP/pods" | head -n "$LIMIT"

echo "
=== [5/11] Métricas de recursos (se o Metrics Server existir) ==="
k top nodes 2>/dev/null || echo "Metrics Server não disponível para Nodes."
echo "--- Top 25 pods por memória ---"
k top pods --all-namespaces --sort-by=memory 2>/dev/null | head -n 26 || echo "Metrics Server não disponível para Pods."

echo "
=== [6/11] PVCs fora de Bound e PVs Released/Failed ==="
k get pvc --all-namespaces --no-headers 2>/dev/null | awk '$3!="Bound" {print; n++} END {if (!n) print "Todos os PVCs estão Bound."}'
k get pv --no-headers 2>/dev/null | awk '$5=="Released" || $5=="Failed" {print; n++} END {if (!n) print "Nenhum PV Released/Failed."}'

echo "
=== [7/11] Services sem nenhum endpoint pronto (somando todos os EndpointSlices do Service) ==="
# v1 Endpoints é obsoleto desde a 1.33; a fonte atual é discovery.k8s.io/v1 EndpointSlice.
# Um Service pode ter vários slices: só é problema se NENHUM tiver endpoint pronto.
k get endpointslices --all-namespaces --no-headers \
  -o custom-columns='NS:.metadata.namespace,SVC:.metadata.labels.kubernetes\.io/service-name,READY:.endpoints[*].conditions.ready' 2>/dev/null \
  | awk '$2 != "<none>" { key = $1 "\t" $2; seen[key] = 1; if ($3 ~ /true/) ok[key] = 1 }
         END { for (s in seen) if (!(s in ok)) { print s "\t(sem endpoints prontos)"; n++ }
               if (!n) print "Todos os Services com seletor têm endpoint pronto." }' | sort | head -n "$LIMIT"

echo "
=== [8/11] Namespaces sem Pod Security Admission (label enforce) ==="
k get ns --no-headers -o custom-columns='NS:.metadata.name,ENFORCE:.metadata.labels.pod-security\.kubernetes\.io/enforce' 2>/dev/null \
  | awk '$1 !~ /^(kube-system|kube-public|kube-node-lease|gatekeeper-system|calico-system|tigera-operator)$/ && $2=="<none>" {print $1; n++}
         END {if (!n) print "Todos os namespaces de aplicação têm PSA enforce."}' | head -n "$LIMIT"

echo "
=== [9/11] Imagens com tag mutável (:latest ou sem tag) ==="
k get pods --all-namespaces --no-headers -o custom-columns='NS:.metadata.namespace,POD:.metadata.name,IMAGES:.spec.containers[*].image,INIT:.spec.initContainers[*].image' 2>/dev/null \
  | awk '{ if ($4 != "<none>") $3 = $3 "," $4; print $1 "\t" $2 "\t" $3 }' > "$TMP/images"
awk -F'\t' '{ split($3, im, ","); for (i in im) { img = im[i]; sub(/@sha256:.*/, "", img); last = img; sub(/.*\//, "", last);
           if (im[i] !~ /@sha256:/ && (last !~ /:/ || last ~ /:latest$/)) { printf "%s\t%s\t%s\n", $1, $2, im[i]; n++ } } }
         END { if (!n) print "Nenhuma imagem com tag mutável." }' "$TMP/images" | head -n "$LIMIT"

echo "
=== [10/11] Ingress: controladores e Gateway API ==="
echo "Ingress NGINX comunitário: manutenção encerrada em março/2026. NGINX do Application Routing (AKS): suporte até novembro/2026."
k get ingressclass --no-headers -o custom-columns='CLASSE:.metadata.name,CONTROLADOR:.spec.controller' 2>/dev/null \
  | awk '{ tag = ""; if ($2 ~ /ingress-nginx/) tag = "  <- Ingress NGINX comunitário"; if ($2 ~ /webapprouting/) tag = "  <- NGINX do Application Routing (AKS)"; print $0 tag }'
echo "--- Pods do controlador NGINX (imagem e versão) ---"
grep -i -E 'ingress-nginx|nginx-ingress|/controller:v' "$TMP/images" | head -n 10 || true
[ -z "$(grep -i -E 'ingress-nginx|nginx-ingress|/controller:v' "$TMP/images")" ] && echo "Nenhum pod de controlador NGINX encontrado."
echo "Recursos Ingress no cluster: $(k get ingress --all-namespaces --no-headers 2>/dev/null | wc -l | tr -d ' ')"
if k get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1; then
  echo "Gateway API instalada. GatewayClasses:"; k get gatewayclass --no-headers 2>/dev/null | head -n 10
  echo "Gateways: $(k get gateways --all-namespaces --no-headers 2>/dev/null | wc -l | tr -d ' ') | HTTPRoutes: $(k get httproutes --all-namespaces --no-headers 2>/dev/null | wc -l | tr -d ' ')"
else
  echo "Gateway API (CRDs gateway.networking.k8s.io) não instalada."
fi

echo "
=== [11/11] Identidade de workloads (aad-pod-identity x Workload Identity) ==="
if k get crd azureidentities.aadpodidentity.k8s.io >/dev/null 2>&1 || grep -q -i 'aad-pod-identity' "$TMP/images"; then
  echo "aad-pod-identity ENCONTRADO (descontinuado; add-on do AKS suportado só até set/2025):"
  grep -i 'aad-pod-identity' "$TMP/images" | head -n 5
  echo "AzureIdentities: $(k get azureidentities --all-namespaces --no-headers 2>/dev/null | wc -l | tr -d ' ')"
else
  echo "aad-pod-identity não encontrado."
fi
echo "ServiceAccounts com Workload Identity (anotação azure.workload.identity/client-id): $(k get sa --all-namespaces --no-headers -o custom-columns='WI:.metadata.annotations.azure\.workload\.identity/client-id' 2>/dev/null | grep -v -c '<none>')"

echo "
--- Eventos Warning mais recentes ---"
k get events --all-namespaces --field-selector type=Warning --sort-by=.lastTimestamp 2>/dev/null | tail -n 30

echo "
=== Coleta Concluída ==="
