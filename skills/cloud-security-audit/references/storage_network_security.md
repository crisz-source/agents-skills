# Referência: Storage, Rede e Exposição Pública (prefixos STO / NET)

## Storage Accounts
| Verificação | Campo | Severidade |
|---|---|---|
| Blob com acesso anônimo permitido | `allowBlobPublicAccess = true` | **Crítico** se algum container for público com dados; **Alto** se só permitido |
| Rede pública sem firewall | `publicNetworkAccess = Enabled` e `networkRuleSet.defaultAction = Allow` | Alto (Produção) / Médio |
| TLS antigo | `minimumTlsVersion` < `TLS1_2` | Alto |
| HTTP permitido | `enableHttpsTrafficOnly = false` | Alto |
| Chave compartilhada habilitada | `allowSharedKeyAccess` ≠ `false` | Médio (preferir Entra ID / identidade gerenciada) |

Confirmar containers públicos (somente leitura, sem chave, exige permissão de dados):
`az storage container list --account-name <conta> --auth-mode login --query "[?properties.publicAccess!=null].{Nome:name, Acesso:properties.publicAccess}" -o table`.
Se falhar por permissão, o achado fica **Potencial**.

## NSG
- Regra **Inbound Allow** com origem `*`, `Internet`, `Any` ou `0.0.0.0/0`:
  - Porta de gestão (22, 3389, 5985-5986) ou `*` → **Crítico**
  - Porta de banco/cache/fila (1433, 3306, 5432, 6379, 27017, 9200, 5672) → **Crítico**
  - Docker/Kubelet (2375-2376, 10250) → **Crítico**
  - 80/443 em recurso que deveria ser interno → **Médio**; em front-end público esperado → informativo
- Sugestão de correção: restringir origem, usar Azure Bastion, Just-In-Time (Defender) ou Private Endpoint.

## Azure SQL
| Verificação | Severidade |
|---|---|
| Regra de firewall `0.0.0.0` – `255.255.255.255` | **Crítico** |
| Regra `0.0.0.0` – `0.0.0.0` ("Allow Azure services") | Médio: libera qualquer recurso Azure, de qualquer tenant |
| `publicNetworkAccess = Enabled` sem necessidade | Médio |
| `minimalTlsVersion` < 1.2 | Alto |
| Sem administrador do Entra ID | Médio |

## App Service / Functions
| Verificação | Severidade |
|---|---|
| `httpsOnly = false` | Alto |
| `minTlsVersion` < 1.2 | Alto |
| `ftpsState = AllAllowed` (FTP sem TLS) | Alto; o ideal é `Disabled` |
| `remoteDebuggingEnabled = true` em Produção | Alto |

## Container Registry
| Verificação | Severidade |
|---|---|
| `adminUserEnabled = true` | Alto (credencial compartilhada; preferir identidade gerenciada / token com escopo) |
| `anonymousPullEnabled = true` | Alto |
| Rede pública aberta (Premium permite Private Endpoint) | Médio |

## Key Vault
| Verificação | Severidade |
|---|---|
| `enablePurgeProtection` ausente/false em Produção | Alto (segredo apagado não pode ser recuperado após o período) |
| Rede pública com `defaultAction = Allow` | Médio |
| Modelo de acesso por Access Policy (`enableRbacAuthorization = false`) | Baixo/Médio: recomendar migração para RBAC |
Nunca liste nem mostre valores de segredos, chaves ou certificados.
