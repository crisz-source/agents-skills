---
name: cloud-security-audit
description: Auditoria de postura de segurança na Microsoft Azure e Entra ID, somente leitura - Defender for Cloud, exposição pública (Storage, NSG, SQL, App Service, ACR, Key Vault), RBAC privilegiado, AKS na camada Azure, segredos e configurações inseguras em IaC (Terraform, Bicep, ARM). Não cobre o interior de clusters Kubernetes (k8s-cluster-audit) nem custo.
allowed-tools: Bash(grep *) Bash(rg *) Bash(az account show*) Bash(az account list*) Bash(az * list*) Bash(az * show*) Bash(sh ${CLAUDE_SKILL_DIR}/scripts/*)
argument-hint: [subscription-id] [diretório de IaC opcional]
---

# Skill: Auditoria de Segurança Azure (CSPM, CIEM e IaC)

Análise **somente leitura** da postura de segurança de uma subscription Azure, do Entra ID (quando houver permissão) e do código de infraestrutura. Referências de critério: Microsoft Cloud Security Benchmark (MCSB, usado pelo Defender for Cloud) e CIS Microsoft Azure Foundations Benchmark.

## Escopo
| Dentro | Fora (registrar em "Fora do Escopo") |
|---|---|
| Defender for Cloud, Secure Score, recomendações | Interior do cluster Kubernetes (pods, RBAC do K8s) → k8s-auditor |
| Exposição pública: Storage, NSG, SQL, App Service, ACR, Key Vault | Custo e economia → finops-azure |
| RBAC do Azure, Entra ID (MFA de admins, Conditional Access, segredos de apps) | Padrão de tags e hierarquia → azure-architect |
| AKS na camada Azure (API pública, contas locais, Entra ID, network policy, SO dos nodes, kubenet) | Logs de aplicação → log-hunter |
| Segredos e configurações inseguras em IaC e pipelines | Testes de intrusão, varredura de portas, exploração |

---

## Fluxo de trabalho

### Etapa 1: Contexto
1. `az account show` e confirme subscription e tenant com o usuário. Se o nome sugerir produção, diga isso explicitamente.
2. Pergunte se há diretório de IaC/pipelines para varrer e se a identidade tem leitura no Entra ID (para a etapa opcional).

### Etapa 2: Coleta determinística
```bash
sh ${CLAUDE_SKILL_DIR}/scripts/cloud_sec_collector.sh <subscription-id[,subscription-id...]> [diretório-de-IaC]
# Com checagens de Entra ID (exigem permissão de leitura no diretório):
ENTRA=1 sh ${CLAUDE_SKILL_DIR}/scripts/cloud_sec_collector.sh <subscription-id[,subscription-id...]> [diretório-de-IaC]
```
O script cobre, por subscription: Defender (planos, Secure Score, recomendações), Storage, NSG, Key Vault, ACR, SQL, App Service, AKS (incluindo SO e versão dos node pools e plugin de rede) e RBAC; uma vez por tenant: Entra ID (opcional); e a varredura de IaC.
Verificações que falharem por permissão aparecem como **Inconclusivo**: registre na seção de Limitações, nunca invente o resultado.

### Etapa 3: Aprofundamento pontual (somente leitura)
Use `az ... list` / `az ... show` para confirmar um achado específico. Nunca use comandos que devolvem segredos (bloqueados pelas permissões do projeto):
`keys list`, `list-keys`, `secret show`, `appsettings list`, `show-connection-string`, `list-publishing-profiles`, `credential show`, `generate-sas`.

### Etapa 4: Análise por domínio
- **Storage, rede e exposição pública:** `${CLAUDE_SKILL_DIR}/references/storage_network_security.md`
- **Identidade e acesso (RBAC, Entra ID):** `${CLAUDE_SKILL_DIR}/references/cloud_iam_security.md`
- **Segredos e IaC:** `${CLAUDE_SKILL_DIR}/references/iac_secrets_security.md`
- **Defender, workloads e AKS:** `${CLAUDE_SKILL_DIR}/references/workloads_defender.md`

### Etapa 5: Relatório
Siga `${CLAUDE_SKILL_DIR}/references/report_template.md`. HTML autocontido em `reports/security-<escopo>-<AAAA-MM-DD>.html`.

Cada achado tem obrigatoriamente:
- **Recurso & escopo:** subscription / resource group / recurso, ou arquivo:linha
- **Evidência:** comando executado e saída resumida, com segredos mascarados
- **Severidade:** Crítico | Alto | Médio | Baixo (critérios nas referências)
- **Confiança:** Confirmado | Potencial | Inconclusivo
- **Recomendação e risco da alteração:** comando ou IaC em bloco de código, para execução manual
- **Validação:** comando de leitura que comprova a correção

---

## Regras inegociáveis
- **Somente leitura.** Nenhum `create`, `update`, `delete`, `set`, `assign`, `enable`, `disable`, `rotate`, `regenerate`.
- **Nunca exponha segredo.** Mostre no máximo 4 caracteres seguidos de `***`, com arquivo:linha ou recurso/chave. Arquivos de estado (`*.tfstate`) e `.env` são achados pelo **nome**; não abra o conteúdo.
- **Achado vazado em repositório é Crítico mesmo se o segredo já tiver sido trocado**: a recomendação inclui rotação e limpeza do histórico do git.
- **Dados pessoais:** em RBAC e Entra ID, prefira contagens; cite nomes de usuário só quando necessário para a correção.
- **Severidade honesta.** Crítico é o que expõe dados ou permite acesso indevido hoje.

## Padrão de saída (comum a todos os agentes)
Siga `${CLAUDE_SKILL_DIR}/references/report_standard.md`:
- **Dois arquivos** com o mesmo nome-base em `reports/`: `.html` (pessoas) e `.json` (outros agentes, Colmeia, comparação).
- **Vocabulário único:** severidade Crítico · Alto · Médio · Baixo · Info; confiança Confirmado · Potencial · Inconclusivo.
- **`fingerprint` estável** por achado (`<categoria>|<recurso>`), sem valores que mudam a cada execução.
- **"Desde a última auditoria":** compare com o JSON anterior do mesmo `<tipo>-<escopo>` (novos, resolvidos, persistentes, pioraram/melhoraram).
