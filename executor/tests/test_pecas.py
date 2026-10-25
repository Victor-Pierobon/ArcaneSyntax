"""Spec: docs/specs/executor/EXE-pecas.md"""
from helpers import acoes, run

ALVO_FOGO = {"id": "elemental_1", "elemento": "fogo", "distancia": 4.5}


def erro(r):
    assert r["ok"] is False, r
    return r["erro"]


def test_EXE_010_elementos_e_formas_como_nomes():
    r = run("print(fogo, gelo, raio, projetil, escudo)")
    assert r["saidas"] == [{"linha": 1, "texto": "fogo gelo raio projetil escudo"}]


def test_EXE_011_lancar_com_alvo():
    r = run("# mirar\nlancar(gelo, projetil, alvo)", alvo=ALVO_FOGO)
    assert r["acoes"] == [
        {"tipo": "lancar", "linha": 2, "elemento": "gelo", "forma": "projetil", "alvo": "elemental_1"}
    ]


def test_EXE_012_lancar_sem_alvo():
    r = run("lancar(raio, escudo)")
    assert r["acoes"] == [{"tipo": "lancar", "linha": 1, "elemento": "raio", "forma": "escudo", "alvo": None}]


def test_EXE_012_lancar_com_alvo_none_explicito():
    r = run("lancar(raio, escudo, alvo)", alvo=None)
    assert r["acoes"][0]["alvo"] is None


def test_EXE_013_lancar_aceita_elemento_do_alvo():
    r = run("lancar(alvo.elemento, projetil, alvo)", alvo=ALVO_FOGO)
    assert r["acoes"][0]["elemento"] == "fogo"


def test_EXE_014_lancar_rejeita_elemento_desconhecido():
    e = erro(run('lancar("agua", projetil)'))
    assert e["tipo"] == "ValueError"
    assert "fogo" in e["mensagem"] and "agua" in e["mensagem"]


def test_EXE_014_lancar_rejeita_forma_desconhecida():
    e = erro(run('lancar(fogo, "laser")'))
    assert e["tipo"] == "ValueError"
    assert "projetil" in e["mensagem"]


def test_EXE_014_lancar_rejeita_elemento_que_nao_e_texto():
    assert erro(run("lancar(3, projetil)"))["tipo"] == "ValueError"


def test_EXE_015_lancar_rejeita_alvo_invalido():
    assert erro(run('lancar(fogo, projetil, "elemental_1")'))["tipo"] == "TypeError"


def test_EXE_016_mover():
    r = run("mover(3)\nmover(-2)\nmover(1.5)")
    assert [(a["passos"], a["linha"]) for a in acoes(r, "mover")] == [(3, 1), (-2, 2), (1.5, 3)]


def test_EXE_016_mover_rejeita_texto_e_bool():
    assert erro(run('mover("3")'))["tipo"] == "TypeError"
    assert erro(run("mover(True)"))["tipo"] == "TypeError"


def test_EXE_017_levitar():
    r = run("levitar(4)")
    assert r["acoes"] == [{"tipo": "levitar", "linha": 1, "altura": 4}]


def test_EXE_017_levitar_valida_altura():
    assert erro(run("levitar(0)"))["tipo"] == "ValueError"
    assert erro(run("levitar(-1)"))["tipo"] == "ValueError"
    assert erro(run('levitar("alto")'))["tipo"] == "TypeError"


def test_EXE_018_meditar_e_absorver_simulam_mana_com_teto():
    r = run(
        "absorver_mana()\nmeditar()",
        mago={"vida": 10, "mana": 18, "mana_max": 20},
        regras={"ganho_meditar": 5, "ganho_absorver": 1},
    )
    assert [a["tipo"] for a in r["acoes"]] == ["absorver_mana", "meditar"]
    assert r["mago"]["mana"] == 20


def test_EXE_019_loop_sobre_a_mana():
    r = run(
        "while mana < mana_max:\n    absorver_mana()",
        mago={"vida": 10, "mana": 0, "mana_max": 5},
        regras={"ganho_absorver": 1},
    )
    assert len(acoes(r, "absorver_mana")) == 6  # a primeira volta paga 0,2 e as outras 0,1 (EXE-045)
    assert all(a["linha"] == 2 for a in r["acoes"])
    assert r["mago"]["mana"] == 5


def test_EXE_020_sentidos_do_mundo():
    r = run(
        "print(vida_atual == 7, alvo.elemento == 'planta', alvo.distancia == 3.5)",
        mago={"vida": 7, "mana": 0, "mana_max": 10},
        alvo={"id": "p1", "elemento": "planta", "distancia": 3.5},
    )
    assert r["saidas"][0]["texto"] == "True True True"


def test_EXE_021_sem_alvo():
    assert run("print(alvo is None)", alvo=None)["saidas"][0]["texto"] == "True"


def test_EXE_022_alvo_e_somente_leitura():
    assert erro(run("alvo.elemento = 'gelo'", alvo=ALVO_FOGO))["tipo"] == "AttributeError"


def test_EXE_023_sentidos_nao_podem_ser_trapaceados():
    r = run(
        "mana = 999\nabsorver_mana()\nprint(mana)",
        mago={"vida": 10, "mana": 2, "mana_max": 10},
        regras={"ganho_absorver": 1},
    )
    assert r["saidas"][0]["texto"] == "2.6"
    assert r["mago"]["mana"] == 2.4


def test_EXE_023_sentidos_atualizam_dentro_de_funcao():
    codigo = "def carregar():\n    while mana < mana_max:\n        absorver_mana()\ncarregar()\nprint(mana)"
    r = run(codigo, mago={"vida": 10, "mana": 7, "mana_max": 9}, regras={"ganho_absorver": 1})
    assert r["saidas"][0]["texto"] == "8.8"  # chegou a 9 dentro da função; a chamada custou 0,2 (com inscrição)


FEITICO_ADAPTAVEL = """def feitico_adaptavel(alvo):
    if alvo.elemento == "fogo":
        lancar(gelo, projetil, alvo)
    elif alvo.elemento == "planta":
        lancar(fogo, projetil, alvo)
    else:
        lancar(raio, projetil, alvo)

feitico_adaptavel(alvo)
"""


def test_EXE_024_feitico_adaptavel_do_gdd():
    r = run(FEITICO_ADAPTAVEL, alvo={"id": "p1", "elemento": "planta", "distancia": 2})
    assert r["acoes"] == [{"tipo": "lancar", "linha": 5, "elemento": "fogo", "forma": "projetil", "alvo": "p1"}]
