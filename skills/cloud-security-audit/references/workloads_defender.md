# Referência: Defender for Cloud, Workloads e AKS na camada Azure (prefixo WKL)

## Defender for Cloud
| Verificação | Severidade |
|---|---|
| Plano relevante em `Free` (ex.: `VirtualMachines`, `Containers`, `StorageAccounts`, `KeyVaults`, `SqlServers`, `Arm`) em subscription de Produção | Alto |
| Secure Score abaixo de 60% | Médio (indicador geral; não substitui os achados) |
| Recomendação `Unhealthy` de severidade alta repetida em muitos recursos | conforme a recomendação |

Use as recomendações do Defender como **evidência**, não como relatório: agrupe por tema e cite quantos recursos cada uma afeta.
O custo de ligar planos do Defender é assunto do finops-azure (registre em "Fora do Escopo" se relevante).

## Imagens e vulnerabilidades (CWPP)
- Com o plano **Containers** ativo, o Defender avalia vulnerabilidades das imagens no ACR e em execução. Use as recomendações correspondentes (`assessment list`) como evidência.
- Sem o plano, a análise de CVE fica **Inconclusiva**: recomende ativar ou usar scanner no pipeline (ex.: Trivy). Não rode scanners que não estejam disponíveis.
- Imagem base em fim de suporte (EOL), quando visível no IaC/Dockerfile → Alto.

## AKS — camada Azure
| Verificação | Severidade |
|---|---|
| API server pública sem `authorizedIpRanges` e não privada | Alto |
| Contas locais habilitadas (`disableLocalAccounts` ≠ true) | Alto: o `--admin` kubeconfig ignora o Entra ID |
| Sem integração com Entra ID (`aadProfile` vazio) | Alto |
| Sem network policy (`networkPolicy` vazio) | Médio (achado de rede; o detalhe é do k8s-auditor) |
| Versão do Kubernetes fora do suporte do AKS | Alto — confirme o calendário atual com `az aks get-versions -l <região>` |
| Defender for Containers desligado no cluster | Médio |
| Node pool com **Azure Linux 2.0** (`osSku` AzureLinux em Kubernetes < 1.32) | **Crítico**: sem patches desde 30/11/2025 e imagens removidas em 31/03/2026 — escalar ou recriar nodes **falha**. Migrar para `AzureLinux3` (in-place a partir da 1.28) ou subir a versão |
| Node pool **Ubuntu 20.04** | Alto: suporte no AKS termina em 17/03/2027 |
| Rede **kubenet** (`networkPlugin = kubenet`) | Médio: aposentadoria em 31/03/2028; planejar migração para Azure CNI Overlay |
| SKU Basic em IP público ou Load Balancer usado pelo cluster | Alto: aposentado em 30/09/2025, sem suporte nem SLA |

O que está **dentro** do cluster (pods privilegiados, RBAC do Kubernetes, Secrets) é do k8s-auditor: registre em "Fora do Escopo".
