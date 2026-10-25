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
