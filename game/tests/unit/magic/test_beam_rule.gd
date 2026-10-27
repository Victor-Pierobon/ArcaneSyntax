extends GdUnitTestSuite
## Spec: docs/specs/magia/MAG-feixe.md (regras 4, 5 e 7; MAG-082 e MAG-083)

const TILE := RoomLayout.TILE


## Bloqueia as células de `cells`.
func _walls(cells: Array) -> Callable:
	return func(cell: Vector2i) -> bool: return cell in cells


# --- MAG-082: onde o feixe termina ---


func test_MAG_082_para_antes_da_parede() -> void:
	var origin := Vector2(2 * TILE + 8, 5 * TILE + 8)
	var end := BeamRule.end_point(origin, Vector2.RIGHT, _walls([Vector2i(10, 5)]))
	# Encosta na borda esquerda da célula 10.
	assert_float(end.x).is_equal_approx(10 * TILE, BeamRule.STEP)
	assert_float(end.x).is_less_equal(10 * TILE)
	assert_float(end.y).is_equal(origin.y)


func test_MAG_082_sem_parede_vai_ate_o_alcance() -> void:
	var origin := Vector2(100, 100)
	var end := BeamRule.end_point(origin, Vector2(1, 1), _walls([]))
	assert_float(origin.distance_to(end)).is_equal_approx(BeamRule.MAX_LENGTH, BeamRule.STEP)
	assert_float(BeamRule.MAX_LENGTH).is_equal(40.0 * TILE)


func test_MAG_082_quem_bloqueia_e_quem_chama_decide() -> void:
	# Uma plataforma não está na lista do que bloqueia: o feixe passa.
	var origin := Vector2(8, 8)
	var end := BeamRule.end_point(origin, Vector2.DOWN, _walls([Vector2i(0, 20)]))
	assert_float(end.y).is_equal_approx(20 * TILE, BeamRule.STEP)


# --- MAG-083: quem o feixe acerta ---


func test_MAG_083_acerta_quem_encosta_na_largura() -> void:
	var start := Vector2(0, 100)
	var end := Vector2(300, 100)
	var rects: Array[Rect2] = [
		Rect2(50, 90, 12, 24),     # no meio da linha
		Rect2(120, 104, 12, 24),   # o topo encosta na borda de baixo do feixe (100 + 4)
		Rect2(200, 105, 12, 24),   # 1 px abaixo da largura: não
		Rect2(-40, 90, 12, 24),    # atrás da origem: não
		Rect2(320, 90, 12, 24),    # depois do fim: não
		Rect2(260, 60, 12, 24),    # acima: não
	]
	assert_array(BeamRule.hits(start, end, rects)).is_equal([0, 1])


func test_MAG_083_feixe_diagonal() -> void:
	var start := Vector2(0, 0)
	var end := Vector2(200, 200)
	var rects: Array[Rect2] = [Rect2(95, 95, 10, 10), Rect2(150, 20, 10, 10)]
	assert_array(BeamRule.hits(start, end, rects)).is_equal([0])
