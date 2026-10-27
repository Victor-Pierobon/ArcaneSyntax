class_name World
extends Node2D
## Carrega a sala atual e liga mago, HUD e salas: transições, espinhos, pontos seguros
## e renascimento (specs MUN-salas e MUN-vida).

signal room_changed(room_id: String)
## Emitido quando uma conjuração termina (spec GRI-slots).
signal spell_cast(slot_number: int, result: SpellResult)
## A conversa do fim da demonstração terminou (spec UI-menus, regra 7); a cena principal mostra o resumo.
signal demo_finished

## Raio em que um boneco ou inimigo vira o "alvo" dos feitiços (spec MUN-alvos).
const TARGET_RANGE_TILES := 12.0
## Pausa base entre ações nas salas com puzzle, dividida pela velocidade (spec PUZ-passo-a-passo).
const STEP_DELAY := 0.3
const STEP_SPEEDS := [1.0, 2.0, 0.5]
## Trauma da câmera quando o mago se machuca, e o congelamento dos golpes do chefe (ART-brilho, 6 e 7).
const SHAKE_HURT := 0.3
const HIT_STOP := 0.06
## Onde a runa do código nasce, a partir dos pés do mago.
const RUNE_OFFSET := Vector2(0, -40)
## A fala que faz a lição contar como vista (spec NAR-serpente, regra 2).
const LESSON_LINE := "licao"
## A cena da serpente na `sala_fim` e a fala que encerra a demonstração (UI-menus, regra 7).
const END_SCENE := "fim_demo"
const END_LINE := "fim"

@export var rooms_dir: String = "res://content/rooms/"
@export var start_room: String = "sala_01"
@export var start_entry: String = "A"
## Arquivo do grimório; os testes usam outro caminho para não tocar no do jogador.
@export var grimoire_path: String = GrimoireStore.DEFAULT_PATH
## Arquivo do save; vazio não salva nem carrega. Quem define é a cena principal (spec SAV-progresso, regra 7).
@export var save_path: String = ""

var state := MagoState.new()
var passive_scheduler := PassiveScheduler.new()
## Puzzles resolvidos: id → {"estrelas": melhor}. Vai para o save.
var solved_puzzles: Dictionary = {}
## Salas cujo chefe foi derrotado: o chefe não volta (spec COM-chefe, regra 7). Vai para o save.
var defeated_bosses: Dictionary = {}
## Tremida da câmera e a opção de desligar (ART-brilho, regras 6 e 8).
var camera_shake := CameraShake.new()
var shake_enabled := true
## Lições da serpente já vistas (cena → true) e dicas usadas por puzzle (NAR-serpente, NAR-dicas).
var seen_lessons: Dictionary = {}
var hints_used: Dictionary = {}
## Baús abertos (id → true, MUN-segredos) e salas com a porta de atalho aberta (MUN-mapa). Vão para o save.
var found_secrets: Dictionary = {}
var opened_shortcuts: Dictionary = {}
var hints := HintBook.load_file(HintBook.DEFAULT_PATH)
## Mana gasta na sala atual pelos feitiços que agem, até o puzzle ser resolvido (PUZ-validacao, regra 14).
var room_mana_spent := 0.0
## Sorteio das runas `?` e dos cristais mutáveis; os testes fixam a semente.
var rng := RandomNumberGenerator.new()
var step_speed := 1.0
var grimoire: Grimoire
var grimoire_store: GrimoireStore
var current_room: Room
## Entrada pela qual o mago chegou na sala atual (para onde volta ao morrer).
var current_entry := ""
var safe_point := Vector2.ZERO
var authoring_errors: Array[String] = []
## Quem executa os feitiços. Os testes trocam por um FakeSpellExecutor.
var executor: SpellExecutor:
	set(value):
		executor = value
		if is_node_ready():
			grimoire_ui.set_spell_runner(executor, spell_context)

var _changing_room := false
## As cenas de diálogo e a caixa que as mostra (spec NAR-dialogo).
var dialogues := DialogueBook.load_file(DialogueBook.DEFAULT_PATH)
var dialogue_box := DialogueBox.new()
## A conversa aberta: a leitura, a lição da serpente e o puzzle da dica oferecida (vazio se não é dica).
var _talk_run: DialogueRun
var _talk_lesson := ""
var _talk_hint_puzzle := ""
var _talk_serpent: Serpent
var _progress_store: ProgressStore
## Vida do quadro anterior, para o mago mostrar o dano (ART-esteira, regra 9).
var _last_health := 0
## O fundo com paralaxe atrás da sala (ART-esteira, regra 16).
var backdrop := Backdrop.new()

