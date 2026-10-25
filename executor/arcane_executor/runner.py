"""Executa um feitiço e coleta ações, saídas e erro (specs EXE-pecas e EXE-erros)."""

import builtins
import contextlib
import io

from .pieces import ARQUIVO_FEITICO, Contexto, linha_do_jogador


def _erro(tipo, mensagem, linha, coluna=None):
    return {"tipo": tipo, "mensagem": mensagem, "linha": linha, "coluna": coluna}


def _linha_do_traceback(exc):
    linha = None
    tb = exc.__traceback__
    while tb is not None:
        if tb.tb_frame.f_code.co_filename == ARQUIVO_FEITICO:
            linha = tb.tb_lineno
        tb = tb.tb_next
    return linha


def _builtins_do_feitico(ctx):
    def print_capturado(*args, sep=" ", end="\n", file=None, flush=False):
        texto = (" " if sep is None else sep).join(str(a) for a in args)
        ctx.saidas.append({"linha": linha_do_jogador(), "texto": texto})

    feitico_builtins = dict(vars(builtins))
    feitico_builtins["print"] = print_capturado
    return feitico_builtins


def run_spell(codigo, mago, alvo=None, regras=None):
    """Roda o código do jogador. Devolve {acoes, saidas, mago, erro}."""
    ctx = Contexto(mago, alvo, regras)

    def resultado(erro=None):
        return {"acoes": ctx.acoes, "saidas": ctx.saidas, "mago": ctx.mago, "erro": erro}

    try:
        compilado = compile(codigo, ARQUIVO_FEITICO, "exec")
    except SyntaxError as e:
        return resultado(_erro(type(e).__name__, e.msg, e.lineno, e.offset))

    namespace = {"__name__": "__feitico__", "__builtins__": _builtins_do_feitico(ctx)}
    namespace.update(ctx.nomes_globais())
    ctx.namespace = namespace

    # Qualquer escrita direta no stdout vai para o lixo: o stdout real é o canal do protocolo.
    with contextlib.redirect_stdout(io.StringIO()):
        try:
            exec(compilado, namespace)
        except (Exception, SystemExit) as e:
            return resultado(_erro(type(e).__name__, str(e), _linha_do_traceback(e)))

    return resultado()
