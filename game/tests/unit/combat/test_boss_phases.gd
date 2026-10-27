extends GdUnitTestSuite
## Spec: docs/specs/combate/COM-chefe.md (regras 2 a 4, COM-080 a COM-082)

const STEP := 1.0 / 60.0


## Leva as fases até `target`, já fora da transição.
func _phase(target: int) -> BossPhases:
	var phases := BossPhases.new()
	for health: int in [60, 30].slice(0, target - 1):
		phases.after_damage(health)
		phases.tick(1.5 + STEP)
	return phases


func test_COM_080_fase_1_e_fogo() -> void:
	var phases := BossPhases.new()
	assert_int(phases.phase).is_equal(1)
	assert_str(phases.element()).is_equal("fogo")
	assert_int(phases.resolve("gelo", "projetil", 90)["damage"]).is_equal(6)
	assert_int(phases.resolve("raio", "projetil", 90)["damage"]).is_equal(3)
	assert_int(phases.resolve("fogo", "projetil", 90)["damage"]).is_equal(1)


func test_COM_080_com_60_troca_para_gelo() -> void:
	var phases := BossPhases.new()
	assert_bool(phases.after_damage(61)).is_false()
	assert_int(phases.phase).is_equal(1)
	assert_bool(phases.after_damage(60)).is_true()
	assert_int(phases.phase).is_equal(2)
	assert_str(phases.element()).is_equal("gelo")
	var two := _phase(2)
	assert_dict(two.resolve("raio", "projetil", 60)).is_equal({"blocked": false, "damage": 6, "effect": ElementTable.Effect.WEAK})
	assert_int(two.resolve("gelo", "projetil", 60)["damage"]).is_equal(1)


func test_COM_080_com_30_troca_para_planta() -> void:
	var phases := _phase(2)
	assert_bool(phases.after_damage(31)).is_false()
	assert_bool(phases.after_damage(30)).is_true()
	assert_int(phases.phase).is_equal(3)
	assert_str(phases.element()).is_equal("planta")
	var three := _phase(3)
	assert_int(three.resolve("fogo", "projetil", 30)["damage"]).is_equal(6)
	assert_int(three.resolve("gelo", "projetil", 30)["damage"]).is_equal(3)
	# Não há fase 4.
	assert_bool(three.after_damage(3)).is_false()
	assert_int(three.phase).is_equal(3)


func test_COM_080_um_golpe_grande_nao_pula_duas_fases() -> void:
	var phases := BossPhases.new()
	# Mesmo com a vida bem abaixo dos dois limites, só passa uma fase por vez.
	assert_bool(phases.after_damage(10)).is_true()
	assert_int(phases.phase).is_equal(2)


func test_COM_081_a_troca_para_60_nao_e_pulada() -> void:
	var phases := BossPhases.new()
	assert_int(phases.resolve("gelo", "projetil", 63)["damage"]).is_equal(3)
	assert_int(phases.resolve("gelo", "projetil", 90)["damage"]).is_equal(6)
	assert_int(phases.resolve("gelo", "projetil", 60)["damage"]).is_equal(0)


func test_COM_081_a_troca_para_30_nao_e_pulada() -> void:
	var phases := _phase(2)
	assert_int(phases.resolve("raio", "projetil", 33)["damage"]).is_equal(3)
	assert_int(phases.resolve("raio", "projetil", 60)["damage"]).is_equal(6)


func test_COM_081_fase_3_nao_tem_limite() -> void:
	assert_int(_phase(3).resolve("fogo", "projetil", 3)["damage"]).is_equal(6)


func test_COM_082_transicao_invulneravel() -> void:
	var phases := BossPhases.new()
	phases.after_damage(60)
	assert_bool(phases.in_transition()).is_true()
	for attack: Array in [["raio", "projetil"], ["gelo", "faisca"], ["cajado", ""]]:
		var result := phases.resolve(attack[0], attack[1], 60)
		assert_bool(result["blocked"]).override_failure_message(str(attack)).is_true()
		assert_int(result["damage"]).is_equal(0)
	assert_bool(phases.tick(1.4)).is_false()
	assert_bool(phases.in_transition()).is_true()
	# O passo que termina a transição avisa.
	assert_bool(phases.tick(0.2)).is_true()
	assert_bool(phases.in_transition()).is_false()
	assert_bool(phases.tick(0.2)).is_false()
	assert_int(phases.resolve("raio", "projetil", 60)["damage"]).is_equal(6)


func test_COM_082_nao_troca_de_novo_durante_a_transicao() -> void:
	var phases := BossPhases.new()
	phases.after_damage(60)
	assert_bool(phases.after_damage(30)).is_false()
	assert_int(phases.phase).is_equal(2)