@onready var player: Player = $Player
@onready var hud: Hud = $Hud
@onready var grimoire_ui: GrimoireUI = $GrimoireUI
@onready var cast_log: CastLog = $CastLog
@onready var action_player: ActionPlayer = $ActionPlayer
@onready var world_actions: WorldActions = $WorldActions
## Toca as ações do slot passivo, sem atrasar as conjurações (MAG-056).
@onready var passive_player: ActionPlayer = $PassivePlayer
@onready var sfx: Sfx = $Sfx
@onready var step_view: StepView = $StepView


func _ready() -> void:
	backdrop.name = "Backdrop"
	add_child(backdrop)
	move_child(backdrop, 0)
	# A sala fica escura; a HUD, os menus e o grimório são CanvasLayer e não escurecem (ART-brilho, regra 1).
	var shade := CanvasModulate.new()
	shade.name = "Escuro"
	shade.color = Lighting.AMBIENT
	add_child(shade)
	hud.bind(state)
	_last_health = state.health.current
	state.health.changed.connect(func(current: int, _maximum: int) -> void:
		if current < _last_health:
			player.hurt()
		_last_health = current
	)
	grimoire_store = GrimoireStore.new(grimoire_path)
	grimoire = grimoire_store.load_grimoire()
	grimoire_ui.bind(grimoire, grimoire_store)
	hud.bind_slots(grimoire)
	if executor == null:
		executor = $Executor
	grimoire_ui.set_spell_runner(executor, spell_context)
	world_actions.world = self
	action_player.port = world_actions
	passive_player.port = world_actions
	action_player.sequence_started.connect(_on_sequence_started)
	action_player.action_started.connect(_on_action_started)
	action_player.finished.connect(_on_actions_finished)
	state.health.attack_blocked.connect(world_actions.on_attack_blocked)
	grimoire.passive_changed.connect(_on_passive_changed)
	grimoire.spell_code_changed.connect(func(spell_name: String) -> void:
		if spell_name == grimoire.passive():
			_on_passive_changed()
	)
	_update_passive_hud()
	grimoire_ui.load_problem = grimoire_store.last_problem
	if not grimoire_store.last_problem.is_empty():
		push_warning("%s; cópia guardada em %s" % [grimoire_store.last_problem, grimoire_store.backup_path()])
	state.health.died.connect(_on_died)
	state.leveled_up.connect(_on_leveled_up)
	add_child(dialogue_box)
	dialogue_box.finished.connect(_on_dialogue_finished)
	for error in dialogues.errors + hints.errors:
		_report(error)
	if not save_path.is_empty():
		_load_progress()
	go_to(start_room, start_entry)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_progress()


## O que vai para o save (spec SAV-progresso, regra 3).
func progress_snapshot() -> Dictionary:
	return {
		"sala": current_room.room_id if current_room else start_room,
		"entrada": current_entry,
		"mago": {"xp": state.xp, "mana": state.mana},
		"puzzles": solved_puzzles,
		"chefes": defeated_bosses.keys(),
		"licoes": seen_lessons.keys(),
		"dicas": hints_used,
		"segredos": found_secrets.keys(),
		"atalhos": opened_shortcuts.keys(),
	}


## Grava o progresso; false sem `save_path` ou se não conseguiu (regras 4 e 7).
func save_progress() -> bool:
	if _progress_store == null:
		return false
	return _progress_store.save(progress_snapshot())


## Lê o save antes de montar a primeira sala; save com problema começa do zero (regra 6).
func _load_progress() -> void:
	_progress_store = ProgressStore.new(save_path)
	var data := _progress_store.load_data()
	if not _progress_store.last_problem.is_empty():
		var message: String = tr("SAVE_PROBLEMA") % [_progress_store.last_problem, save_path + ".bak"]
		cast_log.add_lines(PackedStringArray([message]))
		push_warning(message)
	if not data.is_empty():
		apply_progress(data)


