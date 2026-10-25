# Sprint 10 — Combate I: inimigos

- **Status:** Planejada
- **Fase do plano:** 6 · **Marco:** M3 · **Estimativa:** 18–26 h
- **Depende de:** Sprint 7

## Objetivo

Três inimigos que pedem lógica, não só dano.

## Tarefas

- [ ] Vida dos inimigos, dano e fraquezas elementais (4–6 h)
- [ ] Inimigo 1: elemental de fogo, fraco contra gelo (4–6 h)
- [ ] Inimigo 2: enxame pequeno, que pede um feitiço com repetição sobre a lista de alvos (5–7 h)
- [ ] Inimigo 3: guardião que alterna o elemento do escudo (5–7 h)

## Specs a escrever

`docs/specs/combate/COM-dano.md`, `COM-elemental.md`, `COM-enxame.md`, `COM-guardiao.md`.

## Testes

- TDD: tabela de dano e fraquezas, máquinas de estado dos inimigos (fora da cena).
- Cena: um encontro de cada inimigo.

## Notas

- **Enxame e ADR-001:** o feitiço não vê inimigos morrendo durante a execução. O padrão vira `for inimigo in inimigos: lancar(raio, projetil, inimigo)` sobre a lista da foto, e não `while inimigo.vivo:`. Isso exige um sentido novo (`inimigos`, lista de alvos): atualizar `EXE-pecas` e o protocolo primeiro.
- O guardião precisa de um sentido para o elemento atual do escudo (ex.: `alvo.escudo`), lido a cada conjuração.

## Pronto quando

Cada inimigo pode ser vencido por um feitiço bem pensado e é sofrido de vencer só no cajado.
