extends GdUnitTestSuite
## Aceitação: docs/specs/puzzles/PUZ-05-elevador.md (PUZ-060, PUZ-061).
## Sala sala_p05 DO JOGO e Python de verdade. Colunas de 4, 10 e 15 tiles: levitar 5, 7 e 6.

const GRIMOIRE_PATH := "user://tests/grimorio_puz05.json"
const PUZZLE := "p05_elevador"

const FUNCAO := """def subir(altura):
    meditar()
    levitar(altura)
    mover(2)

subir(5)
subir(7)
subir(6)"""

const LISTA := """for altura in [5, 7, 6]:
    meditar()
    levitar(altura)
    mover(2)"""

var driver: PuzzleDriver


func before_test() -> void:
	driver = auto_free(PuzzleDriver.new())
	add_child(driver)
	await driver.start("sala_p05", GRIMOIRE_PATH)
	# Encosta na primeira coluna, como o jogador faria.
	await driver.walk_until_x(7 * 16.0)


func after_test() -> void:
	driver.cleanup()


func _plates() -> Array:
	return driver.room().puzzle_state()["placas"]


func _assert_solved(expected: bool, label: String) -> void:
	assert_bool(driver.world.is_puzzle_solved(PUZZLE)).override_failure_message("solução %s, placas %s" % [label, _plates()]).is_equal(expected)
	assert_bool(driver.room().doors_open()).override_failure_message("porta, solução %s" % label).is_equal(expected)


func test_PUZ_060_A_funcao_com_parametro() -> void:
	driver.world.state.set_mana(0.0)
	await driver.cast(FUNCAO, false, 60)
	_assert_solved(true, "A")


func test_PUZ_060_B_loop_sobre_uma_lista() -> void:
	driver.world.state.set_mana(0.0)
	await driver.cast(LISTA, false, 60)
	_assert_solved(true, "B")


func test_PUZ_060_C_linhas_soltas_em_tres_feiticos() -> void:
	for height in [5, 7, 6]:
		await driver.cast("levitar(%d)\nmover(2)" % height, true, 40)
	_assert_solved(true, "C")


func test_PUZ_061_X_a_mesma_altura_para_todas() -> void:
	for i in 3:
		await driver.cast("levitar(5)\nmover(2)", true, 40)
	_assert_solved(false, "X")
	assert_array(_plates()).is_equal([true, false, false])


func test_PUZ_061_Y_ordem_trocada() -> void:
	await driver.cast("mover(2)\nlevitar(5)", true, 60)
	_assert_solved(false, "Y")
	assert_array(_plates()).is_equal([false, false, false])


## Regressão (Sprint 9, captura de tela): as alturas não estavam gravadas na sala.
func test_PUZ_060_as_alturas_estao_gravadas() -> void:
	assert_array(driver.room().engravings()).is_equal(["5", "7", "6"])