## Aplica um save já lido; campo ausente ou do tipo errado fica no padrão (regra 6).
func apply_progress(data: Dictionary) -> void:
	var mago: Dictionary = data.get("mago") if data.get("mago") is Dictionary else {}
	var xp: Variant = mago.get("xp")
	var mana: Variant = mago.get("mana")
	state.restore_progress(maxi(int(xp), 0) if _is_number(xp) else 0, float(mana) if _is_number(mana) else 0.0)
	var puzzles: Variant = data.get("puzzles")
	if puzzles is Dictionary:
		for puzzle_id: String in puzzles:
			var entry: Variant = puzzles[puzzle_id]
			if entry is Dictionary:
				var stars: Variant = entry.get("estrelas")
				solved_puzzles[puzzle_id] = {"estrelas": int(stars) if _is_number(stars) else 0}
	defeated_bosses = _string_set(data.get("chefes"))
	seen_lessons = _string_set(data.get("licoes"))
	found_secrets = _string_set(data.get("segredos"))
	opened_shortcuts = _string_set(data.get("atalhos"))
	var used: Variant = data.get("dicas")
	if used is Dictionary:
		for puzzle_id: String in used:
			if _is_number(used[puzzle_id]):
				hints_used[puzzle_id] = clampi(int(used[puzzle_id]), 0, HintBook.LEVELS)
	var room: Variant = data.get("sala")
	if room is String and ResourceLoader.exists(rooms_dir.path_join(room + ".tscn")):
		start_room = room
		var letter: Variant = data.get("entrada")
		start_entry = letter if letter is String else ""


static func _is_number(value: Variant) -> bool:
	return value is int or value is float


## Lista de textos do save → {texto: true}; qualquer outra coisa → vazio.
static func _string_set(value: Variant) -> Dictionary:
	var result := {}
	if value is Array:
		for item: Variant in value:
			if item is String:
				result[item] = true
	return result


func _physics_process(delta: float) -> void:
	camera_shake.tick(delta)
	(player.get_node("Camera2D") as Camera2D).offset = camera_shake.offset() if shake_enabled else Vector2.ZERO
	state.health.tick(delta)
	state.health.dodging = player.motor.is_dodging()
	if grimoire.passive() != "" and passive_scheduler.tick(delta):
		_run_passive()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"step_speed"):
		cycle_step_speed()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"attack"):
		world_actions.staff_attack()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"talk"):
		talk()
		get_viewport().set_input_as_handled()
		return
	for slot_number in range(1, Grimoire.SLOT_COUNT + 1):
		if event.is_action_pressed(StringName("slot_%d" % slot_number)):
			cast(slot_number)
			get_viewport().set_input_as_handled()
			return


## Conjura o feitiço do slot (1 a 5) com o estado real do mundo (spec GRI-slots, GRI-040 a 044).
func cast(slot_number: int) -> void:
	if get_tree().paused:
		return
	var spell_name := grimoire.slot(slot_number)
	if spell_name.is_empty():
		cast_log.add_lines(PackedStringArray([tr("CONJURAR_SLOT_VAZIO") % slot_number]))
		return
	var code := grimoire.code_of(spell_name)
	var result := await _execute(code)
	cast_log.add_lines(SpellReport.cast_lines(slot_number, spell_name, result))
	grimoire_ui.remember_result(spell_name, result)
	var visions := PackedStringArray()
	for output in result.outputs:
		visions.append(output["texto"])
	world_actions.show_visions(visions)
	# Mesmo com erro, o que rodou antes acontece no mundo (decisão do Victor, MAG-acoes regra 5).
	action_player.play(result.actions, code)
	spell_cast.emit(slot_number, result)


