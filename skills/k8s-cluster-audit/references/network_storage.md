# Referência Técnica: Redes, Ingress e Armazenamento Persistente

## 1. Conectividade
- Services com seletor e **nenhum** endpoint pronto (somando todos os EndpointSlices; `v1 Endpoints` é obsoleto desde a 1.33).
- Ingresses sem `Secret` TLS associado ou referenciando Secret inexistente.
- Services `LoadBalancer`/`NodePort` expostos sem necessidade (detalhe de restrição de IP em `security.md`).

## 2. Controlador de Ingress (prioridade em 2026)
| Situação | Severidade | Recomendação |
|---|---|---|
| **Ingress NGINX comunitário** (IngressClass com controller `k8s.io/ingress-nginx`, instalado via Helm/manifest) | **Alto** (Crítico se exposto à Internet em Produção) | A manutenção upstream terminou em março/2026: não há mais correções, nem de CVE. Migrar para Gateway API. |
| **NGINX do Application Routing do AKS** (`webapprouting.kubernetes.azure.com/nginx`) | **Alto** | A Microsoft dá suporte a patches críticos só até novembro/2026. Migrar para a implementação Gateway API do Application Routing (`--enable-app-routing-istio`) ou para o Application Gateway for Containers. |
| Gateway API já em uso (GatewayClass, Gateway, HTTPRoute) | Info | Verificar se ainda restam objetos `Ingress` ativos no controlador antigo. |

Ao recomendar a migração:
- Liste quantos objetos `Ingress` existem e quais anotações específicas do NGINX eles usam (`nginx.ingress.kubernetes.io/*`); são elas que dão trabalho na conversão.
- Opções no AKS: Application Routing com Gateway API (Istio gerenciado, sem malha) ou Application Gateway for Containers. Fora do AKS (RKE2/kubeadm): outra implementação de Gateway API (Envoy Gateway, Cilium, Istio, Traefik).
- A troca muda o IP/LoadBalancer de entrada: inclua DNS, certificados e regras de firewall no plano.

## 3. Armazenamento e Persistência
- PVCs no estado `Pending` (problemas com provisionamento de storage, StorageClass ou zonas).
- PVs no estado `Released` ou `Failed` sem reciclagem adequada.
- StorageClasses sem política de retenção (`reclaimPolicy`) explicitada; `Delete` em dados de Produção sem backup é risco.
