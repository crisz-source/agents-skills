# Referência Técnica: Redes e Armazenamento Persistente

## Critérios de Análise

1. **Conectividade e Ingress:**
   - Services do tipo `ClusterIP` sem endpoints prontos (`kubectl get endpointslices -A`; `v1 Endpoints` é obsoleto desde a 1.33).
   - Ingresses sem `Secret` TLS associado ou referenciando Secret inexistente.

2. **Armazenamento e Persistência:**
   - PVCs no estado `Pending` (problemas com provisionamento de storage, StorageClass ou zonas).
   - PVs no estado `Released` ou `Failed` sem reciclagem adequada.
   - StorageClasses sem política de retenção (`reclaimPolicy`) explicitada.
