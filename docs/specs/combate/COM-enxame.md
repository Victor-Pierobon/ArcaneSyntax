# COM-enxame — Enxame

- **Status:** Implementada
- **Sprint:** 10
- **Relacionadas:** COM-dano, EXE-pecas (`inimigos`, `faisca`), EXE-custo, MAG-formas (faísca), ADR-001

## Contexto

Muitos inimigos pequenos ao mesmo tempo ensinam a repetir uma ação sobre uma lista: `for inimigo in inimigos: lancar(raio, faisca, inimigo)`. Pelo ADR-001, o feitiço não vê os inimigos morrendo, então `while inimigo.vivo:` não funciona: o loop percorre a lista da foto. Com mana máxima 10, um loop de projéteis (3 cada) não cabe; a **faísca** (custo 1, decisão do Victor) é a ferramenta certa para o enxame.

## Fora do escopo

Enxames que se dividem ou chamam reforço.

## Regras

1. Em `targets`: `inimigo:enxame[:<n>]` cria `n` bichos (padrão **6**, de 1 a 9) em volta da célula. Cada um é um inimigo com id próprio (COM-dano, regra 8).
2. Cada bicho: elemento **gelo**, vida **2**, dano de contato **1**. A faísca de raio (2) derruba um bicho por golpe; o projétil também (3 ou mais); a faísca de outros elementos precisa de dois golpes (a de gelo não faz nada); o cajado, de dois.
3. Os bichos **voam**: sem gravidade e sem colidir com as paredes.
4. **Comportamento** (`SwarmBugBrain`, regra pura, um por bicho):
   - **Pairando:** dá voltas de raio **1,5 tiles** em torno da casa (a célula do dígito), uma volta a cada 2 s, cada bicho com a sua fase.
   - **Mergulho:** quando o mago está a até **7 tiles** da casa, voa reto na direção dele a **70 px/s**.
   - **Recuo:** depois de morder (contato com o mago), volta para a casa a 70 px/s e só pode mergulhar de novo depois de **1,5 s**.
   - Na casa, sem o mago no alcance, volta a pairar.

## Critérios de aceite

### COM-040 — Pairando

- **Dado** um bicho sem o mago por perto
- **Então** fica sempre a 1,5 tile da casa (com folga de 1 px) e dá uma volta em 2 s

### COM-041 — Mergulho

- **Dado** o mago a 6 tiles da casa
- **Então** o bicho voa na direção do mago a 70 px/s; com o mago a 8 tiles, continua pairando

### COM-042 — Recuo

- **Dado** o bicho mergulhando
- **Quando** morde o mago
- **Então** volta para a casa e não mergulha de novo antes de 1,5 s, mesmo com o mago perto

### COM-043 — Bichos do enxame

- **Dado** `targets = {"4": "inimigo:enxame:5"}`
- **Então** a sala tem 5 bichos de gelo com vida 2 e ids `<sala>_alvo_4_1` a `<sala>_alvo_4_5`; `inimigo:enxame:0` e `inimigo:enxame:12` são erros de autoria

### COM-044 — Encontro com Python real (aceitação, `sala_c02`)

- **Dado** a sala do enxame (6 bichos) e o mago com mana 10, a 9 tiles
- **Quando** conjura `for inimigo in inimigos:\n    lancar(raio, faisca, inimigo)`
- **Então** os 6 bichos são derrotados numa conjuração só, que custa 6,7 de mana
- **E** o mesmo loop com `projetil` derrota 3 e para com `ManaEsgotada` (as ações anteriores acontecem)

## Exemplos

| Feitiço (mana 10) | Custo | Resultado |
| --- | --- | --- |
| `for inimigo in inimigos: lancar(raio, faisca, inimigo)` (2 linhas) | 1,2 + 5 × 1,1 = 6,7 | 6 derrotados |
| o mesmo com `projetil` | 3,2 + 3,1 + 3,1 = 9,4, e o 4º não cabe | 3 derrotados, `ManaEsgotada` |
| 6 linhas `lancar(raio, faisca, inimigos[i])` | 6 × 1,2 = 7,2 | 6 derrotados, mas mais caro que o loop |

## Perguntas em aberto

- [ ] Seis bichos mergulhando juntos é demais no cajado? (playtest)
