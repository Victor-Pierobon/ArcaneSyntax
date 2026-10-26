extends GdUnitTestSuite
## Spec: docs/specs/combate/COM-guardiao.md (regras 2 a 4, COM-060 a COM-062)


func _at(seconds: float) -> GuardianShield:
	var shield := GuardianShield.new()
	shield.tick(seconds)
	return shield


func test_COM_060_ciclo_do_escudo() -> void:
	var expected := {0.0: "fogo", 3.9: "fogo", 4.5: "", 5.1: "planta", 8.9: "planta", 9.5: "",
			10.2: "gelo", 13.9: "gelo", 14.5: "", 15.1: "fogo"}
	for seconds: float in expected:
		assert_str(_at(seconds).current()).override_failure_message("t = %s" % seconds).is_equal(expected[seconds])


func test_COM_060_pisca_antes_de_trocar() -> void:
	assert_bool(_at(2.9).is_blinking()).is_false()
	assert_bool(_at(3.5).is_blinking()).is_true()
	assert_bool(_at(4.5).is_blinking()).is_false()
	assert_bool(_at(8.5).is_blinking()).is_true()


func test_COM_060_tick_acumula() -> void:
	var shield := GuardianShield.new()
	for i in 306:
		shield.tick(1.0 / 60.0)
	assert_str(shield.current()).is_equal("planta")


func test_COM_061_so_a_fraqueza_passa() -> void:
	var fire := _at(1.0)
	assert_dict(fire.resolve("gelo", "projetil")).is_equal({"blocked": false, "damage": 6, "effect": ElementTable.Effect.WEAK})
	for attack: Array in [["fogo", "projetil"], ["raio", "projetil"], ["fogo", "faisca"], ["cajado", ""]]:
		var result := fire.resolve(attack[0], attack[1])
		assert_bool(result["blocked"]).override_failure_message(str(attack)).is_true()
		assert_int(result["damage"]).is_equal(0)
	assert_int(_at(6.0).resolve("fogo", "projetil")["damage"]).is_equal(6)
	assert_bool(_at(6.0).resolve("gelo", "projetil")["blocked"]).is_true()
	assert_int(_at(11.0).resolve("raio", "faisca")["damage"]).is_equal(2)
	assert_bool(_at(11.0).resolve("fogo", "projetil")["blocked"]).is_true()


func test_COM_062_a_brecha() -> void:
	var gap := _at(4.5)
	assert_dict(gap.resolve("cajado", "")).is_equal({"blocked": false, "damage": 1, "effect": ElementTable.Effect.NORMAL})
	assert_int(gap.resolve("fogo", "projetil")["damage"]).is_equal(3)
	assert_int(gap.resolve("raio", "faisca")["damage"]).is_equal(1)
