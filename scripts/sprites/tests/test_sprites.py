"""Testes do gerador de sprites (spec ART-gerador)."""

import json
import sys
from pathlib import Path

import pytest
from PIL import Image

PASTA = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PASTA))

import sprites  # noqa: E402

RAIZ = PASTA.parent.parent


def fila_exemplo():
    return [
        {"id": "base", "tipo": "imagem", "tamanho": [48, 48], "prompt": "x", "aprovar": True},
        {"id": "base/anim", "tipo": "animacao", "de": "base", "acao": "andar", "quadros": 4},
        {"id": "obj/a", "tipo": "imagem", "tamanho": [16, 16], "prompt": "y"},
    ]


def bloco(tamanho, x0, y0, x1, y1, cor=(200, 100, 50, 255)):
    img = Image.new("RGBA", tamanho, (0, 0, 0, 0))
    for x in range(x0, x1 + 1):
        for y in range(y0, y1 + 1):
            img.putpixel((x, y), cor)
    return img


def caixa(img):
    return img.getchannel("A").getbbox()


# ART-100
def test_ART_100_proximo_respeita_aprovacao_e_dependencia():
    fila = fila_exemplo()
    estado = {"base": {"situacao": "revisar"}}
    assert sprites.proximo(fila, estado)["id"] == "obj/a"
    estado["base"]["situacao"] = "aprovado"
    assert sprites.proximo(fila, estado)["id"] == "base/anim"


def test_ART_100_sem_nada_pendente_devolve_none():
    fila = fila_exemplo()
    estado = {i["id"]: {"situacao": "pronto"} for i in fila}
    assert sprites.proximo(fila, estado) is None


def test_ART_100_item_com_erro_nao_e_escolhido_de_novo():
    fila = fila_exemplo()[2:]
    assert sprites.proximo(fila, {"obj/a": {"situacao": "erro"}}) is None


# ART-101
def test_ART_101_refazer_volta_os_dependentes():
    fila = [
        {"id": "base", "tipo": "imagem", "tamanho": [48, 48], "prompt": "x"},
        {"id": "x/anim", "tipo": "animacao", "de": "base", "acao": "a", "quadros": 4},
        {"id": "x/anim_gelo", "tipo": "troca_cor", "de": "x/anim", "matiz": 190},
        {"id": "outro/a", "tipo": "imagem", "tamanho": [16, 16], "prompt": "y"},
    ]
    estado = {i["id"]: {"situacao": "pronto"} for i in fila}
    voltaram = sprites.refazer(fila, estado, "base")
    assert sorted(voltaram) == ["base", "x/anim", "x/anim_gelo"]
    assert estado["x/anim_gelo"]["situacao"] == "pendente"
    assert estado["outro/a"]["situacao"] == "pronto"


# ART-102
def test_ART_102_cota_insuficiente_para():
    item = {"id": "a/b", "tipo": "imagem", "custo": 2}
    assert not sprites.cabe_na_cota(item, 1)
    assert sprites.cabe_na_cota(item, 2)


def test_ART_102_troca_de_cor_nao_custa():
    item = {"id": "a/b", "tipo": "troca_cor", "de": "x", "matiz": 10}
    assert sprites.custo(item) == 0
    assert sprites.cabe_na_cota(item, 0)


def test_ART_102_custo_padrao_e_um():
    assert sprites.custo({"id": "a", "tipo": "imagem"}) == 1
    assert sprites.custo({"id": "a", "tipo": "animacao"}) == 1


# ART-103
def test_ART_103_alfa_vira_opaco_ou_transparente():
    img = Image.new("RGBA", (2, 1))
    img.putpixel((0, 0), (10, 20, 30, 200))
    img.putpixel((1, 0), (10, 20, 30, 100))
    out = sprites.binarizar(img)
    assert out.getpixel((0, 0)) == (10, 20, 30, 255)
    assert out.getpixel((1, 0)) == (0, 0, 0, 0)


# ART-104
def test_ART_104_alinha_pelos_pes():
    img = bloco((48, 48), 10, 5, 19, 24)
    dx, dy = sprites.deslocamento(img, "pes")
    out = sprites.deslocar(img, dx, dy)
    assert caixa(out) == (19, 26, 29, 46)  # getbbox: fim exclusivo; base em y = 46


