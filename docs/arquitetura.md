# Arquitetura

Estado em 2026-10-25, fim da Sprint 8. Atualizar ao fim de cada sprint que mudar a estrutura.

## Visão geral

```
┌──────────────────────────── Godot 4.7 (game/) ────────────────────────────┐
│                                                                           │
│  Nodes (src/nodes)            Regras puras (src/core)                     │
│  Player ───────────────────▶  PlayerMotor  ◀── PlayerIntent               │
│  (CharacterBody2D)            (sem Node, testável sem cena)               │
│                                                                           │
│  Cliente do executor (src/executor_client)                                │
│  SpellRequest ─▶ PythonSpellExecutor ─▶ SpellResult / SpellError          │
│                  (extends SpellExecutor; thread + worker)                 │
└──────────────────────────────┬────────────────────────────────────────────┘
                               │ 1 linha JSON por requisição (stdin/stdout)
                               ▼
┌────────────────── Worker Python 3.14 (executor/) ─────────────────────────┐
│  run_worker.py → worker.main → protocol.handle_line → runner.run_spell    │
│     (teto de memória)                    parse → sandbox → instrumentar   │
│                                            → exec com pieces.Contexto     │
└───────────────────────────────────────────────────────────────────────────┘
```

O jogo nunca roda o código do jogador no próprio processo. Ele manda o código e uma foto do mundo para um worker Python; o worker devolve a lista de ações (com a linha que gerou cada uma), as saídas de `print`, o estado final do mago e o erro, se houver. O jogo anima as ações depois.

## Pastas

| Pasta | O que tem |
| --- | --- |
| `docs/` | GDD, plano da Alpha, roadmap, sprints, specs, ADRs, arquitetura, diário |
| `docs/sprints/` | Um arquivo por sprint: plano (futuras) ou relatório (concluídas) |
| `docs/specs/<area>/` | Specs com critérios de aceite (IDs `AREA-NNN`) |
| `docs/adr/` | Decisões de arquitetura |
| `game/` | Projeto Godot (`res://` aponta para cá) |
| `game/src/core/` | Regras puras, sem Node (`AreaMap.load_dir` é a exceção: instancia as cenas das salas só para ler os campos) |
| `game/src/nodes/` | Cenas e scripts de cena (`player/`, `world/`, `ui/`, `magic/`, `puzzles/`, `combat/`, `grimoire/`, `fx/`, `art/`, `dev/`) |
| `game/content/rooms/` | Salas do jogo (cenas `Room` com layout em texto) |
| `game/assets/placeholder/` | Arte provisória gerada por `game/tools/gerar_provisorio.gd`: `tiles_bordas.png` (16 formas de pedra, plataforma, espinhos) e `fundo_1..3.png` |
| `game/assets/<pasta>/` | Arte do Victor (`mago/`, `serpente/`, `cenario/`…), pelo contrato de `content/arte.json` (ART-esteira) |
| `game/tools/` | Scripts de desenvolvimento rodados com `-s` (fora do build) |
| `game/tests/fixtures/rooms/` | Salas pequenas usadas pelos testes |
| `game/src/executor_client/` | Cliente do executor Python |
| `game/content/` | Conteúdo de dados: `text/textos.csv` e `balanceamento.json` (BAL-valores) |
| `game/tests/` | GdUnit4: `unit/`, `scene/`, `integration/`, `acceptance/`, `support/` |
| `game/addons/gdUnit4/` | GdUnit4 v6.2.2 (código de terceiros, não editar) |
| `executor/` | Pacote Python `arcane_executor` + `run_worker.py` + `tests/` (pytest) |
| `tests/contract/` | Fixtures JSON do protocolo, usadas pelas duas suítes |
| `scripts/` | `test.sh` (roda tudo), `fetch_python.sh` (baixa o Python embutido), `build_windows.ps1` (build da Alpha) |
| `build/` | Saída do build (fora do git): `ArcaneSyntax/` e `ArcaneSyntax-alpha.zip` |
| `runtime/` | Python standalone baixado (fora do git) |

## Godot

### Configuração (`game/project.godot`)

- Resolução base 640×360, janela 1280×720, stretch `viewport`, filtro de textura `nearest` (pixel art).
- Renderizador `gl_compatibility`.
- Ações de input: `move_left` (A, ←), `move_right` (D, →), `jump` (Espaço, W, ↑).
- Textos: `content/text/textos.csv` (coluna `pt_BR`) importado como tradução; nunca escrever texto visível direto no código, usar chaves (`PROTOTIPO_DICA`).
- Plugin GdUnit4 habilitado.
- Ações de input: também `dodge` (Shift, K), `grimoire` (Tab), `slot_1` … `slot_5` (teclas 1–5), `attack` (J, cajado) e `step_speed` (V).
- Cor de fundo padrão escura (`default_clear_color`).
- Cena principal: `res://src/nodes/world/world.tscn`.

### Movimento (spec MUN-movimento)

- `PlayerIntent` (`src/core/player/player_intent.gd`): `move_x`, `jump_pressed`, `jump_held`, `dodge_pressed`. `PlayerIntent.from_input()` lê o teclado; `PlayerIntent.make(...)` cria uma à mão.
- `PlayerMotor` (`src/core/player/player_motor.gd`): `step(velocity, intent, on_floor, delta) -> Vector2`. Parâmetros: andar 120 px/s, gravidade 980, altura do pulo 48 px (velocidade derivada: `sqrt(2·g·h)`), queda máxima 400, corte do pulo 0,5 (uma vez por pulo), coyote time 0,1 s, jump buffer 0,1 s, esquiva 280 px/s por 0,16 s com recarga de 0,35 s (uma no ar por salto). `facing`, `is_dodging()`, `is_invulnerable()`.
- `Player` (`src/nodes/player/player.gd`, CharacterBody2D): origem nos pés; chama `intent_source` (Callable, padrão `PlayerIntent.from_input`) e `motor.step` no `_physics_process`. Testes e, no futuro, feitiços trocam `intent_source`.

### Mago, salas e HUD (specs MUN-vida, MUN-salas, UI-hud)

