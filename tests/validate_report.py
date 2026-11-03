#!/usr/bin/env python3
"""Valida relatórios JSON contra o padrão meus-agentes/relatorio@1 (sem dependências).
Uso: python3 tests/validate_report.py reports/*.json"""
import json, re, sys

SEV = {"Crítico": "critico", "Alto": "alto", "Médio": "medio", "Baixo": "baixo", "Info": "info"}
CONF = {"Confirmado", "Potencial", "Inconclusivo"}
AGENTES = {"finops-azure", "finops-maturidade", "azure-architect", "cloud-security-analyst", "k8s-auditor", "log-hunter"}
TIPOS = {"finops", "finops-maturidade", "arch", "security", "k8s", "logs"}
OBRIG = ["schema", "agente", "tipo", "escopo", "data", "resumo", "achados", "fora_do_escopo", "limitacoes", "comparacao"]
SEGREDO = re.compile(r"(AccountKey=[A-Za-z0-9+/=]{8,}|-----BEGIN [A-Z ]*PRIVATE KEY|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}|ghp_[A-Za-z0-9]{20,}|[?&]sig=[A-Za-z0-9%]{20,})")

def validar(caminho):
    erros = []
    try:
        texto = open(caminho, encoding="utf-8").read()
        d = json.loads(texto)
    except Exception as e:  # noqa: BLE001
        return [f"JSON inválido: {e}"]
    for k in OBRIG:
        if k not in d:
            erros.append(f"campo obrigatório ausente: {k}")
    if erros:
        return erros
    if d["schema"] != "meus-agentes/relatorio@1":
        erros.append("schema deve ser 'meus-agentes/relatorio@1'")
    if d["agente"] not in AGENTES:
        erros.append(f"agente desconhecido: {d['agente']}")
    if d["tipo"] not in TIPOS:
        erros.append(f"tipo desconhecido: {d['tipo']}")
    if not re.fullmatch(r"[a-z0-9][a-z0-9._-]*", str(d["escopo"])):
        erros.append("escopo deve ser minúsculo, sem espaços")
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", str(d["data"])):
        erros.append("data deve ser AAAA-MM-DD")
    contagem = {v: 0 for v in SEV.values()}
    fps = set()
    for i, a in enumerate(d["achados"]):
        for k in ("id", "fingerprint", "titulo", "severidade", "confianca", "evidencia", "recomendacao"):
            if k not in a:
                erros.append(f"achado {i}: campo ausente {k}")
        if a.get("severidade") not in SEV:
            erros.append(f"achado {i}: severidade inválida {a.get('severidade')!r}")
        else:
            contagem[SEV[a["severidade"]]] += 1
        if a.get("confianca") not in CONF:
            erros.append(f"achado {i}: confiança inválida {a.get('confianca')!r}")
        fp = a.get("fingerprint", "")
        if "|" not in fp or fp != fp.lower():
            erros.append(f"achado {i}: fingerprint deve ser '<categoria>|<recurso>' em minúsculas")
        if fp in fps:
            erros.append(f"achado {i}: fingerprint duplicado {fp}")
        fps.add(fp)
    for k, v in contagem.items():
        if d["resumo"].get(k) != v:
            erros.append(f"resumo.{k}={d['resumo'].get(k)} não bate com os achados ({v})")
    for k in ("relatorio_anterior", "novos", "resolvidos", "persistentes"):
        if k not in d["comparacao"]:
            erros.append(f"comparacao.{k} ausente")
    if SEGREDO.search(texto):
        erros.append("possível segredo não mascarado no JSON")
    return erros

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__); sys.exit(2)
    falhas = 0
    for c in sys.argv[1:]:
        e = validar(c)
        if e:
            falhas += 1
            print(f"  FALHA {c}"); [print(f"    - {x}") for x in e]
        else:
            print(f"  ok {c}")
    sys.exit(1 if falhas else 0)
