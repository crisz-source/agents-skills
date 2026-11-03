# Referência Técnica: Análise de Sizing, Requests/Limits e Custos

## Diretrizes de Avaliação de Sizing

1. **Configuração de Requests e Limits:**
   - **Request ausente (CPU ou memória):** o scheduler não sabe o tamanho do pod; agendamento imprevisível e pod na classe `BestEffort` (primeiro a ser despejado). Médio.
   - **Memória:** recomendar **limit = request**. Memória não é comprimível: limit muito acima do request permite overcommit e OOM no node, afetando vizinhos. Limit ausente: Médio/Alto conforme o namespace.
   - **CPU:** limit **não é obrigatório** e costuma causar throttling mesmo com o node ocioso. Recomende request bem dimensionado; use limit de CPU só quando houver motivo (multi-tenant, custo por cota, `Guaranteed` QoS). Limit de CPU muito próximo do request em aplicação com picos (ex.: JVM no startup) é achado de desempenho, não de segurança.
   - **LimitRange/ResourceQuota:** namespaces de aplicação sem padrão de requests ficam dependentes de cada time. Baixo/Médio.

2. **Identificação de Desperdício e Superdimensionamento:**
   - Comparar a utilização real do `Metrics Server` (`kubectl top nodes` e `kubectl top pods`) com as solicitações (`requests`).
   - Se o consumo médio < 20% do `request` e o histórico mantiver essa tendência, sinalizar oportunidade de redução (em CPU/memória; o valor em dinheiro é do finops-azure).
   - `kubectl top` é uma foto do momento: para afirmar superdimensionamento, prefira histórico (Prometheus/Container Insights) e diga a confiança (Potencial se só houver `top`).

3. **Detecção de Gargalos e Erros Dinâmicos:**
   - Identificar containers com histórico de terminação por `OOMKilled` (`lastState.terminated.reason: OOMKilled`).
   - Monitorar reinicializações Frequentes (`restartCount` elevado).
