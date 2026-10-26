"""Spec: docs/specs/executor/EXE-pecas.md (regras 10 a 13), EXE-custo.md (faísca) e EXE-protocolo.md (regra 8), Sprint 10."""
from arcane_executor.protocol import handle_request
from helpers import acoes, requisicao, run

MANA_10 = {"vida": 5, "mana": 10, "mana_max": 10}


def inimigo(id, elemento="gelo", distancia=3.0, vida=2, escudo=None):
    return {"id": id, "elemento": elemento, "distancia": distancia, "vida": vida, "escudo": escudo}


ENXAME = [inimigo(f"bicho_{n}", distancia=8 + n * 0.5) for n in range(1, 7)]
LOOP = "for inimigo in inimigos:\n    lancar(raio, {forma}, inimigo)"


def test_EXE_120_inimigos_le_a_foto():
    lista = [inimigo("a", "fogo", 3, 12), inimigo("b", "gelo", 5, 2)]
    r = run("print(len(inimigos), inimigos[0].elemento, inimigos[1].vida)", inimigos=lista)
    assert r["ok"] is True, r["erro"]
    assert r["saidas"][0]["texto"] == "2 fogo 2"


def test_EXE_121_sem_inimigos():
    r = run("print(inimigos == [])\n" + LOOP.format(forma="faisca"))
    assert r["ok"] is True, r["erro"]
    assert r["saidas"][0]["texto"] == "True"
    assert r["acoes"] == []


def test_EXE_122_loop_sobre_os_inimigos():
    r = run(LOOP.format(forma="faisca"), inimigos=[inimigo("a"), inimigo("b"), inimigo("c")])
    assert r["ok"] is True, r["erro"]
    assert [(a["linha"], a["alvo"], a["forma"]) for a in acoes(r, "lancar")] == [
        (2, "a", "faisca"), (2, "b", "faisca"), (2, "c", "faisca"),
    ]


def test_EXE_123_vida_e_escudo():
    guardiao = {"id": "g", "elemento": "pedra", "distancia": 4, "vida": 18, "escudo": "planta"}
    r = run("print(alvo.vida, alvo.escudo)", alvo=guardiao)
    assert r["saidas"][0]["texto"] == "18 planta"
    boneco = {"id": "b", "elemento": "fogo", "distancia": 2}
    r = run("print(alvo.vida, alvo.escudo)", alvo=boneco)
    assert r["saidas"][0]["texto"] == "None None"
    for codigo in ('alvo.escudo = "fogo"', "alvo.vida = 0", "inimigos[0].vida = 0"):
        r = run(codigo, alvo=guardiao, inimigos=[guardiao])
        assert r["erro"]["tipo"] == "AttributeError", codigo


def test_EXE_124_alvo_e_inimigos_sao_o_mesmo_objeto():
    a = inimigo("a", "fogo", 3, 12)
    r = run("print(alvo is inimigos[0], alvo is inimigos[1])", alvo=a, inimigos=[a, inimigo("b")])
    assert r["saidas"][0]["texto"] == "True False"


def test_EXE_125_faisca():
    r = run("lancar(raio, faisca, alvo)", alvo=inimigo("a"))
    assert r["acoes"] == [{"tipo": "lancar", "linha": 1, "elemento": "raio", "forma": "faisca", "alvo": "a"}]
    r = run('lancar(raio, "faísca")')
    assert r["erro"]["tipo"] == "ValueError"
    assert "faisca" in r["erro"]["mensagem"]


def test_EXE_126_a_vida_nao_muda_durante_o_feitico():
    r = run("while inimigos[0].vida > 0:\n    lancar(raio, faisca, inimigos[0])", mago=MANA_10, inimigos=[inimigo("a")])
    assert r["erro"]["tipo"] == "ManaEsgotada"
    assert r["erro"]["linha"] == 2
    assert len(acoes(r, "lancar")) == 9


def test_EXE_095_faisca_custa_1():
    r = run("lancar(raio, faisca)")
    assert r["custo_mana"] == 1.2
    assert r["mago"]["mana"] == 3.8
    assert run("lancar(raio, faisca)", regras={"custo_faisca": 2})["custo_mana"] == 2.2
    # As outras formas continuam custando custo_lancar.
    assert run("lancar(raio, escudo)")["custo_mana"] == 3.2


def test_EXE_096_loop_de_faiscas_sobre_o_enxame():
    r = run(LOOP.format(forma="faisca"), mago=MANA_10, inimigos=ENXAME)
    assert r["ok"] is True, r["erro"]
    assert len(acoes(r, "lancar")) == 6
    assert r["custo_mana"] == 6.7
    r = run(LOOP.format(forma="projetil"), mago=MANA_10, inimigos=ENXAME)
    assert len(acoes(r, "lancar")) == 3
    assert r["erro"]["tipo"] == "ManaEsgotada"
    assert r["erro"]["linha"] == 2
    assert r["custo_mana"] == 9.4


def test_EXE_112_inimigos_na_requisicao():
    alvo = inimigo("a", "pedra", 4, 18, "fogo")
    r = handle_request(requisicao("x = 1", alvo=alvo, inimigos=[alvo, inimigo("b")]))
    assert r["ok"] is True, r["erro"]
    invalidas = [
        {"inimigos": {"a": 1}},
        {"inimigos": [{"elemento": "fogo", "distancia": 1}]},
        {"inimigos": [inimigo("a", vida="muita")]},
        {"inimigos": [inimigo("a", escudo=3)]},
        {"inimigos": [inimigo("a", vida=True)]},
        {"alvo": inimigo("a", vida="muita")},
        {"alvo": inimigo("a", escudo=3)},
    ]
    for mundo in invalidas:
        req = requisicao("x = 1")
        req["mundo"].update(mundo)
        assert handle_request(req)["erro"]["tipo"] == "RequisicaoInvalida", mundo


def test_EXE_123_alvo_nao_fabrica_alvos():
    r = run("print([n for n in dir(alvo) if not n.startswith('_')])", alvo=inimigo("a"))
    assert r["saidas"][0]["texto"] == "['distancia', 'elemento', 'escudo', 'vida']"
