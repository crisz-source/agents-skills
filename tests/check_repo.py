#!/usr/bin/env python3
"""Coerência do repositório: agentes x skills, padrão de relatório idêntico, allowed-tools
restritos, referências existentes, frontmatter e quebras de linha."""
import re, sys, pathlib, json

ROOT = pathlib.Path(__file__).resolve().parents[1]
erros = []

def fm(path):
    s = path.read_text(encoding="utf-8")
    m = re.match(r"---\n(.*?)\n---\n", s, re.S)
    if not m:
        erros.append(f"{path.relative_to(ROOT)}: sem frontmatter"); return {}, s
    d = {}
    for linha in m.group(1).splitlines():
        if ":" in linha and not linha.startswith(" "):
            k, v = linha.split(":", 1); d[k.strip()] = v.strip()
    return d, s

skills = {p.parent.name: p for p in (ROOT / "skills").glob("*/SKILL.md")}
donos = {}
for ag in sorted((ROOT / "agents").glob("*.md")):
    d, s = fm(ag)
    for k in ("name", "description", "tools", "skills"):
        if not d.get(k):
            erros.append(f"agents/{ag.name}: campo '{k}' ausente")
    if d.get("name") != ag.stem:
        erros.append(f"agents/{ag.name}: name '{d.get('name')}' difere do arquivo")
    if "Agent" not in d.get("disallowedTools", "") or "Skill" not in d.get("disallowedTools", ""):
        erros.append(f"agents/{ag.name}: disallowedTools deve conter Skill e Agent (isolamento)")
    sk = d.get("skills", "")
    if sk not in skills:
        erros.append(f"agents/{ag.name}: skill '{sk}' não existe")
    donos.setdefault(sk, []).append(ag.stem)
    if "report_standard.md" not in s:
        erros.append(f"agents/{ag.name}: seção Entrega não cita report_standard.md")

padrao = (ROOT / "schemas" / "report_standard.md").read_text(encoding="utf-8")
for nome, p in skills.items():
    d, s = fm(p)
    if d.get("name") != nome:
        erros.append(f"skills/{nome}: name '{d.get('name')}' difere da pasta")
    if len(donos.get(nome, [])) != 1:
        erros.append(f"skills/{nome}: deve ter exatamente 1 agente dono (tem {donos.get(nome, [])})")
    desc = d.get("description", "")
    if len(desc) < 80:
        erros.append(f"skills/{nome}: description curta demais")
    if not re.search(r"\bn[ãa]o\b", desc, re.I):
        erros.append(f"skills/{nome}: description deve dizer quando NÃO usar")
    tools = d.get("allowed-tools", "")
    for amplo in ("Bash(az *)", "Bash(kubectl *)", "Bash(aws *)", "Bash(gcloud *)"):
        if amplo in tools.split(" ") or amplo + " " in tools + " ":
            erros.append(f"skills/{nome}: allowed-tools amplo demais: {amplo}")
    copia = p.parent / "references" / "report_standard.md"
    if not copia.exists() or copia.read_text(encoding="utf-8") != padrao:
        erros.append(f"skills/{nome}: references/report_standard.md ausente ou diferente de schemas/")
    for ref in set(re.findall(r"references/([A-Za-z0-9_]+\.md)", s)):
        if not (p.parent / "references" / ref).exists():
            erros.append(f"skills/{nome}: referência inexistente references/{ref}")
    for scr in set(re.findall(r"scripts/([A-Za-z0-9_]+\.sh)", s)):
        if not (p.parent / "scripts" / scr).exists():
            erros.append(f"skills/{nome}: script inexistente scripts/{scr}")

for f in ROOT.rglob("*"):
    if f.is_file() and ".git" not in f.parts and f.suffix in (".sh", ".md", ".json", ".py", ".yml"):
        if b"\r" in f.read_bytes():
            erros.append(f"{f.relative_to(ROOT)}: CRLF (use LF)")

for j in (ROOT / "permissoes.json", ROOT / ".claude-plugin" / "plugin.json", ROOT / "schemas" / "relatorio.schema.json"):
    try:
        json.loads(j.read_text(encoding="utf-8"))
    except Exception as e:  # noqa: BLE001
        erros.append(f"{j.relative_to(ROOT)}: JSON inválido ({e})")

for e in erros:
    print(f"  FALHA: {e}")
print(f"  {len(list((ROOT / 'agents').glob('*.md')))} agentes, {len(skills)} skills verificados, {len(erros)} problema(s)")
sys.exit(1 if erros else 0)
