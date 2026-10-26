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
| `game/src/core/` | Regras puras, sem Node |
| `game/src/nodes/` | Cenas e scripts de cena (`player/`, `world/`, `ui/`, `magic/`, `puzzles/`, `combat/`, `grimoire/`, `fx/`, `dev/`) |
| `game/content/rooms/` | Salas do jogo (cenas `Room` com layout em texto) |
| `game/assets/placeholder/` | Arte provisória (tileset de 3 tiles) |
| `game/tests/fixtures/rooms/` | Salas pequenas usadas pelos testes |
| `game/src/executor_client/` | Cliente do executor Python |
| `game/content/` | Conteúdo de dados (hoje só `text/textos.csv`) |
| `game/tests/` | GdUnit4: `unit/`, `scene/`, `integration/`, `acceptance/`, `support/` |
| `game/addons/gdUnit4/` | GdUnit4 v6.2.2 (código de terceiros, não editar) |
| `executor/` | Pacote Python `arcane_executor` + `run_worker.py` + `tests/` (pytest) |
| `tests/contract/` | Fixtures JSON do protocolo, usadas pelas duas suítes |
| `scripts/` | `test.sh` (roda tudo), `fetch_python.sh` (baixa o Python embutido) |
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
- `MagoState` (`src/core/mago/mago_state.gd`): `health` (5), `mana` (0) e `mana_max` (10) com resolução 0,1; sinal `mana_changed`; `to_spell_mago()` gera o `mago` do protocolo. **A mana real mora aqui**; o executor só simula.
- `RoomLayout` (`src/core/world/room_layout.gd`): lê o layout em texto (`#` pedra, `=` plataforma, `^` espinhos, `*` ponto seguro, `A–Z` entradas, `a–z` saídas); `cell_feet(cell)`, `size_px()`, `errors`.
- `Room` (`src/nodes/world/room.gd`): cena com `room_id`, `layout` e `exits` (`{"b": "sala_02:A"}`). No `_ready` monta um `TileMapLayer` com `assets/placeholder/tiles.tres` e cria `Area2D` para saídas, espinhos e pontos seguros, que **só ligam depois do primeiro quadro de física**. Sinais: `exit_touched`, `hazard_touched`, `safe_point_touched`.
- `World` (`src/nodes/world/world.gd` + `world.tscn`, cena principal): tem `Player` e `Hud`; `go_to(sala, entrada)` troca a sala (sempre adiado para fora do callback de física), põe o mago na entrada, ajusta os limites da câmera e o ponto seguro. Espinho: 1 de dano (ignora a esquiva) e volta ao ponto seguro. Morte: vida cheia e volta à entrada da sala atual. `rooms_dir` configurável (testes usam `res://tests/fixtures/rooms/`); `authoring_errors` junta erros de autoria.
- `Hud` (`src/nodes/ui/hud.gd`, CanvasLayer montado em código): `life_label`, `mana_label`, `mana_bar`, dica de controles; `bind(state)`.
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

- Salas do jogo: `content/rooms/sala_01..03.tscn` (sala_01 tem o Puzzle 1) (40–60 × 23 tiles), `sala_p02..p06.tscn` (Puzzles 2 a 6), em sequência a partir da saída `b` da sala_03, e `sala_c01..c03.tscn` (combate), depois da porta da sala_p06 (tudo provisório até a Sprint 14). As salas `sala_p0N` e `sala_c0N` foram geradas por script; se mudar uma, confira a geometria (o elevador depende de colunas de 2 tiles coladas). Tileset provisório: `assets/placeholder/tiles.png` (pedra, plataforma, espinhos; ver `LEIAME.md` ali).

### Combate (specs COM-dano, COM-elemental, COM-enxame, COM-guardiao)

- Autoria: em `targets`, `"inimigo:elemental[:fogo|gelo|planta]"`, `"inimigo:enxame[:n]"` (1 a 9, padrão 6) e `"inimigo:guardiao"`. Ids `<sala>_alvo_<dígito>`; no enxame, `<sala>_alvo_<dígito>_<n>`.
- Regras puras (`src/core/combat/`): `Damage.amount(ataque, forma, elemento)` (projétil 3, faísca 1, cajado 1, vezes o multiplicador, truncado); `ElementalBrain` (`velocity_x(pés, pés do mago ou null, ahead_free)`, `can_walk(layout, pés, direção, meia largura)`: não entra em parede nem sai do chão); `SwarmBugBrain` (`HOVER`/`DIVE`/`RETREAT`, `step(centro, centro do mago ou null, delta)`, `bite()`); `GuardianShield` (`tick`, `current()` vazio na brecha, `is_blinking()`, `resolve(ataque, forma)` → `{blocked, damage, effect}`).
- `Enemy` (`src/nodes/combat/enemy.gd`, herda de `TrainingTarget`, grupos `alvos` e `inimigos`): `setup(id, elemento, vida, tamanho)`, `health` (`Health` sem invencibilidade), `hit(elemento, forma)` → `_resolve` (o guardião troca pelo escudo) → `apply_damage`; `_think(delta)` por tipo; área `Contact` que emite `touched_player` a cada quadro encostado; barra de vida (`life_bar_rect()`); `defeated`: sai dos grupos na hora e some 0,4 s depois; `shield_element()`. Tipos: `Elemental`, `SwarmBug`, `Guardian`.
- `Room`: cria os inimigos, `enemies()` (vivos), sinal `player_attacked(de, dano)`; `player` vem do `World` antes de a sala entrar na árvore.
- `World`: `current_enemies()` (vivos, até 12 tiles, do mais perto para o mais longe), `_target_view` (inimigo traz `vida` e `escudo`), `_on_player_attacked` (dano `ATTACK` e `PlayerMotor.knock_back`). Os inimigos reaparecem porque `go_to` monta a sala de novo (também ao morrer).
- `Health`: bloquear com o escudo também dá 1 s de invencibilidade (regressão da Sprint 10: sem isso, o inimigo encostado mordia no quadro seguinte).
- Aceitação em `tests/acceptance/test_combate_01..03.gd`, com o `PuzzleDriver` (o nome ficou da Sprint 9; serve para qualquer sala).

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
