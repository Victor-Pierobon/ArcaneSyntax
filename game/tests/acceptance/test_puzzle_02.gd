extends GdUnitTestSuite
## Aceitação: docs/specs/puzzles/PUZ-02-runas.md (PUZ-030 a 032).
## Sala sala_p02 DO JOGO e Python de verdade. Runas fixadas em 4, 7 e 2 (soma 13).

const GRIMOIRE_PATH := "user://tests/grimorio_puz02.json"
const PUZZLE := "p02_runas"

var driver: PuzzleDriver


func before_test() -> void:
	driver = auto_free(PuzzleDriver.new())
	add_child(driver)
	await driver.start("sala_p02", GRIMOIRE_PATH)
	driver.set_runes([4, 7, 2])
	await driver.place(driver.cell_of("7") - Vector2i(2, 0))


func after_test() -> void:
	driver.cleanup()


func _assert_solved(expected: bool, label: String) -> void:
	assert_bool(driver.world.is_puzzle_solved(PUZZLE)).override_failure_message("solução %s" % label).is_equal(expected)
	assert_bool(driver.room().doors_open()).override_failure_message("porta, solução %s" % label).is_equal(expected)


func test_PUZ_030_A_uma_variavel_por_runa() -> void:
	await driver.cast("a = ler_runa(1)\nb = ler_runa(2)\nc = ler_runa(3)\ninscrever(a + b + c)")
	_assert_solved(true, "A")


func test_PUZ_030_B_acumulador_num_loop() -> void:
	await driver.cast("total = 0\nfor n in range(1, 4):\n    total = total + ler_runa(n)\ninscrever(total)")
	_assert_solved(true, "B")


func test_PUZ_030_C_expressao_direta() -> void:
	var result := await driver.cast("inscrever(ler_runa(1) + ler_runa(2) + ler_runa(3))")
	assert_float(result.cost).is_equal_approx(1.2, 0.001)
	_assert_solved(true, "C")


func test_PUZ_030_D_ler_com_visao_e_escrever_o_numero() -> void:
	var vision := await driver.cast("print(ler_runa(1) + ler_runa(2) + ler_runa(3))")
	assert_str(vision.outputs[0]["texto"]).is_equal("13")
	await driver.cast("inscrever(13)")
	_assert_solved(true, "D")


func test_PUZ_031_X_faltou_uma_runa() -> void:
	await driver.cast("inscrever(ler_runa(1) + ler_runa(2))")
	_assert_solved(false, "X")


func test_PUZ_031_Y_longe_do_cadeado() -> void:
	await driver.place(driver.room().data.entries["A"])
	await driver.cast("a = ler_runa(1)\nb = ler_runa(2)\nc = ler_runa(3)\ninscrever(a + b + c)")
	_assert_solved(false, "Y")


func test_PUZ_032_decorar_o_numero_nao_serve() -> void:
	driver.world.go_to("sala_p03", "A")
	await driver.frames(3)
	driver.world.go_to("sala_p02", "B")
	await driver.frames(3)
	var runes := driver.room().spell_room()["runas"] as Array
	var total: int = runes[0] + runes[1] + runes[2]
	if total == 13:
		driver.set_runes([1, 1, 1])
	await driver.place(driver.cell_of("7") - Vector2i(2, 0))
	await driver.cast("inscrever(13)")
	_assert_solved(false, "decorada")
	await driver.cast("a = ler_runa(1)\nb = ler_runa(2)\nc = ler_runa(3)\ninscrever(a + b + c)")
	_assert_solved(true, "A depois de decorar")
