extends GdUnitTestSuite
## Specs: docs/specs/mundo/MUN-segredos.md (MUN-090, MUN-091) e MUN-vida.md (regra 9, MUN-028).
## sala_segredo: chão com topo em y = 80; entrada na coluna 2; baú na coluna 7; fonte na coluna 15.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_segredo.json"
const SAVE_PATH := "user://tests/save_segredo.json"
const FLOOR_Y := 80.0
const TILE := RoomLayout.TILE
const SECRET := "sala_segredo_8"

var world: World


func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = "sala_segredo"
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	await _frames(3)


func after_test() -> void:
	get_tree().paused = false
	for path in [GRIMOIRE_PATH, SAVE_PATH]:
		for suffix in ["", ".bak", ".tmp"]:
			var file := ProjectSettings.globalize_path(path + suffix)
			if FileAccess.file_exists(file):
				DirAccess.remove_absolute(file)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _stand_at_column(column: float) -> void:
	world.player.global_position = Vector2(column * TILE + TILE / 2.0, FLOOR_Y)
	world.player.velocity = Vector2.ZERO
	await _frames(3)


func _chest() -> Chest:
	return world.current_room.chests()[0]


func test_MUN_090_bau_da_xp_uma_vez() -> void:
	assert_bool(_chest().is_open).is_false()
	await _stand_at_column(7)
	var xp := Balance.integer("xp", "segredo")
	assert_int(xp).is_equal(10)
	assert_int(world.state.xp).is_equal(xp)
	assert_bool(_chest().is_open).is_true()
	assert_dict(world.found_secrets).is_equal({SECRET: true})
	assert_str(world.cast_log.text()).contains(tr("SEGREDO_ACHADO") % xp)
	await _stand_at_column(3)
	await _stand_at_column(7)
	assert_int(world.state.xp).is_equal(xp)


func test_MUN_091_bau_aberto_vem_do_save() -> void:
	world.found_secrets = {SECRET: true}
	world.go_to("sala_segredo", "A")
	await _frames(3)
	assert_bool(_chest().is_open).is_true()
	await _stand_at_column(7)
	assert_int(world.state.xp).is_equal(0)


func test_MUN_090_bau_salva() -> void:
	world.queue_free()
	await _frames(2)
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = "sala_segredo"
	world.grimoire_path = GRIMOIRE_PATH
	world.save_path = SAVE_PATH
	add_child(world)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	await _frames(3)
	await _stand_at_column(7)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	assert_array(saved["segredos"]).is_equal([SECRET])


func test_MUN_028_fonte_enche_vida_e_mana() -> void:
	world.state.health.damage(3)
	world.state.set_mana(1.0)
	await _stand_at_column(3)
	world.talk()
	assert_int(world.state.health.current).is_equal(2)
	assert_float(world.state.mana).is_equal(1.0)
	await _stand_at_column(14)
	var fountain := world.fountain_in_reach()
	assert_object(fountain).is_not_null()
	assert_bool(fountain.prompt_visible()).is_true()
	world.talk()
	assert_int(world.state.health.current).is_equal(world.state.health.maximum)
	assert_float(world.state.mana).is_equal(world.state.mana_max)
	assert_str(world.cast_log.text()).contains(tr("FONTE_BEBEU"))
	assert_bool(world.dialogue_box.is_open()).is_false()
