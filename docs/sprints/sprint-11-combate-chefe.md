# Sprint 11 — Combate II: chefe e balanceamento

- **Status:** Planejada
- **Fase do plano:** 6 · **Marco:** fecha o combate do M3 · **Estimativa:** 12–19 h
- **Depende de:** Sprint 10

## Objetivo

O chefe da Masmorra é vencível com um feitiço adaptável e todos os números do jogo moram num lugar só.

## Tarefas

- [ ] Chefe da Masmorra: duas fases que trocam de fraqueza (10–15 h)
- [ ] Ajuste de dificuldade e custos de mana, com os valores num único arquivo de balanceamento (2–4 h)

## Specs a escrever

- `docs/specs/combate/COM-chefe.md`: fases, gatilho de troca, sinal visual da fraqueza.
- `docs/specs/balanceamento/BAL-valores.md`: onde vivem os números e quem os lê.

## Testes

- TDD: troca de fase e de fraqueza.
- Teste que garante que um feitiço adaptável de referência vence o chefe dentro de um orçamento de mana.

## Notas

- As `regras` enviadas ao executor (ganhos e custos de mana, desde a Sprint 2) passam a vir desse arquivo de balanceamento.

## Pronto quando

O chefe é vencível com feitiço adaptável e muda de fase de forma legível.
