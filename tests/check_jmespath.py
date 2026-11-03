#!/usr/bin/env python3
"""Compila todas as queries JMESPath (--query "...") dos scripts e .md do repositório.
Requer o pacote jmespath (pip install jmespath). Sem ele, sai com código 77 (pulado)."""
import re, sys, pathlib

try:
    import jmespath
except ImportError:
    print("  jmespath não instalado: verificação pulada (pip install jmespath)")
    sys.exit(77)

ROOT = pathlib.Path(__file__).resolve().parents[1]
arquivos = [p for p in ROOT.rglob("*") if p.suffix in (".sh", ".md") and ".git" not in p.parts and "tests" not in p.parts]
n = erros = 0
for f in arquivos:
    s = f.read_text(encoding="utf-8")
    for m in re.finditer(r'--query\s+"((?:[^"\\]|\\.)*)"', s):
        q = m.group(1).replace("\\`", "`").replace('\\"', '"').replace("\\$", "$")
        q = re.sub(r"\$[A-Z0-9_]+", "2026-01-01T00:00:00Z", q)
        if "<" in q and ">" in q and "{" not in q and "[" not in q:
            continue  # placeholder de documentação
        n += 1
        try:
            jmespath.compile(q)
        except Exception as e:  # noqa: BLE001
            erros += 1
            print(f"  ERRO {f.relative_to(ROOT)}: {q[:90]}...\n     -> {e}")
print(f"  {n} queries compiladas, {erros} com erro")
sys.exit(1 if erros else 0)
