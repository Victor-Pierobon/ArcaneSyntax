extends GdUnitTestSuite
## Spec: docs/specs/grimorio/GRI-grimorio.md (GRI-006)


func test_GRI_006_cores_por_grupo() -> void:
	var highlighter := PythonHighlighter.build()
	var keyword := highlighter.get_keyword_color("while")
	var builtin := highlighter.get_keyword_color("print")
	var piece := highlighter.get_keyword_color("lancar")
	assert_bool(highlighter.has_keyword_color("while")).is_true()
	assert_bool(highlighter.get_keyword_color("def") == keyword).is_true()
	assert_bool(highlighter.get_keyword_color("fogo") == piece).is_true()
	assert_bool(highlighter.get_keyword_color("mana") == piece).is_true()
	assert_bool(keyword != builtin and keyword != piece and builtin != piece).is_true()


func test_GRI_006_regioes_de_texto_e_comentario() -> void:
	var highlighter := PythonHighlighter.build()
	assert_bool(highlighter.has_color_region("#")).is_true()
	assert_bool(highlighter.has_color_region("\"")).is_true()
	assert_bool(highlighter.has_color_region("'")).is_true()
