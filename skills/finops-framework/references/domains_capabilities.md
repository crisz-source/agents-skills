# Referência: Domínios e Capacidades (FinOps Framework 2026)

4 domínios (os resultados que a prática busca) e 22 capacidades (como chegar lá).
Nomes em inglês são os oficiais (usados na certificação FinOps Certified Practitioner).

Para cada capacidade:
- **Evidências:** o que procurar em IaC, Azure ou no relatório da `azure-cost-finops`.
- **Perguntas:** para a entrevista (pule as que a evidência já respondeu).
- **Sinais:** C = Crawl, W = Walk, R = Run.
- **Dono típico:** persona Core responsável.

Mudanças de nome em 2026 (útil se o usuário usar o termo antigo):
| Antes | Framework 2026 |
|---|---|
| Workload Optimization | Usage Optimization |
| Cloud Policy & Governance / Policy & Governance | Governance, Policy & Risk |
| FinOps Tools & Services | Automation, Tools & Services |
| Benchmarking | KPIs & Benchmarking |
| Architecting for Cloud + Onboarding Workloads | Architecting & Workload Placement |
| Cloud Sustainability | Sustainability |
| (nova) | Executive Strategy Alignment |

---

## Domínio 1: Understand Usage & Cost (Entender uso e custo)
Resultado: todos sabem quanto se gasta, onde, com o quê e de quem é.

### 1.1 Data Ingestion (Ingestão de dados)
Coletar, normalizar e disponibilizar dados de custo e uso.
- **Evidências:** exports do Cost Management (`az costmanagement export list`), formato FOCUS, storage/Fabric/Power BI recebendo dados, FinOps Hubs da Microsoft.
- **Perguntas:** De onde vêm os números de custo que vocês usam? Existe export automático? Com que atraso os dados chegam? Outras categorias (SaaS, data center) entram na mesma base?
- **Sinais:** C: só o portal da Azure / fatura em PDF. W: export diário automático para uma base consultável. R: base unificada (FOCUS) com várias categorias, dados confiáveis e com dono.
- **Dono típico:** FinOps Practitioner.

### 1.2 Allocation (Alocação)
Atribuir cada custo a um dono (sistema, secretaria, time, ambiente) via hierarquia, tags e regras de rateio de custos compartilhados.
- **Evidências:** % de recursos com tags obrigatórias (script 1b), tags em IaC (script 1a), hierarquia de management groups/subscriptions/RGs, regras de rateio de custos compartilhados (ex.: cluster AKS usado por vários sistemas).
- **Perguntas:** Quais tags são obrigatórias? Quem garante? Como se divide o custo de recursos compartilhados? Qual % do custo tem dono conhecido?
- **Sinais:** C: ≥ 70% do custo com dono. W: ≥ 85%, compartilhados com regra definida. R: > 90%, rateio automatizado.
- **Dono típico:** FinOps Practitioner + Finance.

### 1.3 Reporting & Analytics (Relatórios e análise)
Relatórios e painéis adequados a cada persona.
- **Evidências:** dashboards (Power BI, Workbooks, Cost Analysis salvos), relatórios periódicos enviados.
- **Perguntas:** Quem recebe relatório de custo, com que frequência e em que formato? Engenharia vê o custo do próprio sistema sem pedir a alguém? A liderança recebe uma visão resumida?
- **Sinais:** C: relatório manual e esporádico. W: painéis por persona atualizados automaticamente. R: autoatendimento; dados usados nas decisões rotineiras.
- **Dono típico:** FinOps Practitioner.

### 1.4 Anomaly Management (Gestão de anomalias)
Detectar, alertar e investigar gastos fora do padrão.
- **Evidências:** alertas de anomalia do Cost Management (scheduledActions do tipo InsightAlert), alertas de budget, histórico de incidentes de custo.
- **Perguntas:** Se o custo dobrar amanhã, quem fica sabendo e em quanto tempo? Existe processo de investigação? Já aconteceu? Como foi tratado?
- **Sinais:** C: descoberto na fatura do mês. W: alerta automático com destinatário definido e resposta em dias. R: detecção diária, triagem com dono, MTTD/MTTR medidos.
- **Dono típico:** FinOps Practitioner + Engineering.

