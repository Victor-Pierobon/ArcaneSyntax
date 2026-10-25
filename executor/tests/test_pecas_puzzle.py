"""Spec: docs/specs/executor/EXE-pecas.md (regras 6 a 9) e EXE-protocolo.md (regra 7), Sprint 9."""
from arcane_executor.protocol import handle_request
from helpers import acoes, requisicao, run

RUNAS = {"runas": [4, 7, 2]}


def test_EXE_100_ler_runa_le_a_sala():
    r = run("a = ler_runa(1)\nb = ler_runa(3)\nprint(a + b)", sala=RUNAS)
    assert r["ok"] is True, r["erro"]
    assert r["saidas"][0]["texto"] == "6"
    assert r["acoes"] == []


def test_EXE_101_ler_runa_fora_da_sala():
    for codigo in ("ler_runa(0)", "ler_runa(4)"):
        r = run(codigo, sala=RUNAS)
        assert r["erro"]["tipo"] == "ValueError", codigo
        assert "3 runas" in r["erro"]["mensagem"]
    for codigo in ('ler_runa("1")', "ler_runa(True)", "ler_runa(1.0)"):
        assert run(codigo, sala=RUNAS)["erro"]["tipo"] == "TypeError", codigo


def test_EXE_102_sala_sem_runas():
    for r in (run("ler_runa(1)"), run("ler_runa(1)", sala={"runas": []})):
        assert r["erro"]["tipo"] == "ValueError"
        assert r["erro"]["mensagem"] == "não há runas nesta sala"


def test_EXE_103_inscrever():
    r = run("inscrever(13)")
    assert r["acoes"] == [{"tipo": "inscrever", "linha": 1, "valor": 13}]
    assert r["custo_mana"] == 1.2
    for codigo in ('inscrever("13")', "inscrever(True)"):
        r = run(codigo)
        assert r["erro"]["tipo"] == "TypeError", codigo
        assert r["acoes"] == []


def test_EXE_104_construir_bloco():
    r = run("construir_bloco()\nconstruir_bloco()")
    assert r["acoes"] == [{"tipo": "construir_bloco", "linha": 1}, {"tipo": "construir_bloco", "linha": 2}]
    assert r["custo_mana"] == 1.4


def test_EXE_105_runas_nao_podem_ser_trapaceadas():
    r = run("ler_runa = lambda n: 99\ninscrever(ler_runa(1))", sala=RUNAS)
    assert acoes(r, "inscrever") == [{"tipo": "inscrever", "linha": 2, "valor": 99}]


def test_EXE_110_sala_invalida():
    for sala in ([4, 7], {"runas": "472"}, {"runas": [4, "7"]}, {"runas": [4, 7.5]}, {"runas": [True]}):
        r = handle_request(requisicao("x = 1", sala=sala))
        assert r["erro"]["tipo"] == "RequisicaoInvalida", sala


def test_EXE_110_campos_desconhecidos_na_sala_sao_ignorados():
    r = handle_request(requisicao("print(ler_runa(2))", sala={"runas": [4, 7], "portas": 3}))
    assert r["ok"] is True, r["erro"]
    assert r["saidas"][0]["texto"] == "7"


def test_EXE_110_sala_nula_e_o_mesmo_que_sem_sala():
    req = requisicao("x = 1")
    req["mundo"]["sala"] = None
    assert handle_request(req) == handle_request(requisicao("x = 1"))
