extends GdUnitTestSuite
## Spec: docs/specs/puzzles/PUZ-validacao.md (PUZ-004 a 006)
## sala_puzzle: chão com topo em y = 80, entrada A em x = 40, cristal em x = 88, porta na coluna 11 (x 176–192).

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_puzzle.json"
const FLOOR_Y := 80.0

var world: World
var player: Player


func before_test() -> void:
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = "sala_puzzle"
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	player = world.player
	_walk(0.0)
	await _frames(3)


func after_test() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(GRIMOIRE_PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func _walk(move_x: float) -> void:
	player.intent_source = func() -> PlayerIntent: return PlayerIntent.make(move_x)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _crystal() -> Crystal:
	return world.find_target("sala_puzzle_alvo_5") as Crystal


func _cast_projectile(element: String) -> void:
	world.action_player.play([{"tipo": "lancar", "elemento": element, "forma": "projetil", "alvo": "sala_puzzle_alvo_5", "linha": 1}])
	await _frames(40)


func test_PUZ_004_cristal_acende_com_feitico() -> void:
	assert_bool(_crystal().lit).is_false()
	await _cast_projectile("gelo")
	assert_bool(_crystal().lit).is_true()
	assert_bool(world.is_puzzle_solved("p_teste")).is_true()


func test_PUZ_004_cajado_nao_acende() -> void:
	player.global_position = Vector2(74, FLOOR_Y)
	await _frames(3)
	world.world_actions.staff_attack()
	await _frames(5)
	assert_int(_crystal().hits).is_equal(1)
	assert_bool(_crystal().lit).is_false()
	assert_bool(world.is_puzzle_solved("p_teste")).is_false()


func test_PUZ_004_cristal_que_exige_elemento() -> void:
	_crystal().required_element = "fogo"
	await _cast_projectile("gelo")
	assert_bool(_crystal().lit).is_false()
	await _cast_projectile("fogo")
	assert_bool(_crystal().lit).is_true()


func test_PUZ_005_porta_bloqueia_ate_resolver() -> void:
	player.global_position = Vector2(150, FLOOR_Y)
	_walk(1.0)
	await _frames(40)
	assert_float(player.global_position.x).is_less(176.0)
	_walk(0.0)
	await _cast_projectile("fogo")
	_walk(1.0)
	await _frames(15)  # sem chegar na saída da coluna 14
	_walk(0.0)
	assert_float(player.global_position.x).is_greater(195.0)


func test_PUZ_006_resolvido_continua_resolvido() -> void:
	await _cast_projectile("raio")
	world.go_to("sala_alvos", "A")
	await _frames(3)
	world.go_to("sala_puzzle", "A")
	await _frames(3)
	assert_bool(_crystal().lit).is_true()
	assert_bool(world.current_room.doors_open()).is_true()
