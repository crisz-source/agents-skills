# Changelog

## 0.4.0 — 2026-11-03
### Novo
- **Permissões por agente** em `permissoes/<agente>.json`: cada agente só tem as ferramentas do seu escopo (ex.: `k8s-auditor` não roda `az`; agentes Azure não rodam `kubectl`), só executa os scripts da própria skill e não lê nem executa arquivos das skills dos outros.
- **Fonte única** `permissoes/fonte.json` + gerador `permissoes/gerar.py`; o `permissoes.json` da raiz passa a ser gerado (união, para compatibilidade).
- Testes: o CI falha se os arquivos gerados estiverem desatualizados; simulação de 376 verificações (união + 6 agentes, incluindo isolamento entre skills).

### Corrigido
- Removida a regra `Write(reports/**)`: regras de caminho com `Write` não são consultadas pelo Claude Code (o `Edit(reports/**)` já cobre a escrita).

## 0.3.0 — 2026-11-03
### Novo
- **Padrão comum de relatório** (`schemas/report_standard.md`, copiado em cada skill): HTML + **JSON** com o mesmo nome-base, vocabulário único de severidade/confiança, `fingerprint` por achado e seção **"Desde a última auditoria"**.
- **Coletor da `azure-cost-finops`** (`cost_collector.sh`), que antes era a única skill sem script.
- **Várias subscriptions** nos coletores Azure (`sub-a,sub-b`).
- **Testes automáticos** (`tests/run.sh`) e **GitHub Actions**.
- `tests/validate_report.py` para validar relatórios JSON gerados.

### Atualizado (mudanças de 2025–2026)
- **Ingress NGINX:** detecção do controlador comunitário (sem manutenção desde mar/2026) e do NGINX do Application Routing (suporte até nov/2026), com caminho para Gateway API.
- **Reservas:** a partir de 01/02/2027, reservas de serviços cobertos por Savings Plan não podem ser trocadas; Savings Plan para bancos de dados.
- **Log Analytics:** tabela `ContainerLog` aposentada em 30/09/2026; limites dos planos Basic/Auxiliary.
- **SKUs Basic** de IP público e Load Balancer (aposentados em 30/09/2025).
- **AKS:** Azure Linux 2.0 (imagens removidas em 31/03/2026), Ubuntu 20.04 (17/03/2027), kubenet (31/03/2028), aad-pod-identity descontinuado.
- **Entra ID:** MFA obrigatório na fase 2 (ARM/CLI) e automação com conta de usuário.
- **log-hunter:** assinaturas de erro atuais (Node 20+, Java 17/21, .NET 8), códigos de saída de container, Envoy/Gateway API e histórico via `ContainerLogV2`.

### Corrigido
- k8s: restarts e erros de init containers/sidecars nativos eram ignorados.
- log-hunter: `exited with code 137` não era detectado.
- k8s `sizing.md`: orientação de limites de CPU/memória alinhada à prática atual.

## 0.2.0 — 2026-11-03
- Permissões endurecidas (comandos que devolvem segredos, `--context`, `-ojson`), `cloud-security-audit` reescrita, coletores do k8s/arch/log corrigidos, agente `finops-maturidade`, skill `finops-framework` no FinOps Framework 2026.
