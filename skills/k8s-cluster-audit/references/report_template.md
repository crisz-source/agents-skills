# Modelo de Relatório de Auditoria de Cluster Kubernetes

## Resumo Executivo
- **Data da Auditoria:** {{DATA}}
- **Contexto / Cluster:** {{CLUSTER_CONTEXT}}
- **Versão do Kubernetes:** {{K8S_VERSION}}
- **Coletor de Métricas Operacional:** {{METRICS_PROVIDER}} (Metrics Server / Prometheus / Indisponível)
- **Achados por severidade:** Crítico {{N_CRIT}} · Alto {{N_ALTO}} · Médio {{N_MED}} · Baixo {{N_BAIXO}}

---

## 1. Visão Geral do Cluster
- **Total de Nodes:** {{TOTAL_NODES}} (Ready: {{READY_NODES}})
- **Total de Namespaces Auditados:** {{TOTAL_NS}}
- **Total de Pods:** {{TOTAL_PODS}} (Running: {{RUNNING_PODS}}, Failed/Pending: {{FAILED_PODS}})

---

## 2. Problemas Críticos e Urgentes
| ID | Recurso / Namespace | Problema Identificado | Severidade | Impacto Potencial |
|---|---|---|---|---|
| SEC-01 | ... | ... | Alta/Crítica | ... |
| RES-01 | ... | ... | Crítica | ... |

---

## 3. Detalhamento dos Achados por Categoria

### A. Segurança & RBAC
- **Achado SEC-01:** {{TITULO}}
  - **Recurso Atingido:** `namespace/kind/name`
  - **Evidência Observada:** `{{EVIDENCIA}}`
  - **Grau de Confiança:** Confirmado
  - **Recomendação de Correção:** ...
  - **Plano de Validação:** `kubectl get ...`

### B. Dimensionamento, Sizing e Custos
- **Achado SIZ-01:** {{TITULO}}
  - ...

### C. Resiliência e Alta Disponibilidade
- ...

### D. Redes e Armazenamento
- ...

---

## 4. Oportunidades de Otimização e Redução de Custos
- Estimativa de CPU/Memória recuperável: ...
- Ações sugeridas para consolidar recursos (em CPU e memória; valores em dinheiro são do finops-azure).

---

## 5. Limitações da Auditoria & Próximos Passos
- Ferramentas não acessíveis durante a auditoria (se houver).
- Plano de ação sugerido em ciclos de sprint.
