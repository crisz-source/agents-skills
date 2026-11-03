# Changelog — finops-framework

## 2.0.0 — 2026-11-03 (atualização para o FinOps Framework 2026)

### Conteúdo
- Domínios: de 6 (estrutura antiga) para os **4 domínios atuais** (Understand Usage & Cost, Quantify Business Value, Optimize Usage & Cost, Manage the FinOps Practice).
- **22 capacidades** com os nomes de 2026, cada uma com evidências, perguntas de entrevista e sinais Crawl/Walk/Run.
- Nova capacidade **Executive Strategy Alignment**.
- Capacidades renomeadas: Usage Optimization, Governance Policy & Risk, Automation Tools & Services, KPIs & Benchmarking, Architecting & Workload Placement (absorveu Onboarding Workloads), Sustainability.
- Personas atualizadas: 6 Core (inclui Product e Procurement separados, Leadership) e Allied (ITAM, ITFM, Sustainability, ITSM/ITIL, Security).
- Definição de FinOps e 6 princípios na redação 2025/2026 (foco em "tecnologia", não só nuvem).
- **Scopes** e **Technology Categories** (Public Cloud, SaaS, Data Center, Data Cloud Platforms, AI).
- Maturidade **por capacidade**, com nível-alvo; removida a "nota 0–100" (o framework não usa nota única).
- KPIs de referência oficiais (alocação, cobertura de compromissos, variação de forecast).
- Notas para setor público (aquisição de compromissos, showback, LOA/PPA, troca de gestão).

### Fluxo
- Etapa 0 de definição de Scope e pergunta de negócio.
- Entrevista estruturada por domínio; confiança Evidenciado / Declarado / Não avaliado.
- Integração com a skill `azure-cost-finops`: lê o relatório `reports/finops-*.html` em vez de refazer a análise técnica.
- Relatório em HTML autocontido em `reports/finops-maturidade-<unidade>-<data>.html`.

### Scripts
- `finops_collector.sh`: corrigido `--exclude-dir={...}` (não funcionava em `sh`); globs protegidos com `set -f`; busca budgets, Azure Policy, exports/FOCUS, alertas de anomalia, agendas, estimativas e relatórios existentes.
- Novo `azure_governance_evidence.sh`: somente leitura; cobertura de tags, budgets, exports, alertas de anomalia, policies e contagem de recomendações do Advisor.

Fonte: FinOps Framework 2026, FinOps Foundation (finops.org), CC BY 4.0.