def test_ART_104_alinha_pelo_centro():
    img = bloco((48, 48), 10, 5, 19, 24)
    dx, dy = sprites.deslocamento(img, "centro")
    out = sprites.deslocar(img, dx, dy)
    assert caixa(out) == (19, 14, 29, 34)


def test_ART_104_imagem_vazia_nao_desloca():
    assert sprites.deslocamento(Image.new("RGBA", (16, 16)), "pes") == (0, 0)


# ART-105
def test_ART_105_tira_e_conferencia():
    quadros = [bloco((16, 16), 2, 2, 5, 5) for _ in range(4)]
    tira = sprites.tira(quadros)
    assert tira.size == (64, 16)
    assert sprites.conferir(tira, 16) == []


def test_ART_105_conferencia_acusa_problemas():
    assert any("altura" in p for p in sprites.conferir(Image.new("RGBA", (32, 20)), 16))
    assert any("largura" in p for p in sprites.conferir(Image.new("RGBA", (40, 16)), 16))
    meio = Image.new("RGBA", (16, 16))
    meio.putpixel((3, 4), (1, 2, 3, 128))
    assert any("(3, 4)" in p for p in sprites.conferir(meio, 16))


def test_ART_105_quadro_retangular():
    assert sprites.conferir(Image.new("RGBA", (32, 64)), (16, 64)) == []


# ART-106
def test_ART_106_imagem_pequena_vai_numa_tela_de_32():
    img = bloco((16, 16), 0, 0, 15, 15)
    tela, (ox, oy) = sprites.para_tela(img)
    assert tela.size == (32, 32)
    assert (ox, oy) == (8, 8)
    assert caixa(tela) == (8, 8, 24, 24)
    volta = sprites.recortar(tela, (ox, oy), (16, 16))
    assert volta.size == (16, 16)
    assert caixa(volta) == (0, 0, 16, 16)


def test_ART_106_imagem_grande_nao_muda():
    img = Image.new("RGBA", (48, 48))
    tela, deslocamento = sprites.para_tela(img)
    assert tela.size == (48, 48) and deslocamento == (0, 0)


# ART-107
def test_ART_107_troca_a_rampa_da_escola_e_mantem_o_resto():
    fogo = ["#B94336", "#D65C38", "#F07842", "#F2A64A", "#FFD071", "#FFE3A1"]
    gelo = ["#477FAD", "#83CFE0", "#D8F6F2"]
    img = Image.new("RGBA", (4, 1))
    img.putpixel((0, 0), (*sprites.cor("#B94336"), 255))  # mais escuro do fogo
    img.putpixel((1, 0), (*sprites.cor("#FFE3A1"), 255))  # mais claro do fogo
    img.putpixel((2, 0), (*sprites.cor("#10131F"), 255))  # contorno
    out = sprites.trocar_escola(img, fogo, gelo)
    assert out.getpixel((0, 0)) == (*sprites.cor("#477FAD"), 255)
    assert out.getpixel((1, 0)) == (*sprites.cor("#D8F6F2"), 255)
    assert out.getpixel((2, 0)) == (*sprites.cor("#10131F"), 255)
    assert out.getpixel((3, 0)) == (0, 0, 0, 0)


# ART-109
def test_ART_109_quantiza_para_a_paleta():
    paleta = ["#10131F", "#F07842", "#83CFE0"]
    img = Image.new("RGBA", (3, 1))
    img.putpixel((0, 0), (250, 120, 70, 255))
    img.putpixel((1, 0), (5, 10, 20, 255))
    out = sprites.quantizar(img, paleta)
    assert out.getpixel((0, 0)) == (*sprites.cor("#F07842"), 255)
    assert out.getpixel((1, 0)) == (*sprites.cor("#10131F"), 255)
    assert out.getpixel((2, 0)) == (0, 0, 0, 0)


