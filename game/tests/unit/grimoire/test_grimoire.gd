extends GdUnitTestSuite
## Spec: docs/specs/grimorio/GRI-feiticos.md (GRI-010 a 017)

const P := Grimoire.Problem

var grimoire: Grimoire


func before_test() -> void:
	grimoire = Grimoire.new()


func test_GRI_010_criar_mantem_a_ordem() -> void:
	assert_int(grimoire.create("Bola de fogo")).is_equal(P.OK)
	assert_int(grimoire.create("Escudo", "lancar(gelo, escudo)")).is_equal(P.OK)
	assert_array(Array(grimoire.names())).is_equal(["Bola de fogo", "Escudo"])
	assert_str(grimoire.code_of("Bola de fogo")).is_empty()
	assert_str(grimoire.code_of("Escudo")).is_equal("lancar(gelo, escudo)")


func test_GRI_010_sinal_de_criacao() -> void:
	var seen := []
	grimoire.spell_created.connect(func(spell_name: String) -> void: seen.append(spell_name))
	grimoire.create("  Raio ")
	assert_array(seen).is_equal(["Raio"])


func test_GRI_011_nome_vazio_e_espacos() -> void:
	assert_int(grimoire.create("")).is_equal(P.EMPTY_NAME)
	assert_int(grimoire.create("   ")).is_equal(P.EMPTY_NAME)
	assert_int(grimoire.create("  Raio  ")).is_equal(P.OK)
	assert_array(Array(grimoire.names())).is_equal(["Raio"])


func test_GRI_012_nome_repetido_sem_diferenciar_maiusculas() -> void:
	grimoire.create("Fogo")
	assert_int(grimoire.create("fogo")).is_equal(P.DUPLICATE_NAME)
	assert_int(grimoire.create("FOGO ")).is_equal(P.DUPLICATE_NAME)
	assert_int(grimoire.names().size()).is_equal(1)


func test_GRI_013_nome_longo() -> void:
	assert_int(grimoire.create("a".repeat(25))).is_equal(P.NAME_TOO_LONG)
	assert_int(grimoire.create("a".repeat(24))).is_equal(P.OK)


func test_GRI_014_renomear() -> void:
	grimoire.create("Fogo", "lancar(fogo, projetil)")
	grimoire.create("Gelo")
	var seen := []
	grimoire.spell_renamed.connect(func(old: String, new: String) -> void: seen.append([old, new]))
	assert_int(grimoire.rename("Fogo", "Chama")).is_equal(P.OK)
	assert_array(Array(grimoire.names())).is_equal(["Chama", "Gelo"])
	assert_str(grimoire.code_of("Chama")).is_equal("lancar(fogo, projetil)")
	assert_array(seen).is_equal([["Fogo", "Chama"]])


func test_GRI_014_renomear_valida_o_nome() -> void:
	grimoire.create("Fogo")
	grimoire.create("Gelo")
	assert_int(grimoire.rename("Fogo", "gelo")).is_equal(P.DUPLICATE_NAME)
	assert_int(grimoire.rename("Fogo", " ")).is_equal(P.EMPTY_NAME)
	assert_int(grimoire.rename("Gelo", "GELO")).is_equal(P.OK)
	assert_array(Array(grimoire.names())).is_equal(["Fogo", "GELO"])
	assert_int(grimoire.rename("Nada", "Algo")).is_equal(P.NOT_FOUND)


func test_GRI_015_apagar() -> void:
	grimoire.create("Fogo")
	var seen := []
	grimoire.spell_deleted.connect(func(spell_name: String) -> void: seen.append(spell_name))
	assert_int(grimoire.delete("Fogo")).is_equal(P.OK)
	assert_array(Array(grimoire.names())).is_empty()
	assert_array(seen).is_equal(["Fogo"])
	assert_int(grimoire.delete("Fogo")).is_equal(P.NOT_FOUND)


func test_GRI_016_editar_codigo() -> void:
	grimoire.create("Fogo")
	var seen := []
	grimoire.spell_code_changed.connect(func(spell_name: String) -> void: seen.append(spell_name))
	assert_int(grimoire.set_code("Fogo", "meditar()")).is_equal(P.OK)
	grimoire.set_code("Fogo", "meditar()")
	assert_str(grimoire.code_of("Fogo")).is_equal("meditar()")
	assert_array(seen).is_equal(["Fogo"])
	assert_int(grimoire.set_code("Nada", "x")).is_equal(P.NOT_FOUND)


func test_GRI_017_nome_padrao_usa_o_menor_numero_livre() -> void:
	assert_str(grimoire.next_default_name("Feitiço")).is_equal("Feitiço 1")
	grimoire.create("Feitiço 1")
	grimoire.create("Feitiço 3")
	assert_str(grimoire.next_default_name("Feitiço")).is_equal("Feitiço 2")
