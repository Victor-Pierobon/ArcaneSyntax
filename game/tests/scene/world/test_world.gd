extends GdUnitTestSuite
## Specs: docs/specs/mundo/MUN-salas.md (MUN-033 a 035) e MUN-vida.md (MUN-025 a 027).
## Usa as salas de teste em res://tests/fixtures/rooms/ (sala_1 e sala_2).

const WORLD := "res://src/nodes/world/world.tscn"
const ENTRY_A_SALA_1 := Vector2(24, 64)
const ENTRY_B_SALA_1 := Vector2(200, 64)
const ENTRY_A_SALA_2 := Vector2(56, 64)
const SAFE_MARKER_SALA_1 := Vector2(72, 64)
const ABOVE_SPIKES_SALA_1 := Vector2(152, 40)
const GRIMOIRE_PATH := "user://tests/grimorio_world.json"

var world: World
var player: Player


func before_test() -> void:
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = "sala_1"
	world.start_entry = "A"
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	player = world.player
	_set_intent(0.0)
	await _physics_frames(5)


func _set_intent(move_x: float) -> void:
	player.intent_source = func() -> PlayerIntent: return PlayerIntent.make(move_x)


func _physics_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _teleport(position: Vector2) -> void:
	player.global_position = position
	player.velocity = Vector2.ZERO
	await _physics_frames(2)


## Anda na direção até a sala mudar; solta a tecla no momento da troca.
func _walk_until_room(move_x: float, room_id: String) -> void:
	_set_intent(move_x)
	var stop := func(changed_to: String) -> void:
		if changed_to == room_id:
			_set_intent(0.0)
	world.room_changed.connect(stop)
	for i in 40:
		await get_tree().physics_frame
		if world.current_room.room_id == room_id:
			break
	world.room_changed.disconnect(stop)
	_set_intent(0.0)
	await _physics_frames(2)


func _rooms_loaded() -> int:
	return world.get_children().filter(func(n: Node) -> bool: return n is Room).size()


func test_comeca_na_entrada_da_sala_inicial() -> void:
	assert_str(world.current_room.room_id).is_equal("sala_1")
	assert_vector(player.global_position).is_equal_approx(ENTRY_A_SALA_1, Vector2(1, 1))


func test_MUN_033_transicao_pela_saida() -> void:
	await _teleport(ENTRY_B_SALA_1)
	await _walk_until_room(1.0, "sala_2")
	assert_str(world.current_room.room_id).is_equal("sala_2")
	assert_vector(player.global_position).is_equal_approx(ENTRY_A_SALA_2, Vector2(1, 1))
	var camera: Camera2D = player.get_node("Camera2D")
	assert_int(camera.limit_left).is_equal(0)
	assert_int(camera.limit_top).is_equal(0)
	assert_int(camera.limit_right).is_equal(12 * 16)
	assert_int(camera.limit_bottom).is_equal(5 * 16)


func test_MUN_034_ida_e_volta() -> void:
	await _teleport(ENTRY_B_SALA_1)
	await _walk_until_room(1.0, "sala_2")
	await _walk_until_room(-1.0, "sala_1")
	assert_str(world.current_room.room_id).is_equal("sala_1")
	assert_vector(player.global_position).is_equal_approx(ENTRY_B_SALA_1, Vector2(1, 1))
	assert_int(_rooms_loaded()).is_equal(1)


func test_MUN_035_entrada_inexistente_cai_na_primeira_entrada() -> void:
	await _teleport(Vector2(136, 32))
	await _physics_frames(3)
	assert_str(world.current_room.room_id).is_equal("sala_2")
	assert_vector(player.global_position).is_equal_approx(ENTRY_A_SALA_2, Vector2(1, 1))
	assert_array(world.authoring_errors).is_not_empty()


func test_MUN_025_espinhos_tiram_vida_e_levam_ao_ponto_seguro() -> void:
	await _teleport(ABOVE_SPIKES_SALA_1)
	await _physics_frames(20)
	assert_int(world.state.health.current).is_equal(4)
	assert_vector(player.global_position).is_equal_approx(ENTRY_A_SALA_1, Vector2(1, 1))


func test_MUN_026_marcador_atualiza_o_ponto_seguro() -> void:
	await _teleport(SAFE_MARKER_SALA_1)
	await _physics_frames(3)
	await _teleport(ABOVE_SPIKES_SALA_1)
	await _physics_frames(20)
	assert_vector(player.global_position).is_equal_approx(SAFE_MARKER_SALA_1, Vector2(1, 1))


func test_MUN_027_morte_e_renascimento() -> void:
	world.state.health.damage(4)
	world.state.health.tick(2.0)
	world.state.set_mana(3.0)
	await _teleport(SAFE_MARKER_SALA_1)
	await _physics_frames(3)
	await _teleport(ABOVE_SPIKES_SALA_1)
	await _physics_frames(20)
	assert_int(world.state.health.current).is_equal(5)
	assert_float(world.state.mana).is_equal(3.0)
	assert_vector(player.global_position).is_equal_approx(ENTRY_A_SALA_1, Vector2(1, 1))


func after_test() -> void:
	get_tree().paused = false
	var file := ProjectSettings.globalize_path(GRIMOIRE_PATH)
	if FileAccess.file_exists(file):
		DirAccess.remove_absolute(file)


func test_GRI_005_mundo_carrega_o_grimorio_do_arquivo_configurado() -> void:
	assert_str(world.grimoire_store.path).is_equal(GRIMOIRE_PATH)
	world.grimoire_ui.open()
	assert_bool(get_tree().paused).is_true()
	world.grimoire_ui.new_spell()
	world.grimoire_ui.close()
	assert_bool(get_tree().paused).is_false()
	assert_array(Array(GrimoireStore.new(GRIMOIRE_PATH).load_grimoire().names())).is_equal(["Feitiço 1"])
