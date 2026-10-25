"""Spec: docs/specs/executor/EXE-desbloqueio.md"""
from arcane_executor.protocol import handle_request
from helpers import requisicao

TODAS = ["lancar", "mover", "levitar", "meditar", "absorver_mana", "fogo", "gelo", "raio", "projetil", "escudo"]


def run_com(codigo, pecas, **kwargs):
    req = requisicao(codigo, **kwargs)
    req["pecas"] = pecas
    return handle_request(req)


def sem(*bloqueadas):
    return [p for p in TODAS if p not in bloqueadas]


def test_EXE_080_sem_lista_tudo_liberado():
    r = handle_request(requisicao("lancar(raio, escudo)"))
    assert r["ok"] is True


def test_EXE_081_peca_bloqueada_antes_de_executar():
    r = run_com("meditar()\nlancar(raio, projetil)", sem("raio"))
    assert r["erro"]["tipo"] == "PecaBloqueada"
    assert r["erro"]["linha"] == 2
    assert isinstance(r["erro"]["coluna"], int)
    assert "raio" in r["erro"]["mensagem"]
    assert r["acoes"] == []
    assert r["custo_mana"] == 0


def test_EXE_082_acao_bloqueada():
    assert run_com("levitar(2)", sem("levitar"))["erro"]["tipo"] == "PecaBloqueada"


def test_EXE_083_texto_com_elemento_bloqueado():
    alvo = {"id": "a1", "elemento": "raio", "distancia": 2}
    r = run_com("mover(1)\nlancar(alvo.elemento, projetil, alvo)", sem("raio"), alvo=alvo)
    assert [a["tipo"] for a in r["acoes"]] == ["mover"]
    assert r["erro"]["tipo"] == "PecaBloqueada"
    assert r["erro"]["linha"] == 2
    assert r["custo_mana"] == 1.1


def test_EXE_083_texto_com_forma_bloqueada():
    assert run_com('lancar(fogo, "escudo")', sem("escudo"))["erro"]["tipo"] == "PecaBloqueada"


def test_EXE_084_sentidos_sempre_disponiveis():
    r = run_com("print(mana, mana_max, vida_atual, alvo)", [])
    assert r["ok"] is True
    assert r["saidas"][0]["texto"] == "5 20 10 None"


def test_EXE_085_nome_desconhecido_na_lista():
    r = run_com("x = 1", ["bola_de_fogo"])
    assert r["erro"]["tipo"] == "RequisicaoInvalida"


def test_EXE_085_lista_precisa_ser_de_textos():
    assert run_com("x = 1", "fogo")["erro"]["tipo"] == "RequisicaoInvalida"
