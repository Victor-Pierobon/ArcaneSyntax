#!/usr/bin/env bash
# Roda as duas suítes: pytest (executor) e GdUnit4 (jogo).
# Uso: GODOT_BIN=/caminho/godot scripts/test.sh
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"

echo "== pytest (executor) =="
(cd "$root/executor" && python -m pytest -q)

echo "== GdUnit4 (game) =="
: "${GODOT_BIN:?Defina GODOT_BIN com o caminho do executável do Godot 4.7}"
cd "$root/game"
"$GODOT_BIN" --headless --path . --import > /dev/null 2>&1 || true
bash addons/gdUnit4/runtest.sh --headless -a res://tests --ignoreHeadlessMode
