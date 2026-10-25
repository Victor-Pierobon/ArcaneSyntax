# PUZ-validacao — Puzzles validados pelo estado do mundo

- **Status:** Implementada
- **Sprint:** 8
- **Relacionadas:** PUZ-01-meditar, PUZ-passo-a-passo, MUN-salas, MAG-formas, GDD "Validação pelo estado do mundo"

## Contexto

O jogo **nunca compara o código com um gabarito**: só verifica o resultado no mundo (GDD, pilar 5). Um jogador acende cristal por cristal, outro usa um loop, outro escreve uma função; todos passam.

## Regras

1. **Cristal:** um alvo especial (`alvo.elemento == "cristal"`) que acende quando um **feitiço** o atinge. O cajado não acende. Um cristal pode exigir um elemento (`cristal:fogo`); com outro elemento, ele só pisca.
2. **Porta de runas:** bloqueia a passagem até o puzzle da sala ser resolvido; então abre (deixa de colidir).
3. **No layout** (MUN-salas): `|` é uma célula de porta; cristais usam os dígitos de alvo com `targets = {"5": "cristal"}` ou `{"5": "cristal:fogo"}`.
4. **Puzzle da sala:** `puzzle = {"id": "p01_meditar", "condicoes": [...]}`. Condições (avaliadas pelo `PuzzleValidator` sobre uma foto do estado da sala):

   | Condição | Verdadeira quando |
   | --- | --- |
   | `{"tipo": "cristais_acesos"}` | todos os cristais da sala estão acesos |
   | `{"tipo": "cristais_acesos", "ids": ["5", "6"]}` | os cristais com esses dígitos estão acesos |

   Todas as condições precisam ser verdadeiras. Um tipo desconhecido é falso e vira erro de autoria.
5. O puzzle é avaliado sempre que algo na sala muda (um cristal acende). Resolvido, abre as portas e avisa o `World` (`puzzle_solved`).
6. O `World` guarda os puzzles resolvidos: ao voltar à sala, cristais acesos e portas abertas. (Gravar em disco é da Sprint 13.)
7. Um puzzle resolvido não "desresolve".

## Critérios de aceite

### PUZ-001 — Todos os cristais acesos

- **Dado** a foto `{"cristais": {"5": true, "6": true}}`
- **Então** `cristais_acesos` é verdadeira; com `"6": false`, falsa; sem cristais, falsa

### PUZ-002 — Cristais escolhidos

- **Dado** `{"cristais": {"5": true, "6": false}}`
- **Então** `cristais_acesos` com `ids ["5"]` é verdadeira, e com `["6"]` é falsa

### PUZ-003 — Condição desconhecida

- **Então** `{"tipo": "dancar"}` torna o puzzle falso e gera um erro de autoria

### PUZ-004 — Cristal acende com feitiço, não com cajado (cena)

- **Quando** um projétil atinge o cristal
- **Então** ele acende; um golpe de cajado não acende; um cristal `cristal:fogo` atingido por gelo não acende, e por fogo acende

### PUZ-005 — Porta bloqueia até resolver (cena)

- **Dado** a porta fechada
- **Quando** o mago anda contra ela
- **Então** não passa; ao acender o cristal, a porta abre e ele passa

### PUZ-006 — Resolvido continua resolvido (cena)

- **Quando** o mago sai da sala e volta
- **Então** o cristal está aceso e a porta aberta
