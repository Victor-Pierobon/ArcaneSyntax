extends GdUnitTestSuite
## Spec: docs/specs/puzzles/PUZ-validacao.md (PUZ-001 a 003)

const ALL_LIT := [{"tipo": "cristais_acesos"}]


func test_PUZ_001_todos_os_cristais_acesos() -> void:
	assert_bool(PuzzleValidator.evaluate(ALL_LIT, {"cristais": {"5": true, "6": true}})).is_true()
	assert_bool(PuzzleValidator.evaluate(ALL_LIT, {"cristais": {"5": true, "6": false}})).is_false()
	assert_bool(PuzzleValidator.evaluate(ALL_LIT, {"cristais": {}})).is_false()


func test_PUZ_002_cristais_escolhidos() -> void:
	var state := {"cristais": {"5": true, "6": false}}
	assert_bool(PuzzleValidator.evaluate([{"tipo": "cristais_acesos", "ids": ["5"]}], state)).is_true()
	assert_bool(PuzzleValidator.evaluate([{"tipo": "cristais_acesos", "ids": ["6"]}], state)).is_false()
	assert_bool(PuzzleValidator.evaluate([{"tipo": "cristais_acesos", "ids": ["9"]}], state)).is_false()


func test_PUZ_003_condicao_desconhecida() -> void:
	var conditions := [{"tipo": "dancar"}]
	assert_bool(PuzzleValidator.evaluate(conditions, {"cristais": {"5": true}})).is_false()
	assert_array(PuzzleValidator.authoring_errors(conditions)).is_not_empty()
	assert_array(PuzzleValidator.authoring_errors(ALL_LIT)).is_empty()


func test_todas_as_condicoes_precisam_valer() -> void:
	var conditions := [{"tipo": "cristais_acesos", "ids": ["5"]}, {"tipo": "cristais_acesos", "ids": ["6"]}]
	assert_bool(PuzzleValidator.evaluate(conditions, {"cristais": {"5": true, "6": false}})).is_false()
	assert_bool(PuzzleValidator.evaluate([], {"cristais": {"5": true}})).is_false()


func test_PUZ_007_condicoes_novas() -> void:
	var done := {"cadeados": {"7": true}, "ponte": {"feitos": 12, "total": 12}, "placas": [true, true]}
	for kind in ["cadeados_abertos", "ponte_completa", "placas_pisadas"]:
		assert_bool(PuzzleValidator.evaluate([{"tipo": kind}], done)).override_failure_message(kind).is_true()
		assert_array(PuzzleValidator.authoring_errors([{"tipo": kind}])).is_empty()
	assert_bool(PuzzleValidator.evaluate([{"tipo": "cadeados_abertos"}], {"cadeados": {"7": true, "8": false}})).is_false()
	assert_bool(PuzzleValidator.evaluate([{"tipo": "ponte_completa"}], {"ponte": {"feitos": 11, "total": 12}})).is_false()
	assert_bool(PuzzleValidator.evaluate([{"tipo": "placas_pisadas"}], {"placas": [true, false]})).is_false()


func test_PUZ_007_sem_mecanismo_e_falso() -> void:
	assert_bool(PuzzleValidator.evaluate([{"tipo": "cadeados_abertos"}], {"cadeados": {}})).is_false()
	assert_bool(PuzzleValidator.evaluate([{"tipo": "ponte_completa"}], {"ponte": {"feitos": 0, "total": 0}})).is_false()
	assert_bool(PuzzleValidator.evaluate([{"tipo": "placas_pisadas"}], {"placas": []})).is_false()
	assert_bool(PuzzleValidator.evaluate([{"tipo": "ponte_completa"}], {})).is_false()


func test_PUZ_017_estrelas() -> void:
	var limits := [3.0, 5.0]
	assert_int(PuzzleValidator.stars(limits, 3.0)).is_equal(3)
	assert_int(PuzzleValidator.stars(limits, 3.1)).is_equal(2)
	assert_int(PuzzleValidator.stars(limits, 5.0)).is_equal(2)
	assert_int(PuzzleValidator.stars(limits, 5.1)).is_equal(1)
	assert_int(PuzzleValidator.stars([], 1.0)).is_equal(0)


func test_PUZ_017_conjuracao_que_so_recupera_mana_nao_conta() -> void:
	assert_bool(PuzzleValidator.counts_for_stars([{"tipo": "meditar"}, {"tipo": "absorver_mana"}])).is_false()
	assert_bool(PuzzleValidator.counts_for_stars([])).is_false()
	assert_bool(PuzzleValidator.counts_for_stars([{"tipo": "meditar"}, {"tipo": "construir_bloco"}])).is_true()
