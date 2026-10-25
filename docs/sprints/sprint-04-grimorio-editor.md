# Sprint 4 — Grimório I: editor e feitiços salvos

- **Status:** Concluída em 2026-10-25 · aguardando revisão e commit do Victor
- **Fase do plano:** 3 · **Marco:** M2 · **Estimativa:** 12–16 h
- **Depende de:** Sprints 2 e 3

## Objetivo

Escrever um feitiço, fechar o jogo, abrir de novo e ele estar lá.

## Tarefas

- [x] Abrir e fechar o grimório pausando o jogo
- [x] `CodeEdit` com realce de Python (e cor própria para as peças do jogo)
- [x] Lista de feitiços: criar, renomear, apagar, persistir em disco

## Decisões

| Decisão | Por quê |
| --- | --- |
| **Tab** abre; **Esc** ou botão Fechar fecham | Tab dentro do editor indenta o código, então não pode fechar |
| Nome: até 24 caracteres, sem espaços nas pontas, único **sem diferenciar maiúsculas** | Evita "Fogo" e "fogo" ao mesmo tempo nos slots |
| Arquivo `user://grimorio.json` em JSON legível com `versao` | Fácil de inspecionar; pronto para migrar na Sprint 13 |
| Gravação atômica (`.tmp` + troca) | Uma queda no meio não destrói o grimório |
| Arquivo ilegível ou de versão mais nova → grimório vazio + **cópia `.bak` antes de qualquer gravação** + aviso na tela | Nunca perder o que o jogador escreveu |
| Salva no disco ao criar, renomear, apagar e fechar; a edição vai para o modelo ao trocar de feitiço | Simples e sem perda; sem gravação a cada tecla |
| Sinais `spell_renamed`/`spell_deleted` no modelo | Os slots da Sprint 5 vão ouvir para não apontar para feitiço que mudou de nome ou sumiu |
| Grimório começa vazio | O primeiro feitiço nasce no Puzzle 1 (Sprint 8) |
| Testes usam `user://tests/…` | Testes e jogo compartilham o `user://`; nenhum teste toca o grimório real |

## O que foi entregue

**Specs**: `docs/specs/grimorio/GRI-feiticos.md` (GRI-010 a 017, 020 a 024), `docs/specs/grimorio/GRI-grimorio.md` (GRI-001 a 008)

**Código**
- `src/core/grimoire/grimoire.gd` — modelo (`Grimoire.Problem`: `OK`, `EMPTY_NAME`, `NAME_TOO_LONG`, `DUPLICATE_NAME`, `NOT_FOUND`)
- `src/core/grimoire/grimoire_store.gd` — leitura e gravação seguras
- `src/nodes/grimoire/python_highlighter.gd` — realce (palavras-chave, builtins, peças do jogo, textos, comentários, números)
- `src/nodes/grimoire/grimoire_ui.gd` — tela (CanvasLayer montado em código, `process_mode = ALWAYS`)
- `World`: carrega o grimório de `grimoire_path` e liga a tela; `world.tscn` ganhou o nó `GrimoireUI`
- `project.godot`: ação `grimoire` (Tab); `textos.csv`: textos do grimório e dica de controles atualizada

## Testes

| Arquivo | Testes |
| --- | --- |
| `tests/unit/grimoire/test_grimoire.gd` | 11 |
| `tests/unit/grimoire/test_grimoire_store.gd` | 8 |
| `tests/unit/grimoire/test_python_highlighter.gd` | 2 |
| `tests/scene/grimoire/test_grimoire_ui.gd` | 10 |
| `tests/scene/world/test_world.gd` | +1 (mundo carrega o grimório do caminho configurado) |

Totais: **96 GdUnit4** e **105 pytest**, todos verdes.

**Teste de mutação** (quebrar e ver se algum teste falha): sem backup do arquivo corrompido (2 falhas), nomes diferenciando maiúsculas (3), fechar sem salvar (1), grimório sem processar com o jogo pausado (1). Todas pegas.

**Captura de tela** do grimório aberto mostrou um bug que os testes não pegavam: o campo de nome não acompanhava o renomear. Virou o teste `test_GRI_003_campo_de_nome_acompanha_o_selecionado` (vermelho → verde).

## Como verificar

`godot --path game` (ou F5) → **Tab** abre o grimório (o jogo pausa) → **Novo** → escreva um feitiço → renomeie pelo campo de nome (Enter ou Renomear) → **Esc** fecha. Feche o jogo, abra de novo, Tab: o feitiço está lá. O arquivo fica em `%APPDATA%\Godot\app_userdata\ArcaneSyntax\grimorio.json`.

## Limitações conhecidas

- O grimório ainda não executa nada: conjurar, slots, erros e custo vêm na Sprint 5. Para testar código, use o console de feitiços (`src/nodes/dev/spell_console.tscn`).
- Visual provisório (painel escuro com borda dourada).
- Fechar o jogo com o grimório aberto salva via `NOTIFICATION_WM_CLOSE_REQUEST`; não há teste automatizado disso.
