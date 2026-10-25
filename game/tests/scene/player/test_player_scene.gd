extends GdUnitTestSuite
## Specs: docs/specs/mundo/MUN-movimento.md (MUN-007, 008, 014) e MUN-salas.md (MUN-032).
## Sem eventos de input: em modo headless o Godot não os entrega, então a intenção é injetada.

const PLAYER := "res://src/nodes/player/player.tscn"
const FLOOR_ROW := 7

# Chão na linha 7 (topo em y = 112); plataforma na linha 5 (topo em y = 80), colunas 10 a 14.
const LAYOUT := """##############################
#............................#
#............................#
#............................#
#............................#
#.........=====..............#
#............................#
##############################"""

var room: Room
var player: Player


func before_test() -> void:
	room = auto_free(Room.new())
	room.layout = LAYOUT
	add_child(room)
	player = auto_free(load(PLAYER).instantiate())
	add_child(player)
	player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()


func _physics_frames(count: int, on_frame: Callable = Callable()) -> void:
	for i in count:
		await get_tree().physics_frame
		if on_frame.is_valid():
			on_frame.call()


func _drop_at(position: Vector2) -> void:
	player.global_position = position
	player.velocity = Vector2.ZERO
	await _physics_frames(60)


func test_MUN_007_pousa_no_chao() -> void:
	await _drop_at(Vector2(48, 60))
	assert_bool(player.is_on_floor()).is_true()
	assert_float(player.global_position.y).is_equal_approx(FLOOR_ROW * 16.0, 1.0)


func test_MUN_008_altura_do_pulo() -> void:
	await _drop_at(Vector2(48, 60))
	var start_y := player.global_position.y
	var first := [true]
	player.intent_source = func() -> PlayerIntent:
		var pressed: bool = first[0]
		first[0] = false
		return PlayerIntent.make(0.0, pressed, true)
	var peak := [start_y]
	await _physics_frames(45, func() -> void: peak[0] = minf(peak[0], player.global_position.y))
	assert_float(start_y - peak[0]).is_equal_approx(player.motor.jump_height, 3.0)


func test_MUN_014_distancia_da_esquiva() -> void:
	await _drop_at(Vector2(48, 60))
	var start_x := player.global_position.x
	var first := [true]
	player.intent_source = func() -> PlayerIntent:
		var intent := PlayerIntent.make()
		intent.dodge_pressed = first[0]
		first[0] = false
		return intent
	await _physics_frames(30)
	assert_float(player.global_position.x - start_x).is_equal_approx(48.0, 5.0)


func test_MUN_032_pousa_na_plataforma_vindo_de_cima() -> void:
	await _drop_at(Vector2(200, 50))
	assert_bool(player.is_on_floor()).is_true()
	assert_float(player.global_position.y).is_equal_approx(80.0, 1.0)


func test_MUN_032_atravessa_a_plataforma_vindo_de_baixo() -> void:
	await _drop_at(Vector2(200, 100))
	var first := [true]
	player.intent_source = func() -> PlayerIntent:
		var pressed: bool = first[0]
		first[0] = false
		return PlayerIntent.make(0.0, pressed, true)
	var peak := [player.global_position.y]
	await _physics_frames(45, func() -> void: peak[0] = minf(peak[0], player.global_position.y))
	assert_float(peak[0]).is_less(72.0)
