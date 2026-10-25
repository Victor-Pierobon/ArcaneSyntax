# Sprint 8 — Puzzles I: validação e execução passo a passo

- **Status:** Concluída em 2026-10-25 · aguardando revisão e commit do Victor
- **Fase do plano:** 5 · **Marco:** M3 · **Estimativa:** 14–20 h
- **Depende de:** Sprint 7

## Objetivo

Um puzzle é resolvido só pelo estado do mundo, vendo o código rodar linha a linha.

## Tarefas

- [x] Validação pelo estado do mundo (`PuzzleValidator`)
- [x] Execução passo a passo com linha destacada e velocidade ajustável (tecla V)
- [x] Puzzle 1: o cristal adormecido, na sala_01

## Decisões

| Decisão | Por quê |
| --- | --- |
| Puzzle 1 = **cristal + porta de runas**: o cristal acende com qualquer feitiço, a porta abre com todos os cristais acesos; o mago começa sem mana | Ensina **sequência** (reunir mana, depois lançar) e mantém o pilar "o mundo decide" |
| O cajado não acende cristais | Senão o puzzle não ensinaria nada |
| Condições do puzzle como **dicionários na cena da sala** (não `Resource`, como dizia o plano) | Ficam no mesmo texto da sala, fáceis de revisar no git, como o layout |
| Cristais reaproveitam os bonecos de treino (`Crystal` herda de `TrainingTarget`) e são `alvo` com `elemento == "cristal"` | Projétil, mira e efeitos já funcionam |
| Porta `|` no layout; `cristal` ou `cristal:<elemento>` em `targets` | Mesmo jeito de autorar das outras peças da sala |
| Puzzles resolvidos guardados no `World` (memória) | Gravar em disco é da Sprint 13 |
| Passo a passo só nas salas com puzzle: painel com o código, linha destacada, 0,3 s entre ações ÷ velocidade (1×, 2×, 0,5×) | O combate continua rápido |
| Teste de aceitação usa a **sala_01 do jogo** e o **Python real** | Prova o puzzle de verdade, não uma cópia |

## O que foi entregue

**Specs**: `docs/specs/puzzles/PUZ-validacao.md` (PUZ-001 a 006), `PUZ-passo-a-passo.md` (PUZ-010 a 014), `PUZ-01-meditar.md` (PUZ-020 a 022); `MUN-salas` com `1–9` e `|` na legenda.

**Código**
- `src/core/puzzles/puzzle_validator.gd` (novo)
- `src/core/world/room_layout.gd`: `doors` (`|`)
- `src/nodes/puzzles/crystal.gd`, `rune_door.gd`, `step_view.gd` (novos)
- `src/nodes/world/room.gd`: `puzzle`, cristais, porta, `puzzle_state()`, `apply_solved()`, `doors_open()`, sinal `puzzle_solved`
- `src/nodes/magic/action_player.gd`: fila por conjuração, sinais `sequence_started` e `action_started`, `step_delay`
- `src/nodes/magic/world_actions.gd`: o mago se vira para o alvo ao lançar (correção abaixo)
- `src/nodes/world/world.gd`: `solved_puzzles`, `is_puzzle_solved`, modo passo a passo, `cycle_step_speed`; `world.tscn` com `StepView`
- `content/rooms/sala_01.tscn`: Puzzle 1 (cristal na coluna 50, porta na coluna 57)
- `project.godot`: ação `step_speed` (V); `textos.csv`: `PASSO_VELOCIDADE`
- `docs/feiticos-exemplo.md`: seção do Puzzle 1

## Testes

| Arquivo | Testes |
| --- | --- |
| `tests/unit/puzzles/test_puzzle_validator.gd` (novo) | 4 |
| `tests/unit/magic/test_action_player.gd` | +2 (sinais, pausa) |
| `tests/unit/world/test_room_layout.gd` | +1 (porta) |
| `tests/scene/puzzles/test_puzzle_room.gd` (novo) | 5 |
| `tests/scene/puzzles/test_step_view.gd` (novo) | 4 |
| `tests/acceptance/test_puzzle_01.gd` (novo; Python real, sala_01 do jogo) | 6 (3 soluções que passam, 2 que falham, cajado) |
| `tests/scene/magic/test_world_actions.gd` | +1 (regressão) |

Totais: **202 GdUnit4** e **114 pytest**, todos verdes.

**Teste de mutação** (todas pegas): cajado acendendo cristal, sala sem cristais "resolvida", sala resolvida esquecida ao voltar, elemento exigido ignorado, porta sem abrir, passo a passo sem pausa.

## Bugs encontrados (cada um com teste de regressão)

| Bug | Como apareceu | Teste |
| --- | --- | --- |
| De costas para o alvo e encostado numa parede ou porta, o projétil nascia dentro dela e sumia | Teste PUZ-005 | `test_MAG_010_projetil_de_costas_encostado_na_parede` (vermelho → verde; o mago agora se vira para o alvo ao lançar) |
| O painel do passo a passo cobria a parte de baixo da tela, onde ficam o mago e o puzzle | Captura de tela | `test_PUZ_012_painel_nao_cobre_a_acao` (vermelho → verde; painel no alto) |

## Como verificar

Siga a seção "4b. Puzzle 1" de `docs/feiticos-exemplo.md`: na sala_01, ande até perto do cristal (antes da saída) e conjure `meditar()` + `lancar(fogo, projetil, alvo)`. O painel do passo a passo mostra a linha atual; o cristal acende e a porta abre. **V** muda a velocidade.

## Mudança que afeta o jogo

A saída da sala_01 agora fica fechada até o Puzzle 1 ser resolvido.

## Limitações conhecidas

- Puzzles resolvidos não são gravados em disco: fechar o jogo fecha a porta de novo (Sprint 13).
- O painel do passo a passo mostra só as ações; as visões (`print`) não entram na sequência, porque o executor não informa a ordem entre visões e ações.
