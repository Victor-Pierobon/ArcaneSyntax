extends GdUnitTestSuite
## Aceitação: docs/specs/combate/COM-enxame.md (COM-044) e EXE-custo (EXE-096).
## Sala sala_c02 DO JOGO e Python de verdade. Enxame de 6 bichos de gelo no ar; o mago conjura de longe,
## fora do alcance do mergulho e dentro do alcance dos sentidos.

const GRIMOIRE_PATH := "user://tests/grimorio_com02.json"
const SPOT := Vector2i(11, 7)

const LOOP_FAISCA := """for inimigo in inimigos:
    lancar(raio, faisca, inimigo)"""
const LOOP_PROJETIL := """for inimigo in inimigos:
    lancar(raio, projetil, inimigo)"""
const LINHAS_SOLTAS := """lancar(raio, faisca, inimigos[0])
lancar(raio, faisca, inimigos[1])
lancar(raio, faisca, inimigos[2])
lancar(raio, faisca, inimigos[3])
lancar(raio, faisca, inimigos[4])
lancar(raio, faisca, inimigos[5])"""

var driver: PuzzleDriver


func before_test() -> void:
	driver = auto_free(PuzzleDriver.new())
	add_child(driver)
	await driver.start("sala_c02", GRIMOIRE_PATH)
	await driver.place(SPOT)


func after_test() -> void:
	driver.cleanup()


func test_COM_044_todos_os_bichos_estao_nos_sentidos() -> void:
	assert_array(driver.world.current_enemies()).has_size(6)


func test_COM_044_loop_de_faiscas_vence_o_enxame_numa_conjuracao() -> void:
	var result := await driver.cast(LOOP_FAISCA, true, 60)
	assert_bool(result.ok).override_failure_message(str(result.error)).is_true()
	assert_float(result.cost).is_equal(6.7)
	assert_array(driver.room().enemies()).is_empty()
	assert_int(driver.world.state.health.current).is_equal(5)


func test_COM_044_loop_de_projeteis_esgota_a_mana() -> void:
	var result := await driver.cast(LOOP_PROJETIL, true, 60)
	assert_str(result.error.type).is_equal("ManaEsgotada")
	assert_int(result.actions.size()).is_equal(3)
	# As ações anteriores ao erro acontecem (MAG-acoes, regra 5).
	assert_array(driver.room().enemies()).has_size(3)


func test_COM_044_linhas_soltas_funcionam_mas_custam_mais() -> void:
	var result := await driver.cast(LINHAS_SOLTAS, true, 60)
	assert_bool(result.ok).override_failure_message(str(result.error)).is_true()
	assert_float(result.cost).is_equal(7.2)
	assert_array(driver.room().enemies()).is_empty()
