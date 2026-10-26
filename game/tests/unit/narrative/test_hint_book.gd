extends GdUnitTestSuite
## Spec: docs/specs/narrativa/NAR-dicas.md (NAR-040, NAR-041)

const PUZZLES := ["p01_meditar", "p02_runas", "p03_simbolo", "p04_ponte", "p05_elevador", "p06_revisao"]


func test_NAR_040_conteudo_das_dicas() -> void:
	var book := HintBook.load_file(HintBook.DEFAULT_PATH)
	assert_array(book.errors).is_empty()
	for puzzle_id: String in PUZZLES:
		assert_bool(book.has_hints(puzzle_id)).override_failure_message(puzzle_id).is_true()
		assert_int(book.hints(puzzle_id).size()).override_failure_message(puzzle_id).is_equal(3)


func test_NAR_040_erros_de_autoria() -> void:
	var data := {"p_curto": ["A", "B"], "p_sem_texto": ["A", "NAO_EXISTE", "B"], "p_ruim": "texto"}
	var errors := HintBook.validate(data, func(key: String) -> bool: return not key.begins_with("NAO_"))
	assert_array(errors).contains([
		"dicas, puzzle p_curto: precisa de 3 dicas (tem 2)",
		"dicas, puzzle p_sem_texto: texto \"NAO_EXISTE\" não existe em textos.csv",
		"dicas, puzzle p_ruim: precisa de 3 dicas (tem 0)",
	])
	assert_array(HintBook.validate([], func(_key: String) -> bool: return true)).is_not_empty()


func test_NAR_041_a_cena_da_dica() -> void:
	var book := HintBook.load_file(HintBook.DEFAULT_PATH)
	var scene := book.scene("p02_runas", 2)
	assert_str(scene["inicio"]).is_equal("pergunta")
	var lines: Dictionary = scene["falas"]
	assert_str(lines["pergunta"]["texto"]).is_equal("SERPENTE_DICA_PERGUNTA_2")
	assert_array(lines["pergunta"]["opcoes"].map(func(option: Dictionary) -> String: return option["proxima"])) \
			.is_equal([HintBook.HINT_LINE, "nao"])
	assert_str(lines[HintBook.HINT_LINE]["texto"]).is_equal(book.hints("p02_runas")[1])
	assert_array(DialogueBook.validate({"dica": scene})).is_empty()


func test_NAR_041_nivel_fora_da_faixa_e_puzzle_sem_dicas() -> void:
	var book := HintBook.load_file(HintBook.DEFAULT_PATH)
	assert_str(book.scene("p04_ponte", 7)["falas"][HintBook.HINT_LINE]["texto"]).is_equal(book.hints("p04_ponte")[2])
	assert_dict(book.scene("p_que_nao_existe", 1)).is_empty()
