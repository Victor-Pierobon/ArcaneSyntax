"""Ponto de entrada do worker. Rodar com: python -I -S -u run_worker.py

Com -I o Python não põe a pasta do script no sys.path, então ela é adicionada aqui.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from arcane_executor.worker import main  # noqa: E402

main()
