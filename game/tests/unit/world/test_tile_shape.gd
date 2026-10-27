extends GdUnitTestSuite
## Spec: docs/specs/arte/ART-esteira.md (ART-020): a forma de cada pedra pela vizinhança.


func _solids(cells: Array) -> Dictionary:
	var found := {}
	for cell: Vector2i in cells:
		found[cell] = true
	return found


func test_ART_020_pedra_isolada_e_cercada() -> void:
	var size := Vector2i(10, 10)
	assert_int(TileShape.mask(_solids([Vector2i(5, 5)]), Vector2i(5, 5), size)).is_equal(0)
	var block := []
	for x in range(4, 7):
		for y in range(4, 7):
			block.append(Vector2i(x, y))
	var solids := _solids(block)
	var expected := {Vector2i(4, 4): 6, Vector2i(5, 4): 14, Vector2i(6, 4): 12,
		Vector2i(4, 5): 7, Vector2i(5, 5): 15, Vector2i(6, 5): 13,
		Vector2i(4, 6): 3, Vector2i(5, 6): 11, Vector2i(6, 6): 9}
	for cell: Vector2i in expected:
		assert_int(TileShape.mask(solids, cell, size)).override_failure_message(str(cell)).is_equal(expected[cell])


func test_ART_020_fora_da_sala_conta_como_pedra() -> void:
	var size := Vector2i(3, 2)
	var ground := _solids([Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)])
	assert_int(TileShape.mask(ground, Vector2i(1, 1), size)).is_equal(14)
	assert_int(TileShape.mask(ground, Vector2i(0, 1), size)).is_equal(14)
	assert_int(TileShape.mask(_solids([Vector2i(0, 0)]), Vector2i(0, 0), size)).is_equal(TileShape.UP | TileShape.LEFT)


func test_ART_020_coordenada_no_atlas() -> void:
	assert_that(TileShape.atlas(0)).is_equal(Vector2i(0, 0))
	assert_that(TileShape.atlas(6)).is_equal(Vector2i(2, 1))
	assert_that(TileShape.atlas(15)).is_equal(Vector2i(3, 3))
	assert_that(TileShape.PLATFORM).is_equal(Vector2i(0, 4))
	assert_that(TileShape.SPIKES).is_equal(Vector2i(1, 4))
