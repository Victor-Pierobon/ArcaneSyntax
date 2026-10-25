# EXE-pecas — Peças disponíveis para os feitiços (Alpha)

- **Status:** Implementada
- **Sprint:** 1
- **Relacionadas:** EXE-protocolo, ADR-001, GDD "Sistema de feitiços"

## Contexto

As peças são o vocabulário do jogador. Elas não fazem nada no mundo diretamente: só registram ações numa fila, com a linha que as chamou. O jogo anima a fila depois.

## Fora do escopo

Custo de mana por peça (EXE-custo). Peças bloqueadas por progressão (Sprint 5). Lista de inimigos para enxames (Sprint 10).

## Regras

1. **Elementos** são strings comuns, disponíveis como nomes prontos: `fogo`, `gelo`, `raio`. **Formas**: `projetil`, `escudo`. Por serem strings, `alvo.elemento == "fogo"` e `alvo.elemento == fogo` funcionam, e `lancar(alvo.elemento, ...)` é válido.
2. **Sentidos** são variáveis globais lidas do mundo: `mana`, `mana_max`, `vida_atual` e `alvo`. `alvo` é `None` quando não há alvo; senão tem os atributos somente-leitura `elemento` e `distancia`.
3. Os sentidos do mago são ressincronizados com o estado real **depois de cada instrução** (desde a Sprint 2, EXE-custo regra 7; antes era a cada peça). Se o jogador escrever `mana = 999`, isso não dá mana nenhuma: no fim da instrução o valor volta ao real.
4. Peças:

| Peça | Ação registrada | Efeito na simulação | Validação |
| --- | --- | --- | --- |
| `lancar(elemento, forma, alvo=None)` | `{"tipo": "lancar", "elemento", "forma", "alvo": id ou null}` | — | elemento e forma conhecidos; alvo é um alvo ou `None` |
| `mover(passos)` | `{"tipo": "mover", "passos"}` | — | número (não `bool`); passos em tiles, sinal é a direção |
| `levitar(altura)` | `{"tipo": "levitar", "altura"}` | — | número maior que 0, em tiles |
| `meditar()` | `{"tipo": "meditar"}` | mana += `ganho_meditar`, até `mana_max` | — |
| `absorver_mana()` | `{"tipo": "absorver_mana"}` | mana += `ganho_absorver`, até `mana_max` | — |

5. Validação falha com exceção Python real (`TypeError` ou `ValueError`) e mensagem em português que diz o que era esperado. A linha do erro é a do código do jogador.

## Critérios de aceite

### EXE-010 — Elementos e formas como nomes prontos

- **Dado** um feitiço `print(fogo, gelo, raio, projetil, escudo)`
- **Então** a saída é `fogo gelo raio projetil escudo`

### EXE-011 — lancar com alvo

- **Dado** um alvo `elemental_1` no mundo
- **Quando** o feitiço chama `lancar(gelo, projetil, alvo)` na linha 2
- **Então** a ação é `{"tipo": "lancar", "linha": 2, "elemento": "gelo", "forma": "projetil", "alvo": "elemental_1"}`

### EXE-012 — lancar sem alvo

- **Quando** o feitiço chama `lancar(raio, escudo)`
- **Então** a ação tem `"alvo": null`

### EXE-013 — lancar aceita o elemento lido do alvo

- **Dado** um alvo de elemento `"fogo"`
- **Quando** o feitiço chama `lancar(alvo.elemento, projetil, alvo)`
- **Então** a ação tem `"elemento": "fogo"`

### EXE-014 — lancar rejeita elemento ou forma desconhecidos

- **Quando** o feitiço chama `lancar("agua", projetil)` ou `lancar(fogo, "laser")`
- **Então** dá `ValueError` com a lista do que é válido

### EXE-015 — lancar rejeita alvo inválido

- **Quando** o feitiço chama `lancar(fogo, projetil, "elemental_1")`
- **Então** dá `TypeError`

### EXE-016 — mover

- **Quando** o feitiço chama `mover(3)` e `mover(-2)`
- **Então** registra duas ações `mover` com `passos` 3 e −2; `mover("3")` e `mover(True)` dão `TypeError`

### EXE-017 — levitar

- **Quando** o feitiço chama `levitar(4)`
- **Então** registra `{"tipo": "levitar", "altura": 4}`; `levitar(0)` dá `ValueError` e `levitar("alto")` dá `TypeError`

### EXE-018 — meditar e absorver_mana simulam a mana

- **Dado** o mago com mana 18 de 20, `ganho_meditar` 5 e `ganho_absorver` 1
- **Quando** o feitiço chama `absorver_mana()` e depois `meditar()`
- **Então** as ações são registradas e a mana final é 20 (nunca passa do máximo)

### EXE-019 — Loop sobre a mana funciona (feitiço do GDD)

- **Dado** o mago com mana 0 de 5 e `ganho_absorver` 1
- **Quando** o feitiço é `while mana < mana_max:\n    absorver_mana()`
- **Então** termina com mana 5 e todas as ações na linha 2 (são 6 ações desde a Sprint 2, porque cada volta paga 0,1; ver EXE-045)

### EXE-020 — Sentidos do mundo

- **Dado** vida 7 e um alvo de elemento `"planta"` a 3,5 tiles
- **Então** o feitiço lê `vida_atual == 7`, `alvo.elemento == "planta"` e `alvo.distancia == 3.5`

### EXE-021 — Sem alvo

- **Dado** `mundo.alvo` null
- **Então** `alvo is None` é verdadeiro no feitiço

### EXE-022 — Alvo é somente leitura

- **Quando** o feitiço faz `alvo.elemento = "gelo"`
- **Então** dá `AttributeError`

### EXE-023 — Sentidos não podem ser trapaceados

- **Dado** mana 2 de 10
- **Quando** o feitiço faz `mana = 999`, depois chama `absorver_mana()` e depois `print(mana)`
- **Então** imprime `2.8` (2 − 0,1 + 1 − 0,1) e a mana final é 2.7: o 999 nunca valeu

### EXE-024 — O feitiço adaptável do GDD roda

- **Dado** um alvo de elemento `"planta"`
- **Quando** o feitiço define `feitico_adaptavel(alvo)` como no GDD e o chama
- **Então** registra `lancar` com elemento `fogo`
