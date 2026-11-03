# Referência: Gestão da Prática, KPIs e Unit Economics

## 1. KPIs de referência do modelo de maturidade
Valores publicados pela FinOps Foundation como referência (não são metas obrigatórias):

| KPI | Crawl | Walk | Run |
|---|---|---|---|
| % do custo alocado a um dono conhecido | ≥ 70% | ≥ 85% | > 90% |
| Cobertura de descontos por compromisso | ~60% | > 75% | > 80% |
| Variação previsto vs. realizado (forecast) | < 20% | < 10% | < 5% |

### Outros KPIs úteis (definir meta com o usuário)
- **Utilização de compromissos:** % das horas reservadas efetivamente usadas (abaixo de ~95% indica compra excessiva).
- **Cobertura de tags:** % de recursos com todas as tags obrigatórias (medido pelo script `azure_governance_evidence.sh`).
- **MTTD / MTTR de anomalia:** tempo até detectar e até resolver um gasto anormal.
- **Taxa de desperdício:** desperdício identificado (relatório `azure-cost-finops`) dividido pelo gasto total.
- **Idade das recomendações:** tempo médio que uma recomendação de custo fica aberta.
- **% de cargas novas com estimativa de custo** antes de entrar em produção.

Sempre indique a fonte de cada KPI: medido (dado), declarado (entrevista) ou não disponível.

## 2. Unit Economics
Métrica unitária = custo de tecnologia ÷ unidade de valor entregue.

Passos para propor:
1. Identificar o que o sistema/Scope **entrega** e que pode ser contado.
2. Confirmar se existe fonte confiável para esse número (sistema, BI, relatórios oficiais).
3. Garantir que o custo do numerador esteja alocado (depende de 1.2 Allocation).
4. Propor uma métrica primária e no máximo duas secundárias.

Exemplos por contexto:
| Contexto | Métrica unitária |
|---|---|
| Sistema jurídico / processual (setor público) | Custo por processo ativo; custo por peça/documento gerado; custo por usuário (servidor/procurador) ativo |
| Serviço ao cidadão | Custo por atendimento; custo por solicitação concluída |
| SaaS / produto digital | Custo por usuário ativo mensal (MAU) |
| E-commerce / transacional | Custo por pedido / por transação |
| Plataforma de dados | Custo por TB processado; custo por consulta |
| IA | Custo por 1 mil tokens; custo por requisição de inferência; custo por resposta útil |

Objetivo: mostrar se o aumento de custo acompanha (ou não) o aumento de valor entregue. Custo total subindo com custo unitário caindo pode ser sinal saudável.

## 3. Estrutura da prática (Domínio 4)
- **Modelo de operação:** centralizado (time FinOps), distribuído (cada time) ou híbrido (núcleo central + campeões nos times). O princípio "FinOps should be enabled centrally" pede que dados, ferramentas e negociação de tarifas sejam centrais, e a responsabilidade pelo uso seja distribuída.
- **Cadência mínima sugerida:** revisão semanal de anomalias (Practitioner + Engineering), mensal de custo por unidade (com Finance), trimestral de compromissos e roadmap (com Leadership e Procurement).
- **Patrocínio:** sem um patrocinador na liderança, a maioria das capacidades para em Crawl. Registre se existe.

## 4. Executive Strategy Alignment (nova em 2026)
Quatro áreas:
1. **Executive Priority Alignment:** ligar gasto e uso de tecnologia às iniciativas estratégicas; sair do relatório retrospectivo para o apoio a decisões futuras.
2. **Multi-Year Investment Strategy:** orçamento, responsabilidade de P&L, governança de compromissos plurianuais com fornecedores, análise de custo do ciclo de vida.
3. **Facilitate Product Prioritization Strategy:** tornar comparáveis os trade-offs de custo, velocidade e qualidade entre iniciativas; FinOps participando mais cedo da entrada de demandas e da arquitetura.
4. **Enable Strategic Decision Support:** modelo de operação, fóruns de governança, direitos de decisão, guardrails de gasto, continuidade em trocas de gestão.

**Setor público:** a "estratégia plurianual" se conecta ao PPA e à LOA; trocas de gestão (mandato) são o caso típico de "continuidade em mudanças de liderança". Avalie se a prática sobreviveria a uma troca de gestão.

## 5. Notas para o setor público
- **Compromissos (Reservas/Savings Plans):** dependem do modelo de contrato (EA, MCA, CSP) e, muitas vezes, de processo de aquisição. Trate como proposta de contratação com prazo realista, não como ação técnica.
- **Chargeback:** muitas vezes inviável pela estrutura orçamentária; **showback por secretaria, órgão ou sistema** é o alvo típico.
- **Orçamento:** o ciclo anual (LOA) torna o Forecasting especialmente importante: o erro de previsão vira pedido de suplementação ou sobra empenhada.
- **Transparência:** relatórios de custo por sistema podem apoiar prestação de contas.
