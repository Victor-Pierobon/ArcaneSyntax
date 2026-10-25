"""Spec: docs/specs/executor/EXE-custo.md"""
from helpers import acoes, run


def mago(mana, mana_max=20):
    return {"vida": 10, "mana": mana, "mana_max": mana_max}


def test_EXE_040_instrucao_custa_um_decimo():
    r = run("x = 1\ny = 2", mago=mago(5))
    assert r["custo_mana"] == 0.4
    assert r["mago"]["mana"] == 4.6


def test_EXE_040_mana_inteira_sai_como_inteiro():
    r = run("meditar()", mago=mago(0.2), regras={"ganho_meditar": 5})
    assert r["mago"]["mana"] == 5
    assert isinstance(r["mago"]["mana"], int)


def test_EXE_041_estruturas_nao_custam():
    assert run("if True:\n    x = 1")["custo_mana"] == 0.2
    assert run("def f():\n    x = 1")["custo_mana"] == 0


def test_EXE_042_laco_paga_cada_volta():
    assert run("for i in range(3):\n    x = i")["custo_mana"] == 0.4


def test_EXE_042_saltos_pagam_antes():
    assert run("def f():\n    return 1\nf()")["custo_mana"] == 0.4
    assert run("for i in range(3):\n    continue")["custo_mana"] == 0.4
    assert run("while True:\n    break")["custo_mana"] == 0.2


def test_EXE_043_custo_base_das_pecas():
    codigo = "lancar(fogo, projetil)\nmover(1)\nlevitar(2)"
    assert run(codigo, mago=mago(20))["custo_mana"] == 6.6
    assert run(codigo, mago=mago(20), regras={"custo_lancar": 1})["custo_mana"] == 4.6


def test_EXE_043_argumento_invalido_nao_cobra_a_peca():
    r = run('lancar("agua", projetil)', mago=mago(5))
    assert r["erro"]["tipo"] == "ValueError"
    assert r["custo_mana"] == 0


def test_EXE_044_meditar_com_mana_zero():
    r = run("meditar()", mago=mago(0))
    assert r["ok"] is True
    assert r["mago"]["mana"] == 4.8


def test_EXE_044_meditar_dentro_de_funcao_com_mana_zero():
    r = run("def recarregar():\n    meditar()\nrecarregar()", mago=mago(0))
    assert r["ok"] is True, r["erro"]
    assert r["mago"]["mana"] == 4.6


def test_EXE_045_loop_de_absorver_termina_cheio():
    r = run(
        "while mana < mana_max:\n    absorver_mana()",
        mago=mago(0, 5),
        regras={"ganho_absorver": 1},
    )
    assert r["ok"] is True, r["erro"]
    assert len(acoes(r, "absorver_mana")) == 6
    assert r["mago"]["mana"] == 5


def test_EXE_046_mana_esgotada():
    r = run("x = 1\nx = 2\nx = 3\nx = 4", mago=mago(0.6))
    assert r["erro"]["tipo"] == "ManaEsgotada"
    assert r["erro"]["linha"] == 4
    assert r["custo_mana"] == 0.6
    assert r["mago"]["mana"] == 0


def test_EXE_047_peca_sem_mana_nao_age():
    r = run("mover(1)\nlancar(fogo, projetil)", mago=mago(2))
    assert [a["tipo"] for a in r["acoes"]] == ["mover"]
    assert r["erro"]["tipo"] == "ManaEsgotada"
    assert r["erro"]["linha"] == 2


def test_EXE_048_sentidos_acompanham_o_gasto():
    assert run("x = 1\nprint(mana)", mago=mago(5))["saidas"][0]["texto"] == "4.8"


def test_EXE_049_checar_antes_economiza():
    cheio = mago(10, 10)
    assert run("if mana < mana_max:\n    absorver_mana()", mago=cheio)["custo_mana"] == 0
    assert run("absorver_mana()", mago=cheio)["custo_mana"] == 0.2


def test_custo_e_deterministico():
    codigo = "for i in range(50):\n    if i % 3 == 0:\n        mover(1)"
    custos = {run(codigo, mago=mago(100, 100))["custo_mana"] for _ in range(5)}
    assert custos == {run(codigo, mago=mago(100, 100))["custo_mana"]}
    assert len(custos) == 1


def test_EXE_090_primeira_passagem_custa_mais():
    assert run("x = 1\nx = 2\nx = 3", mago=mago(5))["custo_mana"] == 0.6
    assert run("for i in range(3):\n    x = i", mago=mago(5))["custo_mana"] == 0.4


def test_EXE_091_loop_sai_mais_barato():
    regras = {"custo_bloco": 0.5}
    soltas = "\n".join(["construir_bloco()"] * 12)
    assert run(soltas, mago=mago(20), regras=regras)["custo_mana"] == 8.4
    loop = "for i in range(12):\n    construir_bloco()"
    assert run(loop, mago=mago(20), regras=regras)["custo_mana"] == 7.3


def test_EXE_092_inscricao_por_linha():
    assert run("a = 1; b = 2", mago=mago(5))["custo_mana"] == 0.3


def test_EXE_093_linha_que_nao_roda_nao_paga():
    assert run("if mana < mana_max:\n    absorver_mana()", mago=mago(10, 10))["custo_mana"] == 0


def test_EXE_094_inscricao_configuravel():
    assert run("x = 1\ny = 2", mago=mago(5), regras={"custo_inscricao": 0})["custo_mana"] == 0.2
