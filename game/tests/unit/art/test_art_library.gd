extends GdUnitTestSuite
## Spec: docs/specs/arte/ART-esteira.md (ART-005): a biblioteca monta as animações a partir dos arquivos.


func before_test() -> void:
	ArtFixtures.clear()
	ArtLibrary.use_root(ArtFixtures.ROOT)


func after_test() -> void:
	ArtLibrary.reset()
	ArtFixtures.clear()


func test_ART_005_monta_as_animacoes_com_reserva() -> void:
	ArtFixtures.write("mago", "parado", ArtFixtures.strip(Vector2i(48, 48), 4))
	ArtFixtures.write("mago", "pular", ArtFixtures.strip(Vector2i(48, 48), 2))
	var frames := ArtLibrary.sprite_frames("mago", ["parado", "pular", "cair", "andar"])
	assert_object(frames).is_not_null()
	assert_bool(frames.has_animation(&"default")).is_false()
	assert_int(frames.get_frame_count(&"parado")).is_equal(4)
	assert_float(frames.get_animation_speed(&"parado")).is_equal(6.0)
	assert_bool(frames.get_animation_loop(&"parado")).is_true()
	assert_int(frames.get_frame_count(&"pular")).is_equal(2)
	assert_bool(frames.get_animation_loop(&"pular")).is_false()
	assert_int(frames.get_frame_count(&"cair")).is_equal(2)
	assert_int(frames.get_frame_count(&"andar")).is_equal(4)
	var first: AtlasTexture = frames.get_frame_texture(&"parado", 1)
	assert_that(first.region).is_equal(Rect2(48, 0, 48, 48))


func test_ART_005_sem_arquivos_usa_o_provisorio() -> void:
	assert_object(ArtLibrary.sprite_frames("mago", ["parado", "andar"])).is_null()
	assert_object(ArtLibrary.texture("cenario", "tiles")).is_null()


func test_ART_005_imagem_parada() -> void:
	ArtFixtures.write("cenario", "fundo_2", ArtFixtures.strip(Vector2i(640, 360), 1))
	var texture := ArtLibrary.texture("cenario", "fundo_2")
	assert_object(texture).is_not_null()
	assert_int(texture.get_width()).is_equal(640)
	assert_str(ArtLibrary.path_of("cenario", "fundo_2")).is_equal(ArtFixtures.ROOT + "cenario/fundo_2.png")
