"""Spec: docs/specs/executor/EXE-protocolo.md"""
import json

from arcane_executor.protocol import handle_line, handle_request
from helpers import requisicao, run


def test_EXE_001_resposta_de_sucesso():
    r = run("meditar()", id=42)
    assert r["versao"] == 1
    assert r["id"] == 42
    assert r["ok"] is True
    assert r["erro"] is None
    assert isinstance(r["acoes"], list)
    assert isinstance(r["saidas"], list)


def test_EXE_002_estado_final_do_mago():
    r = run("meditar()", mago={"vida": 9, "mana": 1, "mana_max": 20}, regras={"ganho_meditar": 4})
    assert r["mago"] == {"vida": 9, "mana": 4.9, "mana_max": 20}


def test_EXE_003_regras_padrao():
    r = run("meditar()\nabsorver_mana()", mago={"vida": 10, "mana": 0, "mana_max": 20})
    assert r["mago"]["mana"] == 5.8


def test_EXE_003_regra_parcial_usa_padrao_no_resto():
    r = run(
        "meditar()\nabsorver_mana()",
        mago={"vida": 10, "mana": 0, "mana_max": 20},
        regras={"ganho_meditar": 2},
    )
    assert r["mago"]["mana"] == 2.8


def _assert_invalida(r, id=None):
    assert r["ok"] is False
    assert r["erro"]["tipo"] == "RequisicaoInvalida"
    assert r["erro"]["linha"] is None
    assert r["id"] == id
    assert r["acoes"] == [] and r["saidas"] == []
    assert r["mago"] is None
    assert r["custo_mana"] == 0


def test_EXE_004_sem_codigo():
    req = requisicao("x")
    del req["codigo"]
    _assert_invalida(handle_request(req), id=1)


def test_EXE_004_sem_mundo():
    req = requisicao("x")
    del req["mundo"]
    _assert_invalida(handle_request(req), id=1)


def test_EXE_004_versao_errada():
    req = requisicao("x")
    req["versao"] = 2
    _assert_invalida(handle_request(req), id=1)


def test_EXE_004_tipos_errados_no_mago():
    req = requisicao("x", mago={"vida": 10, "mana": "5", "mana_max": 20})
    _assert_invalida(handle_request(req), id=1)


def test_EXE_004_alvo_incompleto():
    req = requisicao("x", alvo={"id": "a"})
    _assert_invalida(handle_request(req), id=1)


def test_EXE_004_linha_que_nao_e_json():
    _assert_invalida(json.loads(handle_line("isto não é json")), id=None)


def test_EXE_004_json_que_nao_e_objeto():
    _assert_invalida(json.loads(handle_line("[1, 2]")), id=None)


def test_handle_line_devolve_uma_unica_linha():
    out = handle_line(json.dumps(requisicao("print('a\\nb')")))
    assert "\n" not in out
    assert json.loads(out)["saidas"][0]["texto"] == "a\nb"
