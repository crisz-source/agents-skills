# Referência Técnica: Análise de Sizing, Requests/Limits e Custos

## Diretrizes de Avaliação de Sizing

1. **Configuração de Requests e Limits:**
   - **Request ausente:** Pod pode sofrer starvation de CPU/Memória ou agendamento imprevisível.
   - **Limit ausente para Memória:** Risco de OOMKilled no Node (pode levar à indisponibilidade de vizinhos).
   - **CPU Request x Limit excessivo:** Pode induzir CPU Throttling severo em rajadas de tráfego.

2. **Identificação de Desperdício e Superdimensionamento:**
   - Comparar a utilização real do `Metrics Server` (`kubectl top nodes` e `kubectl top pods`) com as solicitações (`requests`).
   - Se o consumo médio < 20% do `request` e o histórico mantiver essa tendência, sinalizar oportunidade de redução de custos.

3. **Detecção de Gargalos e Erros Dinâmicos:**
   - Identificar containers com histórico de terminação por `OOMKilled` (`lastState.terminated.reason: OOMKilled`).
   - Monitorar reinicializações Frequentes (`restartCount` elevado).
