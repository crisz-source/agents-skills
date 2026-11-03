# Modelo do Relatório de Maturidade FinOps

> **Obrigatório:** cabeçalho, vocabulário de severidade/confiança, arquivo JSON e a seção "Desde a última auditoria" seguem `report_standard.md`. Este template define só as seções específicas deste agente.

Entrega: **HTML único e autocontido** (CSS em `<style>`, sem CDN, fontes ou scripts externos), legível em tela e impresso.
Arquivo: `reports/finops-maturidade-<unidade>-<AAAA-MM-DD>.html`.
Cores por nível: Não praticado (cinza escuro), Crawl (vermelho), Walk (amarelo/âmbar), Run (verde), Não avaliado (cinza claro, tracejado).
Selo de confiança em cada linha: **Evidenciado** | **Declarado** | **Não avaliado**.

As seções abaixo são obrigatórias, nesta ordem (os exemplos mostram o conteúdo, não a marcação).

```text
🧭 Avaliação de Maturidade FinOps
Data: [AAAA-MM-DD]
Unidade avaliada: [organização / órgão / sistema]
Scope FinOps: [nome] — pergunta de negócio: "[...]"
Technology Categories: [Public Cloud (Azure) | SaaS | ...]
Fontes de evidência: [IaC: sim/não | Azure (subscription X): sim/não | Relatório azure-cost-finops de [data]: sim/não | Entrevista: N respostas]
Base: FinOps Framework 2026 — FinOps Foundation (finops.org), CC BY 4.0

1. 💡 Resumo Executivo
   - Visão por domínio (resumo, não média):
     | Domínio                        | Predominante | Capacidades em Run/Walk/Crawl/Não praticado/Não avaliado |
     | Understand Usage & Cost        | Crawl        | 0 / 1 / 2 / 1 / 0                                         |
     | Quantify Business Value        | ...          | ...                                                       |
     | Optimize Usage & Cost          | ...          | ...                                                       |
     | Manage the FinOps Practice     | ...          | ...                                                       |
   - As 3 lacunas mais importantes para o Scope, uma frase cada.
   - Nota: o framework não usa nota única; a maturidade é por capacidade.

2. 👥 Personas e Princípios
   - Matriz de personas: Persona | Quem é (cargo/área) | Envolvimento (Ativo / Parcial / Ausente)
     (6 Core + Allied relevantes; persona sem dono é destacada como lacuna)
   - Princípios: os 6, cada um com Atende / Parcial / Não atende + evidência em uma linha.

3. 📊 Matriz de Maturidade (22 capacidades)
   | Domínio | Capacidade | Atual | Alvo | Confiança | Evidência (1 linha) | Prioridade |
   Uma linha por capacidade, na ordem de domains_capabilities.md.
   Alvo definido pelo valor de negócio do Scope (Run não é meta automática).
   Prioridade: Alta / Média / Baixa.

4. 🔍 Diagnóstico por Domínio
   Para cada um dos 4 domínios:
   - O que funciona (com evidência)
   - Lacunas (com evidência)
   - Dependências (ex.: "Unit Economics depende de Allocation ≥ Walk")

5. 📏 KPIs
   | KPI | Valor atual | Fonte (Medido / Declarado / N/D) | Referência Crawl/Walk/Run | Meta proposta |
   Mínimo: % custo alocado, cobertura de tags, variação de forecast, cobertura de compromissos,
   tempo de detecção de anomalia, taxa de desperdício (do relatório azure-cost-finops, se houver).

6. 🧮 Unit Economics Proposto
   - Métrica primária: [custo por ...] — fonte do denominador — pré-requisitos
   - Até 2 métricas secundárias

7. 🗺️ Roadmap
   Curto prazo (até 30 dias) | Médio (até 90 dias) | Longo (até 180 dias)
   Cada ação: [ ] Ação — Capacidade — Persona dona — Esforço (Baixo/Médio/Alto) — Critério de pronto verificável
   Quando a ação envolver configuração (budget, Azure Policy, export FOCUS, alerta de anomalia, tag),
   inclua o comando ou trecho de IaC sugerido em bloco de código, para execução manual pelo operador.

8. 🔗 Insumos para Outras Análises
   - Para a skill azure-cost-finops: itens técnicos suspeitos encontrados (uma linha cada, sem investigar).
   - Para outras áreas (segurança, licenciamento, contratos): uma linha cada.

9. ⚠️ Limitações da Avaliação
   - Capacidades Não avaliadas e o motivo (sem permissão, sem resposta, fora do Scope).
   - Comandos que falharam e por quê.
   - Quem respondeu a entrevista (cargo/área), sem dados pessoais desnecessários.
```
