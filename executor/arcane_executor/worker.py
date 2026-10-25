"""Worker persistente: uma requisição JSON por linha no stdin, uma resposta por linha no stdout."""

import sys

from .protocol import handle_line


def main():
    sys.stdin.reconfigure(encoding="utf-8")
    saida = sys.stdout
    for line in sys.stdin:
        if not line.strip():
            continue
        saida.write(handle_line(line) + "\n")
        saida.flush()


if __name__ == "__main__":
    main()
