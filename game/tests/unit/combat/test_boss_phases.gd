extends GdUnitTestSuite
## Spec: docs/specs/combate/COM-chefe.md (regras 2 a 4 e 6, COM-080 a COM-083)

const STEP := 1.0 / 60.0


## Leva as fases até a fase 2, já fora da transição.
func _phase_two() -> BossPhases:
	var phases := BossPhases.new()
	phases.after_damage(15)
	phases.tick(1.5 + STEP, false)
	return phases


## Momentos (em décimos de s, a partir de agora) em que sai um orbe, andando de quadro em quadro.
func _shots(phases: BossPhases, seconds: float, near := true) -> Array[int]:
	var times: Array[int] = []
	var elapsed := 0.0
	for i in roundi(seconds / STEP):
		elapsed += STEP
		if phases.tick(STEP, near):
			times.append(roundi(elapsed * 10))
	return times


func test_COM_080_fase_1_e_fogo() -> void:
	var phases := BossPhases.new()
	assert_int(phases.phase).is_equal(1)
	assert_str(phases.element()).is_equal("fogo")
	assert_int(phases.resolve("gelo", "projetil", 30)["damage"]).is_equal(6)
	assert_int(phases.resolve("raio", "projetil", 30)["damage"]).is_equal(3)
	assert_int(phases.resolve("fogo", "projetil", 30)["damage"]).is_equal(1)


func test_COM_080_metade_da_vida_troca_para_gelo() -> void:
	var phases := BossPhases.new()
	assert_bool(phases.after_damage(16)).is_false()
	assert_int(phases.phase).is_equal(1)
	assert_bool(phases.after_damage(15)).is_true()
	assert_int(phases.phase).is_equal(2)
	assert_str(phases.element()).is_equal("gelo")
	assert_bool(phases.after_damage(9)).is_false()
	var two := _phase_two()
	assert_dict(two.resolve("raio", "projetil", 15)).is_equal({"blocked": false, "damage": 6, "effect": ElementTable.Effect.WEAK})
	assert_int(two.resolve("gelo", "projetil", 15)["damage"]).is_equal(1)


func test_COM_081_a_troca_nao_e_pulada() -> void:
	var phases := BossPhases.new()
	assert_int(phases.resolve("gelo", "projetil", 18)["damage"]).is_equal(3)
	assert_int(phases.resolve("gelo", "projetil", 30)["damage"]).is_equal(6)
	assert_int(phases.resolve("gelo", "projetil", 15)["damage"]).is_equal(0)


func test_COM_081_fase_2_nao_tem_limite() -> void:
	assert_int(_phase_two().resolve("raio", "projetil", 3)["damage"]).is_equal(6)


func test_COM_082_transicao_invulneravel() -> void:
	var phases := BossPhases.new()
	phases.after_damage(15)
	assert_bool(phases.in_transition()).is_true()
	for attack: Array in [["raio", "projetil"], ["gelo", "faisca"], ["cajado", ""]]:
		var result := phases.resolve(attack[0], attack[1], 15)
		assert_bool(result["blocked"]).override_failure_message(str(attack)).is_true()
		assert_int(result["damage"]).is_equal(0)
	phases.tick(1.4, false)
	assert_bool(phases.in_transition()).is_true()
	phases.tick(0.2, false)
	assert_bool(phases.in_transition()).is_false()
	assert_int(phases.resolve("raio", "projetil", 15)["damage"]).is_equal(6)


func test_COM_083_orbe_a_cada_3_s_na_fase_1() -> void:
	assert_array(_shots(BossPhases.new(), 6.5)).is_equal([30, 60])


func test_COM_083_longe_nao_ataca() -> void:
	var phases := BossPhases.new()
	assert_array(_shots(phases, 5.0, false)).is_empty()
	# O primeiro sai um intervalo depois de o mago chegar perto.
	assert_array(_shots(phases, 3.5)).is_equal([30])


func test_COM_083_transicao_nao_ataca_e_fase_2_e_mais_rapida() -> void:
	var phases := BossPhases.new()
	_shots(phases, 2.5)
	phases.after_damage(15)
	assert_array(_shots(phases, 1.4)).is_empty()
	# Falta 0,1 s de transição; depois, um orbe a cada 2 s.
	assert_array(_shots(phases, 4.2)).is_equal([21, 41])
