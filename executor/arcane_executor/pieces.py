"""Peças dos feitiços e contabilidade de mana (specs EXE-pecas, EXE-custo, EXE-limites).

As peças não mexem no mundo: registram ações numa fila, com a linha do código do
jogador que as chamou. Só o estado do próprio mago é simulado aqui (ADR-001).
"""

import sys
import time

ARQUIVO_FEITICO = "<feitico>"

ELEMENTOS = ("fogo", "gelo", "raio")
FORMAS = ("projetil", "escudo")
ACOES = ("lancar", "mover", "levitar", "meditar", "absorver_mana", "inscrever", "construir_bloco")
# Peças sujeitas a desbloqueio (spec EXE-desbloqueio); os sentidos ficam sempre disponíveis.
PECAS_DESBLOQUEAVEIS = ACOES + ELEMENTOS + FORMAS

REGRAS_PADRAO = {
    "ganho_meditar": 5,
    "ganho_absorver": 1,
    "custo_instrucao": 0.1,
    "custo_inscricao": 0.1,
    "custo_lancar": 3,
    "custo_mover": 1,
    "custo_levitar": 2,
    "custo_meditar": 0,
    "custo_absorver": 0,
    "custo_inscrever": 1,
    "custo_bloco": 0.5,
    "limite_tempo_ms": 1000,
}

MAX_ACOES = 1000
MAX_SAIDAS = 200
MAX_TEXTO = 500

# A mana é guardada em décimos inteiros ("gotas") para não acumular erro de float.
GOTAS_POR_MANA = 10


def para_gotas(mana):
    return round(mana * GOTAS_POR_MANA)


def para_mana(gotas):
    return gotas // GOTAS_POR_MANA if gotas % GOTAS_POR_MANA == 0 else gotas / GOTAS_POR_MANA


class LimiteDoFeitico(BaseException):
    """Base dos limites. Herda de BaseException para `except Exception` não capturar (EXE-053)."""

    def __init__(self, mensagem, linha):
        super().__init__(mensagem)
        self.linha = linha


class ManaEsgotada(LimiteDoFeitico):
    pass


class TempoEsgotado(LimiteDoFeitico):
    pass


class LimiteExcedido(LimiteDoFeitico):
    pass


class FeiticoProibido(Exception):
    """Uso de algo que o sandbox não permite, detectado durante a execução."""


