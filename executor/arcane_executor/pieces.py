"""Peças dos feitiços (spec EXE-pecas).

As peças não mexem no mundo: registram ações numa fila, com a linha do código do
jogador que as chamou. Só o estado do próprio mago é simulado aqui (ADR-001).
"""

import sys

ARQUIVO_FEITICO = "<feitico>"

ELEMENTOS = ("fogo", "gelo", "raio")
FORMAS = ("projetil", "escudo")

REGRAS_PADRAO = {"ganho_meditar": 5, "ganho_absorver": 1}


def linha_do_jogador():
    """Linha do código do jogador mais próxima na pilha de chamadas."""
    frame = sys._getframe(1)
    while frame is not None:
        if frame.f_code.co_filename == ARQUIVO_FEITICO:
            return frame.f_lineno
        frame = frame.f_back
    return None


def _exigir_numero(nome_peca, nome_param, valor):
    if isinstance(valor, bool) or not isinstance(valor, (int, float)):
        raise TypeError(f"{nome_peca}() precisa de um número em '{nome_param}', recebeu {valor!r}")


class Alvo:
    """O que o mago está mirando. Somente leitura."""

    __slots__ = ("_id", "_elemento", "_distancia")

    def __init__(self, id, elemento, distancia):
        object.__setattr__(self, "_id", id)
        object.__setattr__(self, "_elemento", elemento)
        object.__setattr__(self, "_distancia", distancia)

    @property
    def elemento(self):
        return self._elemento

    @property
    def distancia(self):
        return self._distancia

    def __setattr__(self, nome, valor):
        raise AttributeError(f"o alvo é somente leitura: não dá para mudar '{nome}'")

    def __repr__(self):
        return f"Alvo(elemento={self._elemento!r}, distancia={self._distancia!r})"


class Contexto:
    """Estado de uma execução: fila de ações, saídas e o mago simulado."""

    def __init__(self, mago, alvo, regras=None):
        self.mago = dict(mago)
        self.alvo = Alvo(alvo["id"], alvo["elemento"], alvo["distancia"]) if alvo else None
        self.regras = {**REGRAS_PADRAO, **(regras or {})}
        self.acoes = []
        self.saidas = []
        self.namespace = None

    def nomes_globais(self):
        """Peças, constantes e sentidos que o feitiço enxerga como variáveis globais."""
        nomes = {nome: nome for nome in ELEMENTOS + FORMAS}
        nomes.update(
            lancar=self.lancar,
            mover=self.mover,
            levitar=self.levitar,
            meditar=self.meditar,
            absorver_mana=self.absorver_mana,
            alvo=self.alvo,
        )
        nomes.update(self._sentidos())
        return nomes

    def _sentidos(self):
        return {"mana": self.mago["mana"], "mana_max": self.mago["mana_max"], "vida_atual": self.mago["vida"]}

    def sincronizar(self):
        """Devolve aos sentidos o valor real, desfazendo atribuições do jogador (EXE-023)."""
        if self.namespace is not None:
            self.namespace.update(self._sentidos())

    def registrar(self, tipo, **dados):
        self.acoes.append({"tipo": tipo, "linha": linha_do_jogador(), **dados})
        self.sincronizar()

    def _ganhar_mana(self, quantidade):
        self.mago["mana"] = min(self.mago["mana"] + quantidade, self.mago["mana_max"])

    # --- peças ---

    def lancar(self, elemento, forma, alvo=None):
        if elemento not in ELEMENTOS or not isinstance(elemento, str):
            raise ValueError(f"lancar(): {elemento!r} não é um elemento conhecido; use um destes: {', '.join(ELEMENTOS)}")
        if forma not in FORMAS or not isinstance(forma, str):
            raise ValueError(f"lancar(): {forma!r} não é uma forma conhecida; use uma destas: {', '.join(FORMAS)}")
        if alvo is not None and not isinstance(alvo, Alvo):
            raise TypeError(f"lancar(): o alvo precisa ser 'alvo' ou None, recebeu {alvo!r}")
        self.registrar("lancar", elemento=elemento, forma=forma, alvo=alvo._id if alvo else None)

    def mover(self, passos):
        _exigir_numero("mover", "passos", passos)
        self.registrar("mover", passos=passos)

    def levitar(self, altura):
        _exigir_numero("levitar", "altura", altura)
        if altura <= 0:
            raise ValueError(f"levitar(): a altura precisa ser maior que 0, recebeu {altura!r}")
        self.registrar("levitar", altura=altura)

    def meditar(self):
        self._ganhar_mana(self.regras["ganho_meditar"])
        self.registrar("meditar")

    def absorver_mana(self):
        self._ganhar_mana(self.regras["ganho_absorver"])
        self.registrar("absorver_mana")
