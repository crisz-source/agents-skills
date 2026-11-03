#!/bin/sh
# Universal Log Collector — busca e resume eventos de log SEM alterar arquivos.
# Toda a saída passa por mask.sh (senhas, tokens, CPF, e-mail...) antes de chegar ao contexto.
#
# Uso: log_collector.sh <arquivo-ou-diretório> [padrão-de-nome]
#   padrão-de-nome (opcional): ex. '*.log' ; padrão: *.log *.out *.err
# Variáveis: LOG_LIMIT (linhas por seção, padrão 120), LOG_MAXFILES (padrão 30)

TARGET="${1:-.}"
NAMEPAT="$2"
LIMIT="${LOG_LIMIT:-120}"
MAXFILES="${LOG_MAXFILES:-30}"
DIR=$(dirname "$0")
MASK="sh $DIR/mask.sh"
set -f

if [ ! -e "$TARGET" ]; then
  echo "ERRO: '$TARGET' não existe." >&2
  exit 2
fi

LIST=$(mktemp)
trap 'rm -f "$LIST"' EXIT

# Lista de arquivos, um por linha (suporta espaços no nome).
if [ -f "$TARGET" ]; then
  printf '%s\n' "$TARGET" > "$LIST"
elif [ -n "$NAMEPAT" ]; then
  find "$TARGET" -type f -name "$NAMEPAT" ! -name '*.gz' ! -name '.env*' ! -name '*.pem' ! -name '*.key' 2>/dev/null | head -n "$MAXFILES" > "$LIST"
else
  find "$TARGET" -type f \( -name '*.log' -o -name '*.out' -o -name '*.err' -o -name '*.log.[0-9]' \) 2>/dev/null | head -n "$MAXFILES" > "$LIST"
fi

# grep_all <opções e padrão...>: roda grep em todos os arquivos da lista, preservando espaços.
grep_all() {
  while IFS= read -r f; do
    [ -n "$f" ] && grep -I "$@" -- "$f" 2>/dev/null
  done < "$LIST"
}

echo "=== [1/5] Arquivos analisados ==="
if [ ! -s "$LIST" ]; then
  echo "Nenhum arquivo de log encontrado em '$TARGET'. Use o 2º argumento para outro padrão (ex.: '*.txt')."
  exit 0
fi
while IFS= read -r f; do
  printf '%s\t%s linhas\t%s\n' "$f" "$(wc -l < "$f" | tr -d ' ')" "$(date -r "$f" '+%Y-%m-%d %H:%M' 2>/dev/null)"
done < "$LIST"

ERR='(^|[^[:alnum:]_])(error|erro|exception|panic|fatal|traceback|oomkilled|out of memory|segmentation fault|failed|falha|timeout|timed out|refused|denied|unhandled|critical)([^[:alnum:]_]|$)'
WARN='(^|[^[:alnum:]_])(warn|warning|deprecated|retry|retrying|reconnect|reconnecting|pool (is )?(full|exhausted)|exhausted|slow query|leak|throttl)'

echo "
=== [2/5] Padrões de erro mais frequentes (números normalizados) ==="
grep_all -h -i -E "$ERR" | $MASK | sed -E 's/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/<uuid>/g; s/[0-9]+/N/g' \
  | cut -c1-200 | sort | uniq -c | sort -rn | head -n 25

echo "
=== [3/5] Primeiras ocorrências de erro (a causa costuma estar no começo) ==="
grep_all -H -n -i -E -m 15 "$ERR" | cut -c1-300 | head -n 40 | $MASK

echo "
=== [4/5] Últimos erros com contexto ==="
grep_all -H -n -i -E -B 2 -A 4 "$ERR" | tail -n "$LIMIT" | cut -c1-300 | $MASK

echo "
=== [5/5] Warnings e sinais de erro silencioso (retry, pool, deprecated, leak) ==="
grep_all -h -i -E "$WARN" | $MASK | sed -E 's/[0-9]+/N/g' | cut -c1-200 | sort | uniq -c | sort -rn | head -n 20

echo "
=== Coleta concluída (saída mascarada) ==="
