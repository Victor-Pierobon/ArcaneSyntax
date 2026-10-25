extends GdUnitTestSuite
## Spec: docs/specs/puzzles/PUZ-validacao.md (regra 8, PUZ-008)


func _rule(symbol: String, charges := 3) -> MutableCrystalRule:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var rule := MutableCrystalRule.new(charges, rng)
	rule.symbol = symbol
	return rule


## Um elemento de feitiço que não vence o símbolo.
func _wrong(symbol: String) -> String:
	return "raio" if MutableCrystalRule.answer(symbol) != "raio" else "fogo"


func test_PUZ_008_acerto_certo_ganha_carga_e_muda_o_simbolo() -> void:
	var rule := _rule("planta")
	rule.hit("fogo")
	assert_int(rule.charges).is_equal(1)
	assert_str(rule.symbol).is_not_equal("planta")
	assert_array(MutableCrystalRule.SYMBOLS).contains([rule.symbol])


func test_PUZ_008_acerto_errado_zera() -> void:
	var rule := _rule("planta")
	rule.hit("fogo")
	rule.hit(MutableCrystalRule.answer(rule.symbol))
	assert_int(rule.charges).is_equal(2)
	var before := rule.symbol
	rule.hit(_wrong(before))
	assert_int(rule.charges).is_equal(0)
	assert_str(rule.symbol).is_not_equal(before)


func test_PUZ_008_tres_acertos_seguidos_acendem() -> void:
	var rule := _rule("gelo")
	for i in 3:
		assert_bool(rule.lit).is_false()
		rule.hit(MutableCrystalRule.answer(rule.symbol))
	assert_bool(rule.lit).is_true()


func test_PUZ_008_simbolo_nunca_repete() -> void:
	var rule := _rule("fogo", 100)
	for i in 50:
		var before := rule.symbol
		rule.hit(MutableCrystalRule.answer(before) if i % 2 == 0 else _wrong(before))
		assert_str(rule.symbol).is_not_equal(before)


func test_PUZ_008_cajado_nao_muda_nada() -> void:
	var rule := _rule("planta")
	rule.hit("fogo")
	rule.hit("cajado")
	assert_int(rule.charges).is_equal(1)


func test_PUZ_008_resposta_e_o_elemento_que_vence() -> void:
	assert_str(MutableCrystalRule.answer("planta")).is_equal("fogo")
	assert_str(MutableCrystalRule.answer("fogo")).is_equal("gelo")
	assert_str(MutableCrystalRule.answer("gelo")).is_equal("raio")
