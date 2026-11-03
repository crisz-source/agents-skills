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

## Dados pessoais
Relate contagens. Liste UPNs apenas quando forem necessários para a correção, e só no corpo do achado.