---

## Domínio 2: Quantify Business Value (Quantificar valor de negócio)
Resultado: o gasto é planejado, previsto e ligado ao valor que entrega.

### 2.1 Planning & Estimating (Planejamento e estimativa)
Estimar custo de novas cargas, mudanças e projetos antes de começar.
- **Evidências:** uso da Azure Pricing Calculator, estimativas em documentos de arquitetura/ADR, estimativa em PRs de IaC (ex.: Infracost).
- **Perguntas:** Um sistema novo tem estimativa de custo antes de subir? Quem faz? A estimativa é comparada com o real depois?
- **Sinais:** C: estimativa ocasional e informal. W: estimativa obrigatória para projetos relevantes. R: estimativa automatizada no fluxo de mudança e comparada com o real.
- **Dono típico:** Engineering + Product.

### 2.2 Forecasting (Previsão)
Prever o gasto futuro com base em tendência e planos.
- **Evidências:** forecast do Cost Management usado, planilhas de previsão, histórico de previsto vs. realizado.
- **Perguntas:** Vocês preveem o gasto do próximo mês/ano? Qual foi o erro da última previsão?
- **Sinais:** C: variação previsto vs. real < 20%. W: < 10%. R: < 5%, revisado periodicamente com os times.
- **Dono típico:** Finance + FinOps Practitioner.

### 2.3 Budgeting (Orçamento)
Definir, acompanhar e ajustar orçamentos de tecnologia.
- **Evidências:** budgets no Azure (`az consumption budget list`), budgets em IaC, ligação com o orçamento anual do órgão (LOA/PPA no setor público).
- **Perguntas:** Existe orçamento por subscription/sistema/secretaria? Quem é avisado quando estoura? O orçamento de nuvem conversa com o orçamento oficial da organização?
- **Sinais:** C: um orçamento global, sem alerta. W: budgets por unidade com alertas e responsáveis. R: orçamento revisto com base no forecast e em unit economics.
- **Dono típico:** Finance + Leadership.

### 2.4 KPIs & Benchmarking (KPIs e comparação)
Definir indicadores e comparar entre times, períodos ou com o mercado.
- **Evidências:** lista de KPIs FinOps acompanhados (ver `manage_finops_practice.md`).
- **Perguntas:** Quais indicadores de custo vocês acompanham? Comparam sistemas ou ambientes entre si? Há metas?
- **Sinais:** C: nenhum KPI ou só "gasto total". W: alguns KPIs com meta, revisados em cadência. R: KPIs por Scope e categoria, comparados e usados para priorizar.
- **Dono típico:** FinOps Practitioner.

### 2.5 Unit Economics (Economia unitária)
Ligar custo a uma unidade de valor (custo por usuário, por processo, por transação).
- **Evidências:** métrica unitária publicada, fonte do denominador (dados de negócio).
- **Perguntas:** O que o sistema "entrega" que dá para contar? Existe esse número? Alguém já calculou custo por unidade?
- **Sinais:** C: nenhuma métrica unitária. W: uma ou duas métricas calculadas periodicamente. R: métricas unitárias guiam decisões de produto e orçamento.
- **Dono típico:** Product + Finance.

---

## Domínio 3: Optimize Usage & Cost (Otimizar uso e custo)
Resultado: paga-se o preço certo pelo consumo certo.
**Evidência técnica principal: relatório da skill `azure-cost-finops`.** Aqui se avalia o **processo** de otimização, não se cataloga desperdício.

### 3.1 Architecting & Workload Placement (Arquitetura e alocação de cargas)
Custo e valor como critérios de arquitetura e de onde cada carga roda (Azure, on-premises, SaaS), para cargas novas e existentes. Absorveu "Onboarding Workloads" em 2026.
- **Evidências:** Categoria E do relatório `azure-cost-finops`; ADRs com análise de custo; revisão de arquitetura com critério de custo.
- **Perguntas:** Custo é critério formal nas decisões de arquitetura? Existe revisão antes de subir carga nova? Decisões de onde hospedar consideram custo total?
- **Sinais:** C: decisão caso a caso, só pela entrega imediata. W: revisão de arquitetura inclui custo para cargas relevantes. R: processo contínuo, com direitos de decisão claros, cobrindo cargas novas e existentes.
- **Dono típico:** Engineering + Enterprise Architecture.

