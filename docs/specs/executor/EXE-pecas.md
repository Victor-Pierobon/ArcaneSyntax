# EXE-pecas — Peças disponíveis para os feitiços (Alpha)

- **Status:** Implementada
- **Sprint:** 1, 9, 10
- **Relacionadas:** EXE-protocolo, ADR-001, PUZ-02-runas, PUZ-04-ponte, COM-dano, COM-enxame, COM-guardiao, GDD "Sistema de feitiços"

## Contexto

As peças são o vocabulário do jogador. Elas não fazem nada no mundo diretamente: só registram ações numa fila, com a linha que as chamou. O jogo anima a fila depois.

## Fora do escopo

Custo de mana por peça (EXE-custo). Peças bloqueadas por progressão (Sprint 5).

## Regras

1. **Elementos** são strings comuns, disponíveis como nomes prontos: `fogo`, `gelo`, `raio`. **Formas**: `projetil`, `escudo` e, desde a Sprint 10, `faisca`. Por serem strings, `alvo.elemento == "fogo"` e `alvo.elemento == fogo` funcionam, e `lancar(alvo.elemento, ...)` é válido.
2. **Sentidos** são variáveis globais lidas do mundo: `mana`, `mana_max`, `vida_atual`, `alvo` e, desde a Sprint 10, `inimigos`. `alvo` é `None` quando não há alvo; senão tem os atributos somente-leitura `elemento`, `distancia`, `vida` e `escudo` (os dois últimos valem `None` quando a foto não os traz, como nos bonecos).
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

### Peças dos puzzles (Sprint 9)

6. **Runas.** A foto do mundo pode trazer as runas da sala (`mundo.sala.runas`, EXE-protocolo), uma lista de números em ordem da esquerda para a direita. O sentido `ler_runa(n)` devolve o valor da runa `n`, **contando a partir de 1**, como o jogador as vê na sala. Ele não registra ação e não custa nada além da instrução.
7. Peças novas:

   | Peça | Ação registrada | Efeito na simulação | Validação |
   | --- | --- | --- | --- |
   | `ler_runa(n)` | — (sentido) | devolve o número | `n` inteiro (não `bool`), `TypeError`; fora de 1..quantidade, `ValueError` com a quantidade de runas; sala sem runas, `ValueError` "não há runas nesta sala" |
   | `inscrever(valor)` | `{"tipo": "inscrever", "valor"}` | — | número (não `bool`) |
   | `construir_bloco()` | `{"tipo": "construir_bloco"}` | — | — |

8. O executor **não sabe** se o cadeado abre ou se a ponte já está pronta: ele só registra as ações. Quem decide é o jogo, pelo estado do mundo (PUZ-validacao).
9. `inscrever` e `construir_bloco` estão sujeitas a desbloqueio (EXE-desbloqueio). `ler_runa` é um sentido e está sempre disponível.

### Peças de combate (Sprint 10)

10. `inimigos` é uma lista (`list`) de alvos, na ordem da foto (`mundo.inimigos`, do mais perto para o mais longe; COM-dano, regra 6). Sem inimigos, é a lista vazia. Cada item tem os mesmos atributos somente-leitura do `alvo` e serve de alvo para `lancar`. A lista é nova a cada execução: mexer nela (`inimigos.clear()`, `inimigos = []`) só engana o próprio feitiço.
11. Se o `alvo` tem o mesmo `id` de um item de `inimigos`, os dois são **o mesmo objeto** (`alvo is inimigos[0]` quando o alvo é o inimigo mais perto).
12. O executor não sabe quanto de vida sobra depois de um golpe: `inimigo.vida` é a da foto até o fim da execução (ADR-001). Por isso `while inimigo.vida > 0:` gasta a mana toda e termina em `ManaEsgotada`.
13. `faisca` é uma forma como as outras: `lancar(raio, faisca, alvo)` registra `{"tipo": "lancar", ..., "forma": "faisca"}` e custa `custo_faisca` (EXE-custo).

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
- **Então** imprime `2.6` (2 − 0,2 + 1 − 0,2, com a inscrição da Sprint 9) e a mana final é 2.4: o 999 nunca valeu

