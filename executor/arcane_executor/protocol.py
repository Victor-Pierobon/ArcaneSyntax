"""Protocolo Godot ↔ executor, versão 1 (spec EXE-protocolo)."""

import json

from .pieces import PECAS_DESBLOQUEAVEIS
from .runner import run_spell

VERSAO = 1


class RequisicaoInvalida(Exception):
    pass


def _numero(valor):
    return isinstance(valor, (int, float)) and not isinstance(valor, bool)


def _exigir(obj, campo, valido, descricao, prefixo=""):
    if campo not in obj:
        raise RequisicaoInvalida(f"campo obrigatório ausente: {prefixo}{campo}")
    if not valido(obj[campo]):
        raise RequisicaoInvalida(f"{prefixo}{campo} precisa ser {descricao}")
    return obj[campo]


def _validar_alvo(alvo, prefixo):
    _exigir(alvo, "id", lambda v: isinstance(v, str), "texto", prefixo)
    _exigir(alvo, "elemento", lambda v: isinstance(v, str), "texto", prefixo)
    _exigir(alvo, "distancia", _numero, "um número", prefixo)
    if alvo.get("vida") is not None and not _numero(alvo["vida"]):
        raise RequisicaoInvalida(f"{prefixo}vida precisa ser um número ou null")
    if alvo.get("escudo") is not None and not isinstance(alvo["escudo"], str):
        raise RequisicaoInvalida(f"{prefixo}escudo precisa ser texto ou null")


def _validar(req):
    if req.get("versao") != VERSAO:
        raise RequisicaoInvalida(f"versão de protocolo não suportada: {req.get('versao')!r}")
    _exigir(req, "codigo", lambda v: isinstance(v, str), "texto")
    mundo = _exigir(req, "mundo", lambda v: isinstance(v, dict), "um objeto")
    mago = _exigir(mundo, "mago", lambda v: isinstance(v, dict), "um objeto", "mundo.")
    for campo in ("vida", "mana", "mana_max"):
        _exigir(mago, campo, _numero, "um número", "mundo.mago.")
    alvo = mundo.get("alvo")
    if alvo is not None:
        if not isinstance(alvo, dict):
            raise RequisicaoInvalida("mundo.alvo precisa ser um objeto ou null")
        _validar_alvo(alvo, "mundo.alvo.")
    inimigos = mundo.get("inimigos", [])
    if not isinstance(inimigos, list) or not all(isinstance(i, dict) for i in inimigos):
        raise RequisicaoInvalida("mundo.inimigos precisa ser uma lista de objetos")
    for n, inimigo in enumerate(inimigos):
        _validar_alvo(inimigo, f"mundo.inimigos[{n}].")
    sala = mundo.get("sala")
    if sala is not None:
        if not isinstance(sala, dict):
            raise RequisicaoInvalida("mundo.sala precisa ser um objeto ou null")
        runas = sala.get("runas", [])
        if not isinstance(runas, list) or not all(isinstance(v, int) and not isinstance(v, bool) for v in runas):
            raise RequisicaoInvalida("mundo.sala.runas precisa ser uma lista de números inteiros")
    pecas = req.get("pecas")
    if pecas is not None:
        if not isinstance(pecas, list) or not all(isinstance(p, str) for p in pecas):
            raise RequisicaoInvalida("pecas precisa ser uma lista de nomes")
        desconhecidas = [p for p in pecas if p not in PECAS_DESBLOQUEAVEIS]
        if desconhecidas:
            raise RequisicaoInvalida(f"peças desconhecidas em pecas: {', '.join(desconhecidas)}")
    regras = req.get("regras", {})
    if not isinstance(regras, dict) or not all(_numero(v) for v in regras.values()):
        raise RequisicaoInvalida("regras precisa ser um objeto com valores numéricos")


def _resposta(id, resultado):
    return {
        "versao": VERSAO,
        "id": id,
        "ok": resultado["erro"] is None,
        "acoes": resultado["acoes"],
        "saidas": resultado["saidas"],
        "mago": resultado["mago"],
        "custo_mana": resultado["custo_mana"],
        "erro": resultado["erro"],
    }


def _invalida(id, mensagem):
    erro = {"tipo": "RequisicaoInvalida", "mensagem": mensagem, "linha": None, "coluna": None}
    return _resposta(id, {"acoes": [], "saidas": [], "mago": None, "custo_mana": 0, "erro": erro})


def handle_request(req):
    if not isinstance(req, dict):
        return _invalida(None, "a requisição precisa ser um objeto JSON")
    id = req.get("id")
    try:
        _validar(req)
    except RequisicaoInvalida as e:
        return _invalida(id, str(e))
    mundo = req["mundo"]
    resultado = run_spell(
        req["codigo"], mundo["mago"], mundo.get("alvo"), req.get("regras"), req.get("pecas"), mundo.get("sala"),
        mundo.get("inimigos"),
    )
    return _resposta(id, resultado)


def handle_line(line):
    """Uma linha JSON de entrada → uma linha JSON de saída (sem quebra de linha)."""
    try:
        req = json.loads(line)
    except json.JSONDecodeError:
        resposta = _invalida(None, "a linha recebida não é JSON válido")
    else:
        resposta = handle_request(req)
    # ensure_ascii deixa o canal 100% ASCII, sem depender da codificação do terminal.
    return json.dumps(resposta, ensure_ascii=True)
