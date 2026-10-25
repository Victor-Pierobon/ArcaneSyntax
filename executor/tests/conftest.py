import sys
from pathlib import Path

# Permite rodar `pytest` de dentro de executor/ sem instalar o pacote.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
