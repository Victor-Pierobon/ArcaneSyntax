extends GdUnitTestSuite
## Spec: docs/specs/mundo/MUN-vida.md (MUN-024)


func test_MUN_024_estado_inicial() -> void:
	var state := MagoState.new()
	assert_int(state.health.current).is_equal(5)
	assert_int(state.health.maximum).is_equal(5)
	assert_float(state.mana).is_equal(0.0)
	assert_float(state.mana_max).is_equal(10.0)


func test_MUN_024_mana_com_limites_e_resolucao() -> void:
	var state := MagoState.new()
	state.set_mana(10.06)
	assert_float(state.mana).is_equal(10.0)
	state.set_mana(-1)
	assert_float(state.mana).is_equal(0.0)
	state.set_mana(4.94)
	assert_float(state.mana).is_equal_approx(4.9, 0.0001)


func test_MUN_024_vira_o_mago_do_protocolo() -> void:
	var state := MagoState.new()
	assert_dict(state.to_spell_mago()).is_equal({"vida": 5, "mana": 0.0, "mana_max": 10.0})


func test_sinal_de_mana() -> void:
	var state := MagoState.new()
	var seen := []
	state.mana_changed.connect(func(mana: float, mana_max: float) -> void: seen.append([mana, mana_max]))
	state.set_mana(3.0)
	assert_array(seen).is_equal([[3.0, 10.0]])
