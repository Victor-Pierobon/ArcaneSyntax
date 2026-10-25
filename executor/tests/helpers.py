from arcane_executor.protocol import handle_request

MAGO_PADRAO = {"vida": 10, "mana": 5, "mana_max": 20}


def requisicao(codigo, mago=None, alvo=None, regras=None, id=1, sala=None):
    req = {
        "versao": 1,
        "id": id,
        "codigo": codigo,
        "mundo": {"mago": dict(mago or MAGO_PADRAO), "alvo": alvo},
    }
    if sala is not None:
        req["mundo"]["sala"] = sala
    if regras is not None:
        req["regras"] = regras
    return req


def run(codigo, **kwargs):
    return handle_request(requisicao(codigo, **kwargs))


def acoes(resposta, tipo=None):
    return [a for a in resposta["acoes"] if tipo is None or a["tipo"] == tipo]
