# Sprint 8 — Puzzles I: validação e execução passo a passo

- **Status:** Planejada
- **Fase do plano:** 5 · **Marco:** M3 · **Estimativa:** 14–20 h
- **Depende de:** Sprint 7

## Objetivo

Um puzzle é resolvido só pelo estado do mundo, vendo o código rodar linha a linha.

## Tarefas

- [ ] Validação pelo estado do mundo: condições declarativas (`todos_cristais_acesos`, `porta_aberta`) como `Resource`, avaliadas por um `PuzzleValidator` (5–7 h)
- [ ] Execução passo a passo com linha destacada e velocidade ajustável (6–9 h)
- [ ] Puzzle 1: meditar para reunir a primeira mana e abrir o caminho (3–4 h)

## Specs a escrever

- `docs/specs/puzzles/PUZ-validacao.md`
- `docs/specs/puzzles/PUZ-passo-a-passo.md`
- `docs/specs/puzzles/PUZ-01-meditar.md`: soluções que passam e que falham

## Testes

- TDD no validador.
- **Teste de aceitação por puzzle:** roda o executor real e o validador headless com uma lista de soluções que devem passar e outras que devem falhar.

## Notas

- Cada ação já carrega `linha` (Sprint 1), então o passo a passo só precisa tocar a fila no ritmo escolhido e destacar a linha no `CodeEdit`. Nenhuma conversa extra com o executor (ADR-001).
- O primeiro feitiço do jogo depende da regra de custo da Sprint 2: `meditar()` com mana 0 precisa funcionar.

## Pronto quando

O Puzzle 1 resolve só pelo estado do mundo, com a linha atual destacada.
