"""Spec: docs/specs/executor/EXE-erros.md"""
from helpers import run


def test_EXE_030_erro_de_sintaxe():
    r = run("x = 1\nif x > 0\n    meditar()")
    assert r["ok"] is False
    assert r["erro"]["tipo"] == "SyntaxError"
    assert r["erro"]["linha"] == 2
    assert isinstance(r["erro"]["coluna"], int)
    assert r["acoes"] == [] and r["saidas"] == []


def test_EXE_031_erro_de_indentacao():
    r = run("if True:\nmeditar()")
    assert r["erro"]["tipo"] == "IndentationError"
    assert r["erro"]["linha"] == 2


def test_EXE_032_erro_de_execucao_com_linha():
    r = run("meditar()\nprint(x)")
    assert r["erro"] == {"tipo": "NameError", "mensagem": "name 'x' is not defined", "linha": 2, "coluna": None}


def test_EXE_033_execucao_parcial_preservada():
    r = run('print("antes")\nmeditar()\n1 / 0\nmeditar()')
    assert [a["tipo"] for a in r["acoes"]] == ["meditar"]
    assert r["saidas"] == [{"linha": 1, "texto": "antes"}]
    assert r["erro"]["tipo"] == "ZeroDivisionError"
    assert r["erro"]["linha"] == 3


def test_EXE_034_erro_dentro_de_peca_aponta_linha_do_jogador():
    r = run("\n\nlevitar(-1)")
    assert r["erro"]["tipo"] == "ValueError"
    assert r["erro"]["linha"] == 3


def test_EXE_035_erro_dentro_de_funcao_do_jogador():
    r = run("def f():\n    return 1 / 0\nf()")
    assert r["erro"]["linha"] == 2


def test_EXE_036_sem_vazamento_de_detalhes_internos():
    for codigo in ["levitar(-1)", "lancar(1, 2, 3)", "print(x)", "if"]:
        msg = run(codigo)["erro"]["mensagem"]
        assert "arcane_executor" not in msg
        assert ".py" not in msg


def test_EXE_037_systemexit_vira_erro_comum():
    # Desde o sandbox (Sprint 2) SystemExit nem existe no feitiço; o worker segue de pé.
    r = run("meditar()\nraise SystemExit")
    assert r["erro"]["tipo"] == "NameError"
    assert r["erro"]["linha"] == 2
    assert len(r["acoes"]) == 1
