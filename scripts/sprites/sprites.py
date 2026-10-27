"""Regras puras do gerador de sprites (spec ART-gerador): fila, cota e imagem.

Nada aqui chama a API nem grava arquivo; o `gerar.py` cuida disso.
"""

import json
from pathlib import Path

from PIL import Image

TIPOS = ("imagem", "animacao", "troca_cor")
FEITOS = ("pronto", "aprovado")
TELA_MINIMA = 32


# --- Fila ---------------------------------------------------------------


def carregar_config(caminho):
    """A fila.json inteira: estilo, paleta, escolas e itens."""
    return json.loads(Path(caminho).read_text(encoding="utf-8"))


def carregar_fila(caminho):
    dados = carregar_config(caminho)
    estilo = dados.get("estilo", "")
    fila = []
    for item in dados["itens"]:
        item = dict(item)
        if item["tipo"] == "imagem" and estilo:
            item["prompt"] = f"{item['prompt']}, {estilo}"
        fila.append(item)
    return fila


def por_id(fila):
    return {item["id"]: item for item in fila}


def situacao(estado, item_id):
    return estado.get(item_id, {}).get("situacao", "pendente")


def proximo(fila, estado):
    """O primeiro item pendente cuja base já está pronta ou aprovada (regras 3 e 4)."""
    for item in fila:
        if situacao(estado, item["id"]) != "pendente":
            continue
        base = item.get("de")
        if base is None or situacao(estado, base) in FEITOS:
            return item
    return None


def dependentes(fila, item_id):
    """O item e tudo o que deriva dele, direta ou indiretamente."""
    ids = {item_id}
    for item in fila:  # a fila está em ordem: a base vem antes
        if item.get("de") in ids:
            ids.add(item["id"])
    return ids


def refazer(fila, estado, item_id):
    ids = dependentes(fila, item_id)
    for i in ids:
        estado[i] = {"situacao": "pendente"}
    return [item["id"] for item in fila if item["id"] in ids]


def raiz(fila, item_id):
    itens = por_id(fila)
    item = itens[item_id]
    while item.get("de"):
        item = itens[item["de"]]
    return item


def custo(item):
    if item["tipo"] == "troca_cor":
        return 0
    return item.get("custo", 1)


def cabe_na_cota(item, saldo):
    return custo(item) <= saldo


def instalavel(item):
    return "/" in item["id"]


def quadro_do_item(fila, item_id):
    return tuple(raiz(fila, item_id)["tamanho"])


def nomes_do_contrato(contrato):
    """{"pasta/nome": quadro} com as variantes de elemento; quadro é int ou (l, a)."""
    nomes = {}
    for pasta, dados in contrato.items():
        for anim, regra in dados["animacoes"].items():
            quadro = regra.get("quadro", dados.get("quadro"))
            if regra.get("imagem") and regra.get("tamanho"):
                quadro = regra["tamanho"]
            if isinstance(quadro, list):
                quadro = tuple(quadro)
            elementos = regra.get("elementos")
            for nome in [f"{anim}_{e}" for e in elementos] if elementos else [anim]:
                nomes[f"{pasta}/{nome}"] = quadro
    return nomes


def validar_fila(fila, nomes, escolas=None):
    problemas = []
    vistos = set()
    for item in fila:
        i = item["id"]
        if i in vistos:
            problemas.append(f"{i}: id repetido")
        if item.get("tipo") not in TIPOS:
            problemas.append(f"{i}: tipo desconhecido {item.get('tipo')!r}")
        base = item.get("de")
        if item.get("tipo") == "imagem":
            if base or not item.get("prompt") or not item.get("tamanho"):
                problemas.append(f"{i}: imagem precisa de prompt e tamanho, sem 'de'")
        elif base not in vistos:
            problemas.append(f"{i}: 'de' ({base}) precisa ser um item antes dele")
        if item.get("tipo") == "animacao":
            q = item.get("quadros", 0)
            if not (4 <= q <= 16 and q % 2 == 0) or not item.get("acao"):
                problemas.append(f"{i}: animação precisa de acao e quadros par de 4 a 16")
        if item.get("tipo") == "troca_cor" and escolas is not None and not problemas_de_raiz(fila, base, vistos):
            origem = raiz(fila, base).get("escola")
            if origem not in escolas or item.get("escola") not in escolas:
                problemas.append(f"{i}: troca_cor precisa de 'escola' no item e na base ({origem})")
        vistos.add(i)
        if instalavel(item):
            if i not in nomes:
                problemas.append(f"{i}: não existe no contrato (content/arte.json)")
            elif isinstance(nomes, dict) and not problemas_de_raiz(fila, base, vistos):
                esperado = nomes[i]
                esperado = esperado if isinstance(esperado, tuple) else (esperado, esperado)
                tem = quadro_do_item(fila, i)
                if tem != esperado:
                    problemas.append(f"{i}: quadro {tem} diferente do contrato {esperado}")
    return problemas


def problemas_de_raiz(fila, base, vistos):
    """True quando a cadeia `de` está quebrada (já acusada acima)."""
    itens = por_id(fila)
    while base:
        if base not in vistos or base not in itens:
            return True
        base = itens[base].get("de")
    return False


# --- Imagem -------------------------------------------------------------


def pixels(img):
    if hasattr(img, "get_flattened_data"):
        return img.get_flattened_data()
    return img.getdata()


def binarizar(img):
    """Regra 10: alfa >= 128 vira opaco; o resto, transparente."""
    img = img.convert("RGBA")
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.putdata([(r, g, b, 255) if a >= 128 else (0, 0, 0, 0) for r, g, b, a in pixels(img)])
    return out


