extends GdUnitTestSuite
## Aceitação: docs/specs/puzzles/PUZ-03-simbolo.md (PUZ-040, PUZ-041).
## Sala sala_p03 DO JOGO e Python de verdade. Cristal mutável de 3 cargas, semente fixa.

const GRIMOIRE_PATH := "user://tests/grimorio_puz03.json"
const PUZZLE := "p03_simbolo"

const IF_ELIF := """if alvo.elemento == "planta":
    lancar(fogo, projetil, alvo)
elif alvo.elemento == "fogo":
    lancar(gelo, projetil, alvo)
else:
    lancar(raio, projetil, alvo)"""

const DICIONARIO := """vence = {"planta": fogo, "fogo": gelo, "gelo": raio}
lancar(vence[alvo.elemento], projetil, alvo)"""

const FUNCAO := """def contra(simbolo):
    if simbolo == "planta":
        return fogo
    if simbolo == "fogo":
        return gelo
    return raio
lancar(contra(alvo.elemento), projetil, alvo)"""

var driver: PuzzleDriver


func before_test() -> void:
	driver = auto_free(PuzzleDriver.new())
	add_child(driver)
	await driver.start("sala_p03", GRIMOIRE_PATH)
	await driver.place(driver.cell_of("5") - Vector2i(6, 0))


func after_test() -> void:
	driver.cleanup()


func _crystal() -> Crystal:
	return driver.world.find_target("sala_p03_alvo_5") as Crystal


func _cast_times(code: String, times: int) -> void:
	for i in times:
		await driver.cast(code)


func _assert_solved(expected: bool, label: String) -> void:
	assert_bool(driver.world.is_puzzle_solved(PUZZLE)).override_failure_message("solução %s" % label).is_equal(expected)
	assert_bool(driver.room().doors_open()).override_failure_message("porta, solução %s" % label).is_equal(expected)


func test_PUZ_040_o_alvo_mostra_o_simbolo() -> void:
	var target: Dictionary = driver.world.current_target()
	assert_array(MutableCrystalRule.SYMBOLS).contains([target["elemento"]])
	assert_str(target["elemento"]).is_equal(_crystal().rule.symbol)


func test_PUZ_040_A_if_elif_else() -> void:
	await _cast_times(IF_ELIF, 3)
	_assert_solved(true, "A")


func test_PUZ_040_B_dicionario() -> void:
	await _cast_times(DICIONARIO, 3)
	_assert_solved(true, "B")


func test_PUZ_040_C_funcao_com_return() -> void:
	await _cast_times(FUNCAO, 3)
	_assert_solved(true, "C")


func test_PUZ_040_D_passivo() -> void:
	await driver.run_passive(IF_ELIF, 6.0)
	_assert_solved(true, "D")


func test_PUZ_041_X_sempre_o_mesmo_elemento() -> void:
	await _cast_times("lancar(fogo, projetil, alvo)", 3)
	_assert_solved(false, "X")


func test_PUZ_041_Y_o_proprio_simbolo() -> void:
	await _cast_times("lancar(alvo.elemento, projetil, alvo)", 3)
	_assert_solved(false, "Y")


func test_PUZ_041_Z_tres_lancamentos_num_feitico() -> void:
	var looped := "for i in range(3):\n" + "\n".join(Array(IF_ELIF.split("\n")).map(func(line: String) -> String: return "    " + line))
	await driver.cast(looped, true, 90)
	_assert_solved(false, "Z")
