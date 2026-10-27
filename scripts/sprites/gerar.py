"""Gerador de sprites com o PixelLab (spec ART-gerador).

Uso (na raiz do repositório):
    py -3 scripts/sprites/gerar.py status
    py -3 scripts/sprites/gerar.py rodar [--simular] [--maximo N]
    py -3 scripts/sprites/gerar.py aprovar <id>
    py -3 scripts/sprites/gerar.py refazer <id>
    py -3 scripts/sprites/gerar.py relimpar <id>
    py -3 scripts/sprites/gerar.py saldo
    py -3 scripts/sprites/gerar.py paleta

A chave vem da variável de ambiente PIXELLAB_API_TOKEN.
"""

import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path

from PIL import Image

import pixellab
import sprites

PASTA = Path(__file__).resolve().parent
RAIZ = PASTA.parent.parent
FILA = PASTA / "fila.json"
ASSETS = RAIZ / "game" / "assets"
TRABALHO = RAIZ / "art" / "ia"
ESTADO = TRABALHO / "estado.json"
BRUTOS = TRABALHO / "brutos"
PRONTOS = TRABALHO / "prontos"
PREVIA = TRABALHO / "previa"


# --- Arquivos -----------------------------------------------------------


def nome(item_id):
    return item_id.replace("/", "__") + ".png"


def ler_estado():
    if ESTADO.exists():
        return json.loads(ESTADO.read_text(encoding="utf-8"))
    return {}


def gravar_estado(estado):
    ESTADO.parent.mkdir(parents=True, exist_ok=True)
    tmp = ESTADO.with_suffix(".tmp")
    tmp.write_bytes(json.dumps(estado, ensure_ascii=False, indent=2).encode("utf-8"))
    tmp.replace(ESTADO)


def salvar(img, caminho):
    caminho.parent.mkdir(parents=True, exist_ok=True)
    img.save(caminho)


def chave_do_registro():
    try:
        import winreg

        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as chave:
            return str(winreg.QueryValueEx(chave, "PIXELLAB_API_TOKEN")[0]).strip()
    except OSError:
        return ""


def token():
    # Regra 15: o `setx` só aparece em processos novos; o registro tem a chave mais recente
    valor = chave_do_registro() if sys.platform == "win32" else ""
    if not valor:
        valor = os.environ.get("PIXELLAB_API_TOKEN", "").strip()
    if not valor:
        sys.exit(
            "Falta a chave do PixelLab. No PowerShell:\n"
            '  setx PIXELLAB_API_TOKEN "sua-chave"\n'
            "e abra um terminal novo."
        )
    return valor


# --- Passos -------------------------------------------------------------


def primeiro_quadro(img):
    if img.width > img.height:
        return img.crop((0, 0, img.height, img.height))
    return img


def limpar(img, paleta):
    return sprites.quantizar(sprites.binarizar(img), paleta)


def fazer_imagem(cliente, item, config):
    bruto, gasto = cliente.criar_imagem(item["prompt"], item.get("gerar", item["tamanho"]), item.get("opcoes"))
    salvar(bruto, BRUTOS / nome(item["id"]))
    if not item.get("opaco") and sprites.sem_fundo(bruto):
        raise pixellab.ErroApi("a imagem veio com fundo (os cantos são opacos); refaça o item")
    return limpar_imagem(bruto, item, config), gasto


def limpar_imagem(bruto, item, config):
    largura, altura = item["tamanho"]
    if bruto.size != (largura, altura):  # gerada maior (`gerar`): fica o meio
        x, y = (bruto.width - largura) // 2, (bruto.height - altura) // 2
        bruto = bruto.crop((x, y, x + largura, y + altura))
    img = limpar(bruto, config["paleta"])
    dx, dy = sprites.deslocamento(img, item.get("alinhar", "pes"))
    return sprites.deslocar(img, dx, dy)


def fazer_animacao(cliente, item, config):
    base = primeiro_quadro(Image.open(PRONTOS / nome(item["de"])).convert("RGBA"))
    tela, _ = sprites.para_tela(base)
    quadros, gasto = cliente.animar(tela, item["acao"], item["quadros"])
    salvar(sprites.tira(quadros), BRUTOS / nome(item["id"]))
    return limpar_quadros(quadros, base, config, item.get("inverter")), gasto