- `Health` (`src/core/mago/health.gd`): vida inteira, `damage(amount, source)` devolve se contou, `Source.ATTACK`/`HAZARD`, 1 s de invencibilidade pós-dano (`tick(delta)`), `dodging` protege só de `ATTACK`, sinais `changed(current, maximum)` e `died`.
- `MagoState` (`src/core/mago/mago_state.gd`): `health` (5), `mana` (0) e `mana_max` (a do nível; 10 no nível 1) com resolução 0,1; `xp`, `level`, `gain_xp(n)` (sobe níveis, aumenta e enche a mana); sinais `mana_changed`, `xp_changed`, `leveled_up`; `to_spell_mago()` gera o `mago` do protocolo. **A mana real mora aqui**; o executor só simula.
- `RoomLayout` (`src/core/world/room_layout.gd`): lê o layout em texto (`#` pedra, `=` plataforma, `^` espinhos, `*` ponto seguro, `A–Z` entradas, `a–z` saídas, `|` porta de runas, `%` porta de atalho); `cell_feet(cell)`, `size_px()`, `errors`.
- `Room` (`src/nodes/world/room.gd`): cena com `room_id`, `layout` e `exits` (`{"b": "sala_02:A"}`). No `_ready` monta um `TileMapLayer` (cada pedra com a forma da vizinhança, `TileShape`; tileset montado por código em `Room.tileset_for` a partir de `cenario/tiles.png` ou do provisório; ver "Arte") e cria `Area2D` para saídas, espinhos e pontos seguros, que **só ligam depois do primeiro quadro de física**. Sinais: `exit_touched`, `hazard_touched`, `safe_point_touched`.
- `World` (`src/nodes/world/world.gd` + `world.tscn`; desde a Sprint 13 quem o sobe é a cena principal `Main`, desde a Sprint 14 pelo menu inicial): tem `Player` e `Hud`; `go_to(sala, entrada)` troca a sala (sempre adiado para fora do callback de física), põe o mago na entrada, ajusta os limites da câmera e o ponto seguro. Espinho: 1 de dano (ignora a esquiva) e volta ao ponto seguro. Morte: vida cheia e volta à entrada da sala atual. `rooms_dir` configurável (testes usam `res://tests/fixtures/rooms/`); `authoring_errors` junta erros de autoria.
- `Hud` (`src/nodes/ui/hud.gd`, CanvasLayer montado em código): `life_label`, `mana_label`, `mana_bar`, `level_label` (nível e XP), dica de controles; `bind(state)`.
### Grimório (specs GRI-feiticos, GRI-grimorio)

- `Grimoire` (`src/core/grimoire/grimoire.gd`): lista ordenada de `{name, code}`; `create`, `rename`, `delete`, `set_code` devolvem `Grimoire.Problem`; nomes até 24 caracteres, únicos sem diferenciar maiúsculas; `next_default_name("Feitiço")`; sinais `spell_created/renamed/deleted/code_changed`; `to_dict()`/`from_dict()` (null se inválido).
- `GrimoireStore` (`src/core/grimoire/grimoire_store.gd`): `user://grimorio.json` (`{"versao": 1, "feiticos": [{"nome", "codigo"}]}`); `save()` grava em `.tmp` e renomeia; `load_grimoire()` devolve vazio e preenche `last_problem` se o arquivo for ilegível, copiando o original para `.bak` antes.
- `GrimoireUI` (`src/nodes/grimoire/grimoire_ui.gd`, CanvasLayer `layer = 10`, `process_mode = ALWAYS`): `open()` pausa a árvore, `close()` guarda a edição, salva e despausa; `new_spell()`, `rename_selected()`, `delete_selected()`, `select()`; `spell_list`, `name_field`, `editor` (CodeEdit com `PythonHighlighter.build()`), `status_label`; `load_problem` mostra o aviso de arquivo ilegível.
- Slots no `Grimoire`: `equip(n, nome)`, `unequip(n)`, `slot(n)` (n de 1 a 5), `slots()`, sinal `slots_changed`; renomear/apagar atualizam os slots; salvos em `"slots"` no mesmo arquivo.
- `SpellReport` (`src/core/grimoire/spell_report.gd`): `phrase_key(tipo, tem_linha)`, `describe_error(erro)` (frase no mundo + erro real), `action_text(acao)`, `cast_lines(slot, nome, resultado)`, `full_text(resultado)`.
- `CompletionProvider` (`src/core/grimoire/completion_provider.gd`): `suggest(prefixo, desbloqueadas)` e `prefix_before_caret(linha)`.
- `GrimoireUI` também tem: botões de slot (`toggle_slot`), **Testar** (`test_selected`, sem gastar mana), `result_label` com rolagem, `marked_line`, `remember_result` (erro da conjuração aparece ao abrir), custo estimado (`estimate_now`, `estimate_timer` de 0,5 s) e autocompletar. Precisa de `set_spell_runner(executor, contexto)`.
- `World` cria `grimoire_store` em `grimoire_path` (padrão `user://grimorio.json`) e liga `grimoire_ui`. **Testes sempre trocam `grimoire_path`** para `user://tests/…`.

### Conjuração e alvos (specs GRI-slots, MUN-alvos, EXE-desbloqueio)

- `World.cast(n)`: se o jogo não está pausado e o slot tem feitiço, monta `SpellRequest` com `spell_context()` (`mago` de `MagoState`, `target` de `current_target()`, `pieces` de `MagoState.unlocked_pieces`, `room` de `Room.spell_room()`, `enemies` de `current_enemies()`), espera `executor.execute`, aplica a **variação** de mana, escreve no `CastLog`, avisa o grimório e emite `spell_cast`. Teclas 1–5 via `_unhandled_input`.
- `World.executor`: nó `Executor` (`PythonSpellExecutor`) por padrão; o setter religa o grimório. Testes trocam por `FakeSpellExecutor` (`tests/support/`).
- `TrainingTarget` (`src/nodes/world/training_target.gd`): boneco com `target_id` e `element`, no grupo `alvos`; `body_size` (os inimigos mudam), `hit(elemento, forma)`, `last_form`, `_show_hit(elemento, texto)`. Layout: dígitos `1`–`9`; `Room.targets = {"1": "fogo"}`. `World.current_target()`: o mais perto num raio de 12 tiles, distância em tiles.
- `CastLog` (`src/nodes/ui/cast_log.gd`): últimas 6 linhas no canto superior direito. `Hud.bind_slots(grimoire)`: barra com os 5 slots.
- `MagoState.ALL_PIECES` (constante `Array[String]`) e `unlocked_pieces` (hoje tudo desbloqueado).

### Ações no mundo (specs MAG-acoes, MAG-formas, MAG-elementos)

