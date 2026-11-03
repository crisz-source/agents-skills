# Referência: Segredos e IaC (prefixo SEC)

## Segredos expostos
| Achado | Severidade |
|---|---|
| Chave privada (`-----BEGIN ... PRIVATE KEY-----`), `AccountKey=`, SAS com `sig=`, token de GitHub/PAT | **Crítico** |
| Senha ou client secret literal em `.tf`, `.tfvars`, `.bicep`, `.json`, pipeline YAML | **Crítico** |
| `*.tfstate` versionado (contém segredos em texto puro) | **Crítico** |
| `.env`, `.pfx`, `.p12`, `kubeconfig` versionados | **Crítico** |
| JWT em arquivo de configuração | Alto (verificar se expira) |
| Variável com nome de segredo e `default` literal em Terraform | Alto |

Regras:
- Mostre no máximo 4 caracteres + `***`. Cite arquivo:linha.
- **Não abra** `.tfstate`, `.env` ou certificados; o nome do arquivo já é a evidência.
- Segredo em repositório é comprometido **mesmo que removido depois**: recomendação = rotacionar o segredo + remover do histórico (`git filter-repo` ou BFG) + mover para Key Vault / variável secreta do pipeline.
- Referências (`var.x`, `${{ secrets.X }}`, `@Microsoft.KeyVault(...)`, `$(VAR)`) **não** são achados.

## Configurações inseguras em IaC
| Padrão | Severidade |
|---|---|
| `allow_nested_items_to_be_public = true` / `allowBlobPublicAccess: true` | Alto |
| `public_network_access_enabled = true` em banco, Key Vault ou ACR de Produção | Médio |
| `min_tls_version = "TLS1_0"` ou `"TLS1_1"` | Alto |
| `https_only = false` / `enableHttpsTrafficOnly: false` | Alto |
| `admin_enabled = true` (ACR) | Alto |
| `source_address_prefix = "*"` em regra Inbound Allow de porta sensível | **Crítico** |
| `purge_protection_enabled = false` em Key Vault de Produção | Alto |

## Pipelines
- Segredos devem vir de variável secreta, variable group ligado ao Key Vault ou identidade federada (OIDC), nunca do YAML.
- Service connection com papel `Owner` é achado de IAM (registre lá).
