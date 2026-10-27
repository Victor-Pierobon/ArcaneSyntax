extends GdUnitTestSuite
## Spec: docs/specs/grimorio/GRI-referencia.md (GRI-080 a GRI-082)

const PAGES := ["lancar", "elementos", "formas", "feixe", "mover", "levitar", "meditar", "absorver_mana", "inscrever",
		"construir_bloco", "sentidos", "alvo", "ler_runa", "print", "sequencia", "variaveis", "condicionais", "loops",
		"funcoes"]


func test_GRI_080_paginas_visiveis_pelo_desbloqueio() -> void:
	var data := [{"id": "a", "requer": ["lancar"]}, {"id": "b", "requer": ["lancar", "gelo"]}, {"id": "c", "requer": []}]
	var book := ReferenceBook.from_data(data, func(_key: String) -> bool: return true)
	assert_array(book.visible_pages(PackedStringArray(["lancar"]))).is_equal(["a", "c"])
	assert_array(book.visible_pages(PackedStringArray(["lancar", "gelo"]))).is_equal(["a", "b", "c"])
	assert_array(book.visible_pages(PackedStringArray())).is_equal(["c"])


func test_GRI_081_erros_de_autoria() -> void:
	var data := [
		{"id": "a", "requer": []},
		{"id": "a", "requer": []},
		{"id": "b", "requer": ["voar"]},
		{"id": "sem_texto", "requer": []},
		{"requer": []},
	]
	var known := func(key: String) -> bool: return not key.begins_with("REF_SEM_TEXTO")
	var errors := ReferenceBook.validate(data, known)
	assert_array(errors).contains([
		"referência, página a: id repetido",
		"referência, página b: peça \"voar\" não existe",
		"referência, página sem_texto: texto \"REF_SEM_TEXTO_TITULO\" não existe em textos.csv",
		"referência, página sem_texto: texto \"REF_SEM_TEXTO_TEXTO\" não existe em textos.csv",
		"referência, página 5: falta \"id\"",
	])
	assert_array(ReferenceBook.validate({"nao": "lista"}, known)).is_not_empty()


func test_GRI_082_conteudo_do_jogo_e_valido() -> void:
	var book := ReferenceBook.load_file(ReferenceBook.DEFAULT_PATH)
	assert_array(book.errors).is_empty()
	assert_array(book.visible_pages(PackedStringArray(MagoState.ALL_PIECES))).is_equal(PAGES)
	var text := book.text("lancar")
	assert_str(text).contains("\n").contains("lancar(")
	assert_str(book.title("lancar")).is_not_equal("REF_LANCAR_TITULO")
