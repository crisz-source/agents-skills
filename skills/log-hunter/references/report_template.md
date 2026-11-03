# Relatório de Análise e Auditoria de Logs

## 1. Resumo Executivo
- **Data da Análise:** {{DATA}}
- **Fonte(s) dos Logs:** {{LOG_SOURCES}} (ex: `/var/log/app.log`, Kubernetes Pod `auth-service`, Docker Container `redis`)
- **Período Coberto:** {{LOG_PERIOD}}
- **Total de Linhas Analisadas:** {{TOTAL_LINES}}
- **Total de Erros/Alertas Encontrados:** {{ERROR_COUNT}}

---

## 2. Distribuição por Severidade
- **Crítico (Crashes, OOM, Panics, Outages):** {{CRITICAL_COUNT}}
- **Alto (Exceções não tratadas, Falhas de Conexão):** {{HIGH_COUNT}}
- **Médio (Warnings, Timeouts intermitentes):** {{MEDIUM_COUNT}}
- **Baixo / Silencioso (Depreciações, GC Pressure, Retries):** {{LOW_COUNT}}

---

## 3. Matriz de Achados e Diagnóstico de Causa Raiz

### Achado #1: [Título Sucinto do Erro]
- **Componente / Linguagem:** {{COMPONENT_LANG}}
- **Severidade:** {{SEVERITY}}
- **Frequência de Ocorrência:** {{FREQUENCY}} vezes no período
- **Evidência do Log:**
  ```text
  {{LOG_SNIPPET}}
  ```
- **Análise da Causa Raiz:** {{ROOT_CAUSE_ANALYSIS}}
- **Impacto no Sistema:** {{SYSTEM_IMPACT}}
- **Recomendação de Correção:**
  - *Ação Imediata:* {{IMMEDIATE_ACTION}}
  - *Correção de Código/Configuração:* {{CODE_FIX_SUGGESTION}}

---

## 4. Erros Silenciosos e Riscos Ocultos Identificados
- Detalhamento de warnings, retries e tendências de fadiga de recursos que exigem prevenção.

---

## 5. Próximos Passos e Ações Recomendadas
1. [ ] Aplicar correção no arquivo `...`
2. [ ] Ajustar pool de conexões / limites de memória em `...`
3. [ ] Configurar monitoramento para o log de alerta `...`
