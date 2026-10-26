extends GdUnitTestSuite
## Spec: docs/specs/narrativa/NAR-serpente.md (regras 1 e 2, NAR-020): conteúdo das salas do jogo.

const LESSONS := {
	"sala_01": "ensino_sequencia",
	"sala_p02": "ensino_variaveis",
	"sala_p03": "ensino_condicionais",
	"sala_p04": "ensino_loops",
	"sala_p05": "ensino_funcoes",
	"sala_p06": "ensino_revisao",
}


func _serpent_scenes(room_id: String) -> Array:
	var room: Room = load("res://content/rooms/%s.tscn" % room_id).instantiate()
	var scenes := []
	for spec: Variant in room.targets.values():
		if str(spec).begins_with("serpente:"):
			scenes.append(str(spec).trim_prefix("serpente:"))
	room.free()
	return scenes


func test_NAR_020_toda_sala_de_puzzle_tem_a_sua_serpente() -> void:
	var book := DialogueBook.load_file(DialogueBook.DEFAULT_PATH)
	assert_array(book.errors).is_empty()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DialogueBook.DEFAULT_PATH))
	for room_id: String in LESSONS:
		var lesson: String = LESSONS[room_id]
		assert_array(_serpent_scenes(room_id)).override_failure_message(room_id).is_equal([lesson])
		assert_bool(book.can_play(lesson)).override_failure_message(lesson).is_true()
		assert_bool(data[lesson]["falas"].has(World.LESSON_LINE)).override_failure_message("%s sem licao" % lesson).is_true()


## NAR-040 pelas salas: todo puzzle que existe no jogo tem as três dicas, mesmo um puzzle novo.
func test_NAR_040_todo_puzzle_das_salas_tem_dicas() -> void:
	var book := HintBook.load_file(HintBook.DEFAULT_PATH)
	var found := 0
	for file in DirAccess.get_files_at("res://content/rooms/"):
		if not file.ends_with(".tscn"):
			continue
		var room: Room = load("res://content/rooms/" + file).instantiate()
		if room.has_puzzle():
			found += 1
			assert_int(book.hints(room.puzzle_id()).size()).override_failure_message(room.puzzle_id()).is_equal(3)
		room.free()
	assert_int(found).is_equal(6)


func test_NAR_020_cena_de_teste_da_sprint_12_saiu() -> void:
	assert_bool(DialogueBook.load_file(DialogueBook.DEFAULT_PATH).can_play("serpente_ola")).is_false()
