"""Spec: docs/specs/executor/EXE-sandbox.md"""
import pytest

from helpers import run

ALVO = {"id": "elemental_1", "elemento": "fogo", "distancia": 2}


def tipo_erro(codigo, **kwargs):
    r = run(codigo, **kwargs)
    return r["erro"]["tipo"] if r["erro"] else None


def test_EXE_060_imports_permitidos():
    assert run("import math\nprint(math.floor(2.7))")["saidas"][0]["texto"] == "2"
    assert run("from random import randint\nprint(randint(1, 1))")["saidas"][0]["texto"] == "1"


@pytest.mark.parametrize(
    "codigo",
    ["import os", "import sys", "from os import path", "import os.path", "from . import x", "import math, os"],
)
def test_EXE_061_imports_proibidos(codigo):
    r = run("x = 1\n" + codigo)
    assert r["erro"]["tipo"] == "FeiticoProibido"
    assert r["erro"]["linha"] == 2
    assert "math" in r["erro"]["mensagem"] and "random" in r["erro"]["mensagem"]


def test_EXE_062_nada_roda_quando_ha_violacao():
    r = run("meditar()\nimport os")
    assert r["acoes"] == []
    assert r["erro"]["linha"] == 2
    assert r["custo_mana"] == 0


@pytest.mark.parametrize("nome", ["open", "exec", "eval", "compile", "input", "globals", "vars", "breakpoint"])
def test_EXE_063_builtins_perigosos_nao_existem(nome):
    assert tipo_erro(f"{nome}('x')") == "NameError"


@pytest.mark.parametrize("codigo", ["__import__('os')", "print(__builtins__)", "x = __name__"])
def test_EXE_064_nomes_internos(codigo):
    assert tipo_erro(codigo) == "FeiticoProibido"


@pytest.mark.parametrize("codigo", ["x = ().__class__", "x = alvo._id", "x = print.__self__", "x = f'{alvo.__class__}'"])
def test_EXE_065_atributos_internos(codigo):
    r = run("y = 1\n" + codigo, alvo=ALVO)
    assert r["erro"]["tipo"] == "FeiticoProibido"
    assert r["erro"]["linha"] == 2
    assert isinstance(r["erro"]["coluna"], int)


def test_EXE_066_getattr_recusa_nomes_internos():
    assert tipo_erro("getattr(alvo, '__class__')", alvo=ALVO) == "FeiticoProibido"
    assert tipo_erro("setattr(alvo, '_id', 1)", alvo=ALVO) == "FeiticoProibido"
    assert tipo_erro("hasattr(alvo, '_id')", alvo=ALVO) == "FeiticoProibido"
    assert run("print(getattr(alvo, 'elemento'))", alvo=ALVO)["saidas"][0]["texto"] == "fogo"


@pytest.mark.parametrize(
    "codigo",
    ["try:\n    x = 1\nexcept:\n    pass", "try:\n    x = 1\nexcept BaseException:\n    pass"],
)
def test_EXE_067_except_sem_tipo_e_baseexception(codigo):
    r = run(codigo)
    assert r["erro"]["tipo"] == "FeiticoProibido"
    assert "except Exception" in r["erro"]["mensagem"]


CODIGO_DO_JOGADOR = """
def dobro(n):
    return n * 2

triplo = lambda n: n * 3

class Frasco:
    def __init__(self, conteudo):
        self.conteudo = conteudo

for _ in range(2):
    pass

try:
    int("abc")
except ValueError:
    print("erro tratado")

print(dobro(2), triplo(2), Frasco("mana").conteudo, sorted([3, 1, 2]), len("abc"))
"""


def test_EXE_068_o_que_o_jogador_escreve_continua_funcionando():
    r = run(CODIGO_DO_JOGADOR)
    assert r["ok"] is True, r["erro"]
    assert [s["texto"] for s in r["saidas"]] == ["erro tratado", "4 6 mana [1, 2, 3] 3"]
