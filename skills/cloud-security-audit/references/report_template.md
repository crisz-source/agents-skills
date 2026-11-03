# Modelo de Relatório de Auditoria de Segurança em Nuvem

> **Obrigatório:** cabeçalho, vocabulário de severidade/confiança, arquivo JSON e a seção "Desde a última auditoria" seguem `report_standard.md`. Este template define só as seções específicas deste agente.

## Resumo Executivo
- **Data da Auditoria:** {{DATA}}
- **Subscription / Tenant:** {{SUBSCRIPTION_NOME}} ({{SUBSCRIPTION_ID}}) / {{TENANT_ID}}
- **Escopo Auditado:** {{ESCOPO}} (Storage e Rede / RBAC e Identidade / Secrets e IaC / Workloads)
- **Identidade usada na leitura:** {{IDENTIDADE}} (sem exibir e-mail se não for necessário)
- **Contagem de Achados:** Crítico {{N_CRIT}} · Alto {{N_ALTO}} · Médio {{N_MED}} · Baixo {{N_BAIXO}}
- **Secure Score do Defender for Cloud:** {{SECURE_SCORE}}% (valor do próprio Defender; "N/D" se indisponível — não invente nota própria)

---

## 1. Visão Geral do Ambiente
- **Recursos analisados:** {{TOTAL_RECURSOS}} (Storage Accounts, NSGs, Key Vaults, ACR, App Services...)
- **Atribuições de RBAC analisadas:** {{TOTAL_ROLE_ASSIGNMENTS}}
- **Arquivos de IaC / pipeline analisados:** {{TOTAL_ARQUIVOS}} (ou "nenhum encontrado")

---

## 2. Problemas Críticos e Urgentes
| ID | Recurso / Escopo | Problema Identificado | Severidade | Impacto Potencial |
|---|---|---|---|---|
| STO-01 | ... | ... | Crítico/Alto | ... |
| IAM-01 | ... | ... | Crítico/Alto | ... |

---

## 3. Detalhamento dos Achados por Categoria

### A. Storage, Rede e Exposição Pública (prefixo STO / NET)
- **Achado STO-01:** {{TITULO}}
  - **Recurso Atingido:** `resourceGroup/tipo/nome`
  - **Evidência Observada:** `{{COMANDO}}` → `{{SAIDA_RESUMIDA}}`
  - **Grau de Confiança:** Confirmado | Potencial | Inconclusivo
  - **Recomendação de Correção:** ... (comando em bloco de código, para aplicação manual)
  - **Risco da Alteração:** ...
  - **Plano de Validação:** `az ...`

### B. Identidade e Acesso — RBAC, Entra ID, Service Principals (prefixo IAM)
- ...

### C. Secrets Expostos em IaC, Pipelines e Configurações (prefixo SEC)
- Valor sempre mascarado (4 primeiros caracteres + `***`), com arquivo:linha ou recurso/chave.

### D. Defender, Workloads, Imagens e AKS na camada Azure (prefixo WKL)
- ...

---

## 4. Plano de Remediação Priorizado
| Prioridade | Achado(s) | Ação | Esforço | Risco da alteração |
|---|---|---|---|---|
| 1 | ... | ... | ... | ... |

---

## 5. Fora do Escopo
- Itens que pertencem a outro agente (custo, governança/tags, cluster Kubernetes, logs), em uma linha cada.

## 6. Limitações da Auditoria & Próximos Passos
- Permissões ou ferramentas indisponíveis durante a coleta e o que ficou sem cobertura.
- Comandos que o operador precisa rodar para fechar as lacunas.
