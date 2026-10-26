extends GdUnitTestSuite
## Spec: docs/specs/mundo/MUN-mapa.md (regra 5, MUN-084): o atalho de mão única, com as salas do jogo.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_atalho.json"
const SAVE_PATH := "user://tests/save_atalho.json"

var world: World


func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	world = auto_free(load(WORLD).instantiate())
	world.grimoire_path = GRIMOIRE_PATH
	world.save_path = SAVE_PATH
	add_child(world)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	await _frames(3)


func after_test() -> void:
	for path in [GRIMOIRE_PATH, SAVE_PATH]:
		for suffix in ["", ".bak", ".tmp"]:
			var file := ProjectSettings.globalize_path(path + suffix)
			if FileAccess.file_exists(file):
				DirAccess.remove_absolute(file)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func test_MUN_084_atalho_fechado_no_comeco() -> void:
	assert_str(world.current_room.room_id).is_equal("sala_01")
	assert_bool(world.current_room.shortcut_open()).is_false()
	assert_dict(world.opened_shortcuts).is_empty()


func test_MUN_084_entrar_por_tras_abre_e_fica_aberto() -> void:
	world.go_to("sala_c01", "C")
	await _frames(2)
	world.go_to("sala_01", "C")
	await _frames(2)
	assert_bool(world.current_room.shortcut_open()).is_true()
	assert_dict(world.opened_shortcuts).is_equal({"sala_01": true})
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	assert_array(saved["atalhos"]).is_equal(["sala_01"])
	world.go_to("sala_02", "A")
	await _frames(2)
	world.go_to("sala_01", "B")
	await _frames(2)
	assert_bool(world.current_room.shortcut_open()).is_true()


func test_MUN_084_a_saida_alta_da_c01_leva_ao_atalho() -> void:
	world.go_to("sala_c01", "C")
	await _frames(3)
	var entry := world.player.global_position
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make(1.0)
	for i in 60:
		await get_tree().physics_frame
		if world.current_room.room_id == "sala_01":
			break
	assert_str(world.current_room.room_id).override_failure_message("saiu de %s" % entry).is_equal("sala_01")
	assert_str(world.current_entry).is_equal("C")
	assert_bool(world.current_room.shortcut_open()).is_true()
