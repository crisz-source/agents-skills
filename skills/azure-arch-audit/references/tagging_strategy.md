# Referência Técnica: Estratégia de Tagging e Categorização

## 1. Esquema Padrão de Tags Recomendado (Taxonomia)
Todas as organizações Azure devem implementar um padrão mínimo de tags para governança financeira e operacional:

| Tag | Descrição | Exemplos |
|---|---|---|
| `Environment` | Ambiente do recurso | `Production`, `Staging`, `Development`, `Sandbox` |
| `CostCenter` | Centro de custo ou código de projeto | `CC-1020`, `Proj-Finance` |
| `Owner` | Responsável técnico ou equipe | `team-devops@empresa.com`, `data-squad` |
| `BusinessUnit` | Unidade de negócio atendida | `Vendas`, `RH`, `Core-Banking` |
| `Criticality` | Impacto em caso de indisponibilidade | `Mission-Critical`, `High`, `Medium`, `Low` |
| `AutoShutdown` | Política de desligamento automático | `True`, `False`, `Schedule-1800` |

## 2. Diagnóstico de Recursos sem Tags
- O coletor deve listar todos os recursos onde o objeto `tags` for nulo ou vazio (`length(tags) == 0`).
- Recomendar a aplicação de Azure Policy para propagação automática de tags a partir do Resource Group ou bloqueio de criação sem tags obrigatórias.
