# PUZ-01-meditar — Puzzle 1: o cristal adormecido

- **Status:** Implementada
- **Sprint:** 8
- **Relacionadas:** PUZ-validacao, EXE-custo, GDD "O primeiro feitiço: reunir mana"
- **Conceito:** sequência (o primeiro dos cinco conceitos da Alpha)

## Desenho

Na sala_01, antes da saída para a sala_02, uma **porta de runas** fecha a passagem. Diante dela há um **cristal adormecido**. Ele acende com qualquer feitiço que o atinja, mas o mago começa **sem mana**. A solução é uma sequência: reunir mana e depois lançar no cristal. Isso pode ser um feitiço de duas linhas ou dois feitiços conjurados um depois do outro.

- Puzzle: `{"id": "p01_meditar", "condicoes": [{"tipo": "cristais_acesos"}]}`
- Cristal: dígito `5`, `cristal` (qualquer elemento)
- O lançamento custa 3,2; meditar rende 4,8 já descontada a instrução. Na Sprint 8 eram 3,1 e 4,9; mudou com o custo de inscrição da Sprint 9 (EXE-custo, regra 13), e as três soluções continuam passando.

## Soluções que devem passar (teste de aceitação com o Python real, mana inicial 0)

| # | Estilo | Código (um slot, salvo onde indicado) |
| --- | --- | --- |
| A | Sequência num feitiço | `meditar()` + `lancar(fogo, projetil, alvo)` |
| B | Dois feitiços, um depois do outro | slot 1 `meditar()`, depois slot 2 `lancar(gelo, projetil, alvo)` |
| C | Loop para juntar mana | `while mana < 5:` / `    absorver_mana()` + `lancar(raio, projetil, alvo)` |

## Soluções que devem falhar

| # | Por quê | Código |
| --- | --- | --- |
| X | Sem mana: o lançamento esgota | `lancar(fogo, projetil, alvo)` |
| Y | Escudo não atinge o cristal | `meditar()` + `lancar(fogo, escudo)` |

## Critérios de aceite

### PUZ-020 — Soluções válidas abrem a porta

- **Dado** a sala_01 do jogo, o mago perto do cristal e mana 0
- **Quando** conjura cada solução A, B e C (cada uma num mundo novo)
- **Então** o puzzle `p01_meditar` fica resolvido e a porta abre

### PUZ-021 — Soluções erradas não abrem

- **Quando** conjura X ou Y
- **Então** o puzzle continua sem solução e a porta fechada

### PUZ-022 — O cajado não resolve

- **Quando** o mago golpeia o cristal com o cajado
- **Então** o puzzle continua sem solução
