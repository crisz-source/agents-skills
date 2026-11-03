# meus-agentes

Plugin do Claude Code com agentes e skills de auditoria para **Microsoft Azure** e **Kubernetes (AKS, RKE2, kubeadm)**, usado pelo Colmeia
(rodapé esquerdo → **Meus agentes** → escolher esta pasta).

Todos os agentes trabalham em modo **somente leitura**: coletam dados, analisam e entregam um relatório HTML com achados, evidências e recomendações. Comandos de correção aparecem só no relatório, para o operador executar depois de revisar.

---

## Agentes

| Agente | Papel | Skill | Quando usar |
| :--- | :--- | :--- | :--- |
| `finops-azure` | Analista FinOps | `azure-cost-finops` | Custo, desperdício, right-sizing, reservas, arquitetura cara |
| `finops-maturidade` | FinOps Practitioner | `finops-framework` | Maturidade da prática FinOps (Framework 2026), roadmap |
| `azure-architect` | Arquiteto Azure | `azure-arch-audit` | Hierarquia, locks, policy, tags, órfãos e risco de remoção |
| `cloud-security-analyst` | Analista de segurança | `cloud-security-audit` | Defender, exposição pública, RBAC, Entra ID, segredos em IaC |
| `k8s-auditor` | SRE / Platform Engineer | `k8s-cluster-audit` | Saúde, segurança, resiliência, rede e sizing dentro do cluster |
| `log-hunter` | Investigador de incidentes | `log-hunter` | Erros, crashes, timeouts e causa raiz em logs |

As fronteiras entre agentes estão no `CLAUDE.md` (tabela "Fronteiras que costumam confundir").

### Isolamento
- **Contexto próprio:** cada agente começa com uma janela de contexto nova.
- **Skill própria:** o campo `skills:` carrega a skill do agente; `disallowedTools: Skill, Agent` impede carregar outra skill ou chamar outro agente.
- **Escopo próprio:** o que é de outra área vai para a seção "Fora do escopo" do relatório. Quem decide acionar outro agente é você.
- **Exceção:** o `finops-maturidade` lê relatórios já salvos em `reports/` (`finops-*`, `arch-*`) como evidência.

---

## Estrutura

```
meus-agentes/
├── .claude-plugin/plugin.json   # nome do plugin: os agentes ficam meus-agentes:<nome>
├── agents/                      # QUEM faz: persona, regras e limites (um .md por agente)
├── skills/<nome>/               # COMO fazer
│   ├── SKILL.md                 # roteiro, allowed-tools (só leitura)
│   ├── scripts/                 # coleta determinística, somente leitura
│   └── references/              # critérios de análise e template do relatório
├── permissoes.json              # allow/deny aplicados pelo Colmeia a cada agente
├── CLAUDE.md                    # regras para a conversa principal delegar (referência; plugin não carrega)
├── .gitattributes               # LF nos scripts (CRLF quebra o sh)
└── .gitignore                   # backups, reports/, segredos
```

---

## Uso

No Colmeia: escolha esta pasta em **Meus agentes**.

Fora do Colmeia (**sempre com as permissões**, senão nada bloqueia comandos destrutivos):
```
claude --plugin-dir C:\meus-agentes --settings C:\meus-agentes\permissoes.json --agent meus-agentes:k8s-auditor
```

Exemplos de pedido:
```text
use o finops-azure para analisar a subscription de produção
use o azure-architect para auditar o resource group rg-supp-hml
use o cloud-security-analyst para auditar a subscription de homologação e o repositório de IaC
use o k8s-auditor para auditar o cluster de homologação
use o log-hunter para investigar por que o pod api-xyz está reiniciando
use o finops-maturidade para avaliar a prática FinOps do sistema SUPP
```

Relatórios: `reports/<tipo>-<escopo>-<AAAA-MM-DD>.html`.

---

## Pré-requisitos
- Claude Code; Azure CLI autenticada (`az login`) com **Reader** e **Cost Management Reader** no escopo
- Opcional: **Security Reader** (Defender) e leitura no Entra ID (MFA/Conditional Access) para o `cloud-security-analyst`
- `kubectl` com contexto configurado (de preferência um contexto só leitura)
- Leitura de `docker logs` e `journalctl` para o `log-hunter`
- Scripts rodam com `sh` (Git Bash no Windows)

---

## Segurança

Três camadas, da mais fraca para a mais forte:
1. **Instruções do agente e da skill:** "somente leitura", mascaramento, escopo.
2. **`allowed-tools` das skills:** só pré-aprovam verbos de leitura (`list`, `show`, `get`, `describe`, `logs`, `query`).
3. **`permissoes.json` (`deny` vence `allow`):** bloqueia escrita (`delete`, `create`, `update`, `set`, `add`, `remove`, `enable`, `disable`, `invoke`...), comandos que **devolvem segredos** (`keys list`, `list-keys`, `appsettings list`, `show-connection-string`, `secret show`, `generate-sas`...), `az rest`, `kubectl exec/debug/run`, leitura de Secrets com `-o`/`--output`, `docker inspect` sem `--format`, e arquivos sensíveis (`.env`, `*.pem`, `*.key`, `~/.kube`, `~/.azure`, `~/.ssh`). Os `deny` do kubectl valem também com `--context`.

> ⚠️ **Limites conhecidos**
> - As regras validam o **comando digitado**, não o conteúdo dos scripts. Todo script em `skills/*/scripts/` deve conter só leitura — revise antes de aceitar mudanças.
> - As regras comparam texto: um `--query` com um alias como ` settings` ou ` enableX` (com espaço antes) pode ser negado por engano. Nos `--query`, use aliases sem espaço antes dessas palavras.
> - `kubectl describe pod` mostra variáveis de ambiente escritas direto no manifesto. O mascaramento depende do agente; prefira Secrets a env literal.

Mascaramento: o `log-hunter` passa toda saída de log por `skills/log-hunter/scripts/mask.sh` (senhas, tokens, JWT, CPF, CNPJ, e-mail, cartão). O `cloud-security-analyst` mostra no máximo 4 caracteres de qualquer segredo encontrado em IaC.
