"""Executa um feitiço e coleta ações, saídas, custo e erro (specs EXE-pecas, EXE-erros, EXE-custo)."""

import ast
import contextlib
import io

from . import sandbox
from .pieces import ARQUIVO_FEITICO, Contexto, LimiteDoFeitico

ESTRUTURAS = (
    ast.If, ast.For, ast.AsyncFor, ast.While, ast.With, ast.AsyncWith, ast.Try, ast.TryStar,
    ast.Match, ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef,
)
SALTOS = (ast.Return, ast.Break, ast.Continue, ast.Raise)
LACOS = (ast.For, ast.AsyncFor, ast.While)


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


def _gancho(nome, modelo):
    chamada = ast.Expr(ast.Call(ast.Name(nome, ast.Load()), [ast.Constant(modelo.lineno)], []))
    return ast.copy_location(chamada, modelo)


def _instrumentar_lista(instrucoes):
    nova = []
    for instrucao in instrucoes:
        if isinstance(instrucao, SALTOS):
            nova += [_gancho("__instrucao__", instrucao), instrucao]
        elif isinstance(instrucao, ESTRUTURAS):
            nova.append(instrucao)
        else:
            nova += [instrucao, _gancho("__instrucao__", instrucao)]
    return nova


def instrumentar(arvore):
    """Insere os ganchos de custo e de limite (EXE-custo, EXE-limites) sem mudar as linhas."""
    for node in list(ast.walk(arvore)):
        for campo, valor in ast.iter_fields(node):
            if isinstance(valor, list) and valor and isinstance(valor[0], ast.stmt):
                setattr(node, campo, _instrumentar_lista(valor))
        if isinstance(node, LACOS):
            node.body.insert(0, _gancho("__volta__", node))
    return ast.fix_missing_locations(arvore)


def run_spell(codigo, mago, alvo=None, regras=None):
    """Roda o código do jogador. Devolve {acoes, saidas, mago, custo_mana, erro}."""
    ctx = Contexto(mago, alvo, regras)

    def resultado(erro=None):
        ctx.fechar()
        return {"acoes": ctx.acoes, "saidas": ctx.saidas, "mago": ctx.mago, "custo_mana": ctx.custo_mana, "erro": erro}

    try:
        arvore = ast.parse(codigo, ARQUIVO_FEITICO)
    except SyntaxError as e:
        return resultado(_erro(type(e).__name__, e.msg, e.lineno, e.offset))

    try:
        sandbox.verificar(arvore)
    except sandbox.Violacao as e:
        return resultado(_erro("FeiticoProibido", str(e), e.linha, e.coluna))

    try:
        compilado = compile(instrumentar(arvore), ARQUIVO_FEITICO, "exec")
    except SyntaxError as e:  # ex.: `return` fora de função só é detectado aqui
        return resultado(_erro(type(e).__name__, e.msg, e.lineno, e.offset))

    def print_capturado(*args, sep=" ", end="\n", file=None, flush=False):
        ctx.registrar_saida((" " if sep is None else sep).join(str(a) for a in args))

    namespace = {"__name__": "__feitico__", "__builtins__": sandbox.builtins_do_feitico(print_capturado)}
    namespace.update(ctx.nomes_globais())
    ctx.namespace = namespace

    # Qualquer escrita direta no stdout vai para o lixo: o stdout real é o canal do protocolo.
    with contextlib.redirect_stdout(io.StringIO()):
        try:
            exec(compilado, namespace)
        except KeyboardInterrupt:
            raise
        except BaseException as e:
            limite = ctx.estouro if isinstance(e, LimiteDoFeitico) and ctx.estouro is not None else e
            linha = limite.linha if isinstance(limite, LimiteDoFeitico) else _linha_do_traceback(e)
            return resultado(_erro(type(limite).__name__, str(limite), linha))

    return resultado()
