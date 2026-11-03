# Referência: Identidade e Acesso — RBAC do Azure e Entra ID (prefixo IAM)

## RBAC do Azure
| Verificação | Severidade |
|---|---|
| Mais de 3 **Owner** no escopo da subscription | Alto (MCSB recomenda poucos Owners) |
| `Owner` ou `User Access Administrator` atribuído a **usuário convidado (guest)** | **Crítico** |
| `Owner`/`Contributor` em escopo de subscription para **service principal** de pipeline | Alto: reduzir para o escopo do resource group e papel mínimo |
| Atribuições a principais excluídos (`principalType = Unknown`) | Baixo: limpeza |
| Papéis amplos herdados de management group sem necessidade | Médio |
| Ausência de PIM (acesso permanente em vez de elegível) | Médio — só se for possível verificar; caso contrário, Inconclusivo |

Boa prática a recomendar: grupos do Entra ID em vez de usuários individuais, menor privilégio, acesso privilegiado via PIM.

## Entra ID (requer `ENTRA=1` e permissão de leitura no diretório)
| Verificação | Severidade |
|---|---|
| Administrador sem MFA registrado | **Crítico** |
| Nenhuma política de Conditional Access exigindo MFA para administradores | **Crítico** |
| Política de CA em `enabledForReportingButNotEnforced` há muito tempo | Médio |
| App registration com segredo **vencido** | Baixo (limpeza) — mas indica falta de gestão de ciclo de vida |
| App registration com segredo vencendo em 30 dias | Médio (risco de indisponibilidade, não de segurança) |
| Apps usando segredo em vez de certificado ou identidade federada | Baixo/Médio |

Se o Graph negar acesso (`Authorization_RequestDenied`), todas essas linhas ficam **Inconclusivo** e vão para Limitações, com a permissão necessária (ex.: leitura de relatórios de autenticação e de políticas de Conditional Access).

## MFA obrigatório da Azure e automação
- Desde a fase 2 (a partir de 01/10/2025, aplicada gradualmente por tenant), **usuários** precisam de MFA para operações de gerenciamento via Azure Resource Manager — portal, CLI, PowerShell, IaC. Identidades de workload (managed identity, service principal) não são afetadas.
- **Achado Alto:** pipeline, script agendado ou ferramenta que roda com **conta de usuário** (login com usuário/senha) no lugar de identidade de workload. Vai quebrar quando a fase 2 for aplicada ao tenant (o adiamento tem prazo) e é credencial de pessoa usada por máquina. Recomendação: managed identity ou service principal com identidade federada (OIDC).
- Azure DevOps: service connections de workload identity federation com o emissor do Azure DevOps (`vstoken.dev.azure.com`) estão descontinuadas; aposentadoria em 01/07/2027. Converter para o emissor do Entra ID. Baixo (prazo longo), mas registre.
- Evidência típica: em IaC/pipelines, `az login -u`, `Connect-AzAccount -Credential`, variáveis `AZURE_USERNAME`/`AZURE_PASSWORD`. O coletor de IaC mostra `password`; procure também esses padrões com `rg`.

## Dados pessoais
Relate contagens. Liste UPNs apenas quando forem necessários para a correção, e só no corpo do achado.
