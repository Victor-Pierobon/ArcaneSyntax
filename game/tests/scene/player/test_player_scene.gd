extends GdUnitTestSuite
## Spec: docs/specs/mundo/MUN-movimento.md
## Sem eventos de input: em modo headless o Godot não os entrega, então a intenção é injetada.

const ROOM := "res://src/nodes/world/prototype_room.tscn"
const SPAWN_ABOVE_FLOOR := Vector2(100.0, 200.0)

var room: Node
var player: Player


func before_test() -> void:
	room = auto_free(load(ROOM).instantiate())
	add_child(room)
	player = room.get_node("Player")


func _physics_frames(count: int, on_frame: Callable = Callable()) -> void:
	for i in count:
		await get_tree().physics_frame
		if on_frame.is_valid():
			on_frame.call()


func _settle_on_floor() -> void:
	player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	player.global_position = SPAWN_ABOVE_FLOOR
	await _physics_frames(60)


func test_MUN_007_pousa_no_chao() -> void:
	await _settle_on_floor()
	var floor_top: float = room.get_node("Floor").global_position.y
	assert_bool(player.is_on_floor()).is_true()
	assert_float(player.global_position.y).is_equal_approx(floor_top, 1.0)


func test_MUN_008_altura_do_pulo() -> void:
	await _settle_on_floor()
	var start_y := player.global_position.y
	var first := [true]
	player.intent_source = func() -> PlayerIntent:
		var pressed: bool = first[0]
		first[0] = false
		return PlayerIntent.make(0.0, pressed, true)
	var peak := [start_y]
	await _physics_frames(45, func() -> void: peak[0] = minf(peak[0], player.global_position.y))
	assert_float(start_y - peak[0]).is_equal_approx(player.motor.jump_height, 3.0)
