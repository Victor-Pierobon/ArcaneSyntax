extends GdUnitTestSuite
## Spec: docs/specs/executor/EXE-protocolo.md (EXE-009), lado Godot do contrato.

var fixtures: Dictionary


func before() -> void:
	fixtures = ContractFixtures.load_all()


func test_existem_fixtures() -> void:
	assert_int(fixtures.size()).is_greater_equal(5)


func test_EXE_009_resultado_le_toda_resposta_sem_perder_campos() -> void:
	for name: String in fixtures:
		var expected: Dictionary = fixtures[name]["resposta"]
		var result := SpellResult.from_dict(expected)
		assert_dict(ContractFixtures.normalize(result.to_dict())) \
				.override_failure_message("fixture %s" % name) \
				.is_equal(expected)


func test_EXE_009_requisicao_gera_o_formato_do_contrato() -> void:
	var fixture: Dictionary = fixtures["02_loop_de_mana"]
	var request := SpellRequest.make(
		"while mana < mana_max:\n    absorver_mana()",
		{"vida": 10, "mana": 1, "mana_max": 3},
		null,
		{"ganho_absorver": 1},
	)
	assert_dict(ContractFixtures.normalize(request.to_dict(2))).is_equal(fixture["requisicao"])


func test_requisicao_sem_regras_omite_o_campo() -> void:
	var request := SpellRequest.make("meditar()", {"vida": 10, "mana": 5, "mana_max": 20})
	assert_bool(request.to_dict(1).has("regras")).is_false()


func test_resultado_converte_linhas_para_int() -> void:
	var result := SpellResult.from_dict(fixtures["05_erro_execucao_parcial"]["resposta"])
	assert_int(typeof(result.actions[0]["linha"])).is_equal(TYPE_INT)
	assert_int(typeof(result.outputs[0]["linha"])).is_equal(TYPE_INT)
	assert_int(result.error.line).is_equal(3)
	assert_int(result.error.column).is_equal(SpellError.NO_POSITION)
	assert_str(result.error.type).is_equal("NameError")


func test_resultado_de_erro_de_requisicao_tem_mago_vazio() -> void:
	var result := SpellResult.from_dict(fixtures["06_requisicao_invalida"]["resposta"])
	assert_bool(result.ok).is_false()
	assert_dict(result.mago).is_empty()
	assert_int(result.error.line).is_equal(SpellError.NO_POSITION)


func test_falha_local_do_cliente() -> void:
	var result := SpellResult.failure("ExecutorIndisponivel", "sem Python")
	assert_bool(result.ok).is_false()
	assert_str(result.error.type).is_equal("ExecutorIndisponivel")
	assert_array(result.actions).is_empty()