def sem_fundo(img):
    """True quando a API não tirou o fundo (cenário atrás do personagem).

    Medido nas primeiras imagens: um sprite cobre até ~70% do quadro e ~30% da faixa de 2 px
    da borda; o elemental com uma caverna atrás cobria 86% e 49%.
    """
    alfa = img.convert("RGBA").getchannel("A")
    largura, altura = img.size
    opaco = [[alfa.getpixel((x, y)) >= 128 for x in range(largura)] for y in range(altura)]
    cantos = (opaco[0][0], opaco[0][-1], opaco[-1][0], opaco[-1][-1])
    if all(cantos):
        return True
    cobertura = sum(map(sum, opaco)) / (largura * altura)
    borda = [opaco[y][x] for y in range(altura) for x in range(largura)
             if min(x, y, largura - 1 - x, altura - 1 - y) < 2]
    return cobertura >= 0.8 or sum(borda) / len(borda) >= 0.4


def deslocamento(img, modo="pes"):
    """Regra 11: quanto mover para a caixa opaca ficar no lugar."""
    caixa = img.getchannel("A").getbbox()
    if caixa is None or modo == "nenhum":
        return (0, 0)
    largura, altura = img.size
    x0, y0, x1, y1 = caixa  # x1, y1 exclusivos
    dx = largura // 2 - (x0 + x1) // 2
    if modo == "centro":
        dy = altura // 2 - (y0 + y1) // 2
    else:
        dy = (altura - 2) - y1
    return (dx, dy)


def deslocar(img, dx, dy):
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (dx, dy))
    return out


def tira(quadros):
    largura, altura = quadros[0].size
    out = Image.new("RGBA", (largura * len(quadros), altura), (0, 0, 0, 0))
    for n, q in enumerate(quadros):
        out.paste(q, (n * largura, 0))
    return out


def conferir(img, quadro):
    """Regra 12: os mesmos problemas que o teste ART-004 do jogo acusa."""
    largura_q, altura_q = quadro if isinstance(quadro, tuple) else (quadro, quadro)
    largura, altura = img.size
    problemas = []
    if altura != altura_q:
        problemas.append(f"altura {altura}, o quadro tem {altura_q}")
    if largura == 0 or largura % largura_q != 0:
        problemas.append(f"largura {largura} não é múltipla de {largura_q}")
    alfa = img.convert("RGBA").getchannel("A")
    for y in range(altura):
        for x in range(largura):
            if alfa.getpixel((x, y)) not in (0, 255):
                problemas.append(f"pixel semitransparente em ({x}, {y})")
                return problemas
    return problemas


def para_tela(img):
    """Regra 13: imagem pequena vai centralizada numa tela de 32 para animar."""
    largura, altura = img.size
    tela_l, tela_a = max(largura, TELA_MINIMA), max(altura, TELA_MINIMA)
    if (tela_l, tela_a) == (largura, altura):
        return img, (0, 0)
    ox, oy = (tela_l - largura) // 2, (tela_a - altura) // 2
    tela = Image.new("RGBA", (tela_l, tela_a), (0, 0, 0, 0))
    tela.paste(img, (ox, oy))
    return tela, (ox, oy)


def recortar(img, origem, tamanho):
    ox, oy = origem
    return img.crop((ox, oy, ox + tamanho[0], oy + tamanho[1]))


def cor(hexa):
    hexa = hexa.lstrip("#")
    return tuple(int(hexa[i:i + 2], 16) for i in (0, 2, 4))


def mais_perto(rgb, paleta):
    """A cor da paleta mais parecida (distância "redmean", sem pontilhado)."""
    r, g, b = rgb

    def distancia(c):
        rm = (r + c[0]) / 2
        dr, dg, db = r - c[0], g - c[1], b - c[2]
        return (2 + rm / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rm) / 256) * db * db

    return min(paleta, key=distancia)


def quantizar(img, paleta):
    """Regra 11a: todo pixel opaco passa a ter uma cor da paleta do guia."""
    paleta = [cor(c) if isinstance(c, str) else tuple(c) for c in paleta]
    cache = {}
    dados = []
    for r, g, b, a in pixels(img.convert("RGBA")):
        if a == 0:
            dados.append((0, 0, 0, 0))
            continue
        if (r, g, b) not in cache:
            cache[(r, g, b)] = mais_perto((r, g, b), paleta)
        dados.append((*cache[(r, g, b)], a))
    out = Image.new("RGBA", img.size)
    out.putdata(dados)
    return out


def trocar_escola(img, origem, destino):
    """Troca a rampa de uma escola de magia pela de outra, do escuro ao claro.

    Os pixels que não são da rampa de origem (contorno, pedra) não mudam.
    """
    origem = [cor(c) for c in origem]
    destino = [cor(c) for c in destino]
    mapa = {c: destino[n * len(destino) // len(origem)] for n, c in enumerate(origem)}
    dados = [(*mapa.get((r, g, b), (r, g, b)), a) if a else (r, g, b, a) for r, g, b, a in pixels(img.convert("RGBA"))]
    out = Image.new("RGBA", img.size)
    out.putdata(dados)
    return out


def quadros_da_tira(img, quadro):
    largura_q, altura_q = quadro
    return [img.crop((n * largura_q, 0, (n + 1) * largura_q, altura_q)) for n in range(img.width // largura_q)]


def previa(img, escala=None, fundo=(40, 44, 60, 255)):
    if escala is None:
        escala = 8 if max(img.height, img.width // 16) <= 64 else 2
    grande = img.resize((img.width * escala, img.height * escala), Image.NEAREST)
    out = Image.new("RGBA", grande.size, fundo)
    out.alpha_composite(grande)
    return out