- `ActionPlayer` (`src/nodes/magic/action_player.gd`): `play(acoes)` enfileira e toca em ordem; `is_playing()`, sinal `finished`; chama `port.act_<tipo>(acao)`. No jogo o `port` é o `WorldActions`; nos testes, `FakeWorldPort` (`tests/support/`).
- `WorldActions` (`src/nodes/magic/world_actions.gd`): `act_lancar` (projétil ou escudo, espera 0,15 s), `act_mover` e `act_levitar` (controlam o mago pela `intent_source` e devolvem o controle; param ao chegar, ao ficar 0,3 s sem avançar ou em 3 s), `act_meditar` (0,5 s parado), `act_absorver_mana` (0,08 s), `staff_attack()` (cajado, recarga 0,35 s), `show_visions(textos)`, `on_attack_blocked()`. Esperas em tempo de jogo, congelam com o grimório aberto.
- `Projectile` (Area2D, grupo `projeteis`): `form` `projetil` (220 px/s) ou `faisca` (300 px/s, menor), alcance 12 tiles. Com alvo, **persegue** o `center()` dele e só acerta ele (atravessa os outros); sem alvo, ou se o alvo sumiu, vai reto e acerta o primeiro. Some em parede ou ao acertar. `Shield` (filho `Shield` do `Player`): 2 s ou até bloquear um ataque; liga `Health.shielded`.
- Camada de colisão **4** = hurtboxes (bonecos, cristais e inimigos). Projétil detecta 1 (mundo) + 4; cajado detecta 4. A área `Contact` dos inimigos detecta 1 (o mago).
- `ElementTable` (`src/core/magic/element_table.gd`): `effect(ataque, alvo)` → `NORMAL`/`WEAK`/`RESIST`; `multiplier()`. `TrainingTarget.hit(elemento)` guarda `last_hit_element`/`last_effect` e mostra o texto.
- `World.cast` agora também toca as ações (inclusive as anteriores a um erro) e as visões; `World.find_target(id)`.
- Motor: `PlayerIntent.fly_y` (NAN = sem voo) desliga a gravidade (MUN-015).

### Passivo, sons e efeitos (specs MAG-passivo, MAG-efeitos)

- `Grimoire`: slot passivo (`set_passive`, `clear_passive`, `passive`, `passive_changed`; campo `"passivo"` no arquivo).
- `PassiveScheduler` (`src/core/magic/passive_scheduler.gd`): `tick(delta)` devolve true a cada 1 s (não enquanto ocupado ou desligado); `mark_started`, `mark_finished(resultado)` → `Outcome` (`OK`, `MANA_OUT_FIRST`, `MANA_OUT_REPEAT`, `DISABLED`, `TRANSIENT`); `reset()`.
- `World._execute(codigo)`: execução comum (estado real + mana pela variação), usada por `cast` e `_run_passive`. O passivo toca as ações no `PassivePlayer` (outro `ActionPlayer`) e só escreve no registro quando desliga ou fica sem mana pela primeira vez. Editar o código do passivo ou trocá-lo chama `passive_scheduler.reset()`.
- `Sfx` (`src/nodes/fx/sfx.gd`, nó `Sfx` no `World`): sons gerados por código para `conjurar` (timbre por elemento), `acerto`, `fraco`, `escudo`, `cajado`, `mana`, `derrota`; `played` guarda o histórico; barramento `SFX` (`default_bus_layout.tres`).
- `Fx.burst(pai, posição, cor, quantidade, subindo)` (`src/nodes/fx/fx.gd`): partículas provisórias. `TrainingTarget` emite `was_hit` (o `World` toca o som).

### Puzzles (specs PUZ-validacao, PUZ-passo-a-passo, PUZ-01 a PUZ-06)

- Autoria na cena da sala: `puzzle = {"id", "condicoes", "estrelas"?}`. Em `targets`: `"cristal"`, `"cristal:fogo"`, `"cristal:mutavel[:cargas]"`, `"runa:4"`/`"runa:?"`, `"cadeado:soma"`. No layout: porta `|`, vão de ponte `~`, placa `_`.
- `PuzzleValidator` (`src/core/puzzles/`): `evaluate(condicoes, estado)` sobre `{"cristais", "cadeados", "ponte": {feitos, total}, "placas": [..]}`; condições `cristais_acesos` (todos ou `ids`), `cadeados_abertos`, `ponte_completa`, `placas_pisadas`; `authoring_errors`; `stars(limites, gasto)`; `counts_for_stars(acoes)` (só recuperar mana não conta).
- `MutableCrystalRule` (`src/core/puzzles/`): símbolo, cargas, `answer(simbolo)` (o elemento que vence, pela `ElementTable`), `hit(elemento)`; o gerador vem do `World`.
- `Crystal` (`src/nodes/puzzles/crystal.gd`, herda de `TrainingTarget`, `elemento == "cristal"`): acende com feitiço (não cajado), respeita `required_element`, sinal `lit_changed`. Mutável: tem `rule` e o `element` é o símbolo atual (é o que o feitiço lê em `alvo.elemento`). `RuneDoor` (`rune_door.gd`): `StaticBody2D` das células `|`, `open()`.
- `Rune` (número; não é alvo), `RuneLock` (`inscribe(valor, esperado)`, alcance 3 tiles, não é alvo), `Bridge` (`StaticBody2D` das células `~`, `build_next()`, esquerda → direita), `PressurePlate` (`Area2D`; pisada com o mago no chão dentro).
- `Room`: avalia o puzzle quando um mecanismo muda; resolvido → abre a porta e emite `puzzle_solved`; `puzzle_state()`, `apply_solved()`, `doors_open()`, `has_puzzle()`, `puzzle_id()`, `spell_room()` (`{"runas": [...]}` para o executor), `runes()`, `inscribe(valor, de)`, `build_block()`, `bridge`. Runas e placas são numeradas da esquerda para a direita. `rng` vem do `World` antes de a sala entrar na árvore.
- `World.solved_puzzles`: id → `{"estrelas": melhor}` (memória; disco na Sprint 13); ao voltar numa sala resolvida chama `apply_solved()`. `World.room_mana_spent` soma o custo das conjurações que agem (slots e passivo) até resolver; zera ao entrar na sala. `puzzle_stars(id)`. `World.rng` sorteia runas `?` e cristais mutáveis (testes fixam a semente).
- Passo a passo: `ActionPlayer` emite `sequence_started(codigo)` e `action_started(acao)` e espera `step_delay` entre ações; nas salas com puzzle o `World` usa 0,3 s ÷ `step_speed` e mostra o `StepView` (painel no alto com o código e a linha destacada). `World.cycle_step_speed()` (V): 1× → 2× → 0,5×.
- Testes de aceitação de puzzle em `tests/acceptance/`: sala do jogo + Python real + soluções que passam e que falham. `tests/support/puzzle_driver.gd` (`PuzzleDriver`) joga a sala: `start`, `place`, `walk_until_x`, `set_runes`, `cast` (enche a mana antes), `run_passive`.

