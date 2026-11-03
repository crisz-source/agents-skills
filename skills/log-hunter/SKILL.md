---
name: log-hunter
description: Investigação de logs e causa raiz, somente leitura - erros, crashes, OOM, timeouts, lentidão e erros silenciosos em aplicações (Java, Python, Node.js, Go, .NET, PHP, C/C++), containers Docker, pods Kubernetes, systemd e arquivos de log. Mascara senhas, tokens e dados pessoais já na coleta. Não audita configuração de cluster nem infraestrutura Azure.
allowed-tools: Bash(grep *) Bash(rg *) Bash(journalctl *) Bash(docker logs *) Bash(docker ps*) Bash(docker inspect --format *) Bash(kubectl logs *) Bash(kubectl --context * logs *) Bash(kubectl describe pod*) Bash(kubectl get events*) Bash(kubectl config current-context*) Bash(sh ${CLAUDE_SKILL_DIR}/scripts/*)
---
# Skill: Auditoria e Análise Universal de Logs
Esta habilidade executa a varredura, parseamento, categorização e diagnóstico de logs em qualquer ecossistema de software, runtime, linguagem de programação (Python, Java, Node.js/TS, Go, Rust, C#, PHP, Ruby, C/C++), container (Docker/Kubernetes) ou serviço de infraestrutura.
## Objetivos Principais
1. **Detecção Multilinguagem & Multi-Runtime:** Parser automático de exceções, stack traces, panics, fatal errors e warnings em múltiplos ecossistemas.
2. **Identificação de Erros Silenciosos e Riscos Ocultos:** Mapeamento de falhas de conexão intermitentes, estouro de pool de conexões, vazamento de memória, GC pressure, warnings de depreciação e exceções engolidas (swallowed exceptions).
3. **Diagnóstico de Conectividade e Dependências:** Falhas de DNS, timeouts de rede (internas/externas), erros de SSL/TLS, falhas em chamadas de API de terceiros ou microsserviços.
4. **Análise de Containers & Orquestradores:** Leitura de `stdout`/`stderr` em Docker, Pods Kubernetes, Systemd, Nginx, Apache, PM2, etc.
---
## Fluxo de Trabalho de Auditoria de Logs
### Etapa 1: Descobrimento do Ambiente e Coleta de Logs
**Regra de ouro: todo log passa pelo filtro de mascaramento antes de chegar ao contexto.**
O filtro `mask.sh` troca senhas, tokens, JWT, AccountKey/SAS, CPF, CNPJ, e-mail e números de cartão por `***`.

1. Identifique os alvos e colete sempre com limite (`--tail`, `--since`, `-n`) e com o filtro:
   - Docker: `docker logs --tail 500 --timestamps <container> 2>&1 | sh ${CLAUDE_SKILL_DIR}/scripts/mask.sh`
   - Estado do container (sem variáveis de ambiente): `docker inspect --format '{{.State.Status}} restarts={{.RestartCount}} oom={{.State.OOMKilled}} exit={{.State.ExitCode}} inicio={{.State.StartedAt}}' <container>`
   - Kubernetes: `kubectl logs -n <ns> <pod> --all-containers --tail=500 --timestamps | sh ${CLAUDE_SKILL_DIR}/scripts/mask.sh`
   - Pod que reiniciou: acrescente `--previous`; veja também `kubectl describe pod -n <ns> <pod>` (seções State, Last State e Events) e `kubectl get events -n <ns> --sort-by=.lastTimestamp`
   - Systemd / Linux: `journalctl -u <serviço> --since "1 hour ago" --no-pager | sh ${CLAUDE_SKILL_DIR}/scripts/mask.sh`
2. Para arquivos ou diretórios de log, use o coletor (já aplica o filtro, aceita nomes com espaço e agrupa erros repetidos):
   ```bash
   sh ${CLAUDE_SKILL_DIR}/scripts/log_collector.sh "<arquivo-ou-diretório>" ['*.txt']
   ```
   Seções: arquivos analisados, padrões de erro mais frequentes (números normalizados), primeiras ocorrências (a causa costuma estar no começo), últimos erros com contexto e sinais de erro silencioso.
---
### Etapa 2: Análise Técnica por Categoria
Consulte os arquivos de referência da skill para identificar assinaturas de erros específicos:
- **Assinaturas por Linguagem/Framework:** `${CLAUDE_SKILL_DIR}/references/log_patterns.md` (Java StackTraces, Python Tracebacks, Node UnhandledRejections, Go Panics, C/C++ Segfaults, etc.).
- **Erros Silenciosos e Concorrência:** `${CLAUDE_SKILL_DIR}/references/silent_errors.md` (Memory leak, Deadlocks, Thread pool exhaustion, Timeout progressivo).
---
### Etapa 3: Síntese e Estruturação do Relatório
Estruture o resultado final da análise utilizando rigorosamente o modelo em `${CLAUDE_SKILL_DIR}/references/report_template.md`.
Cada evento crítico deve apresentar:
- **Origem / Componente:** Serviço, container, arquivo ou linha de log.
- **Timestamp & Frequência:** Horário do evento e contagem de ocorrências.
- **Tipo do Erro:** Exceção, Crash, Falha de Rede, Memory Leak, Warning Silencioso.
- **Evidência (Trecho do Log):** Trecho relevante da stack trace, já mascarado.
- **Causa Raiz Provável:** Explicação técnica do motivo do problema.
- **Severidade:** Crítica | Alta | Média | Baixa.
- **Recomendação de Correção:** Solução em código, configuração ou infraestrutura.
---
## Arquivos de Referência
- [Padrões de Logs e Linguagens](references/log_patterns.md)
- [Erros Silenciosos e Riscos Ocultos](references/silent_errors.md)
- [Modelo de Relatório](references/report_template.md)