## Tecla E: abre a cena da serpente ao alcance; cena com erro só é registrada (NAR-dialogo, regras 3 e 5).
## Sem serpente perto, bebe da fonte ao alcance (MUN-vida, regra 9).
func talk() -> void:
	if dialogue_box.is_open():
		return
	var serpent := serpent_in_reach()
	if serpent == null:
		if fountain_in_reach():
			drink()
		return
	if not dialogues.can_play(serpent.scene_id):
		_report(tr("DIALOGO_CENA_COM_ERRO") % serpent.scene_id)
		return
	# Lição vista e puzzle da sala sem solução: a próxima dica; senão, a lição (NAR-serpente, regra 3).
	_talk_lesson = serpent.scene_id
	_talk_hint_puzzle = ""
	var puzzle_open := current_room.has_puzzle() and not current_room.is_solved()
	if seen_lessons.has(_talk_lesson) and puzzle_open and hints.has_hints(current_room.puzzle_id()):
		_talk_hint_puzzle = current_room.puzzle_id()
		_talk_run = DialogueRun.new(hints.scene(_talk_hint_puzzle, int(hints_used.get(_talk_hint_puzzle, 0)) + 1))
	else:
		_talk_run = dialogues.start(_talk_lesson)
	grimoire_ui.blocked = true
	_talk_serpent = serpent
	serpent.set_talking(true)
	dialogue_box.open(_talk_run)


## Fim da conversa: conta a lição e a dica pelas falas que apareceram (NAR-serpente, regra 2; NAR-dicas,
## regra 4) e salva.
func _on_dialogue_finished() -> void:
	grimoire_ui.blocked = false
	if is_instance_valid(_talk_serpent):
		_talk_serpent.set_talking(false)
	_talk_serpent = null
	if _talk_run == null:
		return
	if _talk_run.has_seen(LESSON_LINE):
		seen_lessons[_talk_lesson] = true
	if not _talk_hint_puzzle.is_empty() and _talk_run.has_seen(HintBook.HINT_LINE):
		hints_used[_talk_hint_puzzle] = mini(int(hints_used.get(_talk_hint_puzzle, 0)) + 1, HintBook.LEVELS)
	var demo_over := _talk_lesson == END_SCENE and _talk_run.has_seen(END_LINE)
	_talk_run = null
	save_progress()
	if demo_over:
		demo_finished.emit()


## A fonte enche vida e mana e salva (MUN-vida, regra 9).
func drink() -> void:
	state.health.restore_full()
	state.set_mana(state.mana_max)
	sfx.play("mana")
	Fx.burst(player, Vector2(0, -15), Color("8fd8ff"), 14, true)
	cast_log.add_lines(PackedStringArray([tr("FONTE_BEBEU")]))
	save_progress()


## A fonte da sala atual ao alcance do mago, ou null.
func fountain_in_reach() -> Fountain:
	if current_room == null:
		return null
	for fountain in current_room.fountains():
		if is_instance_valid(fountain) and fountain.in_reach():
			return fountain
	return null


## Resumo da tela de fim (UI-menus, regra 7); os totais vêm do mapa da área.
func summary() -> Dictionary:
	var area := AreaMap.load_dir(rooms_dir)
	var stars := 0
	for puzzle_id: String in solved_puzzles:
		stars += puzzle_stars(puzzle_id)
	return {
		"nivel": state.level, "xp": state.xp,
		"puzzles": solved_puzzles.size(), "puzzles_total": area.puzzles().size(), "estrelas": stars,
		"licoes": seen_lessons.size(), "licoes_total": area.lesson_ids().size(),
		"segredos": found_secrets.size(), "segredos_total": area.secret_ids().size(),
	}


## A serpente da sala atual ao alcance do mago, ou null.
func serpent_in_reach() -> Serpent:
	if current_room == null:
		return null
	for serpent in current_room.serpents():
		if is_instance_valid(serpent) and serpent.in_reach():
			return serpent
	return null


func is_puzzle_solved(puzzle_id: String) -> bool:
	return solved_puzzles.has(puzzle_id)


## Melhor quantidade de estrelas do puzzle; 0 se não foi resolvido ou não tem estrelas.
func puzzle_stars(puzzle_id: String) -> int:
	return int(solved_puzzles.get(puzzle_id, {}).get("estrelas", 0))


func _on_puzzle_solved(puzzle_id: String) -> void:
	var stars := PuzzleValidator.stars(current_room.puzzle.get("estrelas", []), room_mana_spent)
	solved_puzzles[puzzle_id] = {"estrelas": maxi(stars, puzzle_stars(puzzle_id))}
	if stars > 0:
		cast_log.add_lines(PackedStringArray([tr("PUZZLE_RESOLVIDO_ESTRELAS") % [stars, room_mana_spent]]))
	else:
		cast_log.add_lines(PackedStringArray([tr("PUZZLE_RESOLVIDO")]))
	# Só chega aqui na primeira vez: a sala de um puzzle resolvido já nasce resolvida (PRO-xp, regra 3).
	var bonus := Progression.economy_bonus(stars)
	var xp := Progression.puzzle_xp(stars)
	_gain_xp(xp, tr("XP_GANHO_ECONOMIA") % [xp, bonus] if bonus > 0 else tr("XP_GANHO") % xp)
	save_progress()


