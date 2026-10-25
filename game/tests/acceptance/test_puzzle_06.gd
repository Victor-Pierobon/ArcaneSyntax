extends GdUnitTestSuite
## Aceitação: docs/specs/puzzles/PUZ-06-revisao.md (PUZ-070 a 072).
## Sala sala_p06 DO JOGO e Python de verdade, percorrida da esquerda para a direita:
## cadeado (coluna 12), ponte de 8 (colunas 16 a 23), cristal mutável de 2 cargas (coluna 31),
## colunas de 4 e 9 tiles (levitar 5 e 6) a partir da coluna 35. Estrelas [20, 24].

const GRIMOIRE_PATH := "user://tests/grimorio_puz06.json"
const PUZZLE := "p06_revisao"

const CRISTAL_IF := """if alvo.elemento == "planta":
    lancar(fogo, projetil, alvo)
elif alvo.elemento == "fogo":
    lancar(gelo, projetil, alvo)
else:
    lancar(raio, projetil, alvo)"""

const CRISTAL_DICT := """vence = {"planta": fogo, "fogo": gelo, "gelo": raio}
lancar(vence[alvo.elemento], projetil, alvo)"""

const SUBIR := """def subir(h):
    levitar(h)
    mover(2)
subir(5)
subir(6)"""

var driver: PuzzleDriver


func before_test() -> void:
	driver = auto_free(PuzzleDriver.new())
	add_child(driver)
	await driver.start("sala_p06", GRIMOIRE_PATH)
	driver.set_runes([4, 7, 2])


func after_test() -> void:
	driver.cleanup()


func _assert_solved(expected: bool, label: String) -> void:
	assert_bool(driver.world.is_puzzle_solved(PUZZLE)) \
			.override_failure_message("solução %s, estado %s" % [label, driver.room().puzzle_state()]).is_equal(expected)
	assert_bool(driver.room().doors_open()).override_failure_message("porta, solução %s" % label).is_equal(expected)


## Percorre a sala: cadeado, ponte, cristal e colunas, cada etapa com o seu feitiço.
func _play_room(lock: String, bridge: String, crystal: Array, climb: Array, cross_walking := true) -> void:
	await driver.place(Vector2i(10, 13))
	await driver.cast(lock)
	await driver.place(Vector2i(14, 13))
	await driver.cast(bridge)
	if cross_walking:
		await driver.walk_until_x(26 * 16.0 + 8)
	else:
		await driver.place(Vector2i(26, 13))
	for code: String in crystal:
		await driver.cast(code)
	await driver.walk_until_x(35 * 16.0)
	for code: String in climb:
		await driver.cast(code, true, 60)


func test_PUZ_070_A_economica() -> void:
	await _play_room("inscrever(ler_runa(1) + ler_runa(2) + ler_runa(3))",
			"for i in range(8):\n    construir_bloco()", [CRISTAL_IF, CRISTAL_IF], [SUBIR])
	_assert_solved(true, "A")
	assert_float(driver.world.room_mana_spent).is_equal_approx(19.5, 0.001)
	assert_int(driver.world.puzzle_stars(PUZZLE)).is_equal(3)


func test_PUZ_070_B_detalhada() -> void:
	var eight := PackedStringArray()
	for i in 8:
		eight.append("construir_bloco()")
	await _play_room("a = ler_runa(1)\nb = ler_runa(2)\nc = ler_runa(3)\ninscrever(a + b + c)",
			"\n".join(eight), [CRISTAL_DICT, CRISTAL_DICT], ["levitar(5)\nmover(2)\nlevitar(6)\nmover(2)"])
	_assert_solved(true, "B")
	assert_float(driver.world.room_mana_spent).is_equal_approx(21.0, 0.001)
	assert_int(driver.world.puzzle_stars(PUZZLE)).is_equal(2)


func test_PUZ_070_C_passivo_e_funcoes() -> void:
	await driver.place(Vector2i(10, 13))
	await driver.cast("inscrever(ler_runa(1) + ler_runa(2) + ler_runa(3))")
	await driver.place(Vector2i(14, 13))
	await driver.cast("def ponte(n):\n    for i in range(n):\n        construir_bloco()\nponte(8)")
	await driver.walk_until_x(26 * 16.0 + 8)
	await driver.run_passive(CRISTAL_IF, 4.0)
	await driver.walk_until_x(35 * 16.0)
	await driver.cast(SUBIR, true, 60)
	_assert_solved(true, "C")
	assert_int(driver.world.puzzle_stars(PUZZLE)).is_greater_equal(1)


func test_PUZ_071_um_erro_a_mais_tira_a_terceira_estrela() -> void:
	await _play_room("inscrever(ler_runa(1) + ler_runa(2) + ler_runa(3))",
			"for i in range(8):\n    construir_bloco()",
			["lancar(alvo.elemento, projetil, alvo)", CRISTAL_IF, CRISTAL_IF], [SUBIR])
	_assert_solved(true, "A com um erro")
	assert_float(driver.world.room_mana_spent).is_equal_approx(22.7, 0.001)
	assert_int(driver.world.puzzle_stars(PUZZLE)).is_equal(2)


func test_PUZ_072_X_ponte_incompleta() -> void:
	await _play_room("inscrever(ler_runa(1) + ler_runa(2) + ler_runa(3))",
			"for i in range(7):\n    construir_bloco()", [CRISTAL_IF, CRISTAL_IF], [SUBIR], false)
	_assert_solved(false, "X")
	var state := driver.room().puzzle_state()
	assert_dict(state["cadeados"]).is_equal({"7": true})
	assert_bool(state["cristais"]["5"]).is_true()
	assert_array(state["placas"]).is_equal([true, true])


func test_PUZ_072_Y_cristal_com_elemento_fixo() -> void:
	await _play_room("inscrever(ler_runa(1) + ler_runa(2) + ler_runa(3))",
			"for i in range(8):\n    construir_bloco()",
			["lancar(fogo, projetil, alvo)", "lancar(fogo, projetil, alvo)"], [SUBIR])
	_assert_solved(false, "Y")


## Regressão (Sprint 9, captura de tela): as alturas das colunas não estavam gravadas na sala.
func test_PUZ_070_as_alturas_estao_gravadas() -> void:
	assert_array(driver.room().engravings()).is_equal(["5", "6"])
