class_name World
extends Node2D
## Carrega a sala atual e liga mago, HUD e salas: transições, espinhos, pontos seguros
## e renascimento (specs MUN-salas e MUN-vida).

signal room_changed(room_id: String)
## Emitido quando uma conjuração termina (spec GRI-slots).
signal spell_cast(slot_number: int, result: SpellResult)

## Raio em que um boneco ou inimigo vira o "alvo" dos feitiços (spec MUN-alvos).
const TARGET_RANGE_TILES := 12.0
## Pausa base entre ações nas salas com puzzle, dividida pela velocidade (spec PUZ-passo-a-passo).
const STEP_DELAY := 0.3
const STEP_SPEEDS := [1.0, 2.0, 0.5]

@export var rooms_dir: String = "res://content/rooms/"
@export var start_room: String = "sala_01"
@export var start_entry: String = "A"
## Arquivo do grimório; os testes usam outro caminho para não tocar no do jogador.
@export var grimoire_path: String = GrimoireStore.DEFAULT_PATH

var state := MagoState.new()
var passive_scheduler := PassiveScheduler.new()
## Puzzles resolvidos nesta sessão: id → {"estrelas": melhor} (gravar em disco é da Sprint 13).
var solved_puzzles: Dictionary = {}
## Salas cujo chefe foi derrotado nesta sessão: o chefe não volta (spec COM-chefe, regra 7).
var defeated_bosses: Dictionary = {}
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
	hud.bind(state)
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
	go_to(start_room, start_entry)


func _physics_process(delta: float) -> void:
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


## Encostar num inimigo: dano de ataque e um empurrão para longe dele (spec COM-dano, regra 4).
func _on_player_attacked(from: Vector2, amount: int) -> void:
	if state.health.damage(amount, Health.Source.ATTACK):
		player.motor.knock_back(1 if player.global_position.x >= from.x else -1)


func _on_boss_defeated(room_id: String) -> void:
	defeated_bosses[room_id] = true
	cast_log.add_lines(PackedStringArray([tr("CHEFE_DERROTADO")]))


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
		if distance < best_distance:
			best = target
			best_distance = distance
	if best == null:
		return null
	return _target_view(best, best_distance)


## Inimigos vivos da sala no alcance, do mais perto para o mais longe (spec COM-dano, regra 6).
func current_enemies() -> Array:
	var found := []
	if current_room == null:
		return found
	for enemy in current_room.enemies():
		var distance := player.global_position.distance_to(enemy.global_position)
		if distance <= TARGET_RANGE_TILES * RoomLayout.TILE + 0.001:
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
	room_mana_spent = 0.0
	add_child(current_room)
	move_child(current_room, 0)
	authoring_errors.append_array(current_room.errors)
	current_room.exit_touched.connect(_on_exit_touched)
	current_room.hazard_touched.connect(_on_hazard_touched)
	current_room.safe_point_touched.connect(func(feet: Vector2) -> void: safe_point = feet)
	current_room.puzzle_solved.connect(_on_puzzle_solved)
	current_room.player_attacked.connect(_on_player_attacked)
	current_room.boss_defeated.connect(_on_boss_defeated)
	if current_room.has_puzzle() and solved_puzzles.has(current_room.puzzle_id()):
		current_room.apply_solved()
	_apply_step_mode()
	for node in current_room.get_children():
		if node is TrainingTarget:
			node.was_hit.connect(_on_target_hit)
		if node is Enemy:
			node.defeated.connect(func() -> void: sfx.play("derrota"))

	if not current_room.has_entry(entry):
		_report("entrada '%s' não existe na sala %s; usando a primeira" % [entry, room_id])
		entry = current_room.first_entry()
	current_entry = entry
	_place_player(current_room.entry_feet(entry))
	safe_point = player.global_position
	_apply_camera_limits(current_room.bounds())
	room_changed.emit(room_id)


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
