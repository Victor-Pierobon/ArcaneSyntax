# PUZ-02-runas — Puzzle 2: o cadeado de runas

- **Status:** Implementada
- **Sprint:** 9
- **Relacionadas:** PUZ-validacao (regras 9, 10 e 13), EXE-pecas (regras 6 e 7), EXE-protocolo (regra 7)
- **Conceito:** variáveis

## Desenho

Na parede da sala há três runas com números sorteados (`runa:?`). Diante da porta fica um cadeado com o símbolo Σ: ele abre quando recebe a **soma** das runas. Como os números mudam a cada entrada na sala, o feitiço precisa ler e guardar os valores, não decorá-los.

- Sala: `sala_p02`, ligada à sala_03. A posição é provisória: o mapa é montado na Sprint 14.
- Puzzle: `{"id": "p02_runas", "condicoes": [{"tipo": "cadeados_abertos"}]}`
- Runas: três dígitos `runa:?`. Cadeado: um dígito `cadeado:soma`, a 4 tiles da porta.
- Custo de referência da solução A: 1.8.

## Soluções que devem passar

Teste de aceitação com o Python real e a sala do jogo. O teste fixa as runas em 4, 7 e 2, põe o mago a 2 tiles do cadeado e começa com a mana cheia.

| # | Estilo | Código |
| --- | --- | --- |
| A | Uma variável por runa | `a = ler_runa(1)` / `b = ler_runa(2)` / `c = ler_runa(3)` / `inscrever(a + b + c)` |
| B | Acumulador num loop | `total = 0` / `for n in range(1, 4):` / `    total = total + ler_runa(n)` / `inscrever(total)` |
| C | Expressão direta | `inscrever(ler_runa(1) + ler_runa(2) + ler_runa(3))` |
| D | Ler com uma visão e escrever o número | slot 1 `print(ler_runa(1) + ler_runa(2) + ler_runa(3))`, depois slot 2 `inscrever(13)` |

## Soluções que devem falhar

| # | Por quê | Código |
| --- | --- | --- |
| X | Faltou uma runa: 11 em vez de 13 | `inscrever(ler_runa(1) + ler_runa(2))` |
| Y | Longe do cadeado: a inscrição se perde | a solução A conjurada com o mago na entrada da sala |

## Critérios de aceite

### PUZ-030 — Soluções válidas abrem a porta

- **Dado** a sala_p02, as runas 4, 7 e 2 e o mago perto do cadeado
- **Quando** conjura cada solução A, B, C e D, cada uma num mundo novo
- **Então** o puzzle `p02_runas` fica resolvido e a porta abre

### PUZ-031 — Soluções erradas não abrem

- **Quando** conjura X ou Y
- **Então** o cadeado e a porta continuam fechados

### PUZ-032 — Decorar o número não serve

- **Dado** o mago saiu da sala sem resolver o puzzle, e as runas foram sorteadas de novo com soma diferente de 13
- **Quando** conjura `inscrever(13)`
- **Então** o cadeado continua fechado, e a solução A ainda abre

## Perguntas em aberto

- [ ] A soma é a melhor regra para iniciantes, ou um cadeado que pede "a runa do meio" ensinaria variável com menos conta? A soma obriga a guardar três valores, e por isso foi a escolhida.
