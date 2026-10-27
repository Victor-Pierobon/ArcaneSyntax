extends GdUnitTestSuite
## Spec: docs/specs/mundo/MUN-salas.md (regras 9 e 10, MUN-111): as salas refeitas na Sprint 18
## deixam voltar a pé e chegar a pé ao puzzle; desde a Sprint 19, as 13 salas da Alpha.

const ROOMS_DIR := "res://content/rooms/"
const ROOMS := ["sala_01", "sala_02", "sala_03", "sala_p02", "sala_p03", "sala_p04", "sala_p05", "sala_p06",
		"sala_c01", "sala_c02", "sala_c03", "sala_c04", "sala_fim"]
## A entrada ao lado da saída para a sala anterior (na sala_01, a do começo).
const BACK_ENTRY := "A"
## A serpente fala com o mago a até 2 tiles (NAR-dialogo); os alvos do feitiço ficam a até 12.
const TALK_TILES := 2
const TARGET_TILES := 12.0


func _room(room_id: String) -> Room:
	var room: Room = load(ROOMS_DIR + room_id + ".tscn").instantiate()
	room.data = RoomLayout.parse(room.layout)
	return auto_free(room)


func test_MUN_111_salas_do_tamanho_da_tela() -> void:
	for room_id: String in ROOMS:
		var data := _room(room_id).data
		assert_bool(data.width >= 40 and data.height >= 22) \
				.override_failure_message("%s tem %dx%d" % [room_id, data.width, data.height]).is_true()
		assert_array(data.errors).override_failure_message(room_id).is_empty()


func test_MUN_111_toda_entrada_volta_a_pe() -> void:
	for room_id: String in ROOMS:
		var data := _room(room_id).data
		var map := WalkMap.new(data, true)
		var back: Vector2i = data.entries[BACK_ENTRY]
		for letter: String in data.entries:
			var reach := map.reach(data.entries[letter])
			assert_bool(reach.has(back)) \
					.override_failure_message("%s: da entrada %s não se volta a pé à %s" % [room_id, letter, BACK_ENTRY]) \
					.is_true()


func test_MUN_111_o_puzzle_se_alcanca_a_pe() -> void:
	for room_id: String in ROOMS:
		var room := _room(room_id)
		var data := room.data
		# Antes de resolver: portas fechadas. A ponte conta como feita: ela é parte do puzzle (na
		# sala_p06, o cristal fica do outro lado).
		var reach := WalkMap.new(data, false, true).reach(data.entries[BACK_ENTRY])
		for digit: String in data.targets:
			var spec := str(room.targets.get(digit, ""))
			var cell: Vector2i = data.targets[digit]
			var limit := -1.0
			if spec.begins_with("serpente:") or spec == "fonte":
				limit = TALK_TILES
			elif spec.begins_with("cadeado"):
				limit = RuneLock.REACH_TILES
			elif spec.begins_with("cristal") or spec.begins_with("runa:"):
				limit = TARGET_TILES
			if limit < 0.0:
				continue
			var near := reach.keys().any(func(at: Vector2i) -> bool:
				return Vector2(at).distance_to(Vector2(cell)) <= limit + 0.001)
			assert_bool(near).override_failure_message("%s: %s (%s) longe do caminho a pé" % [room_id, spec, digit]).is_true()


## Saídas que só o feitiço do puzzle alcança (o elevador).
const SPELL_EXITS := {"sala_p05": ["b"], "sala_p06": ["b"]}


func test_MUN_111_toda_saida_se_alcanca_a_pe() -> void:
	for room_id: String in ROOMS:
		var data := _room(room_id).data
		var reach := WalkMap.new(data, true).reach(data.entries[BACK_ENTRY])
		for letter: String in data.exits:
			if letter in SPELL_EXITS.get(room_id, []):
				continue
			var cells: Array = data.exits[letter]
			var near := reach.keys().any(func(at: Vector2i) -> bool:
				return cells.any(func(exit: Vector2i) -> bool: return absi(exit.x - at.x) <= 1 and exit.y == at.y))
			assert_bool(near).override_failure_message("%s: a saída %s não se alcança a pé" % [room_id, letter]).is_true()

