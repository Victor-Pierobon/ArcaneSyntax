extends GdUnitTestSuite
## Spec: docs/specs/mundo/MUN-movimento.md

const DT := 1.0 / 60.0

var motor: PlayerMotor


func before_test() -> void:
	motor = PlayerMotor.new()


func test_MUN_001_andar_para_os_dois_lados() -> void:
	var right := motor.step(Vector2.ZERO, PlayerIntent.make(1.0), true, DT)
	var left := motor.step(Vector2.ZERO, PlayerIntent.make(-1.0), true, DT)
	assert_float(right.x).is_equal(120.0)
	assert_float(left.x).is_equal(-120.0)


func test_MUN_002_parar_ao_soltar() -> void:
	var v := motor.step(Vector2(120.0, 0.0), PlayerIntent.make(0.0), true, DT)
	assert_float(v.x).is_equal(0.0)


func test_MUN_003_gravidade_no_ar() -> void:
	var v := motor.step(Vector2(0.0, 10.0), PlayerIntent.make(), false, DT)
	assert_float(v.y).is_equal_approx(10.0 + 980.0 * DT, 0.001)


func test_MUN_003_gravidade_respeita_queda_maxima() -> void:
	var v := motor.step(Vector2(0.0, 399.0), PlayerIntent.make(), false, DT)
	assert_float(v.y).is_equal(400.0)


func test_MUN_004_pular_do_chao() -> void:
	var expected := -sqrt(2.0 * 980.0 * 48.0)
	var v := motor.step(Vector2.ZERO, PlayerIntent.make(0.0, true, true), true, DT)
	assert_float(motor.jump_velocity()).is_equal_approx(-expected, 0.001)
	assert_float(v.y).is_equal_approx(expected, 0.001)


func test_MUN_005_sem_pulo_no_ar() -> void:
	var v := motor.step(Vector2(0.0, 50.0), PlayerIntent.make(0.0, true, true), false, DT)
	assert_float(v.y).is_greater(0.0)


func test_MUN_006_soltar_pulo_corta_subida() -> void:
	var v := motor.step(Vector2.ZERO, PlayerIntent.make(0.0, true, true), true, DT)
	v = motor.step(v, PlayerIntent.make(0.0, false, false), false, DT)
	var expected := (-motor.jump_velocity() + 980.0 * DT) * 0.5
	assert_float(v.y).is_equal_approx(expected, 0.001)


func test_MUN_006_corte_acontece_uma_vez_por_pulo() -> void:
	var v := motor.step(Vector2.ZERO, PlayerIntent.make(0.0, true, true), true, DT)
	v = motor.step(v, PlayerIntent.make(), false, DT)
	var after_cut := v.y
	v = motor.step(v, PlayerIntent.make(), false, DT)
	assert_float(v.y).is_equal_approx(after_cut + 980.0 * DT, 0.001)
