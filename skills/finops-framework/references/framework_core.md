# Referência: Núcleo do FinOps Framework 2026

Fonte: FinOps Foundation, finops.org/framework (CC BY 4.0). Versão vigente: Framework 2026, apresentada no FinOps Summit de março de 2026.

## 1. Definição (2026)
Missão da FinOps Foundation: *"Advancing the People who manage the Value of Technology"*.

Definição de FinOps: prática operacional e cultural que **maximiza o valor de negócio da tecnologia**, permite decisões rápidas baseadas em dados e cria responsabilidade financeira por meio da colaboração entre engenharia, finanças e negócio.

Mudança importante desde 2025: o foco deixou de ser só "nuvem" e passou a ser **tecnologia** (Cloud+): nuvem pública, SaaS, data center, plataformas de dados e IA.

## 2. Os 6 Princípios
1. **Teams need to collaborate:** as equipes precisam colaborar.
2. **Business value drives technology decisions:** o valor de negócio orienta as decisões de tecnologia.
3. **Everyone takes ownership for their technology usage:** cada um é dono do próprio consumo de tecnologia.
4. **FinOps data should be accessible, timely, and accurate:** os dados de FinOps devem ser acessíveis, oportunos e precisos.
5. **FinOps should be enabled centrally:** FinOps deve ser habilitado de forma central.
6. **Take advantage of the variable cost model of the cloud:** aproveite o modelo de custo variável da nuvem.

Na avaliação, verifique cada princípio com uma pergunta: "Isso acontece aqui? Qual a evidência?"

## 3. Personas

### Core Personas (sempre envolvidas)
| Persona | Papel em FinOps |
|---|---|
| **FinOps Practitioner** | Conecta negócio, engenharia e finanças; constrói a cultura e os dados para decisão. |
| **Engineering** | Projeta e opera a infraestrutura equilibrando custo, desempenho, confiabilidade, segurança e conformidade. |
| **Finance** | Quantifica valor, apoia orçamento e forecast, cuida de alocação e relatórios contábeis. |
| **Product** | Define requisitos e prioridades e comunica o valor das decisões de tecnologia. |
| **Procurement** | Compras, contratos, fornecedores e negociação (inclui compromissos de desconto). |
| **Leadership** | Define objetivos, prioriza iniciativas FinOps e cobra decisões conscientes de custo. |

O framework 2026 destaca o **"FinOps Enabled Executive"**: um líder de nível C-1 (diretor, VP) que patrocina e usa os dados FinOps nas decisões.

### Allied Personas (disciplinas que se cruzam com FinOps)
| Persona | Interseção |
|---|---|
| **ITAM / SAM** | Ativos, licenças, conformidade contratual. |
| **ITFM** | Registro e categorização do gasto de TI; base para chargeback. |
| **Sustainability** | Impacto ambiental e carbono do uso de tecnologia. |
| **ITSM / ITIL** | Gestão de serviços; equilíbrio entre nível de serviço e custo. |
| **Security** | Monitoramento de uso e anomalias; custo e governança de segurança. |

Enterprise Architecture também aparece como disciplina que se cruza com FinOps (ligada à capacidade Architecting & Workload Placement).

**Na avaliação:** para cada persona Core, identifique **quem é a pessoa ou o cargo** na organização. Persona sem dono é lacuna. Uma mesma pessoa acumulando várias personas é comum em times pequenos; registre, mas não é por si só um problema.

## 4. Fases (ciclo iterativo, não sequencial)
- **Inform:** dados de custo, uso e eficiência; alocação, relatórios, forecast, métricas unitárias e benchmarking. Revisitada sempre, para medir o efeito das otimizações.
- **Optimize:** a partir do Inform, identificar melhorias. **Otimização de uso** (consumir menos para o mesmo resultado, normalmente liderada por Engineering) e **otimização de tarifa** (pagar o preço adequado, normalmente Procurement e Leadership). Saída: lista priorizada e documentada de opções.
- **Operate:** colocar em prática por mudanças pequenas e contínuas, com responsabilidade distribuída; amadurece a própria prática e volta ao Inform.

Uma organização está em fases diferentes em capacidades diferentes ao mesmo tempo.

## 5. Modelo de maturidade (Crawl, Walk, Run)
Avaliado **por capacidade** (ou por domínio como resumo). Cada capacidade pode estar num nível diferente.

| Nível | Características |
|---|---|
| **Crawl** | Pouco relatório e ferramenta; KPIs básicos; processo definido mas não seguido por todos os times principais; foco em "frutas baixas". |
| **Walk** | Capacidade entendida e seguida na organização; casos difíceis identificados (alguns deixados de lado de propósito); automação/processo cobre a maioria; KPIs médios a altos. |
| **Run** | Todos os times entendem e seguem; casos difíceis sendo tratados; KPIs muito altos; automação é a abordagem preferida. |

Use também **"Não praticado"** quando a capacidade não existe, e **"Não avaliado"** quando não há evidência nem resposta.

**Princípio-chave:** o objetivo **não** é ser Run em todas as capacidades. O nível-alvo depende do valor de negócio. Amadurecer uma capacidade que já atende ao que o negócio precisa não traz benefício.

## 6. Scopes (introduzidos em 2025, aprofundados em 2026)
- **Scope** é um segmento definido de gasto, que pode cruzar várias Technology Categories, alinhado a uma construção de negócio (produto, centro de custo, ambiente, iniciativa).
- A **Technology Category** é o "o quê"; o **Scope** é o "por quê".
- Scopes nascem de uma **pergunta de negócio**, normalmente da liderança. Antes de definir um Scope, investigue qual é o objetivo real.
- São situacionais: podem durar pouco, ter intensidade diferente, e ser absorvidos pela prática padrão depois.
- O mesmo gasto pode estar em mais de um Scope, com expectativas diferentes; isso deve ser gerenciado de forma deliberada.
- Cada Scope define quais personas, capacidades, nível de maturidade aceitável e cadência se aplicam. Exemplo do framework: um Scope de IA focado em velocidade e qualidade, que **aceita maturidade baixa** e cadência rápida.

## 7. Technology Categories (2026)
1. **Public Cloud:** IaaS e PaaS (Azure, AWS, GCP...); commitments, multi-cloud, mudança rápida.
2. **SaaS:** software gerenciado por assinatura ou consumo.
3. **Data Center:** infraestrutura própria ou colocation.
4. **Data Cloud Platforms:** dados e analytics por consumo (Snowflake, Databricks, BigQuery, Microsoft Fabric).
5. **AI:** modelos, tokens, GPU; custo imprevisível e governança entre categorias.

A lista não é exaustiva. Cada categoria tem no framework: considerações, personas, capacidades, KPIs e alinhamento com o **FOCUS** (FinOps Open Cost & Usage Specification, padrão aberto de dados de custo; a Microsoft disponibiliza exports do Cost Management no formato FOCUS).
