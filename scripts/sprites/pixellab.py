"""Cliente mínimo da API v2 do PixelLab (só a biblioteca padrão)."""

import base64
import io
import json
import time
import urllib.error
import urllib.request

from PIL import Image

BASE = "https://api.pixellab.ai/v2"


class ErroApi(Exception):
    pass


class Cliente:
    def __init__(self, token, espera=5.0, limite=900.0):
        self.token = token
        self.espera = espera
        self.limite = limite

    def _pedir(self, metodo, caminho, corpo=None):
        dados = json.dumps(corpo).encode("utf-8") if corpo is not None else None
        req = urllib.request.Request(BASE + caminho, data=dados, method=metodo)
        req.add_header("Authorization", f"Bearer {self.token}")
        req.add_header("Accept", "application/json")
        req.add_header("User-Agent", "ArcaneSyntax-sprites/1")
        if dados is not None:
            req.add_header("Content-Type", "application/json")
        try:
            with urllib.request.urlopen(req, timeout=180) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as erro:
            texto = erro.read().decode("utf-8", "replace")[:600]
            raise ErroApi(f"HTTP {erro.code} em {caminho}: {texto}") from None
        except urllib.error.URLError as erro:
            raise ErroApi(f"sem conexão com o PixelLab: {erro.reason}") from None

    def saldo(self):
        """Gerações restantes da assinatura (os créditos em dólar não são usados)."""
        dados = self._pedir("GET", "/balance")
        assinatura = dados.get("subscription") or {}
        return float(assinatura.get("generations") or 0), dados

    def criar_imagem(self, descricao, tamanho, opcoes):
        corpo = {
            "description": descricao,
            "image_size": {"width": tamanho[0], "height": tamanho[1]},
            "no_background": True,
            "view": "side",
            "direction": "east",
            "outline": "single color outline",
            "detail": "medium detail",
        }
        for chave, valor in (opcoes or {}).items():
            if valor is None:
                corpo.pop(chave, None)
            else:
                corpo[chave] = valor
        dados = self._pedir("POST", "/create-image-pixen", corpo)
        return imagem(dados["image"]), gasto(dados)

    def animar(self, primeiro, acao, quadros):
        corpo = {
            "first_frame": para_base64(primeiro),
            "action": acao,
            "frame_count": quadros,
            "no_background": True,
        }
        dados = self._pedir("POST", "/animate-with-text-v3", corpo)
        trabalho = self.esperar(dados["background_job_id"])
        resposta = trabalho.get("last_response") or {}
        imagens = [imagem(i) for i in resposta.get("images") or []]
        if not imagens:
            raise ErroApi(f"a animação voltou sem quadros: {json.dumps(resposta)[:400]}")
        return imagens, gasto(trabalho) or gasto(dados)

    def esperar(self, trabalho_id):
        inicio = time.monotonic()
        while True:
            dados = self._pedir("GET", f"/background-jobs/{trabalho_id}")
            situacao = dados.get("status")
            if situacao == "completed":
                return dados
            if situacao == "failed":
                raise ErroApi(f"o trabalho falhou: {json.dumps(dados.get('last_response'))[:400]}")
            if time.monotonic() - inicio > self.limite:
                raise ErroApi(f"o trabalho {trabalho_id} passou de {self.limite:.0f} s; veja no site do PixelLab")
            time.sleep(self.espera)


def gasto(dados):
    uso = (dados or {}).get("usage") or {}
    return uso.get("generations")


def imagem(obj):
    if isinstance(obj, dict):
        texto = obj.get("base64") or obj.get("image") or ""
    else:
        texto = obj
    if "," in texto[:64] and texto.startswith("data:"):
        texto = texto.split(",", 1)[1]
    return Image.open(io.BytesIO(base64.b64decode(texto))).convert("RGBA")


def para_base64(img):
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    return {"type": "base64", "base64": base64.b64encode(buffer.getvalue()).decode("ascii"), "format": "png"}
