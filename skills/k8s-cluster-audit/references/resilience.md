# Referência Técnica: Alta Disponibilidade e Resiliência

## Critérios de Avaliação

1. **Probes da Aplicação:**
   - **Liveness Probe:** Verificar se está configurado adequadamente (evitar checagens pesadas de DB que causam restarts em cadeia).
   - **Readiness Probe:** Garantir que o tráfego só seja direcionado quando a aplicação estiver apta a responder.
   - **Startup Probe:** Essencial para aplicações de inicialização lenta para evitar falsos-positivos na Liveness Probe.

2. **Distribuição e Tolerância a Falhas:**
   - **Replicas:** Mínimo de 2 réplicas para serviços críticos em produção.
   - **PodDisruptionBudget (PDB):** Verificar existência e se `minAvailable` / `maxUnavailable` não bloqueiam drenagem de nodes durante manutenção.
   - **HorizontalPodAutoscaler (HPA):** Verificar se os targets de CPU/Memória/Métricas customizadas estão configurados e coerentes com os `requests`.
   - **Afinidade e TopologySpreadConstraints:** Garantir distribuição multi-AZ ou multi-node para evitar pontos únicos de falha.

3. **Imagens Reproduzíveis:**
   - Tags mutáveis (`:latest` ou sem tag) impedem rollback determinístico: um restart pode subir outra versão. Recomendar tag de versão ou digest (`@sha256:`).