- Salas do jogo: `content/rooms/sala_01..03.tscn` (sala_01 tem o Puzzle 1) (40–60 × 23 tiles), `sala_p02..p06.tscn` (Puzzles 2 a 6), em sequência a partir da saída `b` da sala_03, e `sala_c01..c04.tscn` (combate; a c04 é a do chefe), depois da porta da sala_p06 (tudo provisório até a Sprint 14). As salas `sala_p0N` e `sala_c0N` foram geradas por script; se mudar uma, confira a geometria (o elevador depende de colunas de 2 tiles coladas). Tileset provisório: `assets/placeholder/tiles.png` (pedra, plataforma, espinhos; ver `LEIAME.md` ali).

### Combate (specs COM-dano, COM-elemental, COM-enxame, COM-guardiao)

- Autoria: em `targets`, `"inimigo:elemental[:fogo|gelo|planta]"`, `"inimigo:enxame[:n]"` (1 a 9, padrão 6) e `"inimigo:guardiao"`. Ids `<sala>_alvo_<dígito>`; no enxame, `<sala>_alvo_<dígito>_<n>`.
- Regras puras (`src/core/combat/`): `Damage.amount(ataque, forma, elemento)` (projétil 3, faísca 1, cajado 1, vezes o multiplicador, truncado); `ElementalBrain` (`velocity_x(pés, pés do mago ou null, ahead_free)`, `can_walk(layout, pés, direção, meia largura)`: não entra em parede nem sai do chão); `SwarmBugBrain` (`HOVER`/`DIVE`/`RETREAT`, `step(centro, centro do mago ou null, delta)`, `bite()`); `GuardianShield` (`tick`, `current()` vazio na brecha, `is_blinking()`, `resolve(ataque, forma)` → `{blocked, damage, effect}`).
- `Enemy` (`src/nodes/combat/enemy.gd`, herda de `TrainingTarget`, grupos `alvos` e `inimigos`): `setup(id, elemento, vida, tamanho)`, `health` (`Health` sem invencibilidade), `hit(elemento, forma)` → `_resolve` (o guardião troca pelo escudo) → `apply_damage`; `_think(delta)` por tipo; área `Contact` que emite `touched_player` a cada quadro encostado; barra de vida (`life_bar_rect()`); `defeated`: sai dos grupos na hora e some 0,4 s depois; `shield_element()`. Tipos: `Elemental`, `SwarmBug`, `Guardian`.
- `Room`: cria os inimigos, `enemies()` (vivos), sinal `player_attacked(de, dano)`; `player` vem do `World` antes de a sala entrar na árvore.
- `World`: `current_enemies()` (vivos, até 12 tiles, do mais perto para o mais longe), `_target_view` (inimigo traz `vida` e `escudo`), `_on_player_attacked` (dano `ATTACK` e `PlayerMotor.knock_back`). Os inimigos reaparecem porque `go_to` monta a sala de novo (também ao morrer).
- `Health`: bloquear com o escudo também dá 1 s de invencibilidade (regressão da Sprint 10: sem isso, o inimigo encostado mordia no quadro seguinte).
- Aceitação em `tests/acceptance/test_combate_01..04.gd`, com o `PuzzleDriver` (o nome ficou da Sprint 9; serve para qualquer sala).

### Chefe (spec COM-chefe)

- Autoria: `"inimigo:chefe"` em `targets`, mais `chefe:ponto` (pontos no ar, na ordem dos dígitos) e `chefe:investida` (dois pontos no chão); a sala do jogo é a arena `sala_c04` (40×22, Sprint 17, gerada por script), com uma porta `|` do chão ao teto que abre quando o chefe cai.
- `BossPhases` (`src/core/combat/`, regra pura): três fases (`chefe.elementos`), limites `chefe.troca_vida` (60, 30) que nenhum golpe pula, `resolve`, `after_damage(vida)` → true quando troca (uma fase por vez), `in_transition()`, `tick(delta)` → true quando a transição termina.
- `BossBrain` (`src/core/combat/`, regra pura, Sprint 17): dono das fases e do ciclo mover → aviso → ataque → descanso; `tick(delta, centro_do_mago)` devolve eventos (`mover`, `aviso`, `leque`, `marca`, `pilar`, `pilar_fim`, `investida`, `cancelar`); `marks` (marcas de pilar com o relógio), `charging()`, `destination()`, `fan(mira, n, graus)`, `floor_finder` (o nó liga `RoomLayout.floor_below`). Tempos e listas por fase em `balanceamento.json`.
- `Boss` (`src/nodes/combat/boss.gd`, herda de `Enemy`): aplica os eventos do cérebro (cria `BossBolt` em leque e `BossPillar`, faixa da investida), `position = brain.position`, `phases` é o do cérebro, `warning`, `pillars()`, `arena(pontos, investida, layout)`; troca elemento, nome e cor no começo da transição; `any_distance = true` (alvo a qualquer distância: `World.current_target`/`current_enemies` e o `Projectile` que o persegue não têm o limite de 12 tiles). `BossBolt` (grupo `orbes_chefe`) e `BossPillar` (grupo `pilares_chefe`, marca piscando e pilar que machuca enquanto está de pé) emitem `hit_player(de, dano)`.
- `Room`: `boss_beaten` (o World passa antes de pôr a sala na árvore; a sala nasce sem chefe e com a porta aberta), sinal `boss_defeated(room_id)`; o orbe chega ao World pelo mesmo `player_attacked` do contato. `World.defeated_bosses` guarda as salas na sessão.

### Balanceamento (spec BAL-valores)

- `game/content/balanceamento.json`: seções `mago`, `executor`, `dano`, `elemental`, `enxame`, `guardiao`, `chefe`. **Nenhum número de dificuldade ou de custo fica em constante.** Sensação (pulo, esquiva, empurrão, velocidade dos projéteis do mago) continua nas classes.
- `Balance` (`src/core/balance/balance.gd`, estática): carrega na primeira consulta; `number`/`integer`/`list(seção, chave)` (0 ou `[]` se faltar), `rules()` (a seção `executor`), `validate(dados)`, `errors()`, `use_file(caminho)` e `reset()` para os testes (sempre `reset()` no `after_test`).
- Quem lê: `Damage`, `ElementTable.multiplier`, os cérebros e o escudo do guardião (em variáveis de instância, lidas na criação), os nós dos inimigos (vida), `Enemy` (contato), `MagoState` (vida, invencibilidade), `Progression` (XP e curva de níveis), `BossPhases`, `BossBrain`, `BossBolt`, `BossPillar`.
- `World._execute` e `GrimoireUI` (Testar e estimativa) mandam `Balance.rules()` como `regras` em toda requisição. O executor mantém `REGRAS_PADRAO` como padrão; `executor/tests/test_balanceamento.py` exige que seja igual à seção `executor`.

### Progressão (specs PRO-xp, PRO-niveis)