## Soma o custo das conjurações que agem enquanto o puzzle da sala não foi resolvido (regra 14).
func _tally_mana(result: SpellResult) -> void:
	if current_room == null or not current_room.has_puzzle() or current_room.is_solved():
		return
	if PuzzleValidator.counts_for_stars(result.actions):
		room_mana_spent += result.cost


## Tecla V: 1× → 2× → 0,5× → 1× (PUZ-013).
func cycle_step_speed() -> void:
	var index := STEP_SPEEDS.find(step_speed)
	step_speed = STEP_SPEEDS[(index + 1) % STEP_SPEEDS.size()]
	step_view.set_speed(step_speed)
	_apply_step_mode()


func _in_puzzle_room() -> bool:
	return current_room != null and current_room.has_puzzle()


func _apply_step_mode() -> void:
	action_player.step_delay = STEP_DELAY / step_speed if _in_puzzle_room() else 0.0


func _on_sequence_started(code: String) -> void:
	if _in_puzzle_room():
		step_view.show_code(code)


func _on_action_started(action: Dictionary) -> void:
	if _in_puzzle_room() and step_view.is_showing():
		step_view.highlight(int(action.get("linha", -1)))
	_release_rune(action)


## A linha que gerou a ação vira uma runa acima do mago (ART-brilho, regra 9).
func _release_rune(action: Dictionary) -> void:
	var line := int(action.get("linha", -1))
	if line < 1 or current_room == null:
		return
	var rune := CodeRune.make(line, str(action.get("elemento", "")))
	rune.position = current_room.to_local(player.global_position) + RUNE_OFFSET
	current_room.add_child(rune)


func _on_actions_finished() -> void:
	if step_view.is_showing():
		step_view.finish()


## Executa um código com o estado real e aplica a mana pela variação.
func _execute(code: String) -> SpellResult:
	var context := spell_context()
	# As regras de mana vêm do arquivo de balanceamento (BAL-valores, regra 3).
	var request := SpellRequest.make(code, context["mago"], context["target"], Balance.rules(), context["pieces"],
			context["room"], context["enemies"])
	var result: SpellResult = await executor.execute(request)
	_tally_mana(result)
	if not result.mago.is_empty():
		# Variação, não valor absoluto: outra coisa pode ter mudado a mana enquanto o feitiço rodava (GRI-041).
		state.set_mana(state.mana + float(result.mago["mana"]) - float(request.mago["mana"]))
	return result


## Uma execução do slot passivo (spec MAG-passivo).
func _run_passive() -> void:
	var spell_name := grimoire.passive()
	passive_scheduler.mark_started()
	var result := await _execute(grimoire.code_of(spell_name))
	if spell_name != grimoire.passive():
		passive_scheduler.mark_finished(SpellResult.from_dict({"ok": true}))
		return  # trocou de passivo enquanto rodava
	passive_player.play(result.actions)
	match passive_scheduler.mark_finished(result):
		PassiveScheduler.Outcome.DISABLED:
			cast_log.add_lines(PackedStringArray([tr("PASSIVO_DESLIGADO") % spell_name]))
			cast_log.add_lines(SpellReport.describe_error(result.error).split("\n"))
			grimoire_ui.remember_result(spell_name, result)
		PassiveScheduler.Outcome.MANA_OUT_FIRST:
			cast_log.add_lines(PackedStringArray([tr("PASSIVO_SEM_MANA") % spell_name]))
	_update_passive_hud()


func _on_passive_changed() -> void:
	passive_scheduler.reset()
	_update_passive_hud()


func _update_passive_hud() -> void:
	hud.set_passive_status(grimoire.passive(), passive_scheduler.is_disabled())


## Estado do mundo que vai para o executor: mago, alvo, peças desbloqueadas, o que a sala mostra
## e os inimigos no alcance (spec COM-dano, regra 6).
func spell_context() -> Dictionary:
	var room: Dictionary = current_room.spell_room() if current_room else {}
	return {"mago": state.to_spell_mago(), "target": current_target(), "pieces": state.unlocked_pieces, "room": room,
			"enemies": current_enemies()}


