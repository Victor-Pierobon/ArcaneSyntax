extends GdUnitTestSuite
## Spec: docs/specs/mundo/MUN-alvos.md (MUN-041 a 043)

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_alvos.json"

var world: World


func _start(room_id: String) -> void:
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = room_id
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	for i in 3:
		await get_tree().physics_frame


func after_test() -> void:
	var file := ProjectSettings.globalize_path(GRIMOIRE_PATH)
	if FileAccess.file_exists(file):
		DirAccess.remove_absolute(file)


func test_MUN_041_alvo_mais_proximo() -> void:
	await _start("sala_alvos")
	var target: Variant = world.current_target()
	assert_dict(target).is_equal({"id": "sala_alvos_alvo_1", "elemento": "fogo", "distancia": 3.0})


func test_MUN_042_fora_do_alcance() -> void:
	await _start("sala_longe")
	assert_object(world.current_target()).is_null()


func test_MUN_043_digito_sem_elemento() -> void:
	var room: Room = auto_free(Room.new())
	room.room_id = "sem_elemento"
	room.layout = "#A.3#\n#####"
	add_child(room)
	assert_array(room.errors).is_not_empty()
	assert_str(room.errors[0]).contains("3")