- `Progression` (`src/core/mago/progression.gd`, estática): `level_for(xp)`, `mana_max_for(nível)`, `next_threshold(nível)` (-1 no último), `max_level()`, `puzzle_xp(estrelas)`, `economy_bonus(estrelas)`. Lê as seções `xp` e `niveis` do balanceamento.
- `Enemy.setup(id, elemento, tipo, tamanho)`: `tipo` (`elemental`, `enxame`, `guardiao`, `chefe`) é a seção da vida e a chave da XP; `Enemy.xp`.
- `World`: `_on_enemy_defeated(xp)` (todo inimigo derrotado, inclusive os que reaparecem), XP do puzzle em `_on_puzzle_solved` (só roda na primeira vez), `_gain_xp(n, mensagem)` escreve no registro; `_on_leveled_up` avisa o nível.

### Diálogo (spec NAR-dialogo)

- `content/dialogos.json`: `{"<cena>": {"inicio", "falas": {"<id>": {"quem", "texto", "proxima" | "opcoes": [{"texto", "proxima"}]}}}}`; textos são chaves do `textos.csv`.
- `DialogueBook` (`src/core/narrative/`): `load_file`, `from_data(dados, has_text)`, `validate` (cena e fala no erro; confere também que toda fala é alcançada e chega a um fim), `can_play(cena)`, `start(cena)` → `DialogueRun` (`current()`, `advance()`, `choose(n)`, `is_finished()`, `line_id`).
- `DialogueBox` (`src/nodes/narrative/`, CanvasLayer `layer = 11`, `PROCESS_MODE_ALWAYS`): no alto da tela, pausa a árvore enquanto aberta, consome toda a entrada; `open(run)`, `advance()`, `choose(n)`, `panel_rect()`, sinal `finished`.
- `Serpent` (`src/nodes/narrative/`): `serpente:<cena>` em `targets`; `in_reach()` (2 tiles), aviso `E: falar`, `prompt_rect()`. `World.talk()` (ação `talk`, tecla E) abre a cena da serpente ao alcance e liga `GrimoireUI.blocked` até o fim; cena com erro vai para `authoring_errors`.

### Lições e dicas da serpente (specs NAR-serpente, NAR-dicas)

- `content/dialogos.json`: uma cena `ensino_<conceito>` por sala de puzzle, cada uma com a fala `licao` (`World.LESSON_LINE`). `content/dicas.json`: `{"<puzzle>": [3 chaves]}`.
- `HintBook` (`src/core/narrative/hint_book.gd`): `load_file`, `validate`, `hints(puzzle)`, `has_hints`, `scene(puzzle, nível)` monta a cena `pergunta` → `dica` | `nao` (`HINT_LINE = "dica"`).
- `DialogueRun.has_seen(fala)`: a lição e a dica contam pela fala que apareceu.
- `World.talk()`: lição não vista → lição; vista e puzzle aberto com dicas → `hints.scene(puzzle, usadas + 1)`; senão, a lição. `_on_dialogue_finished` atualiza `seen_lessons` e `hints_used` (teto 3) e salva.

### Save (spec SAV-progresso)

- `Main` (`src/nodes/main/main.gd` + `main.tscn`, **cena principal**): perfil `user://perfis/padrao/`, copia `user://grimorio.json` antigo se o perfil não tem grimório e, pelo menu inicial (Sprint 14), sobe o `World` com `grimoire_path` e `save_path` do perfil. Exports `profile_root`, `profile`, `legacy_grimoire` (os testes trocam).
- `ProgressStore` (`src/core/save/progress_store.gd`): `save(dados)` atômico com `versao`; `load_data()` devolve vazio sem arquivo, e com arquivo ilegível ou versão desconhecida também, preenchendo `last_problem` e copiando para `.bak`. Migrações de versão entram em `load_data`.
- `World`: `save_path` vazio = sem save (todos os testes antigos). `_load_progress()` no `_ready`, antes da primeira sala; `apply_progress(dados)` aceita campo ruim (usa o padrão); `progress_snapshot()`; `save_progress()` em `go_to`, puzzle resolvido, chefe derrotado, subida de nível, fim de diálogo, baú, fonte, Voltar ao menu e `NOTIFICATION_WM_CLOSE_REQUEST`. Desde a Sprint 14 o save tem `segredos` e `atalhos`.
- `MagoState.restore_progress(xp, mana)`: nível e mana máxima vêm da XP, sem `leveled_up`.

### Mapa, segredos e fonte (specs MUN-mapa, MUN-segredos, MUN-vida regra 9)

- 13 salas em `content/rooms/`; o caminho e os bloqueios estão em `docs/mapa-area.md`. Cada puzzle declara `licoes` (cenas da serpente que ensinam o que ele cobra).
- `AreaMap` (`src/core/world/area_map.gd`): `load_dir`, `add_room`; `reach(sala, entrada, abertas)` faz um flood fill de células (pedra e porta fechada bloqueiam, sem gravidade: o máximo que o mago alcança voando) e devolve salas, células, entradas e portas encostadas; `walkthrough` abre cada porta quando pode (puzzle: serpentes das lições alcançadas; chefe: ao chegar; atalho: ao chegar na entrada do atalho) e devolve a ordem dos puzzles. `puzzles()`, `secret_ids()`, `lesson_ids()` alimentam o resumo do fim.
- Porta de atalho (`%`): `Room.atalho_entrada`; `World.go_to` marca `opened_shortcuts[sala]` quando o mago entra por ela e chama `Room.open_shortcut()` sempre que a sala já tem o atalho aberto.
- `Chest` (`src/nodes/world/chest.gd`): `segredo` em `targets`; a `Room` cria a área do baú e emite `secret_found("<sala>_<dígito>")` só na primeira vez; `World._on_secret_found` dá `xp.segredo` e salva. `Room.found_secrets` (passado antes do `_ready`) faz o baú nascer aberto.
- `Fountain` (`src/nodes/world/fountain.gd`): `fonte` em `targets`; `World.talk()` sem serpente perto chama `drink()` (vida e mana cheias, salva).

### Menus e opções (spec UI-menus)

- `Main` abre no `TitleMenu`; `continue_game()` sobe o `World` com o save, `new_game()` pergunta se há save e apaga só o `save.json`; `return_to_menu()` salva e libera o mundo. Ela liga `PauseMenu` (Esc, `handle_cancel()`; só abre com o jogo correndo, e bloqueia o grimório), `OptionsMenu` e `EndScreen` (sinal `World.demo_finished` → `World.summary()`).
- `MenuPanel` (`src/nodes/ui/menu_panel.gd`): base dos menus, `CanvasLayer` com `PROCESS_MODE_ALWAYS`, foco no primeiro botão. As opções ficam depois da pausa na árvore para receber o Esc primeiro.
- `Settings` (`src/core/settings/settings.gd`): `TextSize` (Normal/Grande/Muito grande = +0/+2/+3), `volume` de 10 em 10, `<perfil>/opcoes.json` com gravação atômica. `FontScale.apply(nó, pontos)` soma pontos a todo `font_size` sobrescrito, guardando o original em metadado; `GrimoireUI.set_text_delta` e `DialogueBox.set_text_delta` (que sobe a caixa para `TOP_LARGE_TEXT` com texto maior).

