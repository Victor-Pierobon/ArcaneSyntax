# PUZ-04-ponte — Puzzle 4: a ponte de 12 blocos

- **Status:** Rascunho
- **Sprint:** 9
- **Relacionadas:** PUZ-validacao (regras 11, 13 e 14), EXE-custo (regra 13, custo de inscrição), EXE-pecas, GDD "Bloqueio por conhecimento"
- **Conceito:** loops

## Desenho

Um vão de 12 tiles sobre espinhos separa o mago da porta. Cada `construir_bloco()` põe um bloco. Doze linhas soltas resolvem, mas o loop paga a inscrição de uma linha só, e por isso **gasta menos mana**. As estrelas mostram a diferença.

- Sala: `sala_p04`, ligada à `sala_p03`
- Puzzle: `{"id": "p04_ponte", "condicoes": [{"tipo": "ponte_completa"}], "estrelas": [7.5, 9.0]}`
- Layout: 12 células `~` numa linha, com espinhos embaixo. O ponto seguro fica antes do vão.
- Custos (`custo_bloco` 0,5): `for` com 12 voltas, 7.3; 12 linhas, 8.4; `while` com contador, 8.8.

## Soluções que devem passar

O teste começa com a mana cheia (10) e enche a mana antes de cada conjuração.

| # | Estilo | Código | Custo | Estrelas |
| --- | --- | --- | --- | --- |
| A | `for` | `for i in range(12):` / `    construir_bloco()` | 7.3 | 3 |
| B | `while` com contador | `n = 0` / `while n < 12:` / `    construir_bloco()` / `    n = n + 1` | 8.8 | 2 |
| C | Doze linhas soltas | `construir_bloco()` repetida 12 vezes | 8.4 | 2 |
| D | Dois feitiços de 6 | `for i in range(6):` / `    construir_bloco()`, conjurado 2 vezes | 7.4 | 3 |

## Soluções que devem falhar

| # | Por quê | Código |
| --- | --- | --- |
| X | Uma volta a menos: 11 blocos | `for i in range(11):` / `    construir_bloco()` |
| Y | Sem os parênteses: a peça não é chamada | `for i in range(12):` / `    construir_bloco` |

## Critérios de aceite

### PUZ-050 — Soluções válidas completam a ponte

- **Dado** a sala_p04
- **Quando** conjura cada solução A, B, C e D, cada uma num mundo novo
- **Então** o puzzle `p04_ponte` fica resolvido, a porta abre, o mago atravessa a ponte andando e as estrelas são as da tabela

### PUZ-051 — Soluções erradas não completam

- **Quando** conjura X ou Y
- **Então** o puzzle continua sem solução; com X, 11 blocos ficam no lugar e um `construir_bloco()` a mais resolve

## Perguntas em aberto

- [ ] Com mana máxima 10, as 12 linhas soltas cabem numa conjuração (8.4). Então o loop não é obrigatório, só mais barato. Para o loop ser o único jeito de fazer tudo de uma vez, `custo_bloco` 0,7 daria: loop 9.7, linhas 10.8. Mas aí sobra pouca folga para iniciantes, e a mana máxima sobe com os níveis na Sprint 12. Recomendo manter 0,5 e deixar as estrelas ensinarem.
