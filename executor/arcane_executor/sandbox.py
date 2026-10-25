"""O que o feitiço pode usar (spec EXE-sandbox).

Modelo de ameaça: evitar acidentes e manter a fantasia, não conter um atacante
determinado. Sandbox dentro do processo Python não é à prova de ataque deliberado.
"""

import ast
import builtins

from .pieces import FeiticoProibido

MODULOS_PERMITIDOS = ("math", "random")

_LISTA_MODULOS = " e ".join(MODULOS_PERMITIDOS)

BUILTINS_PERMITIDOS = (
    "abs", "all", "any", "bin", "bool", "callable", "chr", "classmethod", "complex", "dict", "dir",
    "divmod", "enumerate", "filter", "float", "format", "frozenset", "hash", "hex", "id", "int",
    "isinstance", "issubclass", "iter", "len", "list", "map", "max", "min", "next", "object", "oct",
    "ord", "pow", "property", "range", "repr", "reversed", "round", "set", "slice", "sorted",
    "staticmethod", "str", "sum", "super", "tuple", "type", "zip",
    # Exceções que um iniciante encontra ou levanta.
    "Exception", "ArithmeticError", "AssertionError", "AttributeError", "IndexError", "KeyError",
    "LookupError", "NameError", "NotImplementedError", "OverflowError", "RecursionError",
    "RuntimeError", "StopIteration", "TypeError", "ValueError", "ZeroDivisionError",
    "NotImplemented", "Ellipsis",
)


class Violacao(Exception):
    def __init__(self, mensagem, node, tipo="FeiticoProibido"):
        super().__init__(mensagem)
        self.tipo = tipo
        self.linha = node.lineno
        self.coluna = node.col_offset + 1


def _modulo_permitido(nome):
    return nome is not None and nome.split(".")[0] in MODULOS_PERMITIDOS


class _Verificador(ast.NodeVisitor):
    def visit_Import(self, node):
        for alias in node.names:
            if not _modulo_permitido(alias.name):
                raise Violacao(f"import {alias.name} não é permitido; só {_LISTA_MODULOS} podem ser importados", node)
        self.generic_visit(node)

    def visit_ImportFrom(self, node):
        if node.level or not _modulo_permitido(node.module):
            origem = "." * node.level + (node.module or "")
            raise Violacao(f"from {origem} import não é permitido; só {_LISTA_MODULOS} podem ser importados", node)
        self.generic_visit(node)

    def visit_Name(self, node):
        if node.id.startswith("__"):
            raise Violacao(f"nomes que começam com __ são internos do Python e não podem ser usados ({node.id})", node)
        if node.id == "BaseException":
            raise Violacao("BaseException não é permitido; use except Exception", node)
        self.generic_visit(node)

    def visit_Attribute(self, node):
        if node.attr.startswith("_"):
            raise Violacao(f"atributos que começam com _ são internos e não podem ser usados (.{node.attr})", node)
        self.generic_visit(node)

    def visit_ExceptHandler(self, node):
        if node.type is None:
            raise Violacao("except sem tipo não é permitido; use except Exception", node)
        self.generic_visit(node)


def verificar(arvore):
    """Levanta Violacao na primeira coisa proibida encontrada."""
    _Verificador().visit(arvore)


def verificar_pecas(arvore, bloqueadas):
    """Levanta Violacao(PecaBloqueada) no primeiro uso, em ordem de posição, de uma peça bloqueada."""
    usos = [
        node
        for node in ast.walk(arvore)
        if isinstance(node, ast.Name) and isinstance(node.ctx, ast.Load) and node.id in bloqueadas
    ]
    if usos:
        primeiro = min(usos, key=lambda n: (n.lineno, n.col_offset))
        raise Violacao(f"você ainda não conhece {primeiro.id}", primeiro, "PecaBloqueada")


def _recusar_interno(funcao, nome):
    if isinstance(nome, str) and nome.startswith("_"):
        raise FeiticoProibido(f"{funcao}(): atributos que começam com _ são internos ({nome})")


def _getattr(obj, nome, *padrao):
    _recusar_interno("getattr", nome)
    return getattr(obj, nome, *padrao)


def _setattr(obj, nome, valor):
    _recusar_interno("setattr", nome)
    setattr(obj, nome, valor)


def _hasattr(obj, nome):
    _recusar_interno("hasattr", nome)
    return hasattr(obj, nome)


def _delattr(obj, nome):
    _recusar_interno("delattr", nome)
    delattr(obj, nome)


def _importar(nome, globais=None, locais=None, lista=(), nivel=0):
    if nivel or not _modulo_permitido(nome):
        raise FeiticoProibido(f"import {nome} não é permitido; só {_LISTA_MODULOS} podem ser importados")
    return builtins.__import__(nome, globais, locais, lista, nivel)


def builtins_do_feitico(print_capturado):
    permitidos = {nome: getattr(builtins, nome) for nome in BUILTINS_PERMITIDOS}
    permitidos.update(
        print=print_capturado,
        getattr=_getattr,
        setattr=_setattr,
        hasattr=_hasattr,
        delattr=_delattr,
        # Internos que o próprio Python usa para `import` e `class`; o jogador não alcança
        # porque nomes com __ são proibidos.
        __import__=_importar,
        __build_class__=builtins.__build_class__,
    )
    return permitidos
