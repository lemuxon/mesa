"""lib/ altındaki tr('...') anahtarlarını kaynak sırasıyla çıkarır (dosyaya göre)."""
import glob
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")
ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")) + "/lib/"
CALL = re.compile(r"\btr\(\s*")


def literals(src, i):
    out, found = [], False
    while True:
        while i < len(src) and src[i] in " \t\r\n":
            i += 1
        if i >= len(src) or src[i] not in "'\"":
            break
        q = src[i]
        i += 1
        while src[i] != q:
            if src[i] == "\\":
                c = src[i + 1]
                out.append({"n": "\n", "t": "\t"}.get(c, c))
                i += 2
            else:
                if src[i] == "$":
                    return None
                out.append(src[i])
                i += 1
        i += 1
        found = True
    return "".join(out) if found else None


seen = {}
for path in sorted(glob.glob(ROOT + "**/*.dart", recursive=True)):
    name = os.path.basename(path)
    if "l10n" in path.replace("\\", "/") and name != "stored_labels.dart":
        continue
    src = open(path, encoding="utf-8").read()
    for m in CALL.finditer(src):
        k = literals(src, m.end())
        if k is not None and k not in seen:
            seen[k] = name
out = sys.argv[1]
json.dump([{"file": f, "tr": k} for k, f in seen.items()], open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=0)
print(len(seen), "anahtar")
