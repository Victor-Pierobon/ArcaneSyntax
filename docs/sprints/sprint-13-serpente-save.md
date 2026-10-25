# Sprint 13 — Conteúdo da serpente e save

- **Status:** Planejada
- **Fases do plano:** 7 e 8 · **Marco:** M4 · **Estimativa:** 14–21 h
- **Depende de:** Sprint 12

## Objetivo

A serpente ensina cada conceito e dá dicas; o progresso é salvo.

## Tarefas

- [ ] Falas da serpente: apresentação e um ensinamento por conceito (sequência, variáveis, condicionais, loops, funções) (4–6 h)
- [ ] Dicas em três níveis para cada puzzle: conceito → estrutura → exemplo parcial (4–6 h)
- [ ] Salvar e carregar o progresso, com versão no formato do save (4–6 h)
- [ ] Desenhar o mapa da área no papel, cerca de 12 salas (2–3 h)

## Specs a escrever

`docs/specs/narrativa/NAR-serpente.md`, `NAR-dicas.md`, `docs/specs/save/SAV-progresso.md`.

## Testes

- TDD no save: ida e volta preserva tudo; save corrompido ou de versão antiga não quebra o jogo.
- Teste de conteúdo: todo puzzle tem as três dicas e toda fala referenciada existe em `textos.csv`.

## Notas

- O save inclui o grimório (Sprint 4), os slots (Sprint 5), XP e nível (Sprint 12), sala atual e puzzles resolvidos.
- Um perfil só na Alpha, mas guardar o save por perfil desde já (laboratórios de escola dividem computadores, ver GDD).

## Pronto quando

Fechar e reabrir o jogo mantém todo o progresso, e cada conceito tem fala e dicas.
