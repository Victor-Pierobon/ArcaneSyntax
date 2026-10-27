extends GdUnitTestSuite
## Spec: docs/specs/arte/ART-brilho.md (ART-062, ART-063)


# --- ART-062: estilo de partícula por elemento ---


func test_ART_062_fogo_sobe_gelo_cai_devagar() -> void:
	var fire := ParticleStyle.for_element("fogo")
	var ice := ParticleStyle.for_element("gelo")
	assert_float(fire.gravity.y).is_less(0.0)
	assert_float(ice.gravity.y).is_greater(0.0)
	assert_float(ice.gravity.y).is_less(ParticleStyle.for_element("").gravity.y)


func test_ART_062_raio_e_o_mais_rapido_e_curto() -> void:
	var lightning := ParticleStyle.for_element("raio")
	for other: String in ["fogo", "gelo", "planta", ""]:
		var style := ParticleStyle.for_element(other)
		assert_float(lightning.speed).override_failure_message(other).is_greater(style.speed)
		assert_float(lightning.lifetime).override_failure_message(other).is_less(style.lifetime)


func test_ART_062_planta_vai_para_o_lado() -> void:
	assert_float(absf(ParticleStyle.for_element("planta").gravity.x)).is_greater(0.0)
	for other: String in ["fogo", "gelo", "raio"]:
		assert_float(ParticleStyle.for_element(other).gravity.x).is_equal(0.0)


func test_ART_062_desconhecido_usa_o_neutro() -> void:
	var neutral := ParticleStyle.for_element("")
	var unknown := ParticleStyle.for_element("pedra")
	assert_vector(unknown.gravity).is_equal(neutral.gravity)
	assert_float(unknown.speed).is_equal(neutral.speed)
	assert_that(unknown.color).is_equal(neutral.color)


func test_ART_062_cada_elemento_tem_a_cor_dele() -> void:
	assert_that(ParticleStyle.for_element("fogo").color).is_equal(TrainingTarget.ELEMENT_COLORS["fogo"])
	assert_that(ParticleStyle.for_element("gelo").color).is_equal(TrainingTarget.ELEMENT_COLORS["gelo"])


# --- ART-063: tremida de câmera ---


func test_ART_063_sem_trauma_nao_treme() -> void:
	var shake := CameraShake.new()
	assert_vector(shake.offset()).is_equal(Vector2.ZERO)


func test_ART_063_trauma_vira_deslocamento() -> void:
	var shake := CameraShake.new()
	shake.add(0.5)
	assert_float(shake.trauma).is_equal(0.5)
	var biggest := 0.0
	for i in 60:
		shake.time = i * 0.05
		biggest = maxf(biggest, shake.offset().length())
	assert_float(biggest).is_greater(0.0)
	assert_float(biggest).is_less_equal(CameraShake.MAX_OFFSET * 0.25 * sqrt(2.0) + 0.001)


func test_ART_063_trauma_nao_passa_de_1_e_cai() -> void:
	var shake := CameraShake.new()
	shake.add(0.8)
	shake.add(0.8)
	assert_float(shake.trauma).is_equal(1.0)
	shake.tick(0.5)
	assert_float(shake.trauma).is_equal_approx(0.25, 0.001)
	shake.tick(1.0)
	assert_float(shake.trauma).is_equal(0.0)
	assert_vector(shake.offset()).is_equal(Vector2.ZERO)


func test_ART_063_mesmo_tempo_mesmo_deslocamento() -> void:
	var a := CameraShake.new()
	var b := CameraShake.new()
	a.add(1.0)
	b.add(1.0)
	a.time = 0.37
	b.time = 0.37
	assert_vector(a.offset()).is_equal(b.offset())
	b.time = 0.5
	assert_vector(a.offset()).is_not_equal(b.offset())
