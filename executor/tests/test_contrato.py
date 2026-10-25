"""Spec: docs/specs/executor/EXE-protocolo.md (EXE-009), com as fixtures compartilhadas com o Godot."""
import json
from pathlib import Path

import pytest

from arcane_executor.protocol import handle_request

CONTRACT_DIR = Path(__file__).resolve().parents[2] / "tests" / "contract"
FIXTURES = sorted(CONTRACT_DIR.glob("*.json"))


def test_existem_fixtures():
    assert len(FIXTURES) >= 5


@pytest.mark.parametrize("path", FIXTURES, ids=lambda p: p.stem)
def test_EXE_009_executor_cumpre_o_contrato(path):
    fixture = json.loads(path.read_text(encoding="utf-8"))
    assert handle_request(fixture["requisicao"]) == fixture["resposta"]