### Build e fumaça (spec BLD-alpha)

- `game/export_presets.cfg`: preset `Windows Desktop` (x86_64, `.pck` separado, `.console.exe`), `include_filter="content/*.json"` (os JSON não são recursos importados), `exclude_filter` com `tests/`, `addons/gdUnit4/`, `reports/` e `tools/`.
- `scripts/build_windows.ps1`: `--import`, `--export-release`, copia `executor/run_worker.py` + `arcane_executor/` e `runtime/python/` sem o que o worker não usa, `docs/build/LEIA-ME.txt`, roda a fumaça no `.console.exe` e gera o `.zip` só se ela passar.
- `SmokeCheck` (`src/nodes/main/smoke_check.gd`): `requested(args)`, `run()` devolve a lista de problemas (balanceamento, diálogos, dicas, referência, `tr("MENU_TITULO")`, `AreaMap.walkthrough` em todas as salas, executor com `meditar()` + `print`), também o contrato da arte; `report()` imprime `FUMACA OK`. A `Main` verifica `user_args` antes de tudo, roda a fumaça e fecha com 0 ou 1 (`quit_after_smoke`); os menus só são criados depois.
- No jogo exportado, `PythonSpellExecutor.base_dir()` é a pasta do `.exe`; `AreaMap.load_dir` aceita as cenas `.tscn.remap`.

### Arte (spec ART-esteira)

- Contrato: `content/arte.json` (pasta → quadro e animações com `fps`, `laco`, `reserva`, `elementos`; imagens paradas com `imagem`/`tamanho`). `ArtCatalog` (`src/core/art/`, puro) lê e confere um PNG (`check`: altura, largura múltipla do quadro, nome, pixel semitransparente, cor fora da `assets/paleta.png`). `test_arte_entregue.gd` varre `game/assets/` (menos `placeholder/`).
- `ArtLibrary` (`src/nodes/art/`, estática): `texture(pasta, nome)`, `sprite_frames(pasta, nomes)` (cadeia de reservas) e `sprite(pasta, nomes)` (AnimatedSprite2D com a base do quadro na origem); null sem arquivo, e quem pediu fica no provisório. Lê pelo `ResourceLoader` (importado) ou direto do PNG; os testes trocam a pasta com `use_root` e chamam `reset()` no `after_test`.
- Mago: `PlayerAnimation` (`src/core/player/`, puro) escolhe a animação (dano > esquivar > ação > ar > andar > parado); `Player.play_action(acao, s)` (o `WorldActions` chama em lançar, inscrever, meditar, absorver e cajado) e `Player.hurt()` (o `World` chama quando a vida cai). `PlayerVisual` (nó `Visual` do `player.tscn`): arte de `mago/` espelhada pelo `facing`, ou o mago provisório desenhado por código.
- Paredes: `TileShape` (puro) dá o número de 4 bits da vizinhança (1 cima, 2 direita, 4 baixo, 8 esquerda; fora da sala conta como pedra) e a coordenada no atlas 4×5. `Room.tiles_source` diz de onde veio a imagem.
- Fundo: `Backdrop` (filho do `World`, `z_index` −100): cor sólida num `CanvasLayer` −100, três `Parallax2D` (0,2, 0,45, 0,7; repetem a cada 640 px) e uma moldura escura em volta da sala (`fit`, chamado no `go_to`).
- `TrainingTarget._art()` devolve `[pasta, principal, outras...]` (o elemental pede `andar_<elemento>` e `morrer_<elemento>`; o cristal, `cristal_apagado` e os acesos); sem a principal fica o retângulo, com contorno escuro. `top_height()` é o pixel mais alto do desenho (`ArtLibrary.drawn_height`), para o nome e a barra de vida. `Serpent`, `Projectile`, `Shield`, `Chest`, `Torch` e `RuneDoor` (`art_sprites`, uma por célula) também têm arte opcional.
- Primeira leva de arte (regras 21 a 28): `ArtLibrary.effect(pai, pasta, nome, posição)` toca uma vez e some (impacto do projétil); `PlayerVisual.aura` (`magia/meditar`) aparece só meditando; inimigo derrotado com `morrer` fica até a animação acabar (`ArtLibrary.duration`); `SwarmBug` troca para `mergulhar`; `Guardian.shield_sprite` substitui o círculo (`draws_shield_circle()`); `Crystal.lit_element`; `tocha` em `targets` é um `Torch` (decoração, fora dos alvos).
- Projeto: `snap_2d_transforms_to_pixel` e `snap_2d_vertices_to_pixel` ligados (sem isso, o texto pequeno do mundo embaralhava com a câmera suave).

### Referência (spec GRI-referencia)

- `content/referencia.json`: lista `[{"id", "requer": [peças]}]` (13 páginas de peças e, desde a Sprint 13, 5 de conceito); título e texto são `REF_<ID>_TITULO`/`REF_<ID>_TEXTO` (BBCode, `\n` no CSV vira quebra de linha).
- `ReferenceBook` (`src/core/grimoire/reference_book.gd`): `load_file`, `from_data`, `validate`, `visible_pages(desbloqueadas)`, `title(id)`, `text(id)`.
- `GrimoireUI`: `tabs` (Feitiços | Referência), `show_reference()`, `show_spells()`, `select_page(id)`, `reference_list`, `reference_text`; as peças desbloqueadas vêm do contexto (`pieces`).

### Cliente do executor (spec EXE-protocolo)

