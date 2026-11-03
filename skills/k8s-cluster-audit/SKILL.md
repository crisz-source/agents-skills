---
name: k8s-cluster-audit
description: Skill especializada para auditoria, análise de saúde, segurança, sizing e otimização de clusters Kubernetes em modo somente-leitura.
allowed-tools: Bash(kubectl config current-context*) Bash(kubectl config get-contexts*) Bash(kubectl version*) Bash(kubectl get *) Bash(kubectl describe *) Bash(kubectl top *) Bash(kubectl events *) Bash(kubectl auth can-i *) Bash(kubectl api-resources*) Bash(kubectl --context * get *) Bash(kubectl --context * describe *) Bash(kubectl --context * top *) Bash(sh ${CLAUDE_SKILL_DIR}/scripts/*)
---
# Skill: Auditoria e Otimização de Cluster Kubernetes
Esta habilidade executa uma auditoria completa, não destrutiva (somente leitura) de clusters Kubernetes, cobrindo saúde dos workloads, dimensionamento de CPU/memória, segurança, alta disponibilidade, redes, armazenamento e conformidade declarativa.
O coletor (Etapa 2) cobre: nodes e pressão, pods com erro (inclusive `CrashLoopBackOff`, que fica na fase Running), restarts por container, métricas, PVC/PV, Services sem endpoint, namespaces sem Pod Security Admission, imagens com tag mutável e eventos Warning.

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
- **Redes & Armazenamento:** Análise segundo `${CLAUDE_SKILL_DIR}/references/network_storage.md` (Services sem Endpoints, Ingress, TLS, PVCs em `Pending`, StorageClasses).
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
