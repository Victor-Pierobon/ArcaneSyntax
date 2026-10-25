# Sprint 4 — Grimório I: editor e feitiços salvos

- **Status:** Planejada
- **Fase do plano:** 3 · **Marco:** M2 · **Estimativa:** 12–16 h
- **Depende de:** Sprint 2 (executor seguro), Sprint 3 (modelo do mago)

## Objetivo

Escrever um feitiço, fechar o jogo, abrir de novo e ele estar lá.

## Tarefas

- [ ] Abrir e fechar o grimório pausando o jogo (2–3 h)
- [ ] `CodeEdit` com realce de Python (4–6 h)
- [ ] Lista de feitiços: criar, renomear, apagar, persistir em disco (6–7 h)

## Specs a escrever

- `docs/specs/grimorio/GRI-grimorio.md`: abre e fecha por tecla, pausa o mundo, não pausa a si mesmo.
- `docs/specs/grimorio/GRI-feiticos.md`: nomes únicos, nome vazio recusado, apagar feitiço equipado (o que acontece com o slot), salvar e carregar.

## Testes

- TDD no modelo `Grimorio` (`src/core`): CRUD, nomes únicos, serialização e desserialização, arquivo corrompido não quebra o jogo.
- Cena: abrir pausa (`get_tree().paused`) e o grimório continua respondendo (`process_mode = ALWAYS`).

## Notas

- O console de feitiços (`src/nodes/dev/spell_console.gd`) já tem `CodeEdit`, execução e linha de erro pintada; serve de ponto de partida.
- Persistir em `user://` como JSON com campo de versão (o save completo vem na Sprint 13; manter o formato compatível).
- Textos visíveis sempre via `textos.csv`.

## Pronto quando

Escrever um feitiço, fechar o jogo, abrir de novo e ele estar lá.
