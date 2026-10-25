"""Spec: docs/specs/executor/EXE-limites.md (EXE-057 fica em test_worker.py, com processo real)"""
import time

from arcane_executor.pieces import LimiteExcedido, ManaEsgotada, TempoEsgotado
from helpers import acoes, run


def test_EXE_050_loop_infinito_esgota_a_mana():
    inicio = time.perf_counter()
    r = run("while True:\n    pass", mago={"vida": 10, "mana": 5, "mana_max": 20})
    assert r["erro"]["tipo"] == "ManaEsgotada"
    assert r["erro"]["linha"] == 2
    assert time.perf_counter() - inicio < 1


def test_EXE_051_limite_de_tempo():
    inicio = time.perf_counter()
    r = run(
        "while True:\n    pass",
        mago={"vida": 10, "mana": 1000000, "mana_max": 1000000},
        regras={"limite_tempo_ms": 200},
    )
    assert r["erro"]["tipo"] == "TempoEsgotado"
    assert time.perf_counter() - inicio < 1


def test_EXE_052_laco_sem_instrucoes_simples_tambem_para():
    r = run("while True:\n    if False:\n        pass", regras={"limite_tempo_ms": 200})
    assert r["erro"]["tipo"] == "TempoEsgotado"


def test_EXE_053_limites_nao_podem_ser_capturados():
    codigo = "try:\n    while True:\n        pass\nexcept Exception:\n    meditar()"
    r = run(codigo)
    assert r["erro"]["tipo"] == "ManaEsgotada"
    assert acoes(r, "meditar") == []


def test_EXE_053_limites_nao_herdam_de_exception():
    for limite in (ManaEsgotada, TempoEsgotado, LimiteExcedido):
        assert not issubclass(limite, Exception)


def test_EXE_053_finally_nao_reabre_o_feitico():
    codigo = "try:\n    while True:\n        pass\nfinally:\n    while True:\n        pass"
    r = run(codigo, regras={"limite_tempo_ms": 300})
    assert r["erro"]["tipo"] == "ManaEsgotada"


def test_EXE_054_limite_de_acoes():
    r = run("for i in range(2000):\n    meditar()", mago={"vida": 10, "mana": 1000, "mana_max": 1000})
    assert r["erro"]["tipo"] == "LimiteExcedido"
    assert len(r["acoes"]) == 1000


def test_EXE_055_limite_de_saidas():
    r = run("for i in range(300):\n    print(i)", mago={"vida": 10, "mana": 1000, "mana_max": 1000})
    assert r["erro"]["tipo"] == "LimiteExcedido"
    assert len(r["saidas"]) == 200


def test_EXE_056_texto_longo_e_cortado():
    texto = run('print("a" * 600)')["saidas"][0]["texto"]
    assert len(texto) == 500
    assert texto.endswith("…")