### 3.2 Rate Optimization (Otimização de tarifa)
Reservas, Savings Plans, descontos contratuais, Spot, preço Dev/Test.
- **Evidências:** cobertura e utilização de compromissos (relatório `azure-cost-finops`, Categoria D), contrato (EA/MCA/CSP).
- **Perguntas:** Vocês têm Reservas ou Savings Plans? Quem decide a compra? Como é o processo de aquisição? Alguém acompanha a utilização?
- **Sinais:** C: cobertura ~60% ou compras pontuais. W: > 75%, revisão periódica. R: > 80%, gestão contínua de cobertura e utilização.
- **Dono típico:** Procurement + FinOps Practitioner.

### 3.3 Usage Optimization (Otimização de uso)
Right-sizing, desligamento, remoção de ociosos, autoscaling, agendas.
- **Evidências:** volume de desperdício no relatório `azure-cost-finops` (Categorias A–C), agendas de desligamento em IaC, contagem de recomendações de custo do Advisor em aberto.
- **Perguntas:** Quem age sobre recomendações de otimização? Com que frequência? Existe meta? Quanto tempo uma recomendação fica aberta?
- **Sinais:** C: limpeza esporádica, reativa. W: revisão periódica com donos, ambientes não produtivos com agenda. R: otimização automatizada com guardrails e medida em KPI.
- **Dono típico:** Engineering.

### 3.4 Sustainability (Sustentabilidade)
Considerar emissões de carbono junto com custo.
- **Evidências:** uso do Azure Carbon Optimization / Emissions Impact Dashboard, metas de sustentabilidade da organização.
- **Perguntas:** A organização tem meta de sustentabilidade que inclui TI? Alguém olha emissões da nuvem?
- **Sinais:** C: não acompanhado. W: emissões visíveis em relatório. R: carbono é critério de decisão junto com custo.
- **Dono típico:** Sustainability (Allied) + Engineering.

### 3.5 Licensing & SaaS (Licenças e SaaS)
Gerenciar licenças (Windows, SQL Server, Microsoft 365) e assinaturas SaaS.
- **Evidências:** Azure Hybrid Benefit (Categoria E5 do relatório `azure-cost-finops`), inventário de licenças/SaaS.
- **Perguntas:** Quem controla licenças e assinaturas SaaS? O time de licenciamento sabe o que está sendo usado na Azure? Existe inventário de SaaS contratado?
- **Sinais:** C: licenças compradas sem ligação com o uso real. W: inventário e uso de benefícios como Hybrid Benefit. R: licença e SaaS geridos com ITAM, com uso medido.
- **Dono típico:** Procurement + ITAM (Allied).

---

## Domínio 4: Manage the FinOps Practice (Gerir a prática FinOps)
Resultado: FinOps existe como prática contínua, com dono, regras e patrocínio.
Detalhes adicionais em `manage_finops_practice.md`.

### 4.1 FinOps Practice Operations (Operação da prática)
Estrutura, papéis, cadência e escopo da prática.
- **Perguntas:** Existe alguém (ou time) responsável por FinOps? Há reunião periódica de custo? Com quem?
- **Sinais:** C: iniciativa individual, sem cadência. W: papel formal e reunião periódica com engenharia e finanças. R: prática estabelecida, com mandato, cadência e escopo revisados.
- **Dono típico:** FinOps Practitioner + Leadership.

