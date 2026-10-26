extends GdUnitTestSuite
## Aceitação: docs/specs/puzzles/PUZ-04-ponte.md (PUZ-050, PUZ-051).
## Sala sala_p04 DO JOGO e Python de verdade. Vão de 12 sobre espinhos; estrelas [7.5, 9.0].

const GRIMOIRE_PATH := "user://tests/grimorio_puz04.json"
const PUZZLE := "p04_ponte"

var driver: PuzzleDriver


func before_test() -> void:
	driver = auto_free(PuzzleDriver.new())
	add_child(driver)
	await driver.start("sala_p04", GRIMOIRE_PATH)
	await driver.place(Vector2i(6, 5))


func after_test() -> void:
	driver.cleanup()


func _assert_solved(expected: bool, label: String) -> void:
	assert_bool(driver.world.is_puzzle_solved(PUZZLE)).override_failure_message("solução %s" % label).is_equal(expected)
	assert_bool(driver.room().doors_open()).override_failure_message("porta, solução %s" % label).is_equal(expected)


func _assert_stars(expected: int, cost: float, label: String) -> void:
	assert_float(driver.world.room_mana_spent).override_failure_message("custo, solução %s" % label).is_equal_approx(cost, 0.001)
	assert_int(driver.world.puzzle_stars(PUZZLE)).override_failure_message("estrelas, solução %s" % label).is_equal(expected)


## Atravessa a ponte andando até a porta (já aberta) e confere que não caiu.
func _cross() -> void:
	await driver.walk_until_x(26 * 16.0)
	assert_float(driver.world.player.global_position.x).is_greater(24 * 16.0)
	assert_int(driver.world.state.health.current).is_equal(5)


func test_PUZ_050_A_for() -> void:
	await driver.cast("for i in range(12):\n    construir_bloco()")
	_assert_solved(true, "A")
	_assert_stars(3, 7.3, "A")
	await _cross()


## PRO-006 (docs/specs/progressao/PRO-xp.md): 3 estrelas dão 20 + 10 de economia.
func test_PRO_006_bonus_de_economia() -> void:
	await driver.cast("for i in range(12):\n    construir_bloco()")
	assert_int(driver.world.state.xp).is_equal(30)
	assert_str(driver.world.cast_log.text()).contains("+30 XP (economia +10)")


func test_PUZ_050_B_while_com_contador() -> void:
	await driver.cast("n = 0\nwhile n < 12:\n    construir_bloco()\n    n = n + 1")
	_assert_solved(true, "B")
	_assert_stars(2, 8.8, "B")


func test_PUZ_050_C_doze_linhas_soltas() -> void:
	await driver.cast("\n".join(_twelve_lines()))
	_assert_solved(true, "C")
	_assert_stars(2, 8.4, "C")


func test_PUZ_050_D_dois_feiticos_de_seis() -> void:
	await driver.cast("for i in range(6):\n    construir_bloco()")
	await driver.cast("for i in range(6):\n    construir_bloco()")
	_assert_solved(true, "D")
	_assert_stars(3, 7.4, "D")


func test_PUZ_051_X_uma_volta_a_menos() -> void:
	await driver.cast("for i in range(11):\n    construir_bloco()")
	_assert_solved(false, "X")
	assert_int(driver.room().bridge.built()).is_equal(11)
	await driver.cast("construir_bloco()")
	_assert_solved(true, "X + 1")


func test_PUZ_051_Y_sem_parenteses() -> void:
	await driver.cast("for i in range(12):\n    construir_bloco")
	_assert_solved(false, "Y")
	assert_int(driver.room().bridge.built()).is_equal(0)


func _twelve_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for i in 12:
		lines.append("construir_bloco()")
	return lines
