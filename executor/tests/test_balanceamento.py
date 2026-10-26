"""Spec: docs/specs/balanceamento/BAL-valores.md (regra 4, BAL-005)."""
import json
from pathlib import Path

from arcane_executor.pieces import REGRAS_PADRAO

BALANCEAMENTO = Path(__file__).resolve().parents[2] / "game" / "content" / "balanceamento.json"


def test_BAL_005_executor_e_arquivo_concordam():
    arquivo = json.loads(BALANCEAMENTO.read_text(encoding="utf-8"))
    assert arquivo["executor"] == REGRAS_PADRAO
