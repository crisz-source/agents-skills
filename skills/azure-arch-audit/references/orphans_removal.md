# Referência Técnica: Recursos Órfãos e Risco de Remoção

Este agente decide **se é seguro remover**, não **quanto se economiza** (valor em dinheiro é do finops-azure).
Right-sizing de VMs e bancos também é do finops-azure: registre em "Fora do escopo".

## Níveis de risco de remoção
| Nível | Quando usar |
|---|---|
| **Seguro** | Sem nenhuma dependência encontrada **e** sem atividade nos últimos 30 dias **e** em Não Produção, ou com dono confirmado. |
| **Requer Validação** | Qualquer dúvida: sem dono identificado, em Produção, recurso que pode ser referenciado de fora da Azure, ou evidência de uso indireta. **É o padrão.** |
| **Crítico (não remover)** | Dependência encontrada (Private Endpoint, regra, backup, AKS) ou recurso de grupo gerenciado (`MC_*`, `NetworkWatcherRG`). |

## Por tipo de recurso
- **Managed Disk sem `managedBy`:** use `diskState` e `lastOwnershipUpdateTime` (há quanto tempo foi desanexado). Disco `Reserved` está em uso por outro processo. Verifique se existe snapshot ou ponto de restauração que dependa dele. Mesmo quando seguro, recomende **snapshot antes de remover**. Discos de PVC de AKS removidos do cluster aparecem aqui: o nome costuma começar com `pvc-`.
- **IP público sem associação:** **sempre Requer Validação** se a alocação for `Static`. IPs estáticos costumam estar liberados em firewall de parceiros ou cadastrados em DNS externo; removido, o endereço não volta. Verifique o `dnsSettings.fqdn`.
- **NIC sem VM e sem Private Endpoint:** confira se não é de Private Link Service, de NVA (appliance de rede) ou reservada para uma VM em recriação. Requer Validação por padrão.
- **NSG sem subnet e sem NIC:** costuma ser seguro, mas verifique se não é usado como modelo em IaC (removê-lo quebra o próximo deploy).
- **App Service Plan com `numberOfSites = 0`:** seguro em Não Produção; em Produção, confirme se não é reservado para um slot ou deploy futuro.
- **Snapshots antigos:** identifique o disco de origem (`creationData.sourceResourceId`). Snapshot cujo disco de origem não existe mais pode ser o único backup: Requer Validação.

## Recursos que nunca são "órfãos" sem análise
- Tudo em `MC_*` (gerenciado pelo AKS) e `NetworkWatcherRG`.
- Recursos com lock `CanNotDelete` ou `ReadOnly`: o lock é uma decisão explícita de alguém.
- Key Vault referenciado por AKS, App Service ou pipeline.
