#!/usr/bin/env bash
# Установщик плагина ScreenRec для noctalia (ручной режим, альтернатива
# установке из git-репозитория через UI noctalia).
# Делает симлинки:
#   ~/.config/noctalia/plugins/screenrec -> <repo>/screenrec
#   ~/.local/bin/screenrec             -> <repo>/screenrec/screenrec
# и регистрирует плагин в plugins.json (sourceUrl = GitHub).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p ~/.config/noctalia/plugins
ln -sfn "$REPO/screenrec" ~/.config/noctalia/plugins/screenrec

mkdir -p ~/.local/bin
ln -sfn "$REPO/screenrec/screenrec" ~/.local/bin/screenrec

python3 - "$REPO" <<'PY'
import json, os, sys
p = os.path.expanduser("~/.config/noctalia/plugins.json")
d = json.load(open(p)) if os.path.exists(p) else {"states": {}}
d.setdefault("states", {})
if "screenrec" not in d["states"]:
    d["states"]["screenrec"] = {
        "enabled": True,
        "sourceUrl": "https://github.com/zumik3-del/screenrec",
    }
json.dump(d, open(p, "w"), indent=2)
print("plugin registered in plugins.json")
PY

echo "ScreenRec linked. Restart noctalia (or log out/in) to load the plugin."
echo "Widget: Mod+Shift+G start, Mod+Shift+X stop."
