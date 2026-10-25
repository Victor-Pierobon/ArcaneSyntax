extends GdUnitTestSuite
## Spec: docs/specs/magia/MAG-elementos.md (MAG-030 a 032)

const E := ElementTable.Effect


func test_MAG_030_fraquezas() -> void:
	assert_int(ElementTable.effect("gelo", "fogo")).is_equal(E.WEAK)
	assert_int(ElementTable.effect("fogo", "planta")).is_equal(E.WEAK)
	assert_int(ElementTable.effect("raio", "gelo")).is_equal(E.WEAK)
	assert_float(ElementTable.multiplier(E.WEAK)).is_equal(2.0)


func test_MAG_031_resistencia() -> void:
	for element in ["fogo", "gelo", "raio"]:
		assert_int(ElementTable.effect(element, element)).override_failure_message(element).is_equal(E.RESIST)
	assert_float(ElementTable.multiplier(E.RESIST)).is_equal(0.5)


func test_MAG_032_neutro() -> void:
	assert_int(ElementTable.effect("fogo", "gelo")).is_equal(E.NORMAL)
	assert_int(ElementTable.effect("raio", "planta")).is_equal(E.NORMAL)
	for target in ["fogo", "gelo", "raio", "planta"]:
		assert_int(ElementTable.effect("cajado", target)).is_equal(E.NORMAL)
	assert_int(ElementTable.effect("fogo", "pedra")).is_equal(E.NORMAL)
	assert_float(ElementTable.multiplier(E.NORMAL)).is_equal(1.0)
