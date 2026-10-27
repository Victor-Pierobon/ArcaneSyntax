extends GdUnitTestSuite
## Spec: docs/specs/mundo/MUN-plataformas.md (MUN-103 a MUN-105).
## sala_plataformas: chão com topo em y = 176; plataforma horizontal de 3 com topo em y = 112, da
## coluna 3 até a 10; vertical de 2 na coluna 22, do topo em y = 144 até y = 48; a que cai, de 3, na
## coluna 15, com topo em y = 144.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_plataformas.json"
const TILE := RoomLayout.TILE
const FLOOR_Y := 176.0

var world: World
var player: Player


func _start() -> void:
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = "sala_plataformas"
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	player = world.player
	player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	await _frames(3)


func after_test() -> void:
	get_tree().paused = false
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(GRIMOIRE_PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _seconds(value: float) -> void:
	await get_tree().create_timer(value, false, true).timeout


func _put_player(at: Vector2) -> void:
	player.global_position = at
	player.velocity = Vector2.ZERO
	await _frames(3)


func _horizontal() -> MovingPlatform:
	return world.current_room.moving_platforms()[0]


func _vertical() -> MovingPlatform:
	return world.current_room.moving_platforms()[1]


func test_MUN_103_o_mago_anda_junto_na_horizontal() -> void:
	await _start()
	var platform := _horizontal()
	assert_vector(platform.position).is_equal(Vector2(3 * TILE, 7 * TILE))
	await _put_player(platform.position + Vector2(24, 0))
	var offset := player.global_position.x - platform.global_position.x
	await _seconds(2.0)
	assert_float(platform.position.x).is_greater(3 * TILE + 32)
	assert_float(player.global_position.x - platform.global_position.x).is_equal_approx(offset, 2.0)
	assert_float(player.global_position.y).is_equal_approx(platform.global_position.y, 1.0)
	assert_bool(player.is_on_floor()).is_true()


func test_MUN_103_o_mago_sobe_junto_na_vertical() -> void:
	await _start()
	var platform := _vertical()
	await _put_player(platform.position + Vector2(16, 0))
	await _seconds(1.5)
	assert_float(platform.position.y).is_less(9 * TILE - 32)
	assert_float(player.global_position.y).is_equal_approx(platform.global_position.y, 2.0)
	assert_bool(player.is_on_floor()).is_true()


func test_MUN_104_pisar_derruba_e_ela_volta() -> void:
	await _start()
	var platform: FallingPlatform = world.current_room.falling_platforms()[0]
	var top := platform.global_position + Vector2(24, 0)
	await _put_player(top)
	assert_int(platform.rule.state).is_equal(FallingPlatformRule.State.SHAKING)
	await _seconds(0.3)
	assert_float(player.global_position.y).is_equal_approx(top.y, 1.0)
	await _seconds(0.5)
	assert_int(platform.rule.state).is_equal(FallingPlatformRule.State.FALLEN)
	await _frames(30)
	assert_float(player.global_position.y).is_equal_approx(FLOOR_Y, 1.0)
	await _seconds(3.0)
	assert_int(platform.rule.state).is_equal(FallingPlatformRule.State.STILL)
	# Segura de novo: o mago que cai de cima pousa nela.
	await _put_player(top + Vector2(0, -20))
	await _frames(20)
	assert_float(player.global_position.y).is_equal_approx(top.y, 1.0)


func test_MUN_104_sem_pisar_continua_parada() -> void:
	await _start()
	var platform: FallingPlatform = world.current_room.falling_platforms()[0]
	await _seconds(1.0)
	assert_int(platform.rule.state).is_equal(FallingPlatformRule.State.STILL)


func test_MUN_105_pausa_congela() -> void:
	await _start()
	var falling: FallingPlatform = world.current_room.falling_platforms()[0]
	await _put_player(falling.global_position + Vector2(24, 0))
	await _seconds(0.7)
	var moving := _horizontal()
	get_tree().paused = true
	var position := moving.position
	var state := falling.rule.state
	await _frames(90)
	assert_vector(moving.position).is_equal(position)
	assert_int(falling.rule.state).is_equal(state)
	get_tree().paused = false
	await _frames(10)
	assert_vector(moving.position).is_not_equal(position)


func test_MUN_105_morrer_monta_de_novo() -> void:
	await _start()
	var falling: FallingPlatform = world.current_room.falling_platforms()[0]
	await _put_player(falling.global_position + Vector2(24, 0))
	await _seconds(1.5)
	world.state.health.damage(5, Health.Source.HAZARD)
	await _frames(3)
	assert_vector(_horizontal().position).is_equal(Vector2(3 * TILE, 7 * TILE))
	assert_int(world.current_room.falling_platforms()[0].rule.state).is_equal(FallingPlatformRule.State.STILL)


## Regressão (captura de tela, Sprint 18): a plataforma que cai era igual à fixa (as rachaduras de 1 px
## somem na escala do jogo) e o mago caía sem ter como prever.
func test_MUN_104_a_que_cai_se_distingue_da_fixa() -> void:
	await _start()
	var platform: FallingPlatform = world.current_room.falling_platforms()[0]
	var tint := platform.visual.self_modulate
	assert_bool(tint.is_equal_approx(Color.WHITE)).is_false()
	# Bem diferente da madeira: mais vermelha e mais escura.
	assert_float(tint.r - tint.b).is_greater(0.2)
	assert_float(tint.get_luminance()).is_less(0.8)