class PecaBloqueada(Exception):
    """Peça que o jogador ainda não desbloqueou, detectada durante a execução (EXE-083)."""


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
    """Estado de uma execução: fila de ações, saídas, mago simulado e mana gasta."""

    def __init__(self, mago, alvo, regras=None, pecas=None, sala=None):
        regras = {**REGRAS_PADRAO, **(regras or {})}
        self.bloqueadas = set() if pecas is None else set(PECAS_DESBLOQUEAVEIS) - set(pecas)
        self.vida = mago["vida"]
        self.gotas = para_gotas(mago["mana"])
        self.gotas_max = para_gotas(mago["mana_max"])
        self.gasto = 0
        self.ganho = {"meditar": para_gotas(regras["ganho_meditar"]), "absorver": para_gotas(regras["ganho_absorver"])}
        self.custo = {
            "instrucao": para_gotas(regras["custo_instrucao"]),
            "inscricao": para_gotas(regras["custo_inscricao"]),
            "lancar": para_gotas(regras["custo_lancar"]),
            "mover": para_gotas(regras["custo_mover"]),
            "levitar": para_gotas(regras["custo_levitar"]),
            "meditar": para_gotas(regras["custo_meditar"]),
            "absorver": para_gotas(regras["custo_absorver"]),
            "inscrever": para_gotas(regras["custo_inscrever"]),
            "bloco": para_gotas(regras["custo_bloco"]),
        }
        # Linhas que já pagaram a inscrição nesta execução (EXE-custo, regra 13).
        self.inscritas = set()
        self.limite_tempo = regras["limite_tempo_ms"] / 1000
        self.inicio = time.perf_counter()
        self.alvo = Alvo(alvo["id"], alvo["elemento"], alvo["distancia"]) if alvo else None
        self.runas = tuple((sala or {}).get("runas") or ())
        self.acoes = []
        self.saidas = []
        self.namespace = None
        # Depois de um limite estourar, todo gancho seguinte relança o mesmo erro.
        self.estouro = None

    @property
    def mago(self):
        return {"vida": self.vida, "mana": para_mana(self.gotas), "mana_max": para_mana(self.gotas_max)}

    @property
    def custo_mana(self):
        return para_mana(self.gasto)

    def nomes_globais(self):
        """Peças, constantes, sentidos e ganchos que o feitiço enxerga como variáveis globais."""
        nomes = {nome: nome for nome in ELEMENTOS + FORMAS}
        nomes.update(
            lancar=self.lancar,
            mover=self.mover,
            levitar=self.levitar,
            meditar=self.meditar,
            absorver_mana=self.absorver_mana,
            inscrever=self.inscrever,
            construir_bloco=self.construir_bloco,
            ler_runa=self.ler_runa,
            alvo=self.alvo,
            __instrucao__=self.instrucao,
            __volta__=self.volta,
        )
        nomes.update(self._sentidos())
        return nomes

    def _sentidos(self):
        return {"mana": para_mana(self.gotas), "mana_max": para_mana(self.gotas_max), "vida_atual": self.vida}

    def sincronizar(self):
        """Devolve aos sentidos o valor real, desfazendo atribuições do jogador (EXE-023)."""
        if self.namespace is not None:
            self.namespace.update(self._sentidos())

    # --- limites e custo ---

    def _estourar(self, erro):
        self.estouro = erro
        raise erro

    def _conferir(self, linha):
        if self.estouro is not None:
            raise type(self.estouro)(str(self.estouro), self.estouro.linha)
        if time.perf_counter() - self.inicio > self.limite_tempo:
            ms = round(self.limite_tempo * 1000)
            self._estourar(TempoEsgotado(f"o feitiço passou do limite de {ms} ms", linha))

    def _pagar(self, gotas, linha, o_que):
        if gotas > self.gotas:
            self._estourar(
                ManaEsgotada(
                    f"a mana acabou na linha {linha}: {o_que} custava {para_mana(gotas)} "
                    f"e restavam {para_mana(self.gotas)}",
                    linha,
                )
            )
        self.gotas -= gotas
        self.gasto += gotas

    def instrucao(self, linha):
        """Gancho inserido depois de cada instrução simples (antes de return/break/continue/raise)."""
        self._conferir(linha)
        custo = self.custo["instrucao"] + (0 if linha in self.inscritas else self.custo["inscricao"])
        self._pagar(custo, linha, "a instrução")
        self.inscritas.add(linha)
        self.gotas = min(self.gotas, self.gotas_max)
        self.sincronizar()

    def volta(self, linha):
        """Gancho grátis no início de cada volta de laço: só confere os limites (EXE-052)."""
        self._conferir(linha)

    def fechar(self):
        """Fim da execução: aplica o teto da mana mesmo se a última instrução não pagou."""
        self.gotas = min(self.gotas, self.gotas_max)

    def registrar(self, tipo, **dados):
        linha = linha_do_jogador()
        if len(self.acoes) >= MAX_ACOES:
            self._estourar(LimiteExcedido(f"o feitiço passou do limite de {MAX_ACOES} ações", linha))
        self.acoes.append({"tipo": tipo, "linha": linha, **dados})

    def registrar_saida(self, texto):
        linha = linha_do_jogador()
        if len(self.saidas) >= MAX_SAIDAS:
            self._estourar(LimiteExcedido(f"o feitiço passou do limite de {MAX_SAIDAS} visões (print)", linha))
        if len(texto) > MAX_TEXTO:
            texto = texto[: MAX_TEXTO - 1] + "…"
        self.saidas.append({"linha": linha, "texto": texto})

    def _cobrar_peca(self, peca):
        linha = linha_do_jogador()
        self._conferir(linha)
        self._pagar(self.custo[peca], linha, f"{peca}()")

    # --- peças ---

    def lancar(self, elemento, forma, alvo=None):
        if elemento not in ELEMENTOS or not isinstance(elemento, str):
            raise ValueError(f"lancar(): {elemento!r} não é um elemento conhecido; use um destes: {', '.join(ELEMENTOS)}")
        if forma not in FORMAS or not isinstance(forma, str):
            raise ValueError(f"lancar(): {forma!r} não é uma forma conhecida; use uma destas: {', '.join(FORMAS)}")
        if alvo is not None and not isinstance(alvo, Alvo):
            raise TypeError(f"lancar(): o alvo precisa ser 'alvo' ou None, recebeu {alvo!r}")
        for peca in (elemento, forma):
            if peca in self.bloqueadas:
                raise PecaBloqueada(f"você ainda não conhece {peca}")
        self._cobrar_peca("lancar")
        self.registrar("lancar", elemento=elemento, forma=forma, alvo=alvo._id if alvo else None)

    def mover(self, passos):
        _exigir_numero("mover", "passos", passos)
        self._cobrar_peca("mover")
        self.registrar("mover", passos=passos)

    def levitar(self, altura):
        _exigir_numero("levitar", "altura", altura)
        if altura <= 0:
            raise ValueError(f"levitar(): a altura precisa ser maior que 0, recebeu {altura!r}")
        self._cobrar_peca("levitar")
        self.registrar("levitar", altura=altura)

    def meditar(self):
        self._cobrar_peca("meditar")
        self.gotas += self.ganho["meditar"]
        self.registrar("meditar")

    def absorver_mana(self):
        self._cobrar_peca("absorver")
        self.gotas += self.ganho["absorver"]
        self.registrar("absorver_mana")

    # --- peças dos puzzles (Sprint 9) ---

    def ler_runa(self, n):
        if isinstance(n, bool) or not isinstance(n, int):
            raise TypeError(f"ler_runa() precisa do número da runa (1, 2, 3...), recebeu {n!r}")
        if not self.runas:
            raise ValueError("não há runas nesta sala")
        if not 1 <= n <= len(self.runas):
            raise ValueError(f"ler_runa(): a sala tem {len(self.runas)} runas; use um número de 1 a {len(self.runas)}, recebeu {n}")
        return self.runas[n - 1]

    def inscrever(self, valor):
        _exigir_numero("inscrever", "valor", valor)
        self._cobrar_peca("inscrever")
        self.registrar("inscrever", valor=valor)

    def construir_bloco(self):
        self._cobrar_peca("bloco")
        self.registrar("construir_bloco")
