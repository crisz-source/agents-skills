#!/bin/sh
# mask.sh — filtro que mascara dados sensíveis em logs ANTES de chegarem ao contexto.
# Uso: <comando de log> | sh mask.sh
#   ex.: kubectl logs -n app api-1 --tail=500 | sh ${CLAUDE_SKILL_DIR}/scripts/mask.sh
# Mascara: senhas/segredos/tokens em pares chave=valor ou "chave": "valor", Bearer/Basic,
# JWT, AccountKey/SAS, chaves de GitHub, CPF, CNPJ, e-mail e cartão (13-19 dígitos).

sed -E \
  -e 's/(Bearer|Basic)[[:space:]]+[A-Za-z0-9._~+\/=-]+/\1 ***/Ig' \
  -e 's/((password|passwd|pwd|senha|secret|client_secret|token|access_token|refresh_token|api[_-]?key|apikey|authorization)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?)[^"'"'"'[:space:],;&}]+/\1***/Ig' \
  -e 's/eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]*/<jwt***>/g' \
  -e 's/(AccountKey|SharedAccessKey|sig)=[^;&" ]+/\1=***/Ig' \
  -e 's/(ghp|gho|ghs|github_pat)_[A-Za-z0-9_]{10,}/\1_***/g' \
  -e 's/[0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}/<cpf***>/g' \
  -e 's/[0-9]{2}\.[0-9]{3}\.[0-9]{3}\/[0-9]{4}-[0-9]{2}/<cnpj***>/g' \
  -e 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/<email***>/g' \
  -e 's/(^|[^0-9])[0-9]{4}[ -]?[0-9]{4}[ -]?[0-9]{4}[ -]?[0-9]{1,7}([^0-9]|$)/\1<cartao***>\2/g'
