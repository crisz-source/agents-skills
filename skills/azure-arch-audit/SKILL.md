---
name: azure-arch-audit
description: Auditoria de arquitetura e governança Azure, somente leitura - hierarquia de subscriptions e resource groups, locks, Azure Policy, padrão e cobertura de tags, recursos órfãos e risco de remoção com checagem de dependências. Não calcula custo nem faz right-sizing (isso é a skill azure-cost-finops).
allowed-tools: Bash(az account show*) Bash(az account list*) Bash(az * list*) Bash(az * show*) Bash(az graph query *) Bash(sh ${CLAUDE_SKILL_DIR}/scripts/*)
---
# Skill: Auditoria de Arquitetura e Governança Azure
Esta habilidade executa uma análise profunda e não destrutiva (somente leitura) da infraestrutura Azure, cobrindo governança, organização da hierarquia (Subscriptions/Resource Groups), locks e Azure Policy, identificação de recursos órfãos, risco de remoção (dependências) e avaliação de políticas de Tagging. Valores em dinheiro e right-sizing ficam com o finops-azure.
## Diretivas de Segurança e Princípios Operacionais
1. **Operação Exclusivamente Somente-Leitura (Read-Only):**
   - NUNCA execute comandos de modificação, exclusão ou criação (`az resource delete`, `az vm stop/deallocate`, `az group delete`).
   - Todos os scripts e comandos `az` devem utilizar verbos de consulta (`list`, `show`).
2. **Avaliação Conservadora de Recursos Órfãos:**
   - Antes de classificar um recurso como "seguro para remoção", verifique dependências (Private Endpoints, snapshots, locks, referências de AKS/App Service) e há quanto tempo está sem uso. Na dúvida, **Requer Validação**. IP público estático é sempre Requer Validação (pode estar liberado em firewall de parceiro).
3. **Confirmação de Contexto:**
   - Exiba a Tenant ID e a Subscription ativa (`az account show`) antes de iniciar a coleta para evitar auditorias na conta incorreta.
---
## Fluxo de Trabalho de Auditoria
### Etapa 1: Validação de Contexto e Ferramentas
1. Verifique a autenticação e conta ativa no Azure CLI:
   ```bash
   az account show --output table
   ```
2. Valide as permissões de leitura no escopo selecionado (Reader / Cost Management Reader).
---
### Etapa 2: Coleta Determinística de Dados
Execute o script auxiliar de coleta para extrair o inventário e estado operacional dos recursos:
```bash
sh ${CLAUDE_SKILL_DIR}/scripts/azure_collector.sh <subscription-id[,subscription-id...]> [tags,obrigatórias]
```
Padrão de tags: `Environment,Owner,CostCenter,Application`. O script aceita várias subscriptions (separadas por vírgula) e cobre hierarquia, locks, Azure Policy, discos, IPs, SKUs Basic aposentados, NICs, NSGs, App Service Plans, cobertura de tags por resource group e dependências (Private Endpoints, snapshots).
---
### Etapa 3: Análise Modular por Domínio Técnico
Consulte os guias especializados de referência contidos na skill para fundamentar o diagnóstico:
- **Organização e Hierarquia:** Veja `${CLAUDE_SKILL_DIR}/references/organization_hierarchy.md` (Grupos de Recursos, Subscriptions, Locks, Azure Policy).
- **Recursos Órfãos e Risco de Remoção:** Veja `${CLAUDE_SKILL_DIR}/references/orphans_removal.md` (níveis de risco, dependências por tipo de recurso).
- **Estratégia de Tagging:** Veja `${CLAUDE_SKILL_DIR}/references/tagging_strategy.md` (Padrões de governança, tags obrigatórias, identificação de recursos despadronizados).
---
### Etapa 4: Síntese e Geração do Relatório
Estruture a entrega final conforme o modelo padronizado em `${CLAUDE_SKILL_DIR}/references/report_template.md`.
Para cada recurso não utilizado ou desalinhado, informe:
- **Recurso & Resource Group:** ID completo e nome.
- **Status de Utilização:** Ativo, Ocioso ou Órfão, com a evidência (estado, há quanto tempo).
- **Nível de Risco de Remoção:** Seguro | Requer Validação (padrão na dúvida) | Crítico (dependência encontrada ou grupo gerenciado), conforme `orphans_removal.md`.
- **Ação Sugerida & Tags Recomendadas:** Script em CLI/Bicep ou recomendação de tag (`Environment`, `CostCenter`, `Owner`).

## Padrão de saída (comum a todos os agentes)
Siga `${CLAUDE_SKILL_DIR}/references/report_standard.md`:
- **Dois arquivos** com o mesmo nome-base em `reports/`: `.html` (pessoas) e `.json` (outros agentes, Colmeia, comparação).
- **Vocabulário único:** severidade Crítico · Alto · Médio · Baixo · Info; confiança Confirmado · Potencial · Inconclusivo.
- **`fingerprint` estável** por achado (`<categoria>|<recurso>`), sem valores que mudam a cada execução.
- **"Desde a última auditoria":** compare com o JSON anterior do mesmo `<tipo>-<escopo>` (novos, resolvidos, persistentes, pioraram/melhoraram).
