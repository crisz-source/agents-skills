---
name: azure-cost-finops
description: Analisa custos e desperdício na Microsoft Azure (FinOps e Cost-Aware Architecture), somente leitura - órfãos, ociosos, SKUs Basic aposentados, right-sizing e geração de VM, reservas e Savings Plans, elasticidade de AKS, armazenamento, Log Analytics, rede e licenciamento - com economia estimada. Não avalia maturidade da prática FinOps (finops-framework) nem risco de remoção (azure-arch-audit).
allowed-tools: Bash(az account show*) Bash(az account list*) Bash(az * list*) Bash(az * show*) Bash(az monitor log-analytics query *) Bash(az costmanagement query *) Bash(sh ${CLAUDE_SKILL_DIR}/scripts/*)
argument-hint: [subscription-id[,subscription-id...]]
---
# Skill: Análise de Custos, Otimização FinOps e Cost-Aware Architecture para Microsoft Azure
## Objetivo
Esta Skill realiza uma auditoria completa de custos na infraestrutura Microsoft Azure com base nas melhores práticas do **FinOps Framework** (Inform, Optimize, Operate) e do pilar de **Otimização de Custos do Azure Well-Architected Framework**. Ela atua em duas frentes:
- **Desperdício (Categorias A a D):** recursos sem uso, discos órfãos, IPs públicos não associados, VMs superdimensionadas e oportunidades de Reserva/Savings Plans.
- **Arquitetura consciente de custo (Categoria E):** decisões de design que tornam o ambiente caro por natureza, mesmo sem nenhum recurso "sobrando", e a alternativa mais barata que entrega o mesmo resultado.
---
## Fluxo de Trabalho e Auditoria FinOps
Ao acionar a skill `/azure-cost-finops [escopo]`, siga as etapas abaixo rigorosamente:
### 1. Coleta de Dados da Infraestrutura Azure
Confirme a conta (`az account show`) e rode o coletor determinístico. Ele aceita uma ou várias subscriptions separadas por vírgula e cobre todas as categorias abaixo:
```bash
sh ${CLAUDE_SKILL_DIR}/scripts/cost_collector.sh <subscription-id[,subscription-id...]>
# LA_QUERY=0 pula as consultas KQL no Log Analytics (mais rápido)
```
Os comandos `az` citados nas categorias servem para **aprofundar** um achado específico (sempre `list`, `show` ou `query`). Para o preço de cada item, use a Azure Retail Prices API ou o Cost Management; nunca invente valores.
### 2. Classificação de Ambiente
Antes de analisar, classifique cada resource group como **Produção** ou **Não Produção** (dev, hml, teste, lab), usando o nome e a tag `Environment` quando existir. Essa classificação muda as recomendações: o que é desperdício em homologação pode ser requisito de resiliência em produção. Se não for possível classificar, marque como "Ambiente não identificado" e trate como Produção.
### 3. Análise de Oportunidades de Economia (As 5 Categorias)
#### Categoria A: Recursos Órfãos e Desconectados (Waste Removal)
- **Discos Gerenciados Não Anexados (Unattached Disks):**
  `az disk list --query "[?managedBy==null].{Name:name, ResourceGroup:resourceGroup, DiskSizeGB:diskSizeGb, Sku:sku.name}" -o table`
- **Endereços de IP Público Não Associados (Unassociated Public IPs):**
  `az network public-ip list --query "[?ipConfiguration==null].{Name:name, ResourceGroup:resourceGroup, Sku:sku.name}" -o table`
- **Gateways de Rede e ExpressRoute Inativos:**
  Verificar vNet Gateways sem conexões ativas.
- **Snapshots e Imagens Antigas/Obsoletas:**
  Listar snapshots com mais de 90 dias sem associação.
- **SKUs Basic aposentados (IP público e Load Balancer):** foram aposentados em 30/09/2025. Os que ainda existem funcionam, mas **sem suporte e sem SLA**. Liste todos (associados ou não) e recomende migração para Standard: é risco operacional antes de ser custo. Atenção: Standard IP é cobrado mesmo associado e exige NSG para liberar tráfego.
#### Categoria B: Recursos Ociosos e Desalocados
- **Virtual Machines Paradas sem desalocar e Desalocadas:**
  `az vm list -d --query "[?powerState=='VM stopped'].{Name:name, ResourceGroup:resourceGroup, Size:hardwareProfile.vmSize}" -o table`
  VM **parada sem desalocar** (`VM stopped`) continua cobrando compute: achado de ganho rápido. VM **desalocada** (`VM deallocated`) cobra só os discos.
- **App Service Plans com Zero Aplicações Ativas:**
  Verificar Planos App Service rodando em tiers pagos (B1, P1v2, etc.) sem Apps associados.
#### Categoria C: Dimensionamento Incorreto (Right-Sizing)
- **VMs e VM Scale Sets Superdimensionados:**
  Analisar métricas do Azure Monitor (CPU < 10%, Memória < 20% média nos últimos 30 dias).
- **Bancos de Dados Azure SQL / Cosmos DB:**
  Identificar DTUs ou vCores provisionados com uso de pico insignificante.
- **Geração antiga de VM (modernização):** séries `_v2`/`_v3`, DS/GS e A costumam custar mais pelo mesmo desempenho que as gerações v5/v6. Trocar de geração é uma economia independente do right-sizing (às vezes as duas juntas). Valide disponibilidade do tamanho na região e compatibilidade (Gen2, discos, aceleração de rede). O coletor marca as VMs de geração antiga.
- **Azure Advisor:** use as recomendações de custo (`az advisor recommendation list --category Cost`) como ponto de partida e **evidência**, não como relatório: confirme cada uma com métrica e contexto (Produção, DR, sazonalidade).
#### Categoria D: Otimização de Compromisso (Commitment Discounts)
- **Recomendações de Reservas (Reserved Instances - RI) e Azure Savings Plans:**
  Verificar se workloads estáveis (VMs rodando 24/7 há mais de 30 dias) possuem cobertura de Reserva de 1 ou 3 anos.
- **Contexto de contratação:** a compra de Reserva ou Savings Plan depende do modelo de contrato (EA, CSP ou MCA) e, no setor público, pode exigir processo de aquisição. Apresente sempre como **proposta de contratação**, com valor do compromisso, prazo, economia estimada e ponto de equilíbrio (em quantos meses o compromisso se paga), nunca como ação técnica imediata.
- **Política de troca (exchange) a partir de 01/02/2027:** reservas compradas a partir dessa data para serviços cobertos por Savings Plan (compute: VMs, Dedicated Host, App Service; e serviços de banco cobertos pelo Savings Plan para bancos de dados) **não poderão ser trocadas** por outra reserva; reservas compradas antes ganham **uma última troca**. Trade-in de reserva para Savings Plan continua permitido.
  Consequência para a recomendação:
  - **Reserva** só para carga estável que não deve mudar de série, região ou tamanho durante o termo (ex.: banco de produção de tamanho fixo).
  - **Savings Plan** (compute ou bancos de dados) para tudo que pode mudar: modernização de geração, migração para PaaS, troca de região, crescimento incerto.
  - No setor público, onde a compra passa por aquisição e é difícil de corrigir depois, a flexibilidade do Savings Plan costuma valer mais que o desconto extra da reserva. Diga isso na proposta.
- **Cobertura e utilização:** se houver leitura de billing, liste as reservas/planos existentes (o coletor tenta); utilização abaixo de ~95% indica compromisso maior que o uso.
#### Categoria E: Arquitetura Consciente de Custo (Cost-Aware Architecture)
Avalia se o **desenho** do ambiente é caro por natureza. Aqui não se procura sobra, e sim decisões de design com alternativa mais barata. Toda a análise é feita pela camada Azure (`az`), sem acesso ao interior dos clusters.

**E1. Elasticidade e agendamento**
- **Node pools AKS sem autoscaler, sem Spot e tier do cluster:**
  ```bash
  az aks list --query "[].{Name:name, ResourceGroup:resourceGroup, Tier:sku.tier, Version:kubernetesVersion}" -o table
  az aks nodepool list -g <rg> --cluster-name <cluster> --query "[].{Pool:name, Mode:mode, VmSize:vmSize, Count:count, Autoscale:enableAutoScaling, Min:minCount, Max:maxCount, Priority:scaleSetPriority}" -o table
  ```
  Sinais: node pool `User` com `Autoscale=false` e contagem fixa; ambiente Não Produção sem node pool Spot; cluster Não Produção no tier `Standard` ou `Premium` (o tier `Free` não cobra pelo control plane, mas não tem SLA).
- **Não Produção ligada 24/7:** VMs e clusters de dev/hml sem desligamento fora do horário comercial.
  ```bash
  az resource list --resource-type Microsoft.DevTestLab/schedules --query "[].{Name:name, ResourceGroup:resourceGroup}" -o table
  ```
  VMs Não Produção sem agenda `shutdown-computevm-<vm>` são candidatas a auto-shutdown. Clusters AKS Não Produção podem ser parados fora do horário (`az aks stop`/`az aks start`, a ser executado pelo operador).

**E2. Tier e redundância de armazenamento**
- **Discos Premium em Não Produção:**
  `az disk list --query "[?starts_with(sku.name, 'Premium')].{Name:name, ResourceGroup:resourceGroup, Sku:sku.name, DiskSizeGB:diskSizeGb}" -o table`
- **Snapshots completos em vez de incrementais:**
  `az snapshot list --query "[].{Name:name, ResourceGroup:resourceGroup, Incremental:incremental, DiskSizeGB:diskSizeGb, Created:timeCreated}" -o table`
- **Storage Accounts: redundância, access tier e lifecycle:**
  ```bash
  az storage account list --query "[].{Name:name, ResourceGroup:resourceGroup, Kind:kind, Sku:sku.name, AccessTier:accessTier}" -o table
  az storage account management-policy show --account-name <conta> -g <rg>
  ```
  Sinais: redundância geográfica (`GRS`, `RAGRS`, `GZRS`) em Não Produção; contas com muitos dados em `Hot` sem lifecycle policy movendo para `Cool`, `Cold` ou `Archive`. Um erro de "policy não encontrada" significa que não há lifecycle configurada.

**E3. Observabilidade (Log Analytics)**
Costuma ser o maior custo escondido em ambientes com AKS e Container Insights.
```bash
az monitor log-analytics workspace list --query "[].{Name:name, ResourceGroup:resourceGroup, CustomerId:customerId, Sku:sku.name, RetentionDays:retentionInDays, DailyCapGB:workspaceCapping.dailyQuotaGb}" -o table
az monitor log-analytics query -w <customerId> --analytics-query "Usage | where TimeGenerated > ago(30d) | where IsBillable == true | summarize IngestedGB = round(sum(Quantity) / 1000, 2) by DataType | top 10 by IngestedGB desc" -o table
az monitor log-analytics workspace table list -g <rg> --workspace-name <workspace> --query "[].{Table:name, Plan:plan, RetentionDays:retentionInDays, TotalRetentionDays:totalRetentionInDays}" -o table
```
**Tabela legada `ContainerLog`:** foi aposentada em 30/09/2026 e deixou de receber dados. Se o coletor mostrar ingestão em `ContainerLog` até essa data e nada em `ContainerLogV2` depois, o cluster está **sem logs de container no Log Analytics**: registre como achado Alto (risco operacional) e coloque em "Fora do escopo" para o log-hunter/k8s-auditor. Alertas que consultam `ContainerLog` também pararam de funcionar.
Sinais: tabelas de alto volume (`ContainerLogV2`, `AzureDiagnostics`, `Perf`, `Syslog`) consumindo a maior parte da ingestão; retenção interativa acima do necessário; tabelas de log bruto que poderiam usar o plano `Basic` ou `Auxiliary` (verifique se a tabela suporta o plano; `AzureDiagnostics` não suporta, e `Auxiliary` ainda tem limitações de preview; consultas em Basic/Auxiliary são cobradas por GB lido); ingestão diária alta sem commitment tier; Não Produção com a mesma coleta e retenção de Produção.

**E4. Rede**
- **Recursos de rede com custo fixo e pouco uso:**
  ```bash
  az network nat gateway list --query "[].{Name:name, ResourceGroup:resourceGroup, Subnets:length(subnets || \`[]\`)}" -o table
  az network application-gateway list --query "[].{Name:name, ResourceGroup:resourceGroup, Sku:sku.name, Capacity:sku.capacity, MinAutoscale:autoscaleConfiguration.minCapacity, MaxAutoscale:autoscaleConfiguration.maxCapacity}" -o table
  az network lb list --query "[?sku.name=='Standard'].{Name:name, ResourceGroup:resourceGroup, Pools:length(backendAddressPools)}" -o table
  ```
  Sinais: Application Gateway com capacidade mínima alta em Não Produção; NAT Gateway ou Load Balancer Standard sem uso efetivo; recursos que se comunicam entre regiões diferentes.
- **Tráfego de saída (egress) e entre regiões:** consulte o custo real por categoria de medidor no Cost Management (requer a extensão `costmanagement` da CLI):
  ```bash
  az costmanagement query --type ActualCost --timeframe MonthToDate --scope "/subscriptions/<subscription-id>" --dataset-grouping name="MeterCategory" type="Dimension"
  ```
  Se a categoria `Bandwidth` tiver peso relevante, registre como achado. Se o comando não estiver disponível, marque a análise de egress como **Inconclusiva**.

**E5. Licenciamento**
- **VMs Windows sem Azure Hybrid Benefit:**
  `az vm list --query "[?storageProfile.osDisk.osType=='Windows'].{Name:name, ResourceGroup:resourceGroup, Size:hardwareProfile.vmSize, License:licenseType}" -o table`
  `License` vazio indica pagamento da licença Windows pelo Azure.
- **SQL Server em VM sem benefício híbrido:**
  `az sql vm list --query "[].{Name:name, ResourceGroup:resourceGroup, License:sqlServerLicenseType}" -o table`
- **Preço Dev/Test:** verificar se ambientes Não Produção estão em subscription com oferta Dev/Test, quando o contrato permitir.
- **Atenção:** o Azure Hybrid Benefit exige licenças próprias elegíveis (com Software Assurance ou assinatura equivalente). Apresente sempre como "validar com o time de licenciamento", nunca como economia garantida.

**E6. Modelo de serviço (IaaS vs PaaS)**
- VMs pequenas com uso intermitente executando rotinas agendadas, filas ou APIs simples podem custar menos em serviços gerenciados (Azure Functions, Container Apps, Container Apps Jobs, App Service).
- Vários App Service Plans pouco utilizados no mesmo ambiente podem ser consolidados em um plano.
- Esses achados são sempre de confiança **Potencial**: dependem de conhecer a aplicação.

**Severidade dos achados de custo (vocabulário do `report_standard.md`):**
| Severidade | Quando |
|---|---|
| Crítico | Risco operacional imediato ligado ao custo (ex.: tabela de logs parada, SKU sem suporte em Produção crítica) |
| Alto | Economia estimada ≥ US$ 500/mês, ou SKU Basic aposentado em Produção |
| Médio | Economia entre US$ 50 e 500/mês |
| Baixo | Economia < US$ 50/mês |
| Info | Proposta de contratação (reserva/Savings Plan) e itens sem economia direta |
As faixas são padrão; se o usuário informar outra escala (ex.: em R$ ou por orçamento), use a dele e registre no relatório.

**Regras específicas da Categoria E:**
- Todo achado da Categoria E descreve o **trade-off**: o que se ganha em custo e o que se perde em SLA, desempenho, resiliência ou esforço de migração.
- Em **Produção**, nenhuma recomendação que reduza redundância, SLA ou capacidade de recuperação é "ganho rápido": classifique como **Decisão de arquitetura (requer aprovação)**.
- Mudanças de arquitetura raramente têm economia exata. Informe faixa de economia e nível de confiança (Confirmado, Potencial ou Inconclusivo).
---
## Formato do Relatório Final (Output Structure)
A entrega final é um **arquivo HTML único e autocontido** (mais o JSON do `report_standard.md`), com CSS dentro de uma tag `<style>` e sem dependências externas (sem CDN, fontes ou scripts de fora). O HTML deve ser legível impresso e em tela, com tabelas para os resumos e destaque visual por severidade e por dificuldade.

O conteúdo segue rigorosamente as seções abaixo (os exemplos mostram o conteúdo esperado, não a marcação):
```text
📊 Relatório de Auditoria de Custos FinOps - Microsoft Azure
Data: [Data Atual]
Escopo Analisado: [Subscription ID / Resource Group]
Ambientes Identificados: [Produção: X RGs | Não Produção: Y RGs | Não identificado: Z RGs]
Status do Ambiente: [Saudável / Atenção / Crítico]

💡 Resumo Executivo e Potencial de Economia
| Categoria FinOps                              | Recursos Afetados | Economia Mensal Estimada (USD) | Dificuldade de Implementação     |
| Recursos Órfãos (Discos/IPs)                  | X                 | $XXX.XX                        | Baixa (Ação Imediata)            |
| SKUs Basic aposentados (IP/LB)                | X                 | risco (sem SLA)                | Média (migração para Standard)   |
| Recursos Ociosos / Parados                    | X                 | $XXX.XX                        | Baixa                            |
| Right-Sizing e Geração de VM                  | X                 | $XXX.XX                        | Média                            |
| Instâncias Reservadas / Savings Plans         | X                 | $XXX.XX                        | Proposta de Contratação          |
| Arquitetura Consciente de Custo               | X                 | $XXX.XX – $X,XXX.XX            | Média a Alta (Decisão de Design) |
| TOTAL ESTIMADO DE ECONOMIA                    | X                 | $X,XXX.XX                      | -                                |

🔍 Detalhamento dos Achados
1. Recursos Órfãos e Sem Uso (Remoção Imediata)
   - Discos Não Anexados: disk-app-prod-01 (Standard_LRS, 128 GB) - RG: rg-prod - Economia: ~$19.20/mês
   - IPs Públicos Inativos: pip-temp-dev (Standard) - RG: rg-dev - Economia: ~$3.60/mês
2. Recursos Desalocados / Inativos
   - vm-legacy-01 - RG: rg-legacy - Recomendação: deletar ou converter disco para Standard HDD.
3. Oportunidades de Right-Sizing
   - vm-backend-02 (Standard_D8s_v3): uso médio de CPU em 4.2% nos últimos 30 dias.
     Recomendação: redimensionar para Standard_D4s_v3 (economia estimada: 50%).
4. Cobertura de Reservas & Savings Plans (Proposta de Contratação)
   - 4 VMs Standard_D4s_v5 operando continuamente há mais de 60 dias sem reserva.
     Proposta: Azure Savings Plan de 1 ano - compromisso de $XXX/hora - economia de ~35% - equilíbrio em X meses.
     Por que Savings Plan e não Reserva: as VMs são candidatas a modernização de geração (reserva comprada após 01/02/2027 não pode ser trocada).
5. Arquitetura Consciente de Custo
   Para cada achado:
   - Recurso / Ambiente: aks-supp-hml (Não Produção) - RG: rg-supp-hml
   - Decisão atual: node pool "user" fixo em 3 nós Standard_D4s_v5, sem autoscaler, ligado 24/7
   - Custo atual: ~$XXX/mês (fonte: Retail Prices API | Cost Management | estimativa)
   - Alternativa: autoscaler 1–3 nós + node pool Spot + parada fora do horário comercial
   - Economia estimada: $XXX – $XXX/mês
   - Trade-off: nós Spot podem ser removidos pela Azure; ambiente indisponível fora do horário
   - Severidade: Crítico | Alto | Médio | Baixo | Info (faixas da seção de severidade)
   - Confiança: Confirmado | Potencial | Inconclusivo
   - Classificação: Ganho rápido | Decisão de arquitetura (requer aprovação)

🚧 Fora do Escopo
- Itens identificados que pertencem a outra área (ex.: requests de pods, governança, tags), uma linha cada, sem investigação.

📋 Plano de Ação Recomendado (Próximos Passos)
1. [ ] Deletar discos e IPs públicos identificados na Seção 1 (Aprovação Técnica).
2. [ ] Redimensionar instâncias de desenvolvimento/homologação na Seção 3.
3. [ ] Aplicar ganhos rápidos de arquitetura em Não Produção (Seção 5).
4. [ ] Levar decisões de arquitetura de Produção para aprovação (Seção 5).
5. [ ] Submeter proposta de contratação de Savings Plan/Reserva ao time de contratos e financeiro (Seção 4).
```
---
## Regras de Qualidade e Segurança FinOps
- **Nunca alterar recursos automaticamente**: a skill apenas AUDITA e RECOMENDA. Nenhum script ou comando cria, altera, para ou remove recursos sem execução manual pelo operador humano.
- **Somente consultas**: use apenas verbos de leitura (`list`, `show`, `query`). Comandos de correção aparecem somente em blocos de código no relatório.
- **Precisão nos cálculos**: utilizar preços oficiais da API do Azure Retail Prices, custo real do Cost Management ou estimativas da documentação oficial da Microsoft, sempre indicando a fonte.
- **Trade-off explícito**: nenhuma recomendação de arquitetura é apresentada sem o custo de oportunidade (SLA, desempenho, resiliência, esforço).
- **Tratamento de Exceções**: se a CLI do Azure (`az`) não estiver autenticada, orientar o usuário a executar `az login`. Se um comando exigir extensão ausente ou permissão que o operador não tem, registrar a verificação como **Inconclusiva** e seguir com o restante da análise.

## Padrão de saída (comum a todos os agentes)
Siga `${CLAUDE_SKILL_DIR}/references/report_standard.md`:
- **Dois arquivos** com o mesmo nome-base em `reports/`: `.html` (pessoas) e `.json` (outros agentes, Colmeia, comparação).
- **Vocabulário único:** severidade Crítico · Alto · Médio · Baixo · Info; confiança Confirmado · Potencial · Inconclusivo.
- **`fingerprint` estável** por achado (`<categoria>|<recurso>`), sem valores que mudam a cada execução.
- **"Desde a última auditoria":** compare com o JSON anterior do mesmo `<tipo>-<escopo>` (novos, resolvidos, persistentes, pioraram/melhoraram).
