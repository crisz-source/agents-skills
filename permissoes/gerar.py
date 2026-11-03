#!/usr/bin/env python3
"""Gera as permissões por agente a partir de permissoes/fonte.json.

  python3 permissoes/gerar.py          # (re)gera permissoes/<agente>.json e ../permissoes.json
  python3 permissoes/gerar.py --check  # só verifica se os arquivos gerados estão atualizados

Cada agente recebe:
  allow = comum + grupos do agente + rodar SÓ os scripts da própria skill + ler a própria skill
  deny  = comum + grupos negados do agente + rodar/ler os scripts e arquivos das OUTRAS skills
O permissoes.json da raiz é a união (compatibilidade com quem ainda usa um arquivo só).
"""
import json, sys, pathlib

AQUI = pathlib.Path(__file__).resolve().parent
RAIZ = AQUI.parent
F = json.loads((AQUI / "fonte.json").read_text(encoding="utf-8"))
G = F["grupos"]
BASE = F["raiz_plugin"].rstrip("/")            # ex.: C:/meus-agentes
BASE_BS = BASE.replace("/", "\\")             # C:\meus-agentes
# Caminho absoluto no formato das regras do Claude Code: //c/meus-agentes (Windows) ou //home/... (Linux)
if len(BASE) > 1 and BASE[1] == ":":
    BASE_ABS = ["//" + BASE[0].lower() + BASE[2:], "//" + BASE]
else:
    BASE_ABS = ["/" + BASE if BASE.startswith("/") else "//" + BASE]
SKILLS = sorted({a["skill"] for a in F["agentes"].values()})

def uniq(xs):
    vistos, out = set(), []
    for x in xs:
        if x not in vistos:
            vistos.add(x); out.append(x)
    return out

def propria(skill):
    allow = [f"Bash(sh {BASE}/skills/{skill}/scripts/*)", f"Bash(sh {BASE_BS}\\skills\\{skill}\\scripts\\*)"]
    allow += [f"Read({b}/skills/{skill}/**)" for b in BASE_ABS]
    return allow

def de_outras(skill):
    deny = []
    for outra in SKILLS:
        if outra == skill:
            continue
        deny += [f"Bash(*skills/{outra}/*)", f"Bash(*skills\\{outra}\\*)"]
        deny += [f"Read({b}/skills/{outra}/**)" for b in BASE_ABS] + [f"Read(**/skills/{outra}/**)"]
    return deny

def gerar_agente(nome, a):
    allow = list(F["comum"]["allow"])
    for g in a.get("allow", []):
        allow += G[g]
    allow += a.get("allow_extra", []) + propria(a["skill"])
    deny = list(F["comum"]["deny"])
    for g in a.get("deny", []):
        deny += G[g]
    deny += de_outras(a["skill"])
    return {"permissions": {"allow": uniq(allow), "deny": uniq(deny)}}

def gerar_uniao():
    allow = list(F["comum"]["allow"])
    for a in F["agentes"].values():
        for g in a.get("allow", []):
            allow += G[g]
        allow += a.get("allow_extra", [])
    allow += [f"Bash(sh {BASE}/skills/*/scripts/*)"]
    return {"permissions": {"allow": uniq(allow), "deny": uniq(list(F["comum"]["deny"]))}}


def texto(d):
    return json.dumps(d, ensure_ascii=False, indent=2) + "\n"

saidas = {AQUI / f"{n}.json": texto(gerar_agente(n, a)) for n, a in F["agentes"].items()}
saidas[RAIZ / "permissoes.json"] = texto(gerar_uniao())

agentes_md = {p.stem for p in (RAIZ / "agents").glob("*.md")}
faltando = agentes_md - set(F["agentes"])
if faltando:
    print(f"ERRO: agentes sem entrada em fonte.json: {sorted(faltando)}"); sys.exit(1)

if "--check" in sys.argv:
    desatualizados = [str(p.relative_to(RAIZ)) for p, t in saidas.items()
                      if not p.exists() or p.read_text(encoding="utf-8") != t]
    if desatualizados:
        print("Desatualizados (rode: python3 permissoes/gerar.py):", ", ".join(desatualizados)); sys.exit(1)
    print(f"  {len(saidas)} arquivos de permissão atualizados"); sys.exit(0)

for p, t in saidas.items():
    p.write_text(t, encoding="utf-8")
    print(f"gerado {p.relative_to(RAIZ)}")
