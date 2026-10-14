"""lib/l10n/<dil>.dart'ı koddaki güncel anahtarlara göre yeniden yazar.

Kullanım: python merge_map.py <dil> [ek.txt]
ek.txt satırları: Türkçe anahtar<TAB>çeviri (\\n satır sonu). Var olan çeviriyi
değiştirir ya da yenisini ekler. Kodda artık olmayan anahtarlar atılır; eksik
kalan anahtar ya da uyuşmayan yer tutucu varsa hata verir.
"""
import json
import re
import subprocess
import sys

sys.stdout.reconfigure(encoding="utf-8")
import os
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.normpath(os.path.join(HERE, "..", "..", "lib", "l10n")) + "/"
lang = sys.argv[1]
subprocess.run([sys.executable, "-I", HERE + "/extract_keys.py", os.path.join(tempfile.gettempdir(), "mm_keys_now.json")], check=True, capture_output=True)
keys = [x["tr"] for x in json.load(open(os.path.join(tempfile.gettempdir(), "mm_keys_now.json"), encoding="utf-8"))]


def unlit(s):
    return re.sub(r"\\(.)", lambda m: {"n": "\n", "t": "\t"}.get(m.group(1), m.group(1)), s)


src = open(LIB + lang + ".dart", encoding="utf-8").read()
entry = re.compile(r"'((?:[^'\\]|\\.)*)'\s*:\s*'((?:[^'\\]|\\.)*)'\s*,")
values = {unlit(k): unlit(v) for k, v in entry.findall(src)}
if len(sys.argv) > 2:
    for n, line in enumerate(open(sys.argv[2], encoding="utf-8").read().splitlines(), 1):
        if not line.strip() or line.startswith("#"):
            continue
        k, sep, v = line.partition("\t")
        assert sep, f"{sys.argv[2]}:{n}: sekme yok"
        values[k.replace("\\n", "\n")] = v.replace("\\n", "\n")
missing = [k for k in keys if k not in values]
assert not missing, f"{lang}: eksik {len(missing)}: {missing[:15]}"


def placeholders(s):
    out, depth, start = set(), 0, -1
    for j, c in enumerate(s):
        if c == "{":
            if depth == 0:
                start = j + 1
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                out.add(s[start:j].split(",")[0].strip())
    return out


bad = [k for k in keys if placeholders(k) != placeholders(values[k])]
assert not bad, f"{lang}: yer tutucu uyuşmuyor: {[(k, values[k]) for k in bad[:5]]}"


def lit(s):
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$").replace("\n", "\\n") + "'"


lines = [
    "// Türkçe metin → çeviri. Anahtarlar test/l10n_test.dart ile denetlenir",
    "// (yeni metin: tr() ekleyin, buraya ve diğer dillere çevirisini yazın).",
    "const " + lang + " = <String, String>{",
]
for k in keys:
    lines.append(f"  {lit(k)}:\n      {lit(values[k])},")
lines.append("};")
open(LIB + lang + ".dart", "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")
dropped = len(values) - len(keys)
print(f"{lang}: {len(keys)} çeviri, {dropped} kullanılmayan atıldı")
