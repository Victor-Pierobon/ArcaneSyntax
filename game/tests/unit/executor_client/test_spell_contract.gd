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


func test_resultado_le_o_custo_de_mana() -> void:
	var result := SpellResult.from_dict(fixtures["01_lancar_com_alvo"]["resposta"])
	assert_float(result.cost).is_equal_approx(3.2, 0.0001)


func test_resultado_de_erro_de_requisicao_tem_mago_vazio() -> void:
	var result := SpellResult.from_dict(fixtures["06_requisicao_invalida"]["resposta"])
	assert_bool(result.ok).is_false()
	assert_dict(result.mago).is_empty()
	assert_int(result.error.line).is_equal(SpellError.NO_POSITION)


func test_EXE_080_requisicao_leva_as_pecas_desbloqueadas() -> void:
	var mago := {"vida": 10, "mana": 5, "mana_max": 20}
	var request := SpellRequest.make("meditar()", mago, null, {}, PackedStringArray(["meditar", "fogo"]))
	assert_array(request.to_dict(1)["pecas"]).is_equal(["meditar", "fogo"])
	assert_bool(SpellRequest.make("meditar()", mago).to_dict(1).has("pecas")).is_false()


func test_falha_local_do_cliente() -> void:
	var result := SpellResult.failure("ExecutorIndisponivel", "sem Python")
	assert_bool(result.ok).is_false()
	assert_str(result.error.type).is_equal("ExecutorIndisponivel")
	assert_array(result.actions).is_empty()


func test_EXE_111_requisicao_leva_a_sala() -> void:
	var fixture: Dictionary = fixtures["10_pecas_de_puzzle"]
	var request := SpellRequest.make(
		fixture["requisicao"]["codigo"],
		{"vida": 5, "mana": 5, "mana_max": 10},
		null, {}, null,
		{"runas": [4, 7]},
	)
	assert_dict(ContractFixtures.normalize(request.to_dict(10))).is_equal(fixture["requisicao"])


func test_EXE_111_sem_sala_omite_o_campo() -> void:
	var request := SpellRequest.make("meditar()", {"vida": 10, "mana": 5, "mana_max": 20})
	assert_bool(request.to_dict(1)["mundo"].has("sala")).is_false()


func test_EXE_113_requisicao_leva_os_inimigos() -> void:
	var fixture: Dictionary = fixtures["11_combate"]
	var mundo: Dictionary = fixture["requisicao"]["mundo"]
	var request := SpellRequest.make(
		fixture["requisicao"]["codigo"], mundo["mago"], mundo["alvo"], {}, null, {}, mundo["inimigos"],
	)
	assert_dict(ContractFixtures.normalize(request.to_dict(11))).is_equal(fixture["requisicao"])


func test_EXE_113_sem_inimigos_omite_o_campo() -> void:
	var request := SpellRequest.make("meditar()", {"vida": 10, "mana": 5, "mana_max": 20})
	assert_bool(request.to_dict(1)["mundo"].has("inimigos")).is_false()


func test_EXE_113_resultado_le_a_faisca() -> void:
	var result := SpellResult.from_dict(fixtures["11_combate"]["resposta"])
	assert_str(result.actions[1]["forma"]).is_equal("faisca")
	assert_str(result.actions[2]["alvo"]).is_equal("sala_c02_alvo_4_1")
	assert_float(result.cost).is_equal(5.7)
