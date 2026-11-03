# Regras do projeto

Este projeto tem 6 agentes isolados. Cada um tem a sua própria skill e não usa a dos outros.

| Agente | Skill exclusiva | Escopo |
| :--- | :--- | :--- |
| `finops-azure` | `azure-cost-finops` | Custo, desperdício e economia na Azure (inclui arquitetura cara por natureza) |
| `finops-maturidade` | `finops-framework` | Maturidade da prática FinOps (FinOps Framework 2026): processos, papéis, governança financeira, roadmap |
| `azure-architect` | `azure-arch-audit` | Hierarquia, governança (locks, policy), padrão de tags e risco de remoção. Sem valores em dinheiro |
| `cloud-security-analyst` | `cloud-security-audit` | Postura de segurança Azure e Entra ID, exposição pública, RBAC, segredos em IaC |
| `k8s-auditor` | `k8s-cluster-audit` | Configuração e saúde dos clusters Kubernetes (o que roda dentro do cluster) |
| `log-hunter` | `log-hunter` | Logs, incidentes e causa raiz |

## Como a conversa principal deve agir

1. **Sempre delegue ao agente.** Não execute nenhuma dessas skills diretamente na conversa principal; elas existem para ser usadas dentro do agente dono.
2. **Um pedido, um agente.** Escolha o agente pelo escopo da tabela. Se o pedido cobrir duas áreas (por exemplo, "custo e tags"), chame cada agente separadamente, com uma tarefa bem delimitada para cada.
3. **Não misture contextos.** Ao delegar, passe só o que aquele agente precisa (escopo, subscription, contexto do cluster, janela de tempo). Não repasse o relatório de um agente como instrução para outro.
   - **Exceção única:** o `finops-maturidade` lê os relatórios já salvos em `reports/` (`finops-*.json` e `arch-*.json`) como **evidência**. Se o usuário pedir avaliação de maturidade completa, sugira rodar antes o `finops-azure` e o `azure-architect` — e pergunte, não acione por conta própria.
4. **"Fora do escopo" é informação para o usuário.** Quando um relatório tiver itens nessa seção, mostre-os ao usuário e pergunte se ele quer acionar o agente correspondente. Não acione por conta própria.
5. **Na dúvida sobre qual agente usar, pergunte ao usuário.**

## Fronteiras que costumam confundir

| Pedido | Agente |
| :--- | :--- |
| "Quanto custa esse disco órfão?" | `finops-azure` |
| "Posso apagar esse disco órfão?" | `azure-architect` (dependências e risco) |
| "Quantos recursos estão sem tag?" | `azure-architect` |
| "Nossa política de tags/showback funciona?" | `finops-maturidade` |
| "O AKS tem API pública?" | `cloud-security-analyst` (camada Azure) |
| "Tem pod privilegiado no cluster?" | `k8s-auditor` |
| "Esse node pool está caro?" | `finops-azure` |
| "Por que o pod reinicia?" | `log-hunter` (e `k8s-auditor` se for configuração) |