## Encostar num inimigo: dano de ataque e um empurrão para longe dele (spec COM-dano, regra 4); a câmera
## treme (ART-brilho, regra 6). Devolve se machucou.
func _on_player_attacked(from: Vector2, amount: int) -> bool:
	if not state.health.damage(amount, Health.Source.ATTACK):
		return false
	player.motor.knock_back(1 if player.global_position.x >= from.x else -1)
	shake(SHAKE_HURT)
	return true


## Golpe do chefe que machuca congela o quadro por um instante (ART-brilho, regra 7).
func _on_boss_struck(from: Vector2, amount: int) -> void:
	if _on_player_attacked(from, amount):
		hit_stop()


func shake(amount: float) -> void:
	if shake_enabled:
		camera_shake.add(amount)


## Para o jogo por HIT_STOP segundos de relógio (o relógio ignora a escala de tempo e a pausa).
func hit_stop() -> void:
	Engine.time_scale = 0.0
	get_tree().create_timer(HIT_STOP, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)


func _exit_tree() -> void:
	# Sair no meio do congelamento não deixa o jogo parado (ART-brilho, regra 7).
	Engine.time_scale = 1.0


## Todo inimigo derrotado dá XP, mesmo os que reaparecem (spec PRO-xp, regra 2).
func _on_enemy_defeated(xp: int) -> void:
	sfx.play("derrota")
	_gain_xp(xp, tr("XP_GANHO") % xp)


func _gain_xp(amount: int, message: String) -> void:
	if amount <= 0:
		return
	cast_log.add_lines(PackedStringArray([message]))
	state.gain_xp(amount)


func _on_leveled_up(level: int) -> void:
	cast_log.add_lines(PackedStringArray([tr("NIVEL_SUBIU") % [level, roundi(state.mana_max)]]))
	save_progress()


## Baú aberto: XP do segredo, uma vez por jogo (MUN-segredos, regras 1 e 2).
func _on_secret_found(secret_id: String) -> void:
	found_secrets[secret_id] = true
	sfx.play("fraco")
	var xp := Balance.integer("xp", "segredo")
	_gain_xp(xp, tr("SEGREDO_ACHADO") % xp)
	save_progress()


func _on_boss_defeated(room_id: String) -> void:
	defeated_bosses[room_id] = true
	cast_log.add_lines(PackedStringArray([tr("CHEFE_DERROTADO")]))
	save_progress()


func _on_target_hit(_attack_element: String, effect: ElementTable.Effect) -> void:
	sfx.play("fraco" if effect == ElementTable.Effect.WEAK else "acerto")


## O boneco da sala atual com esse id, ou null.
func find_target(target_id: String) -> TrainingTarget:
	if current_room == null:
		return null
	for node in get_tree().get_nodes_in_group(TrainingTarget.GROUP):
		var target := node as TrainingTarget
		if target and target.target_id == target_id and current_room.is_ancestor_of(target):
			return target
	return null


## O boneco, cristal ou inimigo mais perto do mago no alcance; null se nenhum (spec MUN-alvos).
func current_target() -> Variant:
	var best: TrainingTarget = null
	var best_distance := TARGET_RANGE_TILES * RoomLayout.TILE + 0.001
	for node in get_tree().get_nodes_in_group(TrainingTarget.GROUP):
		var target := node as TrainingTarget
		if target == null or current_room == null or not current_room.is_ancestor_of(target):
			continue
		var distance := player.global_position.distance_to(target.global_position)
		# Quem é alvo a qualquer distância conta como estando no limite do alcance (COM-chefe, regra 6).
		var ranked := minf(distance, TARGET_RANGE_TILES * RoomLayout.TILE) if _any_distance(target) else distance
		if ranked < best_distance:
			best = target
			best_distance = ranked
	if best == null:
		return null
	return _target_view(best, player.global_position.distance_to(best.global_position))


static func _any_distance(target: TrainingTarget) -> bool:
	return target is Enemy and (target as Enemy).any_distance


