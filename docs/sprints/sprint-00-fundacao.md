# Sprint 0 — Fundação e esteira de testes

- **Status:** Concluída (parte técnica) em 2026-10-25 · tarefas do Victor pendentes
- **Fase do plano:** 0 · **Marco:** M1 · **Estimativa:** 20–32 h
- **Commit:** `8b798a0` ("Sprint 0: estrutura, testes (pytest + GdUnit4), CI e protótipo de movimento")

## Objetivo

Projeto criado, testes rodando no CI e um personagem andando.

## Tarefas

- [ ] Tutorial oficial de jogo 2D do Godot (8–12 h) — **Victor**
- [x] Repositório Git, estrutura de pastas, `.gitignore`, `.gitattributes` (LF)
- [x] GdUnit4 v6.2.2 instalado em `game/addons/gdUnit4` (exige Godot ≥ 4.5)
- [x] `executor/` com `pyproject.toml` e pytest
- [x] GitHub Actions (`.github/workflows/ci.yml`) com job pytest e job GdUnit4 — **ainda não verificado rodando no GitHub**
- [x] `scripts/test.sh` roda as duas suítes
- [x] Textos em arquivo de tradução (`game/content/text/textos.csv`, chave `PROTOTIPO_DICA`)
- [ ] Escolher pacote de assets provisórios (2–3 h) — **Victor**
- [x] Protótipo do personagem andando e pulando

## O que foi entregue

- **Documentos movidos** para `docs/gdd.md` e `docs/plano-alpha.md`; criados `docs/roadmap-alpha.md`, `docs/specs/TEMPLATE.md`, `docs/diario.md`, `README.md`.
- **Projeto Godot 4.7** (`game/project.godot`): 640×360 com stretch `viewport`, filtro `nearest`, `gl_compatibility`, ações `move_left`/`move_right`/`jump`.
- **Spec `docs/specs/mundo/MUN-movimento.md`** (MUN-001 a MUN-008). Não estava prevista para a Sprint 0, mas foi escrita para o protótipo já nascer no fluxo spec → teste → código.
- **Código:**
  - `game/src/core/player/player_intent.gd` — intenção do quadro
  - `game/src/core/player/player_motor.gd` — regra pura do movimento
  - `game/src/nodes/player/player.gd` + `player.tscn` — CharacterBody2D 12×30, origem nos pés, Camera2D
  - `game/src/nodes/world/prototype_room.tscn` — chão, 2 plataformas, paredes, dica de controles
- **Testes (10, todos verdes):**
  - `game/tests/unit/player/test_player_motor.gd` — 8 testes (MUN-001 a MUN-006)
  - `game/tests/scene/player/test_player_scene.gd` — 2 testes (MUN-007 pouso, MUN-008 altura do pulo ±3 px)

## Decisões

- **GDScript**, não C#.
- **Altura do pulo em pixels** (48 px = 3 tiles de 16 px); a velocidade é derivada (`sqrt(2·g·h)`).
- **Intenção injetável** (`Player.intent_source`): em headless o Godot não entrega eventos de input, então os testes de cena injetam a intenção. O mesmo caminho servirá para `mover()`/`levitar()` na Sprint 6.
- **TDD estrito para regras, teste depois para sensação** (ver `docs/roadmap-alpha.md`).

## Desvios do plano

- Sem tileset ainda: visual com `ColorRect` até os assets serem escolhidos.
- Movimento sem aceleração gradual, coyote time, jump buffer ou esquiva (ficam para a Sprint 3).

## Como verificar

- Jogo: abrir `game/project.godot` no Godot e apertar F5. A/D ou setas andam; Espaço ou W pula; segurar o botão pula mais alto.
- Testes: ver `docs/arquitetura.md`, seção Testes.

## Pendências que passam adiante

- Tutorial 2D e escolha de assets (Victor).
- Confirmar o CI verde no GitHub depois do push (a URL do Godot Linux no workflow nunca rodou).
