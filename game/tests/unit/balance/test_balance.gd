extends GdUnitTestSuite
## Spec: docs/specs/balanceamento/BAL-valores.md (BAL-001 a BAL-003)

const TEST_FILE := "user://tests/balanceamento_teste.json"


func after_test() -> void:
	Balance.reset()
	if FileAccess.file_exists(TEST_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_FILE))


## O arquivo do jogo, com `changes` aplicadas: {"secao.chave": valor}; valor null apaga a chave.
func _write_variant(changes: Dictionary) -> Dictionary:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Balance.DEFAULT_PATH))
	for path: String in changes:
		var parts := path.split(".")
		if changes[path] == null:
			data[parts[0]].erase(parts[1])
		else:
			data[parts[0]][parts[1]] = changes[path]
	_write_text(JSON.stringify(data))
	return data


func _write_text(text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	var file := FileAccess.open(TEST_FILE, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_BAL_001_arquivo_do_jogo_e_valido() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(Balance.DEFAULT_PATH))
	assert_array(Balance.validate(data)).is_empty()
	assert_float(Balance.number("chefe", "vida")).is_equal(90.0)
	assert_array(Balance.list("chefe", "elementos")).is_equal(["fogo", "gelo", "planta"])
	assert_array(Balance.list("chefe", "ataques")[2]).is_equal(["investida", "pilares", "leque"])
	assert_int(Balance.integer("guardiao", "vida")).is_equal(18)
	assert_array(Balance.errors()).is_empty()


func test_BAL_002_erros_apontam_a_chave() -> void:
	var data := _write_variant({"chefe.vida": null, "dano.projetil": "três"})
	var errors := Balance.validate(data)
	assert_array(errors).contains([
		"balanceamento: falta \"chefe.vida\"",
		"balanceamento: \"dano.projetil\" não é número",
	])
	assert_int(errors.size()).is_equal(2)


func test_BAL_002_elementos_do_chefe_sao_validados() -> void:
	var data := _write_variant({"chefe.elementos": ["fogo", 3]})
	assert_array(Balance.validate(data)).contains(["balanceamento: \"chefe.elementos\" não é lista de elementos"])


func test_BAL_002_ataques_do_chefe_sao_validados() -> void:
	var data := _write_variant({"chefe.ataques": [["leque"], ["pilares", "voo"], ["investida"]]})
	assert_array(Balance.validate(data)).contains(["balanceamento: \"chefe.ataques\" não é lista de ataques"])


func test_BAL_002_listas_do_chefe_tem_uma_posicao_por_fase() -> void:
	var data := _write_variant({"chefe.troca_vida": [60], "chefe.leque_orbes": [3, 5]})
	assert_array(Balance.validate(data)).contains([
		"balanceamento: \"chefe.troca_vida\" precisa ter 2 posições (uma a menos que as fases)",
		"balanceamento: \"chefe.leque_orbes\" precisa ter 3 posições (uma por fase)",
	])


func test_BAL_002_arquivo_ilegivel() -> void:
	_write_text("{ isto não é json")
	Balance.use_file(TEST_FILE)
	assert_int(Balance.errors().size()).is_equal(1)
	assert_str(Balance.errors()[0]).contains("balanceamento").contains("ler")


func test_BAL_002_chave_que_falta_vale_zero() -> void:
	_write_variant({"chefe.vida": null})
	Balance.use_file(TEST_FILE)
	assert_float(Balance.number("chefe", "vida")).is_equal(0.0)
	assert_float(Balance.number("secao_que_nao_existe", "x")).is_equal(0.0)


func test_BAL_003_os_numeros_mudam_o_jogo() -> void:
	_write_variant({"elemental.vida": 20, "dano.projetil": 4, "executor.custo_lancar": 5})
	Balance.use_file(TEST_FILE)
	var elemental: Elemental = auto_free(Elemental.make_elemental("e", "fogo"))
	add_child(elemental)
	assert_int(elemental.health.maximum).is_equal(20)
	assert_int(Damage.amount("raio", "projetil", "fogo")).is_equal(4)
	assert_float(float(Balance.rules()["custo_lancar"])).is_equal(5.0)


func test_BAL_003_reset_volta_ao_arquivo_do_jogo() -> void:
	_write_variant({"dano.projetil": 4})
	Balance.use_file(TEST_FILE)
	Balance.reset()
	assert_int(Damage.amount("raio", "projetil", "fogo")).is_equal(3)


func test_BAL_003_regras_tem_as_chaves_do_executor() -> void:
	var rules := Balance.rules()
	for key in ["ganho_meditar", "ganho_absorver", "custo_instrucao", "custo_inscricao", "custo_lancar",
			"custo_mover", "custo_levitar", "custo_meditar", "custo_absorver", "custo_inscrever", "custo_bloco",
			"custo_faisca", "limite_tempo_ms"]:
		assert_bool(rules.has(key)).override_failure_message(key).is_true()
	assert_int(rules.size()).is_equal(13)