def limpar_quadros(quadros, base, config, inverter=False):
    tela, origem = sprites.para_tela(base)
    if inverter:
        quadros = list(reversed(quadros))
    limpos = []
    for q in quadros:
        if q.size != tela.size:  # a API pode devolver outra tela: centraliza
            centro = Image.new("RGBA", tela.size, (0, 0, 0, 0))
            centro.paste(q, ((tela.width - q.width) // 2, (tela.height - q.height) // 2))
            q = centro
        limpos.append(limpar(sprites.recortar(q, origem, base.size), config["paleta"]))
    return sprites.tira(limpos)


def fazer_troca(fila, item, config):
    fonte = Image.open(PRONTOS / nome(item["de"])).convert("RGBA")
    origem = config["escolas"][sprites.raiz(fila, item["id"]).get("escola")]
    return sprites.trocar_escola(fonte, origem, config["escolas"][item["escola"]]), 0


def instalar(fila, item, img):
    quadro = sprites.quadro_do_item(fila, item["id"])
    problemas = sprites.conferir(img, quadro)
    if problemas:
        raise pixellab.ErroApi(f"fora do contrato: {'; '.join(problemas)}")
    destino = ASSETS / f"{item['id']}.png"
    salvar(img, destino)
    return destino


def feito_por_mim(estado, item_id):
    return estado.get(item_id, {}).get("arquivo") is not None


def rodar_item(cliente, fila, item, config, estado):
    i = item["id"]
    destino = ASSETS / f"{i}.png"
    if sprites.instalavel(item) and destino.exists() and not feito_por_mim(estado, i):
        estado[i] = {"situacao": "pulado", "motivo": "já existe arte em game/assets (não sobrescrevo)"}
        print(f"  {i}: já existe {destino.relative_to(RAIZ)}; pulei")
        return
    tipo = item["tipo"]
    if tipo == "imagem":
        img, gasto = fazer_imagem(cliente, item, config)
    elif tipo == "animacao":
        img, gasto = fazer_animacao(cliente, item, config)
    else:
        img, gasto = fazer_troca(fila, item, config)
    salvar(img, PRONTOS / nome(i))
    salvar(sprites.previa(img), PREVIA / nome(i))
    registro = {
        "situacao": "revisar" if item.get("aprovar") else "pronto",
        "gasto": gasto if gasto is not None else sprites.custo(item),
        "quando": datetime.now().isoformat(timespec="seconds"),
        "previa": str((PREVIA / nome(i)).relative_to(RAIZ)),
        "arquivo": None,
    }
    if sprites.instalavel(item):
        registro["arquivo"] = str(instalar(fila, item, img).relative_to(RAIZ))
    estado[i] = registro
    quadros = img.width // img.height if img.height else 0
    print(f"  {i}: {registro['situacao']} ({quadros} quadro(s), gasto {registro['gasto']})")
    if item.get("aprovar"):
        print(f"    Veja {registro['previa']}. Gostou: aprovar {i}. Não gostou: refazer {i}.")


# --- Comandos -----------------------------------------------------------


def cmd_rodar(args):
    config = sprites.carregar_config(FILA)
    fila = sprites.carregar_fila(FILA)
    estado = ler_estado()
    cliente = None if args.simular else pixellab.Cliente(token())
    feitos = 0
    estimado = 0
    simulado = dict(estado)
    while args.maximo is None or feitos < args.maximo:
        item = sprites.proximo(fila, simulado if args.simular else estado)
        if item is None:
            break
        custo = sprites.custo(item)
        if args.simular:
            estimado += custo
            print(f"  {item['id']} ({item['tipo']}, ~{custo})")
            simulado[item["id"]] = {"situacao": "revisar" if item.get("aprovar") else "pronto"}
            feitos += 1
            if item.get("aprovar"):
                print(f"  (para aqui até 'aprovar {item['id']}')")
                break
            continue
        if custo > 0:
            saldo, _ = cliente.saldo()
            if not sprites.cabe_na_cota(item, saldo):
                print(f"Cota do mês no fim: restam {saldo:g} gerações e {item['id']} custa ~{custo}. Continue no mês que vem.")
                break
        try:
            rodar_item(cliente, fila, item, config, estado)
        except (pixellab.ErroApi, OSError, KeyError) as erro:
            estado[item["id"]] = {"situacao": "erro", "erro": str(erro)}
            gravar_estado(estado)
            if "heavy load" in str(erro):  # sobrecarga do PixelLab: não é cobrada; segue com os outros
                print(f"  {item['id']}: PixelLab sobrecarregado; fica para depois (refazer {item['id']})")
                feitos += 1  # a tentativa conta para o --maximo
                continue
            print(f"  {item['id']}: ERRO: {erro}\nParei. Depois de ver o erro: refazer {item['id']}.")
            return 1
        gravar_estado(estado)
        feitos += 1
        if item.get("aprovar") and sprites.situacao(estado, item["id"]) == "revisar":
            break  # o que vem depois é menos importante: espera a aprovação para não gastar cota antes
    if args.simular:
        print(f"{feitos} item(ns), ~{estimado} gerações (parando nas aprovações).")
    else:
        avisar_pendencias(fila, estado)
    return 0


def avisar_pendencias(fila, estado):
    revisar = [i["id"] for i in fila if sprites.situacao(estado, i["id"]) == "revisar"]
    if revisar:
        print("Esperando sua aprovação: " + ", ".join(revisar))
    if sprites.proximo(fila, estado) is None and not revisar:
        if all(sprites.situacao(estado, i["id"]) in sprites.FEITOS for i in fila):
            print("Fila inteira pronta.")
    print("Arte nova em game/assets: abra o Godot (ou rode --import) para importar.")


def cmd_status(_args):
    fila = sprites.carregar_fila(FILA)
    estado = ler_estado()
    gasto = 0
    for item in fila:
        s = sprites.situacao(estado, item["id"])
        gasto += estado.get(item["id"], {}).get("gasto") or 0
        extra = estado.get(item["id"], {}).get("erro") or estado.get(item["id"], {}).get("motivo") or ""
        print(f"  {s:9} {item['id']:34} ~{sprites.custo(item)} {extra}")
    restante = sum(sprites.custo(i) for i in fila if sprites.situacao(estado, i["id"]) not in sprites.FEITOS)
    print(f"Gasto até agora: {gasto:g}. Falta: ~{restante} gerações.")
    proximo = sprites.proximo(fila, estado)
    print(f"Próximo: {proximo['id'] if proximo else 'nada'}")
    return 0


def cmd_aprovar(args):
    fila = sprites.carregar_fila(FILA)
    estado = ler_estado()
    if args.id not in sprites.por_id(fila):
        sys.exit(f"{args.id} não está na fila")
    if sprites.situacao(estado, args.id) != "revisar":
        sys.exit(f"{args.id} está '{sprites.situacao(estado, args.id)}', não 'revisar'")
    estado[args.id]["situacao"] = "aprovado"
    gravar_estado(estado)
    print(f"{args.id} aprovado. Rode 'rodar' para continuar.")
    return 0


def cmd_refazer(args):
    fila = sprites.carregar_fila(FILA)
    estado = ler_estado()
    if args.id not in sprites.por_id(fila):
        sys.exit(f"{args.id} não está na fila")
    antigos = {i: dict(estado.get(i, {})) for i in sprites.dependentes(fila, args.id)}
    voltaram = sprites.refazer(fila, estado, args.id)
    for i in voltaram:  # a arte antiga sai do jogo, para o provisório voltar até a nova chegar
        arquivo = antigos[i].get("arquivo")
        if arquivo and (RAIZ / arquivo).exists():
            (RAIZ / arquivo).unlink()
    gravar_estado(estado)
    print("Voltaram para a fila: " + ", ".join(voltaram))
    return 0


def cmd_relimpar(args):
    """Refaz a limpeza (paleta, alfa, alinhamento) a partir do bruto, sem gastar geração."""
    config = sprites.carregar_config(FILA)
    fila = sprites.carregar_fila(FILA)
    estado = ler_estado()
    item = sprites.por_id(fila).get(args.id)
    if item is None or item["tipo"] == "troca_cor":
        sys.exit(f"{args.id}: só imagem ou animação da fila")
    bruto = Image.open(BRUTOS / nome(args.id)).convert("RGBA")
    if item["tipo"] == "imagem":
        img = limpar_imagem(bruto, item, config)
    else:
        base = primeiro_quadro(Image.open(PRONTOS / nome(item["de"])).convert("RGBA"))
        tela, _ = sprites.para_tela(base)
        quadro = tela.size if bruto.width % tela.width == 0 and bruto.height == tela.height \
            else (bruto.height, bruto.height)
        img = limpar_quadros(sprites.quadros_da_tira(bruto, quadro), base, config, item.get("inverter"))
    salvar(img, PRONTOS / nome(args.id))
    salvar(sprites.previa(img), PREVIA / nome(args.id))
    if sprites.instalavel(item) and feito_por_mim(estado, args.id):
        instalar(fila, item, img)
    print(f"{args.id}: limpo de novo. Veja {(PREVIA / nome(args.id)).relative_to(RAIZ)}.")
    return 0


def cmd_saldo(_args):
    restante, dados = pixellab.Cliente(token()).saldo()
    assinatura = dados.get("subscription") or {}
    print(f"Gerações: {restante:g} de {assinatura.get('total', '?')} ({assinatura.get('plan') or assinatura.get('status')})")
    return 0


def cmd_paleta(_args):
    config = sprites.carregar_config(FILA)
    img = Image.new("RGBA", (len(config["paleta"]), 1))
    for x, hexa in enumerate(config["paleta"]):
        img.putpixel((x, 0), (*sprites.cor(hexa), 255))
    salvar(img, ASSETS / "paleta.png")
    print(f"game/assets/paleta.png com {len(config['paleta'])} cores (do guia de estilo).")
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description="Gera os sprites do ArcaneSyntax com o PixelLab.")
    sub = parser.add_subparsers(dest="comando", required=True)
    rodar = sub.add_parser("rodar", help="gera os próximos itens da fila até a cota ou uma aprovação")
    rodar.add_argument("--simular", action="store_true", help="mostra o que rodaria, sem chamar a API")
    rodar.add_argument("--maximo", type=int, help="no máximo N itens nesta vez")
    rodar.set_defaults(func=cmd_rodar)
    sub.add_parser("status", help="situação de cada item").set_defaults(func=cmd_status)
    for nome_cmd, func in (("aprovar", cmd_aprovar), ("refazer", cmd_refazer), ("relimpar", cmd_relimpar)):
        p = sub.add_parser(nome_cmd)
        p.add_argument("id")
        p.set_defaults(func=func)
    sub.add_parser("saldo", help="gerações restantes no PixelLab").set_defaults(func=cmd_saldo)
    sub.add_parser("paleta", help="grava game/assets/paleta.png").set_defaults(func=cmd_paleta)
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
