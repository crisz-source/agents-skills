---
name: k8s-cluster-audit
description: Auditoria de clusters Kubernetes (AKS, RKE2, kubeadm) por dentro, somente leitura - saúde de workloads, restarts (inclusive sidecars), segurança e RBAC, Pod Security Admission, Ingress NGINX descontinuado e Gateway API, identidade de workloads, resiliência, rede, armazenamento e sizing de requests/limits. Não cobre a camada Azure do AKS (cloud-security-audit), custo em dinheiro (azure-cost-finops) nem logs de aplicação (log-hunter).
allowed-tools: Bash(kubectl config current-context*) Bash(kubectl config get-contexts*) Bash(kubectl version*) Bash(kubectl get *) Bash(kubectl describe *) Bash(kubectl top *) Bash(kubectl events *) Bash(kubectl auth can-i *) Bash(kubectl api-resources*) Bash(kubectl --context * get *) Bash(kubectl --context * describe *) Bash(kubectl --context * top *) Bash(sh ${CLAUDE_SKILL_DIR}/scripts/*)
---
# Skill: Auditoria e Otimização de Cluster Kubernetes
Esta habilidade executa uma auditoria completa, não destrutiva (somente leitura) de clusters Kubernetes, cobrindo saúde dos workloads, dimensionamento de CPU/memória, segurança, alta disponibilidade, redes, armazenamento e conformidade declarativa.
O coletor (Etapa 2) cobre: nodes e pressão, pods com erro (inclusive `CrashLoopBackOff`, que fica na fase Running, e init containers), restarts por container e por sidecar nativo, métricas, PVC/PV, Services sem endpoint, namespaces sem Pod Security Admission, imagens com tag mutável, controladores de Ingress (NGINX descontinuado) e Gateway API, aad-pod-identity x Workload Identity e eventos Warning.

## Diretivas de Segurança e Princípios Operacionais
1. **Operação 100% Somente-Leitura (Read-Only):**
   - NUNCA execute comandos de modificação (`kubectl apply`, `delete`, `edit`, `patch`, `scale`, `exec`) durante a auditoria.
   - Forneça recomendações e manifests de correção apenas em bloco de código YAML/bash para execução manual e consciente pelo usuário.
2. **Proteção de Dados Sensíveis:**
   - NUNCA exponha valores de `Secrets` ou tokens de `ServiceAccount`. Ao inspecionar `Secrets`, verifique apenas metadados, tamanhos e vinculações de volume/env.
3. **Confirmação de Contexto:**
   - Antes de iniciar a coleta profunda, valide e apresente o contexto atual do cluster (`kubectl config current-context`) e informe o escopo autorizado.
---
## Fluxo de Trabalho de Auditoria
### Etapa 1: Validação de Escopo e Detecção de Ferramentas
1. Execute a verificação do ambiente e ferramentas disponíveis:
   ```bash
   kubectl config current-context
   kubectl version
   ```
2. Detecte a presença de coletores de métricas:
   - **Metrics Server:** `kubectl get apiservices v1beta1.metrics.k8s.io`
   - **Prometheus/CRDs:** `kubectl get crd | grep -i prometheus`
3. Ajuste o nível de profundidade da análise de dimensionamento com base nas métricas disponíveis.
---
### Etapa 2: Coleta de Dados Determinística
Execute o script auxiliar de coleta fornecido para consolidar o estado operacional do cluster sem alterar nenhum recurso:
```bash
sh ${CLAUDE_SKILL_DIR}/scripts/audit_collector.sh <contexto-do-kubectl>
```
---
### Etapa 3: Análise Modular por Área Tecnica
Consulte os arquivos de referência especializados contidos na skill para orientar cada pilar de análise:
- **Saúde e Cargas de Trabalho:** Verifique Pods `CrashLoopBackOff`, `OOMKilled`, `Pending`, nodes com pressão, réplicas indisponíveis, Jobs com falha e eventos `Warning` recentes.
- **Dimensionamento & Custos:** Análise segundo `${CLAUDE_SKILL_DIR}/references/sizing.md` (Requests vs Limits, CPU Throttling, Capacidade de Nodes).
- **Segurança & RBAC:** Análise segundo `${CLAUDE_SKILL_DIR}/references/security.md` (Containers privilegiados, `runAsRoot`, permissões excessivas, exposição de portas).
- **Resiliência e Alta Disponibilidade:** Análise segundo `${CLAUDE_SKILL_DIR}/references/resilience.md` (Probes de Liveness/Readiness/Startup, PDB, TopologySpreadConstraints, Antiafinidade).
- **Redes, Ingress & Armazenamento:** Análise segundo `${CLAUDE_SKILL_DIR}/references/network_storage.md` (Services sem Endpoints, **migração do Ingress NGINX para Gateway API**, TLS, PVCs em `Pending`, StorageClasses).
---
### Etapa 4: Síntese e Geração do Relatório
Estruture o relatório final seguindo rigorosamente o template em `${CLAUDE_SKILL_DIR}/references/report_template.md`.
Cada achado deve conter obrigatoriamente:
- **Recurso & Namespace:** Identificação exata
- **Evidência Observada:** Dados brutos/comprovantes
- **Problema & Impacto:** Severidade (Crítico, Alto, Médio, Baixo)
- **Nível de Confiança:** Confirmado | Potencial | Inconclusivo
- **Recomendação & Risco da Alteração:** Como corrigir e cuidados ao aplicar
- **Forma de Validação:** Comando para verificar a resolução
---
## Recursos de Suporte Adicionais
- [Regras de Dimensionamento](references/sizing.md)
- [Regras de Segurança & RBAC](references/security.md)
- [Regras de Resiliência](references/resilience.md)
- [Regras de Rede e Armazenamento](references/network_storage.md)
- [Template de Relatório](references/report_template.md)

## Padrão de saída (comum a todos os agentes)
Siga `${CLAUDE_SKILL_DIR}/references/report_standard.md`:
- **Dois arquivos** com o mesmo nome-base em `reports/`: `.html` (pessoas) e `.json` (outros agentes, Colmeia, comparação).
- **Vocabulário único:** severidade Crítico · Alto · Médio · Baixo · Info; confiança Confirmado · Potencial · Inconclusivo.
- **`fingerprint` estável** por achado (`<categoria>|<recurso>`), sem valores que mudam a cada execução.
- **"Desde a última auditoria":** compare com o JSON anterior do mesmo `<tipo>-<escopo>` (novos, resolvidos, persistentes, pioraram/melhoraram).
