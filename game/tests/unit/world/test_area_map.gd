extends GdUnitTestSuite
## Spec: docs/specs/mundo/MUN-mapa.md (MUN-080 a MUN-083): o grafo das salas do jogo e da área de teste.

const ROOMS_DIR := "res://content/rooms/"
const PUZZLE_ORDER := ["p01_meditar", "p02_runas", "p03_simbolo", "p04_ponte", "p05_elevador", "p06_revisao"]


func _game() -> AreaMap:
	return AreaMap.load_dir(ROOMS_DIR)


func test_MUN_080_toda_saida_tem_volta() -> void:
	var area := _game()
	assert_int(area.room_ids().size()).is_equal(13)
	for room_id: String in area.room_ids():
		for target: String in area.neighbours(room_id):
			assert_bool(area.neighbours(target).has(room_id)) \
					.override_failure_message("%s leva a %s, mas %s não volta" % [room_id, target, target]).is_true()


func test_MUN_080_saida_sem_volta_e_apontada() -> void:
	var area := AreaMap.new()
	area.add_room("x", "#####\n#A.b#\n#####", {"b": "y:A"})
	area.add_room("y", "#####\n#A..#\n#####", {})
	assert_bool(area.neighbours("y").has("x")).is_false()


func test_MUN_081_portas_fechadas_seguram_o_mago() -> void:
	var reached := _game().reach("sala_01", "A", {})
	assert_array(reached["rooms"].keys()).contains_exactly(["sala_01"])


## Regressão (Sprint 14): a porta do P1 tinha 3 tiles e o mago passava voando por cima dela.
func test_MUN_081_porta_baixa_deixa_passar_voando() -> void:
	var area := AreaMap.new()
	area.add_room("baixa", "######\n#....#\n#A.|.b\n######", {"b": "fora:A"})
	area.add_room("fora", "####\na.A#\n####", {"a": "baixa:A"})
	assert_bool(area.reach("baixa", "A", {})["rooms"].has("fora")).is_true()
	area.add_room("alta", "######\n#..|.#\n#A.|.b\n######", {"b": "fora:A"})
	assert_bool(area.reach("alta", "A", {})["rooms"].has("fora")).is_false()


func test_MUN_081_porta_aberta_deixa_passar() -> void:
	var area := AreaMap.new()
	area.add_room("alta", "######\n#..|.#\n#A.|.b\n######", {"b": "fora:A"})
	area.add_room("fora", "####\na.A#\n####", {"a": "alta:A"})
	assert_bool(area.reach("alta", "A", {"alta:porta": true})["rooms"].has("fora")).is_true()


func test_MUN_082_os_conceitos_vem_na_ordem() -> void:
	var area := _game()
	var walk := area.walkthrough("sala_01", "A")
	assert_array(walk["rooms"].keys()).contains_exactly_in_any_order(area.room_ids())
	assert_array(walk["puzzles"]).is_equal(PUZZLE_ORDER)
	assert_array(walk["closed"]).is_empty()


func test_MUN_082_licao_depois_da_porta_trava() -> void:
	var area := AreaMap.new()
	area.add_room("sala", "#######\n#A.|.7b\n#######", {"b": "fim:A"}, {"7": "serpente:ensino_x"},
			{"id": "px", "licoes": ["ensino_x"]})
	area.add_room("fim", "####\na.A#\n####", {"a": "sala:A"})
	var walk := area.walkthrough("sala", "A")
	assert_array(walk["puzzles"]).is_empty()
	assert_array(walk["closed"]).contains_exactly(["sala:porta"])
	assert_bool(walk["rooms"].has("fim")).is_false()


func test_MUN_082_atalho_abre_por_tras() -> void:
	var area := AreaMap.new()
	area.add_room("cima", "########\nd.C%.A.b\n########", {"b": "baixo:A", "d": "baixo:C"}, {}, {}, "C")
	area.add_room("baixo", "########\na.A..Cc#\n########", {"a": "cima:A", "c": "cima:C"})
	var only_top := AreaMap.new()
	only_top.add_room("cima", "########\nd.C%.A.#\n########", {}, {}, {}, "C")
	assert_bool(only_top.reach("cima", "A", {})["cells"]["cima"].has(Vector2i(2, 1))).is_false()
	var walk := area.walkthrough("cima", "A")
	assert_array(walk["closed"]).is_empty()
	assert_bool(walk["open"].has("cima:atalho")).is_true()


func test_MUN_083_licoes_declaradas_existem() -> void:
	var area := _game()
	var scenes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DialogueBook.DEFAULT_PATH))
	assert_int(area.puzzles().size()).is_equal(6)
	for room_id: String in area.puzzles():
		var lessons: Array = area.puzzles()[room_id].get("licoes", [])
		assert_array(lessons).override_failure_message("%s: puzzle sem licoes" % room_id).is_not_empty()
		for lesson: String in lessons:
			assert_bool(scenes.has(lesson)).override_failure_message("%s: lição %s não existe" % [room_id, lesson]).is_true()


func test_MUN_090_a_area_tem_dois_segredos() -> void:
	assert_array(_game().secret_ids()).contains_exactly_in_any_order(["sala_02_8", "sala_03_8"])