- `SpellExecutor` (Node): interface, `execute(request) -> SpellResult`, sempre chamado com `await`.
- `PythonSpellExecutor`: sobe o worker com `OS.execute_with_pipe(python, ["-I", "-S", "-u", run_worker.py])`; cada `execute` roda a ida e volta numa `Thread` (o pipe vai como argumento) e espera com `await process_frame` (não trava o jogo). Chamadas simultâneas esperam numa fila (`_busy`). **Watchdog:** passou de `timeout_ms` (padrão 3000), mata o worker e devolve `TempoEsgotado`. Se o processo morreu, sobe outro na próxima chamada. `_exit_tree` mata o worker.
- `PythonSpellExecutor.base_dir()`: pasta que contém `executor/` e `runtime/`. No editor (inclusive nos testes) é a raiz do repo; no jogo exportado, a pasta do `.exe`.
- Python usado, nesta ordem: `python_path` exportado → env `ARCANE_PYTHON` → `<base_dir>/runtime/python/python.exe` (Windows) ou `bin/python3` → `python`/`python3` do PATH.
- `SpellRequest.make(code, mago, target=null, rules={}, pieces=null, room={})` → `to_dict(id)`; `room` vira `mundo.sala` quando não está vazio.
- `SpellResult.from_dict(data)`: `ok`, `actions: Array[Dictionary]`, `outputs`, `mago`, `cost` (float, `custo_mana`), `error: SpellError` (ou null). `SpellResult.failure(tipo, msg)` para falhas do lado Godot (`ExecutorIndisponivel`, `RespostaInvalida`).
- `SpellError`: `type`, `message`, `line`, `column`; `NO_POSITION = -1` representa null.

### Ferramenta de desenvolvimento

`src/nodes/dev/spell_console.tscn`: editor + botão Executar (Ctrl+Enter), mostra visões, ações, erro (linha pintada) e mana final. Não é parte do jogo.

## Executor Python (`executor/arcane_executor/`)

| Módulo | Papel |
| --- | --- |
| `worker.py` | Limita a própria memória (256 MB: Job Object no Windows, `RLIMIT_AS` no Linux); loop: lê linha do stdin (UTF-8), escreve resposta no stdout real, `flush` |
| `protocol.py` | `handle_line(str) -> str`, `handle_request(dict) -> dict`; valida requisição; JSON de saída com `ensure_ascii=True` |
| `runner.py` | `run_spell(codigo, mago, alvo, regras, pecas, sala, inimigos)`: `ast.parse` → `sandbox.verificar` → `instrumentar` (ganchos de custo e de volta) → `compile` como `<feitico>` → `exec`; captura erros com a linha do jogador |
| `sandbox.py` | Verificador da AST (imports, nomes `__`, atributos `_`, `except:`/`BaseException`), builtins em lista branca, `getattr` e companhia protegidos, importador com lista branca (`math`, `random`) |
| `pieces.py` | `Contexto` (fila de ações, saídas, mago simulado em gotas, custo, ganchos `instrucao`/`volta`, limites), peças, `Alvo` somente leitura (`elemento`, `distancia`, `vida`, `escudo`; criado por `_alvo_da_foto`, fora da classe, para o feitiço não fabricar alvos), exceções de limite, `linha_do_jogador()` |
| `run_worker.py` | Entrada; põe `executor/` no `sys.path` (necessário porque `-I` não faz isso) |

Pontos importantes:

- O código do jogador é compilado com o nome de arquivo `<feitico>`. É assim que `linha_do_jogador()` e o traceback encontram a linha certa, ignorando os frames do executor.
- Sentidos (`mana`, `mana_max`, `vida_atual`) são variáveis globais do namespace, ressincronizadas depois de cada instrução paga. `alvo` é um objeto `Alvo` ou `None`; `inimigos` é uma `list` nova de `Alvo` a cada execução, e o alvo que também está na lista é o mesmo objeto.
- Elementos e formas são strings (`fogo = "fogo"`).
- Erro de execução não descarta o que rodou antes; o executor captura qualquer exceção (menos `KeyboardInterrupt`).
- **Custo (EXE-custo):** a instrumentação insere `__instrucao__(linha)` depois de cada instrução simples (antes de `return/break/continue/raise`) e `__volta__(linha)` no início de cada volta de laço. O gancho de instrução cobra `custo_instrucao` (mais `custo_inscricao` na primeira vez de cada linha, guardada em `Contexto.inscritas`), aplica o teto `mana_max` e sincroniza os sentidos; os dois ganchos conferem o tempo. Peças cobram o custo base na chamada.
- **Mana em gotas:** 1 mana = 10 gotas (inteiros); `para_gotas`/`para_mana` convertem. Valores inteiros saem como `int` na resposta.
- **Limites (EXE-limites):** `ManaEsgotada`, `TempoEsgotado` e `LimiteExcedido` herdam de `BaseException`; depois do primeiro estouro, todo gancho relança o mesmo erro (`Contexto.estouro`).

## Protocolo v1 (resumo; detalhes em `docs/specs/executor/EXE-protocolo.md`)

Requisição: `{versao: 1, id, codigo, mundo: {mago: {vida, mana, mana_max}, alvo: {id, elemento, distancia, vida?, escudo?} | null, sala?: {runas: [int]}, inimigos?: [{id, elemento, distancia, vida?, escudo?}]}, pecas?: [..], regras?: {ganho_meditar, ganho_absorver, custo_instrucao, custo_inscricao, custo_lancar, custo_faisca, custo_mover, custo_levitar, custo_meditar, custo_absorver, custo_inscrever, custo_bloco, limite_tempo_ms}}`

Resposta: `{versao: 1, id, ok, acoes: [{tipo, linha, ...}], saidas: [{linha, texto}], mago: {...} | null, custo_mana, erro: {tipo, mensagem, linha, coluna} | null}`

Tipos de erro do executor além das exceções do Python: `RequisicaoInvalida`, `ManaEsgotada`, `TempoEsgotado`, `LimiteExcedido`, `FeiticoProibido`. Do Godot: `ExecutorIndisponivel`, `RespostaInvalida`, `TempoEsgotado` (watchdog).

Ações: `lancar {elemento, forma (projetil, escudo, faisca), alvo}`, `mover {passos}`, `levitar {altura}`, `meditar`, `absorver_mana`, `inscrever {valor}`, `construir_bloco`. Sentido-função: `ler_runa(n)` (não gera ação).

## Testes

| Suíte | Onde | Como rodar |
| --- | --- | --- |
| pytest | `executor/tests/` | `cd executor && python -m pytest` |
| GdUnit4 | `game/tests/` | `cd game && GODOT_BIN=... bash addons/gdUnit4/runtest.sh --headless -a res://tests --ignoreHeadlessMode` (Windows: `runtest.cmd`) |
| Tudo | — | `GODOT_BIN=... scripts/test.sh` |
| CI | `.github/workflows/ci.yml` | A cada push: job pytest (Python 3.14) e job GdUnit4 (Godot 4.7.2 Linux + Python 3.14) |

Convenções:

- Nome do teste carrega o ID da spec: `test_EXE_019_loop_sobre_a_mana`, `test_MUN_004_pular_do_chao`.
- Cabeçalho do arquivo de teste aponta a spec.
- Fixtures de contrato: `tests/contract/NN_nome.json` com `descricao`, `requisicao`, `resposta`. O pytest exige `handle_request(requisicao) == resposta`; o Godot exige que `SpellResult.from_dict(resposta).to_dict()` volte igual.

