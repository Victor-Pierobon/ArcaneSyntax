extends GdUnitTestSuite
## Spec: docs/specs/arte/ART-esteira.md (ART-001 a ART-003): o contrato dos arquivos de arte.

const FOLDERS := ["mago", "serpente", "elemental", "enxame", "guardiao", "chefe", "magia", "objetos", "cenario", "ui"]
const MAGO := ["parado", "andar", "pular", "cair", "esquivar", "conjurar", "meditar", "cajado", "dano", "morrer"]

var catalog: ArtCatalog


func before_test() -> void:
	catalog = ArtCatalog.load_file(ArtCatalog.DEFAULT_PATH)


func test_ART_001_contrato_carrega() -> void:
	assert_array(catalog.errors).is_empty()
	assert_array(Array(catalog.folders())).contains_exactly_in_any_order(FOLDERS)
	for anim in MAGO:
		assert_bool(catalog.has_file("mago", anim)).override_failure_message("mago/" + anim).is_true()
	for element in ["fogo", "gelo", "planta"]:
		assert_bool(catalog.has_file("elemental", "andar_" + element)).is_true()
		assert_bool(catalog.has_file("elemental", "morrer_" + element)).is_true()
	assert_bool(catalog.has_file("elemental", "andar")).is_false()
	for n in [1, 2, 3]:
		assert_bool(catalog.has_file("cenario", "fundo_%d" % n)).is_true()
	assert_that(catalog.spec("cenario", "tiles")["tamanho"]).is_equal(Vector2i(64, 80))
	assert_that(catalog.spec("mago", "andar")["quadro"]).is_equal(Vector2i(48, 48))
	assert_str(catalog.spec("mago", "cair")["reserva"]).is_equal("pular")


## Regressão (2026-10-27, primeira leva de arte): o contrato pedia o escudo do guardião em fogo, gelo e
## raio, mas o escudo do jogo troca entre fogo, planta e gelo; o gerador fez um escudo de raio que
## nunca aparece. As variantes do contrato são as do jogo.
func test_ART_001_variantes_iguais_as_do_jogo() -> void:
	for element: String in GuardianShield.CYCLE:
		assert_bool(catalog.has_file("guardiao", "escudo_" + element)).override_failure_message(element).is_true()
	assert_bool(catalog.has_file("guardiao", "escudo_raio")).is_false()
	for element: String in Elemental.ELEMENTS:
		assert_bool(catalog.has_file("elemental", "andar_" + element)).is_true()
	for element: String in ElementTable.SPELL_ELEMENTS:
		for form in ["projetil", "faisca", "impacto", "escudo"]:
			assert_bool(catalog.has_file("magia", "%s_%s" % [form, element])).is_true()


func test_ART_001_contrato_com_erro_e_acusado() -> void:
	var broken := ArtCatalog.from_data({
		"mago": {"quadro": 48, "animacoes": {
			"parado": {"fps": 0, "laco": true},
			"cair": {"fps": 8, "laco": true, "reserva": "voar"},
		}},
		"nada": {"animacoes": {"x": {"fps": 6, "laco": true}}},
	})
	assert_int(broken.errors.size()).is_equal(3)
	assert_bool(ArtCatalog.from_data("lixo").errors.is_empty()).is_false()


func test_ART_002_arquivo_dentro_do_contrato_passa() -> void:
	var image := ArtFixtures.strip(Vector2i(48, 48), 6)
	assert_array(catalog.check("mago", "andar", image)).is_empty()
	assert_int(catalog.frame_count("mago", "andar", image.get_width())).is_equal(6)
	assert_array(catalog.check("elemental", "andar_gelo", ArtFixtures.strip(Vector2i(32, 32), 4))).is_empty()
	var pillar := ArtFixtures.strip(Vector2i(16, 64), 4)
	assert_array(catalog.check("chefe", "pilar", pillar)).is_empty()
	assert_int(catalog.frame_count("chefe", "pilar", pillar.get_width())).is_equal(4)
	assert_array(catalog.check("cenario", "tiles", ArtFixtures.strip(Vector2i(64, 80), 1))).is_empty()


func test_ART_003_tamanho_errado() -> void:
	var tall := catalog.check("mago", "andar", ArtFixtures.strip(Vector2i(48, 50), 2))
	assert_int(tall.size()).is_equal(1)
	assert_str(tall[0]).contains("mago/andar.png").contains("altura 50").contains("48")
	var odd := catalog.check("mago", "andar", Image.create_empty(100, 48, false, Image.FORMAT_RGBA8))
	assert_str(odd[0]).contains("largura 100")
	var tiles := catalog.check("cenario", "tiles", ArtFixtures.strip(Vector2i(64, 64), 1))
	assert_str(tiles[0]).contains("64×64").contains("64×80")


func test_ART_003_nome_ou_pasta_desconhecidos() -> void:
	var image := ArtFixtures.strip(Vector2i(48, 48), 1)
	assert_str(catalog.check("mago", "voar", image)[0]).contains("mago/voar.png").contains("nome")
	assert_str(catalog.check("dragao", "parado", image)[0]).contains("pasta")


func test_ART_003_pixel_semitransparente() -> void:
	var image := ArtFixtures.strip(Vector2i(48, 48), 2)
	image.set_pixel(10, 20, Color(1, 0, 0, 0.5))
	var problems := catalog.check("mago", "parado", image)
	assert_int(problems.size()).is_equal(1)
	assert_str(problems[0]).contains("semitransparente").contains("(10, 20)")


func test_ART_003_cor_fora_da_paleta() -> void:
	var palette_image := Image.create_empty(2, 1, false, Image.FORMAT_RGBA8)
	palette_image.set_pixel(0, 0, Color("ff7a3d"))
	palette_image.set_pixel(1, 0, Color("6fd3ff"))
	var palette := ArtCatalog.palette_of(palette_image)
	assert_int(palette.size()).is_equal(2)
	var image := ArtFixtures.strip(Vector2i(48, 48), 2, Color("ff7a3d"))
	assert_array(catalog.check("mago", "parado", image, palette)).is_empty()
	image.set_pixel(5, 7, Color("123456"))
	var problems := catalog.check("mago", "parado", image, palette)
	assert_int(problems.size()).is_equal(1)
	assert_str(problems[0]).contains("#123456").contains("(5, 7)").contains("paleta")
	assert_array(catalog.check("mago", "parado", image)).is_empty()
