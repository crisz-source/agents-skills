#!/usr/bin/env bash
# Suíte de testes do plugin meus-agentes.
# Uso: bash tests/run.sh      (no Windows: Git Bash)
# Não acessa Azure nem cluster: az e kubectl são simulados (tests/mocks).
# Segredos de teste são montados em tempo de execução, nunca gravados no repositório.

set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TESTS="$ROOT/tests"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export MOCK_LOG="$WORK/calls.log"
PY="$(command -v python3 || command -v python)"
PASS=0; FAIL=0; SKIP=0

ok()   { PASS=$((PASS+1)); echo "  ✔ $1"; }
fail() { FAIL=$((FAIL+1)); echo "  ✘ $1"; }
skip() { SKIP=$((SKIP+1)); echo "  ⊘ $1"; }
section() { echo ""; echo "== $1"; }
# assert_contains <arquivo> <texto> <descrição>
assert_contains() { if grep -qF -- "$2" "$1"; then ok "$3"; else fail "$3 (esperado: $2)"; fi; }
assert_not_contains() { if grep -qF -- "$2" "$1"; then fail "$3 (encontrado: $2)"; else ok "$3"; fi; }
# Roda com as mocks na frente do PATH
with_mocks() { PATH="$TESTS/mocks:$PATH" "$@"; }
chmod +x "$TESTS/mocks/"* 2>/dev/null || true