### EXE-024 — O feitiço adaptável do GDD roda

- **Dado** um alvo de elemento `"planta"`
- **Quando** o feitiço define `feitico_adaptavel(alvo)` como no GDD e o chama
- **Então** registra `lancar` com elemento `fogo`

### EXE-100 — ler_runa lê a sala

- **Dado** `mundo.sala.runas` `[4, 7, 2]`
- **Quando** o feitiço é `a = ler_runa(1)\nb = ler_runa(3)\nprint(a + b)`
- **Então** a saída é `6` e não há ações

### EXE-101 — ler_runa fora da sala

- **Dado** `mundo.sala.runas` `[4, 7, 2]`
- **Então** `ler_runa(0)` e `ler_runa(4)` dão `ValueError` com a mensagem citando as 3 runas; `ler_runa("1")` e `ler_runa(True)` dão `TypeError`

### EXE-102 — Sala sem runas

- **Dado** uma requisição sem `mundo.sala`, ou com `sala.runas` vazia
- **Quando** o feitiço chama `ler_runa(1)`
- **Então** dá `ValueError` "não há runas nesta sala"

### EXE-103 — inscrever

- **Quando** o feitiço chama `inscrever(13)` na linha 1
- **Então** a ação é `{"tipo": "inscrever", "linha": 1, "valor": 13}`; `inscrever("13")` e `inscrever(True)` dão `TypeError`

### EXE-104 — construir_bloco

- **Quando** o feitiço chama `construir_bloco()` duas vezes
- **Então** registra duas ações `{"tipo": "construir_bloco"}`, cada uma com a sua linha

### EXE-105 — As runas não podem ser trapaceadas

- **Dado** `mundo.sala.runas` `[4, 7, 2]`
- **Quando** o feitiço faz `ler_runa = lambda n: 99` e depois `inscrever(ler_runa(1))`
- **Então** a ação registra `valor` 99: trocar a peça só engana o próprio feitiço, e o cadeado continua julgando pelo valor certo (PUZ-02)

### EXE-120 — inimigos lê a foto

- **Dado** `mundo.inimigos` com `a` (fogo, 3 tiles, vida 12) e `b` (gelo, 5 tiles, vida 2)
- **Quando** o feitiço é `print(len(inimigos), inimigos[0].elemento, inimigos[1].vida)`
- **Então** a saída é `2 fogo 2`

### EXE-121 — Sem inimigos

- **Dado** uma requisição sem `mundo.inimigos`
- **Então** `inimigos == []` é verdadeiro, e `for inimigo in inimigos:\n    lancar(raio, faisca, inimigo)` não registra nada

### EXE-122 — Loop sobre os inimigos

- **Dado** três inimigos `a`, `b`, `c`
- **Quando** o feitiço é `for inimigo in inimigos:\n    lancar(raio, faisca, inimigo)`
- **Então** registra três ações `lancar` na linha 2, com `alvo` `a`, `b` e `c`, nessa ordem

### EXE-123 — vida e escudo

- **Dado** o alvo `{"id": "g", "elemento": "pedra", "distancia": 4, "vida": 18, "escudo": "planta"}`
- **Então** `alvo.vida == 18` e `alvo.escudo == "planta"`; um alvo sem esses campos tem `vida` e `escudo` `None`; `alvo.escudo = "fogo"` dá `AttributeError`

### EXE-124 — alvo e inimigos são o mesmo objeto

- **Dado** o alvo com id `a` e `inimigos` começando por `a`
- **Então** `alvo is inimigos[0]` é verdadeiro

### EXE-125 — faísca

- **Quando** o feitiço chama `lancar(raio, faisca, alvo)`
- **Então** a ação tem `"forma": "faisca"`; `lancar(raio, "faísca")`, com acento, dá `ValueError` com a lista das formas

### EXE-126 — A vida não muda durante o feitiço

- **Dado** um inimigo com vida 2 e mana 10
- **Quando** o feitiço é `while inimigos[0].vida > 0:\n    lancar(raio, faisca, inimigos[0])`
- **Então** registra 9 ações e dá `ManaEsgotada` na linha 2
