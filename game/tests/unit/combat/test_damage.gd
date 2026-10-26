extends GdUnitTestSuite
## Spec: docs/specs/combate/COM-dano.md (regra 1, COM-001)


func test_COM_001_tabela_de_dano() -> void:
	assert_int(Damage.amount("gelo", "projetil", "fogo")).is_equal(6)
	assert_int(Damage.amount("raio", "projetil", "fogo")).is_equal(3)
	assert_int(Damage.amount("fogo", "projetil", "fogo")).is_equal(1)
	assert_int(Damage.amount("raio", "faisca", "gelo")).is_equal(2)
	assert_int(Damage.amount("gelo", "faisca", "gelo")).is_equal(0)
	assert_int(Damage.amount("fogo", "faisca", "gelo")).is_equal(1)


func test_COM_001_cajado_sempre_da_1() -> void:
	for element in ["fogo", "gelo", "raio", "planta", "pedra"]:
		assert_int(Damage.amount("cajado", "", element)).is_equal(1)


func test_COM_001_forma_desconhecida_conta_como_projetil() -> void:
	assert_int(Damage.amount("gelo", "", "fogo")).is_equal(6)
