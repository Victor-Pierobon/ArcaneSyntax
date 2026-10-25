extends GdUnitTestSuite
## Spec: docs/specs/mundo/MUN-salas.md (MUN-030, MUN-031)


func test_MUN_030_leitura_do_layout() -> void:
	var layout := RoomLayout.parse("A.*b\n#=^#")
	assert_int(layout.width).is_equal(4)
	assert_int(layout.height).is_equal(2)
	assert_array(layout.solids).contains_exactly([Vector2i(0, 1), Vector2i(3, 1)])
	assert_array(layout.platforms).contains_exactly([Vector2i(1, 1)])
	assert_array(layout.spikes).contains_exactly([Vector2i(2, 1)])
	assert_array(layout.safe_points).contains_exactly([Vector2i(2, 0)])
	assert_dict(layout.entries).is_equal({"A": Vector2i(0, 0)})
	assert_array(layout.exits["b"]).contains_exactly([Vector2i(3, 0)])
	assert_vector(RoomLayout.cell_feet(Vector2i(0, 0))).is_equal(Vector2(8, 16))
	assert_array(layout.errors).is_empty()


func test_MUN_030_linhas_de_tamanhos_diferentes_e_espacos() -> void:
	var layout := RoomLayout.parse("#\n# . #\n")
	assert_int(layout.width).is_equal(5)
	assert_int(layout.height).is_equal(2)
	assert_vector(layout.size_px()).is_equal(Vector2(80, 32))


func test_MUN_030_saida_com_varias_celulas() -> void:
	var layout := RoomLayout.parse("b.\nb.")
	assert_array(layout.exits["b"]).contains_exactly([Vector2i(0, 0), Vector2i(0, 1)])


func test_MUN_031_caractere_desconhecido() -> void:
	var layout := RoomLayout.parse("#?#\n###")
	assert_array(layout.errors).has_size(1)
	assert_str(layout.errors[0]).contains("linha 1").contains("coluna 2")
	assert_int(layout.solids.size()).is_equal(5)


func test_PUZ_005_porta_no_layout() -> void:
	var layout := RoomLayout.parse("..|\n..|")
	assert_array(layout.doors).contains_exactly([Vector2i(2, 0), Vector2i(2, 1)])
	assert_array(layout.errors).is_empty()


func test_MUN_040_bonecos_no_layout() -> void:
	var layout := RoomLayout.parse("1.2")
	assert_dict(layout.targets).is_equal({"1": Vector2i(0, 0), "2": Vector2i(2, 0)})
	assert_array(layout.errors).is_empty()


func test_PUZ_015_vao_de_ponte_e_placa_no_layout() -> void:
	var layout := RoomLayout.parse("._.\n~~#")
	assert_array(layout.bridge_cells).contains_exactly([Vector2i(0, 1), Vector2i(1, 1)])
	assert_array(layout.plates).contains_exactly([Vector2i(1, 0)])
	assert_array(layout.solids).contains_exactly([Vector2i(2, 1)])
	assert_array(layout.errors).is_empty()
