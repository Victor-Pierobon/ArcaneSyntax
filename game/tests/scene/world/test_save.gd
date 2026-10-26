extends GdUnitTestSuite
## Spec: docs/specs/save/SAV-progresso.md (SAV-001 a SAV-005, SAV-007), com o mundo de verdade.

const WORLD := "res://src/nodes/world/world.tscn"
const SAVE_PATH := "user://tests/save_mundo.json"
const GRIMOIRE_PATH := "user://tests/grimorio_save.json"

var worlds: Array[World] = []


func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	_cleanup()


func after_test() -> void:
	get_tree().paused = false
	_cleanup()


func _cleanup() -> void:
	for path in [SAVE_PATH, GRIMOIRE_PATH]:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


## Mundo com save; `fixtures`: salas de teste em vez das do jogo.
func _world(fixtures := false, save := SAVE_PATH, room := "") -> World:
	var world: World = auto_free(load(WORLD).instantiate())
	if fixtures:
		world.rooms_dir = "res://tests/fixtures/rooms/"
	if not room.is_empty():
		world.start_room = room
	world.grimoire_path = GRIMOIRE_PATH
	world.save_path = save
	add_child(world)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	await _frames(3)
	return world


func _saved() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))


func _write(text: String) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_SAV_001_ida_e_volta_preserva_tudo() -> void:
	var first := await _world()
	first.state.gain_xp(85)
	first.state.set_mana(4.0)
	first.solved_puzzles = {"p01_meditar": {"estrelas": 0}, "p04_ponte": {"estrelas": 3}}
	first.defeated_bosses = {"sala_c04": true}
	first.seen_lessons = {"ensino_sequencia": true, "ensino_loops": true}
	first.hints_used = {"p02_runas": 2}
	first.go_to("sala_p03", "A")
	await _frames(2)
	assert_bool(first.save_progress()).is_true()
	first.queue_free()
	await _frames(2)
	var second := await _world()
	assert_str(second.current_room.room_id).is_equal("sala_p03")
	assert_str(second.current_entry).is_equal("A")
	assert_int(second.state.xp).is_equal(85)
	assert_int(second.state.level).is_equal(3)
	assert_float(second.state.mana_max).is_equal(14.0)
	assert_float(second.state.mana).is_equal(4.0)
	assert_int(second.state.health.current).is_equal(second.state.health.maximum)
	assert_dict(second.solved_puzzles).is_equal({"p01_meditar": {"estrelas": 0}, "p04_ponte": {"estrelas": 3}})
	assert_dict(second.defeated_bosses).is_equal({"sala_c04": true})
	assert_dict(second.seen_lessons).is_equal({"ensino_sequencia": true, "ensino_loops": true})
	assert_dict(second.hints_used).is_equal({"p02_runas": 2})


func test_SAV_002_grava_ao_entrar_na_sala_e_ao_subir_de_nivel() -> void:
	var world := await _world(true, SAVE_PATH, "sala_1")
	assert_str(_saved()["sala"]).is_equal("sala_1")
	world.go_to("sala_2", "A")
	await _frames(2)
	assert_str(_saved()["sala"]).is_equal("sala_2")
	world.state.gain_xp(30)
	assert_int(int(_saved()["mago"]["xp"])).is_equal(30)


func test_SAV_002_grava_ao_resolver_o_puzzle() -> void:
	var world := await _world(true, SAVE_PATH, "sala_puzzle")
	(world.find_target("sala_puzzle_alvo_5") as Crystal).light()
	await _frames(2)
	assert_bool(_saved()["puzzles"].has("p_teste")).is_true()


func test_SAV_002_grava_ao_terminar_o_dialogo() -> void:
	var world := await _world(true, SAVE_PATH, "sala_licao")
	world.talk()
	while world.dialogue_box.is_open():
		world.dialogue_box.choose(1)
		world.dialogue_box.advance()
	assert_array(_saved()["licoes"]).contains(["ensino_sequencia"])


func test_SAV_003_save_ilegivel_comeca_do_zero() -> void:
	_write("lixo que não é json")
	var world := await _world()
	assert_str(world.current_room.room_id).is_equal("sala_01")
	assert_int(world.state.xp).is_equal(0)
	assert_str(FileAccess.get_file_as_string(SAVE_PATH + ".bak")).is_equal("lixo que não é json")
	assert_str(world.cast_log.text()).contains(tr("SAVE_PROBLEMA").split("%")[0])


func test_SAV_004_versao_nova_demais() -> void:
	_write("{\"versao\": 99, \"sala\": \"sala_p03\", \"mago\": {\"xp\": 500}}")
	var world := await _world()
	assert_str(world.current_room.room_id).is_equal("sala_01")
	assert_int(world.state.xp).is_equal(0)
	assert_bool(FileAccess.file_exists(SAVE_PATH + ".bak")).is_true()
	assert_str(world.cast_log.text()).contains("99")


func test_SAV_005_campos_ruins_usam_o_padrao() -> void:
	_write(JSON.stringify({"versao": 1, "sala": "sala_que_nao_existe", "entrada": "Z", "mago": {"xp": "muito"},
			"chefes": 5, "puzzles": {"p01_meditar": {"estrelas": 0}}, "licoes": ["ensino_sequencia", 7],
			"dicas": {"p02_runas": "duas"}}))
	var world := await _world()
	assert_str(world.current_room.room_id).is_equal("sala_01")
	assert_int(world.state.xp).is_equal(0)
	assert_dict(world.defeated_bosses).is_empty()
	assert_bool(world.is_puzzle_solved("p01_meditar")).is_true()
	assert_dict(world.seen_lessons).is_equal({"ensino_sequencia": true})
	assert_dict(world.hints_used).is_empty()


func test_SAV_005_entrada_que_nao_existe_usa_a_primeira() -> void:
	_write(JSON.stringify({"versao": 1, "sala": "sala_p03", "entrada": "Z"}))
	var world := await _world()
	assert_str(world.current_room.room_id).is_equal("sala_p03")
	assert_str(world.current_entry).is_equal(world.current_room.first_entry())


func test_SAV_007_sem_save_path_nada_e_salvo() -> void:
	var world := await _world(true, "", "sala_1")
	world.go_to("sala_2", "A")
	await _frames(2)
	assert_bool(world.save_progress()).is_false()
	assert_bool(FileAccess.file_exists(SAVE_PATH)).is_false()
