extends GdUnitTestSuite
## Spec: docs/specs/narrativa/NAR-dialogo.md (NAR-001 a NAR-004)

const TEST_FILE := "user://tests/dialogos_teste.json"

var _known := func(key: String) -> bool: return not key.begins_with("NAO_")


func after_test() -> void:
	if FileAccess.file_exists(TEST_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_FILE))


func _linear() -> Dictionary:
	return {"inicio": "a", "falas": {
		"a": {"quem": "serpente", "texto": "T_A", "proxima": "b"},
		"b": {"quem": "mago", "texto": "T_B"},
	}}


func _branching() -> Dictionary:
	return {"inicio": "a", "falas": {
		"a": {"texto": "T_A", "opcoes": [{"texto": "O_1", "proxima": "b"}, {"texto": "O_2", "proxima": "c"}]},
		"b": {"texto": "T_B"},
		"c": {"texto": "T_C"},
	}}


func test_NAR_001_cena_linear() -> void:
	var run := DialogueRun.new(_linear())
	assert_dict(run.current()).is_equal({"quem": "serpente", "texto": "T_A", "opcoes": []})
	assert_bool(run.is_finished()).is_false()
	run.advance()
	assert_str(run.current()["quem"]).is_equal("mago")
	assert_str(run.current()["texto"]).is_equal("T_B")
	run.advance()
	assert_bool(run.is_finished()).is_true()
	assert_dict(run.current()).is_empty()


func test_NAR_001_quem_padrao_e_a_serpente() -> void:
	assert_str(DialogueRun.new(_branching()).current()["quem"]).is_equal("serpente")


func test_NAR_002_ramificar() -> void:
	var run := DialogueRun.new(_branching())
	assert_array(run.current()["opcoes"]).is_equal(["O_1", "O_2"])
	run.advance()
	assert_str(run.line_id).is_equal("a")
	run.choose(5)
	assert_str(run.line_id).is_equal("a")
	run.choose(2)
	assert_str(run.current()["texto"]).is_equal("T_C")
	run.advance()
	assert_bool(run.is_finished()).is_true()


func test_NAR_002_texto_e_traduzido() -> void:
	var scene := {"inicio": "a", "falas": {"a": {"texto": "ALVO_FRACO"}}}
	assert_str(DialogueRun.new(scene).current()["texto"]).is_equal("Fraco!")


func test_NAR_003_erros_de_autoria_claros() -> void:
	var data := {
		"x": {"inicio": "a", "falas": {"a": {"texto": "T_A", "proxima": "z"}}},
		"y": {"inicio": "a", "falas": {"a": {"texto": "NAO_EXISTE"}}},
		"sem_inicio": {"falas": {"a": {"texto": "T_A"}}},
		"as_duas": {"inicio": "a", "falas": {
			"a": {"texto": "T_A", "proxima": "b", "opcoes": [{"texto": "O", "proxima": "b"}]},
			"b": {"texto": "T_B"},
		}},
		"opcao_solta": {"inicio": "a", "falas": {"a": {"texto": "T_A", "opcoes": [{"texto": "O"}]}}},
		"quatro": {"inicio": "a", "falas": {
			"a": {"texto": "T_A", "opcoes": [
				{"texto": "O", "proxima": "b"}, {"texto": "O", "proxima": "b"},
				{"texto": "O", "proxima": "b"}, {"texto": "O", "proxima": "b"},
			]},
			"b": {"texto": "T_B"},
		}},
		"inicio_errado": {"inicio": "q", "falas": {"a": {"texto": "T_A"}}},
	}
	var errors := DialogueBook.validate(data, _known)
	assert_array(errors).contains([
		"diálogo x, fala a: próxima fala \"z\" não existe",
		"diálogo y, fala a: texto \"NAO_EXISTE\" não existe em textos.csv",
		"diálogo sem_inicio: falta \"inicio\"",
		"diálogo as_duas, fala a: use \"proxima\" ou \"opcoes\", não as duas",
		"diálogo opcao_solta, fala a: opção 1 sem \"proxima\"",
		"diálogo quatro, fala a: no máximo 3 opções",
		"diálogo inicio_errado: fala inicial \"q\" não existe",
	])


func test_NAR_003_fala_que_nunca_e_alcancada_ou_nao_termina() -> void:
	var data := {
		"solta": {"inicio": "a", "falas": {"a": {"texto": "T_A"}, "b": {"texto": "T_B"}}},
		"ciclo": {"inicio": "a", "falas": {"a": {"texto": "T_A", "proxima": "b"}, "b": {"texto": "T_B", "proxima": "a"}}},
	}
	var errors := DialogueBook.validate(data, _known)
	assert_array(errors).contains([
		"diálogo solta, fala b: nunca é alcançada",
		"diálogo ciclo, fala a: não chega a um fim",
	])


func test_NAR_003_arquivo_ilegivel_e_cena_com_erro_nao_toca() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	var file := FileAccess.open(TEST_FILE, FileAccess.WRITE)
	file.store_string("{ nada")
	file.close()
	var broken := DialogueBook.load_file(TEST_FILE)
	assert_int(broken.errors.size()).is_equal(1)
	assert_str(broken.errors[0]).contains("diálogos").contains("ler")
	var book := DialogueBook.from_data({"boa": _linear(), "ruim": {"falas": {}}}, func(_key: String) -> bool: return true)
	assert_bool(book.can_play("boa")).is_true()
	assert_bool(book.can_play("ruim")).is_false()
	assert_bool(book.can_play("nao_existe")).is_false()
	assert_object(book.start("ruim")).is_null()
	assert_object(book.start("boa")).is_not_null()


func test_NAR_004_conteudo_do_jogo_e_valido() -> void:
	var book := DialogueBook.load_file(DialogueBook.DEFAULT_PATH)
	assert_array(book.errors).is_empty()
	assert_bool(book.can_play("serpente_ola")).is_true()
