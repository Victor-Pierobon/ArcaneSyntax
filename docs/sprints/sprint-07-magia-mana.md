# Sprint 7 — Magia no mundo II: mana viva

- **Status:** Planejada
- **Fase do plano:** 4 · **Marco:** fecha o M2 · **Estimativa:** 10–16 h
- **Depende de:** Sprint 6

## Objetivo

O ciclo escrever → equipar → conjurar → ver acontecer funciona de ponta a ponta, e a mana se recupera por feitiços do jogador.

## Tarefas

- [ ] `meditar()` e `absorver_mana()` no mundo (animação, mago parado ao meditar) (3–4 h)
- [ ] Slot passivo executado periodicamente, com custo por operação (4–6 h)
- [ ] Efeitos visuais e sons provisórios (2–4 h)
- [ ] Playtest do núcleo: alguém de fora escreve e usa um feitiço (1–2 h)

## Specs a escrever

- `docs/specs/magia/MAG-mana.md`: como o resultado do executor atualiza a mana real.
- `docs/specs/magia/MAG-passivo.md`: intervalo, sem sobreposição, para quando a mana não cobre o custo.

## Testes

- TDD: agendador do passivo (intervalo, não sobrepõe execuções).
- Teste comparando dois passivos: o que checa a mana antes rende mais que o que absorve sempre (GDD).

## Notas

- **Concorrência de mana:** passivo e conjuração podem partir da mesma foto do mago. Aplicar a **variação** (`mana_final − mana_inicial`, já com o custo) e não o valor absoluto, senão um sobrescreve o outro. O executor já serializa as chamadas (fila `_busy`).
- Pela ADR-001, o passivo é o lugar natural dos feitiços que reagem ao mundo: ele roda de novo a cada ciclo com uma foto nova.

## Pronto quando (fecha o M2)

O ciclo completo funciona e o passivo recarrega a mana em combate.