### 4.2 Governance, Policy & Risk (Governança, política e risco)
Políticas e guardrails (tags obrigatórias, SKUs permitidos, regiões, limites), gestão de risco financeiro.
- **Evidências:** atribuições de Azure Policy (script 1b), policies em IaC (script 1a), documento de política.
- **Perguntas:** Existem regras escritas de criação de recursos? São aplicadas automaticamente (Azure Policy) ou só documentadas? Exceções são registradas?
- **Sinais:** C: regras informais. W: políticas documentadas e parte aplicada via Azure Policy em modo audit. R: guardrails automáticos (deny/modify) com processo de exceção.
- **Dono típico:** FinOps Practitioner + Security/Governança.

### 4.3 FinOps Assessment (Avaliação FinOps)
Avaliar periodicamente a própria maturidade (esta skill é uma instância disso).
- **Perguntas:** Já houve avaliação de maturidade antes? Existe linha de base para comparar?
- **Sinais:** C: primeira avaliação. W: avaliação periódica com metas. R: avaliação contínua, ligada ao roadmap.
- **Dono típico:** FinOps Practitioner.

### 4.4 Automation, Tools & Services (Automação, ferramentas e serviços)
Ferramentas, automação e serviços (internos ou contratados) que sustentam a prática.
- **Evidências:** ferramentas em uso (Cost Management, FinOps Toolkit/Hubs, Power BI, scripts, agentes), automações de tag/desligamento/alerta.
- **Perguntas:** Quais ferramentas de custo usam? Quanto do trabalho é manual? Alguma automação dispara ação sozinha?
- **Sinais:** C: portal e planilha. W: ferramentas escolhidas, parte do fluxo automatizada. R: automação é a abordagem preferida, com ferramentas integradas.
- **Dono típico:** FinOps Practitioner + Engineering.

### 4.5 FinOps Education & Enablement (Educação e capacitação)
Capacitar as personas para usar dados de custo.
- **Perguntas:** Alguém tem treinamento ou certificação em FinOps? Engenharia sabe ver o custo do que constrói? Existe material interno?
- **Sinais:** C: conhecimento concentrado em uma pessoa. W: treinamento básico para engenharia e finanças. R: capacitação contínua, onboarding inclui FinOps.
- **Dono típico:** FinOps Practitioner.

### 4.6 Invoicing & Chargeback (Faturamento e chargeback)
Conciliar faturas e repassar (chargeback) ou mostrar (showback) custos às unidades.
- **Evidências:** processo de conciliação da fatura, relatórios de showback por unidade.
- **Perguntas:** Quem confere a fatura? O custo é mostrado ou cobrado de cada secretaria/unidade/sistema?
- **Sinais:** C: fatura paga sem conciliação detalhada. W: showback regular por unidade. R: chargeback ou showback formal, conciliado e aceito pelas unidades.
- **Dono típico:** Finance + ITFM (Allied).
- **Setor público:** showback costuma ser o alvo realista; chargeback depende de estrutura orçamentária que permita repasse.

### 4.7 Intersecting Disciplines (Disciplinas que se cruzam)
Coordenação com ITAM/SAM, ITFM, ITSM, Security, Sustainability, Enterprise Architecture.
- **Perguntas:** FinOps conversa com os times de licenciamento, contratos, segurança e arquitetura? Os dados são compartilhados?
- **Sinais:** C: cada área isolada. W: pontos de contato definidos com as principais. R: dados e governança compartilhados, visão comum de TCO.
- **Dono típico:** FinOps Practitioner.

### 4.8 Executive Strategy Alignment (Alinhamento com a estratégia executiva), **nova em 2026**
Ligar o valor da tecnologia à estratégia e apoiar decisões executivas. Quatro áreas: alinhamento a prioridades executivas; estratégia de investimento plurianual; apoio à priorização de produtos; apoio a decisões estratégicas (fóruns, direitos de decisão, guardrails de gasto).
- **Perguntas:** A liderança usa dados de custo nas decisões? Existe patrocinador executivo? Custo entra na priorização de projetos? Há planejamento plurianual de compromissos e contratos?
- **Sinais:** C: liderança só vê o total quando há problema. W: patrocinador definido e custo presente nas decisões de priorização. R: FinOps participa de decisões estratégicas e de investimento plurianual.
- **Dono típico:** Leadership + FinOps Practitioner.
