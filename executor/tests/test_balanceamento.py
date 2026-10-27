"""Spec: docs/specs/balanceamento/BAL-valores.md (regra 4, BAL-005)."""
import json
from pathlib import Path

from arcane_executor.pieces import REGRAS_PADRAO

BALANCEAMENTO = Path(__file__).resolve().parents[2] / "game" / "content" / "balanceamento.json"


def test_BAL_005_executor_e_arquivo_concordam():
    arquivo = json.loads(BALANCEAMENTO.read_text(encoding="utf-8"))
    assert arquivo["executor"] == REGRAS_PADRAO


def test_MAG_081_feixe_no_balanceamento():
    arquivo = json.loads(BALANCEAMENTO.read_text(encoding="utf-8"))
    assert arquivo["executor"]["custo_feixe"] == 8
    assert arquivo["dano"]["feixe"] == 6
    assert arquivo["executor"]["custo_lancar"] == 4
    assert arquivo["executor"]["custo_faisca"] == 1.5
