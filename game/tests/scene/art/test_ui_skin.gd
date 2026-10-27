extends GdUnitTestSuite
## Spec: docs/specs/arte/ART-brilho.md (regras 10 e 11, ART-067).


func before_test() -> void:
	ArtFixtures.clear()
	ArtLibrary.use_root(ArtFixtures.ROOT)


func after_test() -> void:
	ArtLibrary.reset()
	ArtFixtures.clear()


func _with_frame_and_logo() -> void:
	ArtFixtures.write("ui", "moldura", ArtFixtures.strip(Vector2i(48, 48), 1, Color("3a2f55")))
	ArtFixtures.write("ui", "logo", ArtFixtures.strip(Vector2i(160, 60), 1, Color("d8b04a")))
	ArtLibrary.use_root(ArtFixtures.ROOT)


func test_ART_067_com_a_moldura_os_paineis_usam_a_moldura() -> void:
	_with_frame_and_logo()
	var menu: TitleMenu = auto_free(TitleMenu.new())
	add_child(menu)
	var style := menu.panel_style()
	assert_object(style).is_instanceof(StyleBoxTexture)
	assert_float((style as StyleBoxTexture).texture_margin_left).is_equal(UiSkin.FRAME_MARGIN)
	var dialogue: DialogueBox = auto_free(DialogueBox.new())
	add_child(dialogue)
	assert_object(dialogue.panel_style()).is_instanceof(StyleBoxTexture)
	var grimoire: GrimoireUI = auto_free(GrimoireUI.new())
	add_child(grimoire)
	assert_object(grimoire.panel_style()).is_instanceof(StyleBoxTexture)


func test_ART_067_com_o_logo_o_menu_mostra_o_logo() -> void:
	_with_frame_and_logo()
	var menu: TitleMenu = auto_free(TitleMenu.new())
	add_child(menu)
	assert_object(menu.logo).is_not_null()
	assert_bool(menu.logo.visible).is_true()
	assert_bool(menu.title_label.visible).is_false()


func test_ART_067_sem_arte_fica_o_de_hoje() -> void:
	var menu: TitleMenu = auto_free(TitleMenu.new())
	add_child(menu)
	assert_object(menu.panel_style()).is_instanceof(StyleBoxFlat)
	assert_object(menu.logo).is_null()
	assert_bool(menu.title_label.visible).is_true()
	var dialogue: DialogueBox = auto_free(DialogueBox.new())
	add_child(dialogue)
	assert_object(dialogue.panel_style()).is_instanceof(StyleBoxFlat)
