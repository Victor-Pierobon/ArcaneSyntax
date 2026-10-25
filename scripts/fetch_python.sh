#!/usr/bin/env bash
# Baixa o Python standalone usado pelo executor (ADR-002) para runtime/python/.
# Uso: scripts/fetch_python.sh
set -euo pipefail

PY_VERSION="3.14.9"
PBS_RELEASE="20261021"

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) triple="x86_64-pc-windows-msvc" ;;
  Linux*)               triple="x86_64-unknown-linux-gnu" ;;
  Darwin*)              triple="aarch64-apple-darwin" ;;
  *) echo "Sistema não suportado: $(uname -s)" >&2; exit 1 ;;
esac

root="$(cd "$(dirname "$0")/.." && pwd)"
dest="$root/runtime"
file="cpython-${PY_VERSION}+${PBS_RELEASE}-${triple}-install_only_stripped.tar.gz"
url="https://github.com/astral-sh/python-build-standalone/releases/download/${PBS_RELEASE}/${file//+/%2B}"

rm -rf "$dest/python"
mkdir -p "$dest"
echo "Baixando $file"
curl -fsSL "$url" | tar xz -C "$dest"
echo "Python instalado em $dest/python"