# ART-110
def test_ART_110_paleta_e_escolas_iguais_ao_guia_de_estilo():
    import re

    guia = (RAIZ / "docs/arte/ArcaneSyntax_Guia_de_Estilo_Visual.md").read_text(encoding="utf-8")
    secao = guia[guia.index("## 2. Paleta"):guia.index("### Proporção")]
    do_guia = re.findall(r"`(#[0-9A-Fa-f]{6})`", secao)
    config = sprites.carregar_config(PASTA / "fila.json")
    assert [c.upper() for c in config["paleta"]] == [c.upper() for c in do_guia]
    assert len(config["paleta"]) == 27
    for escola, rampa in config["escolas"].items():
        assert set(rampa) <= set(config["paleta"]), escola


# ART-108
def nomes_do_contrato():
    contrato = json.loads((RAIZ / "game/content/arte.json").read_text(encoding="utf-8"))
    return sprites.nomes_do_contrato(contrato)


def test_ART_108_fila_do_projeto_e_valida():
    fila = sprites.carregar_fila(PASTA / "fila.json")
    escolas = sprites.carregar_config(PASTA / "fila.json")["escolas"]
    assert sprites.validar_fila(fila, nomes_do_contrato(), escolas) == []
    assert all(sprites.custo(i) <= 2 for i in fila)  # a fila pode passar de uma cota; a cota é conferida item a item


def test_ART_108_validacao_acusa_erros():
    fila = [
        {"id": "a/x", "tipo": "animacao", "de": "base", "acao": "a", "quadros": 4},
        {"id": "base", "tipo": "imagem", "tamanho": [16, 16], "prompt": "p"},
        {"id": "base", "tipo": "imagem", "tamanho": [16, 16], "prompt": "p"},
    ]
    problemas = " | ".join(sprites.validar_fila(fila, {"mago/andar"}))
    assert "repetido" in problemas
    assert "antes" in problemas
    assert "a/x" in problemas and "contrato" in problemas


def test_ART_108_nomes_do_contrato_incluem_variantes_e_quadro():
    nomes = nomes_do_contrato()
    assert "magia/projetil_gelo" in nomes
    assert "mago/andar" in nomes
    assert nomes["serpente/retrato"] == 64
    assert nomes["mago/andar"] == 48
    assert nomes["chefe/pilar"] == (16, 64)