### Armadilhas já encontradas

| Situação | O que fazer |
| --- | --- |
| Em headless o Godot não entrega eventos de input | Testes de cena injetam `PlayerIntent` via `intent_source`, nunca simulam teclas |
| GdUnit4 recusa rodar headless | Passar `--ignoreHeadlessMode` |
| `ERROR: Remote Debugger ... 127.0.0.1:0` na saída | Esperado; o script do GdUnit4 provoca isso para evitar travar no depurador |
| Quando uma suíte falha, só o primeiro teste dela apareceu no relatório | Observado na Sprint 0; não confiar na contagem quando há falha |
| Script novo com `class_name` não é encontrado pelos testes | Rodar `godot --headless --path game --import` antes, para atualizar o cache de classes |
| `JSON.parse_string` do Godot lê todo número como float | Converter `linha` para int (`SpellResult`); comparar com fixtures via `ContractFixtures.normalize` |
| `res://` não alcança a raiz do repositório | `PythonSpellExecutor.base_dir()`: no editor usa `globalize_path("res://") + "/.."`; no jogo exportado, a pasta do `.exe` |
| Python com `-I` não põe a pasta do script no `sys.path` | `run_worker.py` insere manualmente |
| Inimigo derrotado some 0,4 s depois do último golpe | Em teste, guardar o que precisa pelos sinais (`was_hit`, `defeated`); ler o nó depois disso dá "previously freed" (Sprint 10) |
| Captura de tela por script esperando `process_frame` | A janela desenha bem mais rápido que a física: esperar `physics_frame` para o mundo andar de verdade (Sprint 10) |
| `ActionPlayer.play` com só ações desconhecidas emite `finished` antes de devolver | Um `await player.finished` depois disso trava o teste até o tempo limite; achado na Sprint 9 |
| O pytest não está instalado no Python 3.14 embutido | Rodar com o pytest do Python local no `sys.path`: `runtime/python/python.exe -c "import sys; sys.path.append(r'<site-packages>'); import pytest; pytest.main(['-q', '-p', 'no:cacheprovider'])"` |
| Script Python gravando arquivo com `write_text` no Windows | Grava CRLF; usar `write_bytes(texto.encode())` para manter LF |
| `python` do PATH no Windows é o alias da Microsoft Store | Usar `runtime/python` (`scripts/fetch_python.sh`) |
| Executável do Godot para linha de comando | `Godot_v4.7.2-stable_win64_console.exe` (o sem `_console` não mostra saída) |
| Teste com laço infinito trava o pytest quando o limite ainda não existe | Rodar a suíte com `timeout` no comando; no TDD de limites, o vermelho é um travamento |
| Feitiço em teste com muitos `print`/ações esgota a mana padrão (5) antes do limite testado | Dar mana alta no teste |
| `10 ** 10 ** 8` não é calculado na compilação (o otimizador do Python recusa resultados enormes) | Serve para testar o watchdog: trava em código C, sem passar pelos ganchos |
| `Area2D` recém-criada dispara com a posição antiga do corpo no primeiro quadro | `Room` liga as áreas só depois do primeiro quadro de física |
| Trocar de sala ou teleportar dentro de `body_entered` | Sempre `call_deferred` |
| Teste que segura uma direção e espera N quadros "passa do ponto" depois de uma transição | Soltar a direção no sinal `room_changed` (`_walk_until_room` em `test_world.gd`) |
| Mago posto dentro de um tile sólido é empurrado para fora (às vezes para cima do teto) | Em testes, soltar o mago em célula vazia |
| `assert_*` do GdUnit4 não mostra o valor real em alguns casos | `override_failure_message("valor=%s" % ...)` temporário para diagnosticar |
| Captura de tela por script (`-s`) | Esperar um `process_frame` no `_initialize` antes de adicionar cenas |
| Testes e jogo compartilham `user://` | Testes usam `user://tests/…` e apagam os arquivos no `after_test` |
| Teste que pausa a árvore | Despausar no `after_test` (`get_tree().paused = false`) |
| `PackedStringArray([...])` não é expressão constante em GDScript | Usar `const X: Array[String] = [...]` e converter onde precisar |
| Guardar uma corrotina numa variável para esperar depois não funciona | Chamar sem `await` e esperar um sinal (ex.: `await world.spell_cast`) |
| Heredoc no Bash com scripts grandes falha às vezes ("unexpected EOF") | Escrever o script num arquivo (scratchpad) e rodar com `python arquivo.py` |
| Substituição de texto pega a primeira ocorrência, que pode estar em outro lugar (ex.: dentro de um setter) | Usar um trecho maior e único; conferir com `--check-only` se a classe não compilar |
| `godot --check-only -s res://arquivo.gd` | Mostra o erro de compilação exato de um script |
| `await get_tree().physics_frame` continua chegando com o jogo pausado | Para esperar em tempo de jogo: `create_timer(t, false, true)` ou pular quadros com `get_tree().paused` |
| O grimório aberto faz uma estimativa de custo (requisição com mana 1000) mesmo com o jogo pausado | Em testes que contam requisições, filtrar as de estimativa (`GrimoireUI.ESTIMATE_MANA`) |
| Porta baixa numa sala alta | Com `levitar` o mago voa por cima; toda porta vai do chão ao teto, e `test_area_map.gd` confere (Sprint 14) |
| `.gitignore` com `build/` sem barra | Esconde também `docs/build/` e `docs/specs/build/`; usar `/build/` (Sprint 15) |
| Script `.ps1` com acento no PowerShell 5.1 | Gravar em UTF-8 **com BOM**; stderr de programa nativo com `ErrorActionPreference = Stop` vira erro: decidir por `$LASTEXITCODE` |
| Menus em teste | Teclas não chegam em headless: apertar com `botão.pressed.emit()` e chamar `PauseMenu.handle_cancel()` no lugar do Esc |
| Texto pequeno (7 px) no mundo embaralhado | A câmera suave deixava o texto entre pixels; o projeto prende o desenho 2D à grade (`rendering/2d/snap`), e `test_ART_032` confere (Sprint 16) |
| Sala menor que a tela | Mostrava o fundo em volta e parecia flutuar; o `Backdrop.fit` põe uma moldura escura (Sprint 16, `test_ART_031`) |
| Arte provisória nova ou mudada | Rodar `godot --headless --path game -s res://tools/gerar_provisorio.gd` e depois `--import`; o PNG só vira recurso depois do import |
| Teste que troca a pasta de arte (`ArtLibrary.use_root`) | Chamar `ArtLibrary.reset()` e `ArtFixtures.clear()` no `after_test`, senão a pasta de teste vaza para as outras suítes |