section "1. Sintaxe dos scripts (sh -n, e dash -n se disponível)"
for f in "$ROOT"/skills/*/scripts/*.sh "$TESTS"/mocks/*; do
  if sh -n "$f" 2>"$WORK/err"; then
    if command -v dash >/dev/null 2>&1 && ! dash -n "$f" 2>>"$WORK/err"; then fail "dash: ${f#$ROOT/}"; else ok "${f#$ROOT/}"; fi
  else fail "sh: ${f#$ROOT/} ($(head -n1 "$WORK/err"))"; fi
done
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -s sh -S error "$ROOT"/skills/*/scripts/*.sh; then ok "shellcheck (nível error)"; else fail "shellcheck encontrou erros"; fi
else skip "shellcheck não instalado"; fi

section "2. Coerência do repositório"
if "$PY" "$TESTS/check_repo.py"; then ok "agentes, skills, referências, frontmatter, LF"; else fail "check_repo.py"; fi

section "3. Permissões (uma por agente + união)"
if "$PY" "$ROOT/permissoes/gerar.py" --check; then ok "arquivos gerados batem com permissoes/fonte.json"; else fail "rode: python3 permissoes/gerar.py"; fi
if "$PY" "$TESTS/check_permissions.py"; then ok "cada agente: permitido, negado, fora do escopo e isolamento entre skills"; else fail "check_permissions.py"; fi

section "4. Queries JMESPath"
"$PY" "$TESTS/check_jmespath.py"; rc=$?
if [ $rc -eq 0 ]; then ok "todas compilam"; elif [ $rc -eq 77 ]; then skip "jmespath ausente"; else fail "query inválida"; fi

section "5. Validador de relatório JSON"
if "$PY" "$TESTS/validate_report.py" "$TESTS/fixtures/relatorio-exemplo.json" >/dev/null; then ok "exemplo válido aceito"; else fail "exemplo válido rejeitado"; fi
sed 's/"alto": 1/"alto": 7/' "$TESTS/fixtures/relatorio-exemplo.json" > "$WORK/ruim.json"
if "$PY" "$TESTS/validate_report.py" "$WORK/ruim.json" >/dev/null; then fail "resumo inconsistente não detectado"; else ok "resumo inconsistente detectado"; fi

section "6. Coletores Azure com az simulado (2 subscriptions)"
for c in azure-cost-finops/scripts/cost_collector.sh azure-arch-audit/scripts/azure_collector.sh \
         cloud-security-audit/scripts/cloud_sec_collector.sh finops-framework/scripts/azure_governance_evidence.sh; do
  : > "$MOCK_LOG"
  out="$WORK/$(basename "$c").out"
  extra=""; case "$c" in cloud-security*) extra="$WORK/vazio" ;; esac
  # shellcheck disable=SC2086
  if with_mocks sh "$ROOT/skills/$c" sub-a,sub-b $extra > "$out" 2>&1; then ok "$c executa"; else fail "$c terminou com erro"; fi
  n=$(grep -c '### Subscription' "$out"); [ "$n" -eq 2 ] && ok "$c: percorre as 2 subscriptions" || fail "$c: percorreu $n subscriptions"
  if grep -Eq '(^| )(delete|create|update|set|deallocate|stop|start|restart|purge|regenerate|invoke)( |$)|keys list|list-keys|show-connection-string|appsettings|secret show|generate-sas' "$MOCK_LOG"; then
    fail "$c chamou verbo de escrita ou que devolve segredo"; grep -E 'delete|create|update|keys|secret show' "$MOCK_LOG" | head -3
  else ok "$c: só leitura"; fi
done
assert_contains "$WORK/cost_collector.sh.out" "ANTIGA (avaliar v5/v6)" "finops: marca VM de geração antiga"
assert_contains "$WORK/cost_collector.sh.out" "aks-teste	system" "finops: lista node pools"
assert_contains "$WORK/cost_collector.sh.out" "Inconclusivo" "finops: extensão ausente vira Inconclusivo"
assert_contains "$WORK/azure_collector.sh.out" "Com TODAS as tags obrigatórias: 1 (50.0%)" "arch: cobertura de tags ignora MC_*"
assert_contains "$WORK/cloud_sec_collector.sh.out" "sql-teste	AllowAll	0.0.0.0	255.255.255.255" "security: firewall SQL aberto"
if grep -q "Não avaliado" "$WORK/azure_governance_evidence.sh.out"; then ok "governance: falha de permissão vira Não avaliado"; else fail "governance: falha não sinalizada"; fi

section "7. Varredura de IaC: detecta e mascara segredos"
mkdir -p "$WORK/iac"
K="abcd""EFGHijklMNOPqrstUVWXyz0123456789abcd=="
PW="Super""Secreta123!"
G="ghp""_ABCDEFGHIJKLMNOPQRSTUVWXYZ123456"
cat > "$WORK/iac/main.tf" <<EOF
variable "db_password" { default = "$PW" }
locals { conn = "AccountName=x;AccountKey=$K;EndpointSuffix=core" }
token = "$G"
password = var.db_password
resource "azurerm_storage_account" "sa" { min_tls_version = "TLS1_0" }
EOF
touch "$WORK/iac/terraform.tfstate"
with_mocks sh "$ROOT/skills/cloud-security-audit/scripts/cloud_sec_collector.sh" sub-a "$WORK/iac" > "$WORK/iac.out" 2>&1
assert_contains "$WORK/iac.out" "main.tf:1:" "detecta senha em default de variável"
assert_contains "$WORK/iac.out" "main.tf:2:" "detecta AccountKey"
assert_contains "$WORK/iac.out" "main.tf:3:" "detecta token do GitHub"
assert_not_contains "$WORK/iac.out" "main.tf:4:" "não acusa referência var.x"
assert_contains "$WORK/iac.out" "terraform.tfstate" "lista .tfstate versionado"
assert_contains "$WORK/iac.out" "TLS1_0" "detecta TLS antigo"
assert_not_contains "$WORK/iac.out" "$K" "AccountKey mascarada"
assert_not_contains "$WORK/iac.out" "$G" "token mascarado"
assert_not_contains "$WORK/iac.out" "Secreta123" "senha mascarada"

section "8. k8s-cluster-audit com kubectl simulado"
: > "$MOCK_LOG"
with_mocks sh "$ROOT/skills/k8s-cluster-audit/scripts/audit_collector.sh" ctx-teste > "$WORK/k8s.out" 2>&1
assert_contains "$WORK/k8s.out" "api-1	espera=<none>,CrashLoopBackOff" "detecta CrashLoopBackOff (fase Running)"
assert_contains "$WORK/k8s.out" "sidecar-1	restarts(containers,init/sidecars)=0,9" "conta restarts de sidecar nativo"
assert_contains "$WORK/k8s.out" "init-bad	espera=<none>,CrashLoopBackOff" "detecta init container em CrashLoop"
assert_not_contains "$WORK/k8s.out" "ok-1	restarts" "não acusa pod saudável"
assert_contains "$WORK/k8s.out" "app	batch	(sem endpoints prontos)" "Service sem endpoint"
assert_not_contains "$WORK/k8s.out" "app	web	(sem endpoints" "sem falso positivo com vários EndpointSlices"
assert_contains "$WORK/k8s.out" "<- Ingress NGINX comunitário" "detecta Ingress NGINX comunitário"
assert_contains "$WORK/k8s.out" "<- NGINX do Application Routing" "detecta NGINX do Application Routing"
assert_contains "$WORK/k8s.out" "aad-pod-identity ENCONTRADO" "detecta aad-pod-identity"
assert_contains "$WORK/k8s.out" "acr.io/supp/web:latest" "detecta tag :latest"
assert_not_contains "$WORK/k8s.out" "registry:5000/foo/bar:2.0" "porta de registry não é confundida com tag"
assert_contains "$WORK/k8s.out" "legado" "namespace sem PSA"
if grep -Eq '(^| )(delete|apply|create|patch|edit|scale|exec|drain|cordon|label|annotate)( |$)|get secret.* -o' "$MOCK_LOG"; then fail "k8s: comando de escrita ou leitura de Secret"; else ok "k8s: só leitura"; fi

section "9. log-hunter: coleta e mascaramento"
mkdir -p "$WORK/logs/app 1"
J="eyJ""hbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.abc123def456"
cat > "$WORK/logs/app 1/api server.log" <<EOF
2026-11-03 10:00:05 WARN HikariPool-1 - Connection is not available, request timed out after 30000ms
2026-11-03 10:00:06 ERROR Login failed for user joao.silva@exemplo.gov.br cpf 123.456.789-09 password=Senha@2026
2026-11-03 10:00:07 ERROR Request failed: Authorization: Bearer $J
2026-11-03 10:00:08 ERROR conn: AccountName=x;AccountKey=$K;
2026-11-03 10:00:09 INFO errors=0 processed
container exited with code 137
{"level":"error","api_key":"sk_live_123456789","cnpj":"12.345.678/0001-90"}
EOF
sh "$ROOT/skills/log-hunter/scripts/log_collector.sh" "$WORK/logs" > "$WORK/logs.out" 2>&1
assert_contains "$WORK/logs.out" "api server.log" "aceita nome de arquivo com espaço"
assert_contains "$WORK/logs.out" "exited with code 137" "detecta exit code 137"
for segredo in "Senha@2026" "$J" "$K" "joao.silva@" "123.456.789-09" "12.345.678/0001-90" "sk_live_123456789"; do
  assert_not_contains "$WORK/logs.out" "$segredo" "mascarado: ${segredo:0:12}…"
done
assert_not_contains "$WORK/logs.out" ":5:2026-11-03 10:00:09 INFO errors=0" "errors=0 não conta como erro"
printf 'x Authorization: Bearer abc.def-ghi\n' | sh "$ROOT/skills/log-hunter/scripts/mask.sh" > "$WORK/b.out"
assert_not_contains "$WORK/b.out" "abc.def-ghi" "Bearer mascarado mesmo após 'Authorization:'"

echo ""
echo "== Resultado: $PASS ok, $FAIL falha(s), $SKIP pulado(s)"
[ "$FAIL" -eq 0 ]