## Inimigos vivos da sala no alcance, do mais perto para o mais longe (spec COM-dano, regra 6).
func current_enemies() -> Array:
	var found := []
	if current_room == null:
		return found
	for enemy in current_room.enemies():
		var distance := player.global_position.distance_to(enemy.global_position)
		if distance <= TARGET_RANGE_TILES * RoomLayout.TILE + 0.001 or enemy.any_distance:
			found.append([distance, enemy])
	found.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	return found.map(func(pair: Array) -> Dictionary: return _target_view(pair[1], pair[0]))


## Como o feitiço vê um alvo; inimigos também trazem vida e escudo.
func _target_view(target: TrainingTarget, distance: float) -> Dictionary:
	var view := {"id": target.target_id, "elemento": target.element, "distancia": snappedf(distance / RoomLayout.TILE, 0.1)}
	if target is Enemy:
		view["vida"] = target.health.current
		view["escudo"] = target.shield_element()
	return view


func go_to(room_id: String, entry: String) -> void:
	var path := rooms_dir.path_join(room_id + ".tscn")
	if not ResourceLoader.exists(path):
		_report("sala '%s' não existe em %s" % [room_id, rooms_dir])
		return
	if current_room:
		remove_child(current_room)
		current_room.queue_free()

	current_room = load(path).instantiate()
	current_room.rng = rng
	current_room.player = player
	current_room.boss_beaten = defeated_bosses.has(room_id)
	current_room.found_secrets = found_secrets
	room_mana_spent = 0.0
	add_child(current_room)
	move_child(current_room, 0)
	authoring_errors.append_array(current_room.errors)
	current_room.exit_touched.connect(_on_exit_touched)
	current_room.hazard_touched.connect(_on_hazard_touched)
	current_room.safe_point_touched.connect(func(feet: Vector2) -> void: safe_point = feet)
	current_room.puzzle_solved.connect(_on_puzzle_solved)
	current_room.player_attacked.connect(_on_player_attacked)
	current_room.boss_struck.connect(_on_boss_struck)
	current_room.camera_rumble.connect(shake)
	current_room.boss_defeated.connect(_on_boss_defeated)
	current_room.secret_found.connect(_on_secret_found)
	if current_room.has_puzzle() and solved_puzzles.has(current_room.puzzle_id()):
		current_room.apply_solved()
	_apply_step_mode()
	for node in current_room.get_children():
		if node is TrainingTarget:
			node.was_hit.connect(_on_target_hit)
		if node is Enemy:
			node.defeated.connect(_on_enemy_defeated.bind(node.xp))

	if not current_room.has_entry(entry):
		_report("entrada '%s' não existe na sala %s; usando a primeira" % [entry, room_id])
		entry = current_room.first_entry()
	current_entry = entry
	# Chegar pela entrada do atalho abre a porta por trás, para sempre (MUN-mapa, regra 5).
	if not current_room.atalho_entrada.is_empty() and entry == current_room.atalho_entrada:
		opened_shortcuts[room_id] = true
	if opened_shortcuts.has(room_id):
		current_room.open_shortcut()
	_place_player(current_room.entry_feet(entry))
	safe_point = player.global_position
	_apply_camera_limits(current_room.bounds())
	backdrop.fit(current_room.bounds())
	room_changed.emit(room_id)
	save_progress()


func _on_exit_touched(target_room: String, target_entry: String) -> void:
	if _changing_room:
		return
	_changing_room = true
	# Trocar a sala dentro do callback de física não é seguro; adia para o fim do quadro.
	_change_room.call_deferred(target_room, target_entry)


func _change_room(target_room: String, target_entry: String) -> void:
	go_to(target_room, target_entry)
	_changing_room = false


func _on_hazard_touched() -> void:
	if state.health.damage(1, Health.Source.HAZARD) and not state.health.is_dead():
		_place_player.call_deferred(safe_point)


func _on_died() -> void:
	_respawn.call_deferred()


func _respawn() -> void:
	state.health.restore_full()
	go_to(current_room.room_id, current_entry)


func _place_player(feet: Vector2) -> void:
	player.global_position = feet
	player.velocity = Vector2.ZERO


func _apply_camera_limits(rect: Rect2) -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = int(rect.position.x)
	camera.limit_top = int(rect.position.y)
	camera.limit_right = int(rect.end.x)
	camera.limit_bottom = int(rect.end.y)
	camera.reset_smoothing()


func _report(message: String) -> void:
	authoring_errors.append(message)
	push_warning(message)
