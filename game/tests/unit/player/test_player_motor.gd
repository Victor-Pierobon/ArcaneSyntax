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


# --- Sprint 3: coyote time, jump buffer, esquiva ---

func _idle_frames(frames: int, on_floor: bool, v := Vector2.ZERO) -> Vector2:
	for i in frames:
		v = motor.step(v, PlayerIntent.make(), on_floor, DT)
	return v


func test_MUN_009_coyote_time_permite_pular_logo_apos_sair_do_chao() -> void:
	_idle_frames(1, true)
	_idle_frames(4, false)  # ~0,067 s no ar
	var v := motor.step(Vector2(0, 50), PlayerIntent.make(0.0, true, true), false, DT)
	assert_float(v.y).is_equal_approx(-motor.jump_velocity(), 0.001)


func test_MUN_009_coyote_time_expira() -> void:
	_idle_frames(1, true)
	_idle_frames(8, false)  # ~0,133 s no ar
	var v := motor.step(Vector2(0, 50), PlayerIntent.make(0.0, true, true), false, DT)
	assert_float(v.y).is_greater(0.0)


func test_MUN_009_coyote_nao_permite_pulo_duplo() -> void:
	var v := motor.step(Vector2.ZERO, PlayerIntent.make(0.0, true, true), true, DT)
	v = motor.step(v, PlayerIntent.make(0.0, true, true), false, DT)
	assert_float(v.y).is_equal_approx(-motor.jump_velocity() + 980.0 * DT, 0.001)


func test_MUN_010_jump_buffer_pula_ao_tocar_o_chao() -> void:
	motor.step(Vector2(0, 100), PlayerIntent.make(0.0, true, true), false, DT)
	_idle_frames(3, false)
	var v := motor.step(Vector2.ZERO, PlayerIntent.make(0.0, false, true), true, DT)
	assert_float(v.y).is_equal_approx(-motor.jump_velocity(), 0.001)


func test_MUN_010_jump_buffer_expira() -> void:
	motor.step(Vector2(0, 100), PlayerIntent.make(0.0, true, true), false, DT)
	_idle_frames(8, false)
	var v := motor.step(Vector2.ZERO, PlayerIntent.make(0.0, false, true), true, DT)
	assert_float(v.y).is_equal(0.0)


func _dodge(on_floor := true, v := Vector2.ZERO) -> Vector2:
	var intent := PlayerIntent.make()
	intent.dodge_pressed = true
	return motor.step(v, intent, on_floor, DT)


func test_MUN_011_esquiva_na_direcao_do_olhar_sem_gravidade() -> void:
	motor.step(Vector2.ZERO, PlayerIntent.make(-1.0), true, DT)
	var v := _dodge()
	assert_vector(v).is_equal(Vector2(-280.0, 0.0))
	v = _idle_frames(5, false, v)
	assert_vector(v).is_equal(Vector2(-280.0, 0.0))


func test_MUN_011_esquiva_termina_e_volta_ao_normal() -> void:
	_dodge()
	var v := _idle_frames(12, true)
	assert_float(v.x).is_equal(0.0)
	assert_bool(motor.is_dodging()).is_false()


func test_MUN_012_recarga_impede_esquiva_seguida() -> void:
	_dodge()
	_idle_frames(12, true)  # esquiva terminou há pouco
	assert_float(_dodge().x).is_equal(0.0)
	_idle_frames(25, true)  # passou a recarga
	assert_float(_dodge().x).is_equal(280.0)


func test_MUN_012_uma_esquiva_por_salto() -> void:
	_dodge(false)
	_idle_frames(40, false)
	assert_float(_dodge(false).x).is_equal(0.0)
	_idle_frames(1, true)
	assert_float(_dodge(false).x).is_equal(280.0)


func test_MUN_015_voo_controlado() -> void:
	var up := PlayerIntent.make()
	up.fly_y = -96.0
	assert_float(motor.step(Vector2(0, 50), up, false, DT).y).is_equal(-96.0)
	var hover := PlayerIntent.make()
	hover.fly_y = 0.0
	assert_float(motor.step(Vector2(0, -96), hover, false, DT).y).is_equal(0.0)
	var normal := motor.step(Vector2(0, 0), PlayerIntent.make(), false, DT)
	assert_float(normal.y).is_equal_approx(980.0 * DT, 0.001)


func test_MUN_013_invulneravel_so_durante_a_esquiva() -> void:
	assert_bool(motor.is_invulnerable()).is_false()
	_dodge()
	assert_bool(motor.is_invulnerable()).is_true()
	_idle_frames(12, true)
	assert_bool(motor.is_invulnerable()).is_false()
