class_name World
extends Node2D
## Carrega a sala atual e liga mago, HUD e salas: transições, espinhos, pontos seguros
## e renascimento (specs MUN-salas e MUN-vida).

signal room_changed(room_id: String)

@export var rooms_dir: String = "res://content/rooms/"
@export var start_room: String = "sala_01"
@export var start_entry: String = "A"
## Arquivo do grimório; os testes usam outro caminho para não tocar no do jogador.
@export var grimoire_path: String = GrimoireStore.DEFAULT_PATH

var state := MagoState.new()
var grimoire: Grimoire
var grimoire_store: GrimoireStore
var current_room: Room
## Entrada pela qual o mago chegou na sala atual (para onde volta ao morrer).
var current_entry := ""
var safe_point := Vector2.ZERO
var authoring_errors: Array[String] = []

var _changing_room := false

@onready var player: Player = $Player
@onready var hud: Hud = $Hud
@onready var grimoire_ui: GrimoireUI = $GrimoireUI


func _ready() -> void:
	hud.bind(state)
	grimoire_store = GrimoireStore.new(grimoire_path)
	grimoire = grimoire_store.load_grimoire()
	grimoire_ui.bind(grimoire, grimoire_store)
	grimoire_ui.load_problem = grimoire_store.last_problem
	if not grimoire_store.last_problem.is_empty():
		push_warning("%s; cópia guardada em %s" % [grimoire_store.last_problem, grimoire_store.backup_path()])
	state.health.died.connect(_on_died)
	go_to(start_room, start_entry)


func _physics_process(delta: float) -> void:
	state.health.tick(delta)
	state.health.dodging = player.motor.is_dodging()


func go_to(room_id: String, entry: String) -> void:
	var path := rooms_dir.path_join(room_id + ".tscn")
	if not ResourceLoader.exists(path):
		_report("sala '%s' não existe em %s" % [room_id, rooms_dir])
		return
	if current_room:
		remove_child(current_room)
		current_room.queue_free()

	current_room = load(path).instantiate()
	add_child(current_room)
	move_child(current_room, 0)
	authoring_errors.append_array(current_room.errors)
	current_room.exit_touched.connect(_on_exit_touched)
	current_room.hazard_touched.connect(_on_hazard_touched)
	current_room.safe_point_touched.connect(func(feet: Vector2) -> void: safe_point = feet)

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
