extends GdUnitTestSuite
## Spec: docs/specs/grimorio/GRI-autocompletar.md (GRI-070 a 073)


func _displays(options: Array) -> Array:
	return options.map(func(o: Dictionary) -> String: return o["display"])


func _insert_of(options: Array, display: String) -> String:
	for o: Dictionary in options:
		if o["display"] == display:
			return o["insert"]
	return ""


func test_GRI_070_sugere_pelo_comeco() -> void:
	var options := CompletionProvider.suggest("la", MagoState.ALL_PIECES)
	assert_array(_displays(options)).contains(["lancar"])
	assert_str(_insert_of(options, "lancar")).is_equal("lancar(")
	var me := _displays(CompletionProvider.suggest("ME", MagoState.ALL_PIECES))
	assert_array(me).contains(["meditar"])
	assert_array(me).not_contains(["mover"])


func test_GRI_071_nao_sugere_bloqueadas() -> void:
	var unlocked := PackedStringArray(["lancar", "fogo", "projetil"])
	var options := _displays(CompletionProvider.suggest("ra", unlocked))
	assert_array(options).not_contains(["raio"])
	assert_array(options).contains(["range"])
	assert_array(_displays(CompletionProvider.suggest("ma", unlocked))).contains(["mana", "mana_max"])


func test_GRI_072_ordem_e_grupos() -> void:
	var options := CompletionProvider.suggest("p", MagoState.ALL_PIECES)
	var displays := _displays(options)
	assert_bool(displays.find("projetil") < displays.find("print")).is_true()
	assert_bool(displays.find("print") < displays.find("pass")).is_true()
	assert_str(_insert_of(options, "print")).is_equal("print(")
	assert_str(_insert_of(options, "pass")).is_equal("pass")
	assert_str(_insert_of(options, "projetil")).is_equal("projetil")


func test_GRI_073_prefixo_vazio_e_comentario() -> void:
	assert_array(CompletionProvider.suggest("", MagoState.ALL_PIECES)).is_empty()
	assert_str(CompletionProvider.prefix_before_caret("    # la")).is_empty()
	assert_str(CompletionProvider.prefix_before_caret("    lancar(fo")).is_equal("fo")
	assert_str(CompletionProvider.prefix_before_caret("x = \"la")).is_empty()
