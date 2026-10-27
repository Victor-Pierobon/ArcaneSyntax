extends GdUnitTestSuite
## Spec: docs/specs/mundo/MUN-plataformas.md (MUN-100 a MUN-102)


# --- MUN-100: leitura do layout ---


func test_MUN_100_le_as_plataformas() -> void:
	var layout := RoomLayout.parse("""##############
#............#
#..+.........#
#............#
#..>>..>>>+..#
#.......---..#
##############""")
	assert_array(layout.errors).is_empty()
	assert_int(layout.moving_platforms.size()).is_equal(2)
	var vertical: Dictionary = layout.moving_platforms[0]
	assert_dict(vertical).is_equal({"start": Vector2i(3, 4), "width": 2, "end": Vector2i(3, 2)})
	# A ponta direita da plataforma de 3 encosta no +, incluindo-o: a primeira célula vai até a 8.
	var horizontal: Dictionary = layout.moving_platforms[1]
	assert_dict(horizontal).is_equal({"start": Vector2i(7, 4), "width": 3, "end": Vector2i(8, 4)})
	assert_array(layout.falling_platforms).is_equal([Rect2i(8, 5, 3, 1)])


func test_MUN_100_caminho_para_a_esquerda() -> void:
	var layout := RoomLayout.parse("""##########
#.+...>>.#
##########""")
	assert_array(layout.errors).is_empty()
	assert_dict(layout.moving_platforms[0]).is_equal({"start": Vector2i(6, 1), "width": 2, "end": Vector2i(2, 1)})


func test_MUN_100_erros_de_autoria() -> void:
	var without_end := RoomLayout.parse("""########
#..>>..#
########""")
	assert_int(without_end.errors.size()).is_equal(1)
	assert_str(without_end.errors[0]).contains("+")
	# Sem caminho, fica parada no lugar.
	assert_dict(without_end.moving_platforms[0]).is_equal({"start": Vector2i(3, 1), "width": 2, "end": Vector2i(3, 1)})
	var lonely_end := RoomLayout.parse("""########
#..+...#
########""")
	assert_int(lonely_end.errors.size()).is_equal(1)
	assert_str(lonely_end.errors[0]).contains("+")


# --- MUN-101: caminho ---


func test_MUN_101_vai_para_e_volta() -> void:
	var path := PlatformPath.new(Vector2(0, 0), Vector2(64, 0))
	var travel := 64.0 / 48.0
	assert_vector(path.position_at(0.0)).is_equal(Vector2(0, 0))
	assert_vector(path.position_at(0.5)).is_equal(Vector2(0, 0))
	assert_vector(path.position_at(0.5 + travel / 2.0)).is_equal_approx(Vector2(32, 0), Vector2(0.01, 0.01))
	assert_vector(path.position_at(0.5 + travel)).is_equal_approx(Vector2(64, 0), Vector2(0.01, 0.01))
	assert_vector(path.position_at(1.0 + travel)).is_equal_approx(Vector2(64, 0), Vector2(0.01, 0.01))
	assert_vector(path.position_at(1.0 + travel * 1.5)).is_equal_approx(Vector2(32, 0), Vector2(0.01, 0.01))
	var cycle := 1.0 + travel * 2.0
	assert_float(path.cycle()).is_equal_approx(cycle, 0.001)
	assert_vector(path.position_at(cycle + 0.25)).is_equal_approx(Vector2(0, 0), Vector2(0.01, 0.01))
	assert_vector(path.position_at(cycle + 0.5 + travel / 4.0)).is_equal_approx(Vector2(16, 0), Vector2(0.01, 0.01))


func test_MUN_101_caminho_vertical_e_parado() -> void:
	var up := PlatformPath.new(Vector2(10, 100), Vector2(10, 52))
	assert_vector(up.position_at(0.5 + 0.5)).is_equal_approx(Vector2(10, 76), Vector2(0.01, 0.01))
	var still := PlatformPath.new(Vector2(5, 5), Vector2(5, 5))
	assert_vector(still.position_at(3.7)).is_equal(Vector2(5, 5))


# --- MUN-102: plataforma que cai ---


func test_MUN_102_treme_cai_e_volta() -> void:
	var rule := FallingPlatformRule.new()
	assert_bool(rule.solid()).is_true()
	rule.tick(5.0)
	assert_int(rule.state).is_equal(FallingPlatformRule.State.STILL)
	rule.step_on()
	assert_int(rule.state).is_equal(FallingPlatformRule.State.SHAKING)
	rule.tick(0.4)
	assert_bool(rule.solid()).is_true()
	# Pisar de novo enquanto treme não muda o tempo.
	rule.step_on()
	rule.tick(0.11)
	assert_int(rule.state).is_equal(FallingPlatformRule.State.FALLEN)
	assert_bool(rule.solid()).is_false()
	# Caída, pisar não faz nada.
	rule.step_on()
	rule.tick(2.9)
	assert_bool(rule.solid()).is_false()
	rule.tick(0.11)
	assert_int(rule.state).is_equal(FallingPlatformRule.State.STILL)
	assert_bool(rule.solid()).is_true()


func test_MUN_102_tick_avisa_quando_muda() -> void:
	var rule := FallingPlatformRule.new()
	rule.step_on()
	assert_bool(rule.tick(0.3)).is_false()
	assert_bool(rule.tick(0.3)).is_true()
	assert_bool(rule.tick(1.0)).is_false()
	assert_bool(rule.tick(2.1)).is_true()
