# Referência Técnica: Organização, Hierarquia e Governança Azure

## 1. Estrutura e Hierarquia de Recursos
- **Management Groups & Subscriptions:** Avaliar a segregação de ambientes (Production, Staging, Dev, Shared Services).
- **Resource Groups (RGs):** Verificar a coesão do ciclo de vida dos recursos agrupados.
  - *Boa Prática:* Recursos que compartilham o mesmo ciclo de vida e permissões devem estar no mesmo RG.
  - *Sinal de Alerta:* Resource Groups monolíticos ("rg-geral", "default-rg") contendo recursos heterogêneos de diferentes projetos.

## 2. Controle de Acesso e Governança
- **Azure Policy:** Verificar se há políticas de conformidade ativas impondo criação de tags e regiões permitidas.
- **Locks de Recurso (CanNotDelete / ReadOnly):** Verificar presença de locks em recursos críticos (Key Vaults, Databases, ExpressRoute/VPN Gateways).

## 3. O que observar na coleta
- **Locks:** recursos críticos de Produção (Key Vault, bancos, Application Gateway, VPN/ExpressRoute) sem `CanNotDelete` → recomendar.
- **Azure Policy:** diferenciar efeito `Deny`/`Modify` (impõe) de `Audit` (só registra). Política de tag só em `Audit` explica cobertura baixa.
- **Grupos gerenciados** (`MC_*`, `NetworkWatcherRG`): não recomendar alteração direta; tags e configurações deles devem ser geridas pelo recurso pai (cluster/node pool do AKS), não diretamente.
