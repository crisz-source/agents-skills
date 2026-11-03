# Relatório de Auditoria de Arquitetura Azure

> **Obrigatório:** cabeçalho, vocabulário de severidade/confiança, arquivo JSON e a seção "Desde a última auditoria" seguem `report_standard.md`. Este template define só as seções específicas deste agente.

## Placar
- **Data da Auditoria:** {{DATA}}
- **Subscription (nome / id):** {{SUBSCRIPTION_INFO}}
- **Total de Recursos Avaliados:** {{TOTAL_RESOURCES}} (ignorados em grupos gerenciados: {{GERENCIADOS}})
- **Fora do Padrão de Tags:** {{FORA_PADRAO}} ({{TAG_COVERAGE_PERCENT}}% com todas as tags obrigatórias)
- **Órfãos Identificados:** {{ORFAOS}} — Seguros para remover: {{SEGUROS}} · Requer Validação: {{VALIDAR}} · Críticos: {{CRITICOS}}
- **Locks / Policies:** {{N_LOCKS}} locks · {{N_POLICIES}} atribuições de policy

---

## 1. Organização e Hierarquia
- Resource groups e segregação por ambiente (Produção / Não Produção / Compartilhado).
- Grupos monolíticos ou com recursos de ciclos de vida diferentes.

## 2. Governança
- Locks existentes e recursos críticos **sem** lock (Key Vault, bancos, gateways).
- Azure Policy: o que é imposto (deny/modify) e o que é só auditado.

## 3. Recursos Órfãos e Risco de Remoção

| Recurso | Tipo | Resource Group | Ambiente | Evidência (há quanto tempo, estado) | Dependências verificadas | Risco de Remoção |
|---|---|---|---|---|---|---|
| `disk-data-01` | Managed Disk | `rg-legacy` | Não Produção | Unattached desde 2026-06-10 | Sem snapshot dependente | **Seguro** (snapshot antes) |
| `pip-integracao` | Public IP (Static) | `rg-network` | Produção | Sem associação | IP pode estar liberado em parceiro | **Requer Validação** |

Sem valores em dinheiro: o custo desses itens é calculado pelo finops-azure.

## 4. Tagging
- Cobertura por tag obrigatória e por resource group (fora/total).
- Proposta de padrão e de Azure Policy (`Require a tag` / `Inherit a tag from the resource group`).

## 5. Plano de Ação (somente sugestões, para execução manual)
Cada comando com o risco da alteração.
```bash
# Exemplo: aplicar tags (ALTERA o recurso — executar só após revisão)
az tag update --resource-id "/subscriptions/..." --operation merge --tags Environment=Production Owner=time-devops
```

## 6. Fora do Escopo
- Custo, right-sizing e reservas → finops-azure. Interior de clusters → k8s-auditor. Segurança → cloud-security-analyst. Uma linha cada.

## 7. Limitações
- Verificações Inconclusivas (permissão, extensão) e o que ficou sem cobertura.
