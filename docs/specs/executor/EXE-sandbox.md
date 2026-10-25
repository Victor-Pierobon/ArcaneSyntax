# EXE-sandbox — O que o feitiço pode e não pode fazer

- **Status:** Implementada
- **Sprint:** 2
- **Relacionadas:** EXE-limites, ADR-002

## Contexto

O feitiço é Python de verdade, mas não pode mexer em arquivos, rede ou no próprio executor.

**Modelo de ameaça:** o jogador roda o próprio código na própria máquina. O objetivo é evitar acidentes e manter a fantasia, não conter um atacante determinado. Sandbox dentro do processo Python não é à prova de ataque deliberado; se um dia houver feitiços compartilhados ou modo escola, isolar no nível do sistema operacional.

## Regras

1. Antes de executar, o código passa por uma análise da árvore sintática (AST). Qualquer violação gera o erro `FeiticoProibido` com linha e coluna, e **nada** do feitiço roda.
2. **Imports:** só `math` e `random` (e seus submódulos). Imports relativos são proibidos.
3. **Nomes** que começam com `__` são internos e proibidos (`__import__`, `__builtins__`…). `_` e `_x` são permitidos.
4. **Atributos** que começam com `_` são proibidos (`x.__class__`, `alvo._id`).
5. `except:` sem tipo e o nome `BaseException` são proibidos (a mensagem sugere `except Exception:`), para os limites de EXE-limites não poderem ser capturados.
6. **Builtins** disponíveis: uma lista branca com o que um iniciante usa (`print`, `len`, `range`, `int`, `str`, `list`, `dict`, `sorted`, `min`, `max`, `sum`, `abs`, `round`, `isinstance`, `enumerate`, `zip`, exceções comuns…). Ficam de fora, entre outros, `open`, `exec`, `eval`, `compile`, `input`, `globals`, `locals`, `vars`, `breakpoint`, `memoryview`, `help`. Usá-los dá o `NameError` normal do Python.
7. `getattr`, `setattr`, `hasattr` e `delattr` recusam nomes que começam com `_` (erro `FeiticoProibido` durante a execução).
8. Definir funções, `lambda` e classes (inclusive métodos como `__init__`) é permitido.
9. **Limitação conhecida:** `"{0.__class__}".format(x)` ainda lê atributos internos como texto. Não dá acesso a objetos; aceitável para a Alpha.

## Critérios de aceite

### EXE-060 — Imports permitidos

- **Quando** o feitiço é `import math\nprint(math.floor(2.7))` ou `from random import randint\nprint(randint(1, 1))`
- **Então** a saída é `2` e `1`

### EXE-061 — Imports proibidos

- **Quando** o feitiço contém `import os`, `import sys`, `from os import path`, `import os.path` ou `from . import x`
- **Então** `erro.tipo` é `"FeiticoProibido"` com a linha do import, e a mensagem cita `math` e `random`

### EXE-062 — Nada roda quando há violação

- **Quando** o feitiço é `meditar()\nimport os`
- **Então** não há ações, e o erro aponta a linha 2

### EXE-063 — Builtins perigosos não existem

- **Quando** o feitiço usa `open`, `exec`, `eval`, `compile`, `input`, `globals`, `vars` ou `breakpoint`
- **Então** `erro.tipo` é `"NameError"`

### EXE-064 — Nomes internos

- **Quando** o feitiço usa `__import__('os')` ou `__builtins__`
- **Então** `erro.tipo` é `"FeiticoProibido"`

### EXE-065 — Atributos internos

- **Quando** o feitiço usa `().__class__`, `alvo._id` ou `print.__self__`
- **Então** `erro.tipo` é `"FeiticoProibido"` com a linha e a coluna do atributo

### EXE-066 — getattr e companhia recusam nomes internos

- **Quando** o feitiço faz `getattr(alvo, '__class__')` ou `setattr(alvo, '_id', 1)`
- **Então** `erro.tipo` é `"FeiticoProibido"`; `getattr(alvo, 'elemento')` funciona

### EXE-067 — except sem tipo e BaseException

- **Quando** o feitiço usa `except:` ou `except BaseException:`
- **Então** `erro.tipo` é `"FeiticoProibido"` e a mensagem sugere `except Exception`

### EXE-068 — O que o jogador escreve continua funcionando

- **Quando** o feitiço define funções, `lambda`, uma classe com `__init__`, usa `_` como variável e `try/except ValueError`
- **Então** tudo roda sem erro
