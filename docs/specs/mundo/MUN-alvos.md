# MUN-alvos — Alvos de treino e o "alvo" dos feitiços

- **Status:** Implementada
- **Sprint:** 5
- **Relacionadas:** MUN-salas, GRI-conjurar, EXE-pecas (`alvo`); Sprint 10 (inimigos de verdade)

## Contexto

Feitiços como `lancar(fogo, projetil, alvo)` e o feitiço adaptável precisam de um alvo. Os inimigos só chegam na Sprint 10; até lá, **bonecos de treino** com um elemento fazem esse papel, e o mesmo mecanismo vai servir para os inimigos depois.

## Regras

1. No layout, os dígitos `1`–`9` marcam bonecos de treino. A sala diz o elemento de cada um em `targets` (ex.: `{"1": "fogo", "2": "planta"}`). Um dígito sem elemento é erro de autoria.
2. Cada boneco tem um `target_id` (`<sala>_alvo_<dígito>`) e um `element`, está no grupo `alvos` e fica de pé na célula (visual provisório: retângulo na cor do elemento).
3. **O alvo de um feitiço** é o boneco do grupo `alvos` mais perto do mago num raio de **12 tiles**; se não houver nenhum, `alvo` é `None`.
4. A distância vai ao executor em **tiles**, com uma casa decimal.

## Critérios de aceite

### MUN-040 — Bonecos no layout

- **Dado** o layout `"1.2"`
- **Então** `targets` tem `1` em (0,0) e `2` em (2,0)

### MUN-041 — Alvo mais próximo

- **Dado** dois bonecos, a 3 e a 6 tiles do mago
- **Então** o alvo é o de 3 tiles, com `{"id", "elemento", "distancia": 3.0}`

### MUN-042 — Fora do alcance

- **Dado** o único boneco a 13 tiles
- **Então** o alvo é `null`

### MUN-043 — Dígito sem elemento

- **Dado** um dígito no layout sem entrada em `targets`
- **Então** a sala registra um erro de autoria
