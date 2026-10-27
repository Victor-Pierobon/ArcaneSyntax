extends GdUnitTestSuite
## Spec: docs/specs/arte/ART-brilho.md (regras 6 a 8, ART-064 e ART-065).
## sala_chefe (a mesma das cenas do chefe): chão com topo em y = 176.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_tremida.json"
const FLOOR_Y := 176.0

var world: World


func _start() -> void:
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = "sala_chefe"
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	world.player.global_position = Vector2(6 * 16, FLOOR_Y)
	await _frames(3)


func after_test() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(GRIMOIRE_PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _camera() -> Camera2D:
	return world.player.get_node("Camera2D")


func _boss() -> Boss:
	return world.current_room.enemies()[0] as Boss


func test_ART_064_machucado_treme() -> void:
	await _start()
	world.current_room.player_attacked.emit(world.player.global_position + Vector2(20, 0), 1)
	assert_float(world.camera_shake.trauma).is_equal_approx(0.3, 0.001)
	var moved := false
	for i in 10:
		await _frames(1)
		moved = moved or _camera().offset != Vector2.ZERO
	assert_bool(moved).is_true()
	# Volta ao lugar quando o trauma acaba.
	await get_tree().create_timer(0.5, false, true).timeout
	assert_vector(_camera().offset).is_equal(Vector2.ZERO)


func test_ART_064_com_a_opcao_desligada_nao_treme() -> void:
	await _start()
	world.shake_enabled = false
	world.current_room.player_attacked.emit(world.player.global_position + Vector2(20, 0), 1)
	# Nem acumula: religar a opção não traz uma tremida guardada (mutante sobrevivente da Sprint 20).
	assert_float(world.camera_shake.trauma).is_equal(0.0)
	for i in 10:
		await _frames(1)
		assert_vector(_camera().offset).is_equal(Vector2.ZERO)


func test_ART_064_troca_de_fase_treme_mais() -> void:
	await _start()
	var boss := _boss()
	while boss.health.current > 60:
		boss.hit("gelo", "projetil")
	assert_float(world.camera_shake.trauma).is_equal_approx(0.5, 0.05)


func test_ART_065_golpe_do_chefe_congela() -> void:
	await _start()
	_boss().bolt_hit.emit(world.player.global_position + Vector2(20, 0), 1)
	assert_float(Engine.time_scale).is_equal(0.0)
	await get_tree().create_timer(0.15, true, false, true).timeout
	assert_float(Engine.time_scale).is_equal(1.0)
	assert_int(world.state.health.current).is_equal(4)


func test_ART_065_outro_ataque_nao_congela() -> void:
	await _start()
	world.current_room.player_attacked.emit(world.player.global_position + Vector2(20, 0), 1)
	assert_float(Engine.time_scale).is_equal(1.0)


func test_ART_065_sair_no_meio_destrava() -> void:
	await _start()
	_boss().bolt_hit.emit(world.player.global_position + Vector2(20, 0), 1)
	assert_float(Engine.time_scale).is_equal(0.0)
	remove_child(world)
	assert_float(Engine.time_scale).is_equal(1.0)
	world.free()