# ART-111
class ClienteFalso:
    def __init__(self):
        self.chamadas = []

    def saldo(self):
        return 40.0, {}

    def criar_imagem(self, descricao, tamanho, opcoes):
        self.chamadas.append("imagem")
        img = bloco(tuple(tamanho), 2, 2, tamanho[0] // 2, tamanho[1] // 2, (240, 120, 66, 200))
        return img, 1

    def animar(self, primeiro, acao, quadros):
        self.chamadas.append(("animar", primeiro.size))
        return [primeiro.copy() for _ in range(quadros)], 1


def test_ART_111_fila_de_ponta_a_ponta_com_api_falsa(tmp_path, monkeypatch, capsys):
    import gerar

    fila_json = tmp_path / "fila.json"
    config = sprites.carregar_config(PASTA / "fila.json")
    config["itens"] = [
        {"id": "base", "tipo": "imagem", "tamanho": [16, 16], "prompt": "p", "escola": "fogo", "alinhar": "centro"},
        {"id": "magia/faisca_fogo", "tipo": "animacao", "de": "base", "acao": "a", "quadros": 4},
        {"id": "magia/faisca_gelo", "tipo": "troca_cor", "de": "magia/faisca_fogo", "escola": "gelo"},
        {"id": "mago_base", "tipo": "imagem", "tamanho": [48, 48], "prompt": "p", "aprovar": True},
        {"id": "mago/parado", "tipo": "animacao", "de": "mago_base", "acao": "a", "quadros": 4},
    ]
    fila_json.write_text(json.dumps(config), encoding="utf-8")
    for nome_var, valor in {
        "FILA": fila_json, "ASSETS": tmp_path / "assets", "RAIZ": tmp_path,
        "ESTADO": tmp_path / "ia/estado.json", "BRUTOS": tmp_path / "ia/brutos",
        "PRONTOS": tmp_path / "ia/prontos", "PREVIA": tmp_path / "ia/previa",
    }.items():
        monkeypatch.setattr(gerar, nome_var, valor)
    falso = ClienteFalso()
    monkeypatch.setattr(gerar.pixellab, "Cliente", lambda *a, **k: falso)
    monkeypatch.setattr(gerar, "token", lambda: "x")

    assert gerar.main(["rodar"]) == 0
    assert falso.chamadas == ["imagem", ("animar", (32, 32)), "imagem"]  # parou no mago para aprovar
    faisca = Image.open(tmp_path / "assets/magia/faisca_fogo.png")
    assert faisca.size == (64, 16)
    assert sprites.conferir(faisca, 16) == []
    cores = {p[:3] for p in sprites.pixels(faisca.convert("RGBA")) if p[3]}
    assert cores <= {sprites.cor(c) for c in config["paleta"]}
    gelo = Image.open(tmp_path / "assets/magia/faisca_gelo.png").convert("RGBA")
    assert {p[:3] for p in sprites.pixels(gelo) if p[3]} <= {sprites.cor(c) for c in config["escolas"]["gelo"]}
    assert not (tmp_path / "assets/mago/parado.png").exists()

    assert gerar.main(["aprovar", "mago_base"]) == 0
    assert gerar.main(["rodar"]) == 0
    assert Image.open(tmp_path / "assets/mago/parado.png").size == (192, 48)

    antes = len(falso.chamadas)
    assert gerar.main(["relimpar", "mago/parado"]) == 0
    assert gerar.main(["relimpar", "base"]) == 0
    assert len(falso.chamadas) == antes  # relimpar não chama a API
    assert Image.open(tmp_path / "assets/mago/parado.png").size == (192, 48)

    assert gerar.main(["refazer", "mago_base"]) == 0
    assert not (tmp_path / "assets/mago/parado.png").exists()


def test_ART_111_nao_sobrescreve_arte_do_victor(tmp_path, monkeypatch):
    import gerar

    destino = tmp_path / "assets/objetos/porta.png"
    destino.parent.mkdir(parents=True)
    Image.new("RGBA", (16, 16)).save(destino)
    monkeypatch.setattr(gerar, "ASSETS", tmp_path / "assets")
    monkeypatch.setattr(gerar, "RAIZ", tmp_path)
    estado = {}
    item = {"id": "objetos/porta", "tipo": "imagem", "tamanho": [16, 16], "prompt": "p"}
    gerar.rodar_item(ClienteFalso(), [item], item, {}, estado)
    assert estado["objetos/porta"]["situacao"] == "pulado"


# ART-112 — Regressão (2026-10-27): o elemental veio com um cenário atrás (sem fundo transparente)
# e foi instalado no jogo, onde aparecia como um quadrado.
def test_ART_112_imagem_sem_fundo_transparente_e_recusada():
    cheia = bloco((32, 32), 0, 0, 31, 31)
    assert sprites.sem_fundo(cheia)
    assert not sprites.sem_fundo(bloco((32, 32), 4, 4, 27, 30))


def test_ART_112_cenario_com_cantos_transparentes_tambem_e_recusado():
    # perfil do elemental recusado: cantos vazios, mas 86% do quadro e metade da borda opacos
    cenario = bloco((32, 32), 1, 1, 30, 30)
    for x, y in [(1, 1), (30, 1), (1, 30), (30, 30)]:
        cenario.putpixel((x, y), (0, 0, 0, 0))
    assert sprites.sem_fundo(cenario)


def test_ART_112_fila_com_fundo_e_erro(tmp_path, monkeypatch):
    import gerar

    class ClienteComFundo(ClienteFalso):
        def criar_imagem(self, descricao, tamanho, opcoes):
            return bloco(tuple(tamanho), 0, 0, tamanho[0] - 1, tamanho[1] - 1), 1

    for nome_var, valor in {"ASSETS": tmp_path / "assets", "RAIZ": tmp_path, "BRUTOS": tmp_path / "b",
                            "PRONTOS": tmp_path / "p", "PREVIA": tmp_path / "v"}.items():
        monkeypatch.setattr(gerar, nome_var, valor)
    item = {"id": "objetos/tocha", "tipo": "imagem", "tamanho": [16, 16], "prompt": "p"}
    config = {"paleta": ["#10131F"]}
    with pytest.raises(gerar.pixellab.ErroApi, match="fundo"):
        gerar.rodar_item(ClienteComFundo(), [item], item, config, {})
    assert not (tmp_path / "assets/objetos/tocha.png").exists()
    porta = dict(item, id="objetos/porta", opaco=True)
    gerar.rodar_item(ClienteComFundo(), [porta], porta, config, {})
    assert (tmp_path / "assets/objetos/porta.png").exists()


# ART-113 — Fundos
def test_ART_113_imagem_parada_do_contrato_tem_o_tamanho_fixo():
    assert nomes_do_contrato()["cenario/fundo_1"] == (640, 360)


def test_ART_113_alinhar_nenhum_nao_desloca():
    assert sprites.deslocamento(bloco((48, 48), 0, 0, 5, 5), "nenhum") == (0, 0)


def test_ART_113_previa_de_imagem_grande_nao_estoura():
    assert sprites.previa(Image.new("RGBA", (640, 360))).size == (1280, 720)
    assert sprites.previa(Image.new("RGBA", (16, 16))).size == (128, 128)


# ART-114 — Regressão (2026-10-27): "heavy load" do PixelLab (não cobrado) parava a fila inteira a cada animação.
def test_ART_114_sobrecarga_marca_o_item_e_segue(tmp_path, monkeypatch):
    import gerar

    class ClienteSobrecarregado(ClienteFalso):
        def animar(self, primeiro, acao, quadros):
            raise gerar.pixellab.ErroApi('o trabalho falhou: {"error": "Generation failed due to heavy load."}')

    fila_json = tmp_path / "fila.json"
    config = sprites.carregar_config(PASTA / "fila.json")
    config["itens"] = [
        {"id": "tocha_base", "tipo": "imagem", "tamanho": [16, 16], "prompt": "p"},
        {"id": "objetos/tocha", "tipo": "animacao", "de": "tocha_base", "acao": "a", "quadros": 4},
        {"id": "objetos/placa", "tipo": "imagem", "tamanho": [16, 16], "prompt": "p"},
    ]
    fila_json.write_text(json.dumps(config), encoding="utf-8")
    for nome_var, valor in {"FILA": fila_json, "ASSETS": tmp_path / "assets", "RAIZ": tmp_path,
                            "ESTADO": tmp_path / "ia/estado.json", "BRUTOS": tmp_path / "ia/b",
                            "PRONTOS": tmp_path / "ia/p", "PREVIA": tmp_path / "ia/v"}.items():
        monkeypatch.setattr(gerar, nome_var, valor)
    monkeypatch.setattr(gerar.pixellab, "Cliente", lambda *a, **k: ClienteSobrecarregado())
    monkeypatch.setattr(gerar, "token", lambda: "x")
    assert gerar.main(["rodar"]) == 0
    estado = json.loads((tmp_path / "ia/estado.json").read_text(encoding="utf-8"))
    assert estado["objetos/tocha"]["situacao"] == "erro"
    assert estado["objetos/placa"]["situacao"] == "pronto"


def test_ART_114_maximo_conta_as_tentativas_com_sobrecarga(tmp_path, monkeypatch):
    # Regressão (2026-10-27): com --maximo 1, a sobrecarga não contava e a fila tentou três itens.
    import gerar

    class SempreSobrecarregado(ClienteFalso):
        def criar_imagem(self, descricao, tamanho, opcoes):
            self.chamadas.append("imagem")
            raise gerar.pixellab.ErroApi("heavy load")

    fila_json = tmp_path / "fila.json"
    config = sprites.carregar_config(PASTA / "fila.json")
    config["itens"] = [{"id": f"objetos/{n}", "tipo": "imagem", "tamanho": [16, 16], "prompt": "p"}
                       for n in ("placa", "cadeado", "porta")]
    fila_json.write_text(json.dumps(config), encoding="utf-8")
    for nome_var, valor in {"FILA": fila_json, "ASSETS": tmp_path / "assets", "RAIZ": tmp_path,
                            "ESTADO": tmp_path / "ia/estado.json", "BRUTOS": tmp_path / "ia/b",
                            "PRONTOS": tmp_path / "ia/p", "PREVIA": tmp_path / "ia/v"}.items():
        monkeypatch.setattr(gerar, nome_var, valor)
    falso = SempreSobrecarregado()
    monkeypatch.setattr(gerar.pixellab, "Cliente", lambda *a, **k: falso)
    monkeypatch.setattr(gerar, "token", lambda: "x")
    gerar.main(["rodar", "--maximo", "1"])
    assert falso.chamadas == ["imagem"]


def _usar_fila(gerar, tmp_path, monkeypatch, itens, cliente):
    fila_json = tmp_path / "fila.json"
    config = sprites.carregar_config(PASTA / "fila.json")
    config["itens"] = itens
    fila_json.write_text(json.dumps(config), encoding="utf-8")
    for nome_var, valor in {"FILA": fila_json, "ASSETS": tmp_path / "assets", "RAIZ": tmp_path,
                            "ESTADO": tmp_path / "ia/estado.json", "BRUTOS": tmp_path / "ia/b",
                            "PRONTOS": tmp_path / "ia/p", "PREVIA": tmp_path / "ia/v"}.items():
        monkeypatch.setattr(gerar, nome_var, valor)
    monkeypatch.setattr(gerar.pixellab, "Cliente", lambda *a, **k: cliente)
    monkeypatch.setattr(gerar, "token", lambda: "x")


class ClienteDoPilar(ClienteFalso):
    """Desenha uma coluna no meio e marca as bordas, para ver o recorte; anima sumindo."""

    def criar_imagem(self, descricao, tamanho, opcoes):
        self.chamadas.append(("imagem", tuple(tamanho)))
        img = bloco(tuple(tamanho), 12, 4, 19, tamanho[1] - 3)
        img.putpixel((0, 10), (255, 255, 255, 255))
        img.putpixel((tamanho[0] - 1, 10), (255, 255, 255, 255))
        return img, 1

    def animar(self, primeiro, acao, quadros):
        self.chamadas.append(("animar", primeiro.size))
        vazio = Image.new("RGBA", primeiro.size, (0, 0, 0, 0))
        return [primeiro.copy()] + [vazio.copy() for _ in range(quadros - 1)], 1


PILAR = [
    {"id": "pilar_base", "tipo": "imagem", "tamanho": [16, 64], "gerar": [32, 64], "prompt": "p"},
    {"id": "chefe/pilar", "tipo": "animacao", "de": "pilar_base", "acao": "a", "quadros": 4, "inverter": True},
]


# ART-115
def test_ART_115_gera_maior_e_recorta_o_meio(tmp_path, monkeypatch):
    import gerar

    falso = ClienteDoPilar()
    _usar_fila(gerar, tmp_path, monkeypatch, PILAR[:1], falso)
    assert gerar.main(["rodar"]) == 0
    assert falso.chamadas[0] == ("imagem", (32, 64))
    base = Image.open(tmp_path / "ia/p" / "pilar_base.png").convert("RGBA")
    assert base.size == (16, 64)
    brancos = [p for p in sprites.pixels(base) if p[3] and p[:3] == (255, 255, 255)]
    assert brancos == []  # as bordas da imagem gerada ficaram de fora
    assert caixa(base)[2] - caixa(base)[0] == 8  # a coluna inteira ficou


def test_ART_115_gerar_menor_que_o_tamanho_e_erro():
    fila = [{"id": "pilar_base", "tipo": "imagem", "tamanho": [16, 64], "gerar": [16, 32], "prompt": "p"}]
    assert "gerar" in " ".join(sprites.validar_fila(fila, set()))


# ART-116
def test_ART_116_animacao_invertida_termina_na_imagem_pronta(tmp_path, monkeypatch):
    import gerar

    falso = ClienteDoPilar()
    _usar_fila(gerar, tmp_path, monkeypatch, PILAR, falso)
    assert gerar.main(["rodar"]) == 0
    tira = Image.open(tmp_path / "assets/chefe/pilar.png").convert("RGBA")
    quadros = sprites.quadros_da_tira(tira, (16, 64))
    assert quadros[0].getchannel("A").getbbox() is None
    assert quadros[-1].getchannel("A").getbbox() is not None

    assert gerar.main(["relimpar", "chefe/pilar"]) == 0  # a limpeza de novo também inverte
    tira = Image.open(tmp_path / "assets/chefe/pilar.png").convert("RGBA")
    assert tira.size == (64, 64)
    assert sprites.quadros_da_tira(tira, (16, 64))[0].getchannel("A").getbbox() is None
