extends GdUnitTestSuite
## Spec: docs/specs/progressao/PRO-xp.md (PRO-001, PRO-002) e PRO-niveis.md (PRO-020 a PRO-022)


func test_PRO_001_ganhar_xp() -> void:
	var state := MagoState.new()
	assert_int(state.xp).is_equal(0)
	var seen: Array = []
	state.xp_changed.connect(func(xp: int, level: int) -> void: seen.append([xp, level]))
	state.gain_xp(10)
	state.gain_xp(2)
	assert_int(state.xp).is_equal(12)
	assert_array(seen).is_equal([[10, 1], [12, 1]])


func test_PRO_002_xp_do_puzzle_e_bonus_por_economia() -> void:
	assert_int(Progression.puzzle_xp(0)).is_equal(20)
	assert_int(Progression.puzzle_xp(1)).is_equal(20)
	assert_int(Progression.puzzle_xp(2)).is_equal(25)
	assert_int(Progression.puzzle_xp(3)).is_equal(30)
	assert_int(Progression.economy_bonus(3)).is_equal(10)
	assert_int(Progression.economy_bonus(0)).is_equal(0)


func test_PRO_003_xp_de_cada_inimigo() -> void:
	var enemies: Array[Enemy] = [
		Elemental.make_elemental("e", "fogo"),
		SwarmBug.make_bug("s", Vector2.ZERO, 0.0),
		Guardian.make_guardian("g"),
		Boss.make_boss("c"),
	]
	assert_array(enemies.map(func(enemy: Enemy) -> int: return enemy.xp)).is_equal([10, 2, 15, 50])
	for enemy in enemies:
		add_child(enemy)
		enemy.queue_free()


func test_PRO_020_curva_de_niveis() -> void:
	var expected := {0: 1, 29: 1, 30: 2, 69: 2, 70: 3, 129: 3, 130: 4, 209: 4, 210: 5, 9999: 5}
	for xp: int in expected:
		assert_int(Progression.level_for(xp)).override_failure_message("xp %d" % xp).is_equal(expected[xp])
	var mana := []
	for level in range(1, 6):
		mana.append(Progression.mana_max_for(level))
	assert_array(mana).is_equal([10.0, 12.0, 14.0, 16.0, 18.0])
	assert_int(Progression.max_level()).is_equal(5)


func test_PRO_020_proximo_limiar() -> void:
	assert_int(Progression.next_threshold(1)).is_equal(30)
	assert_int(Progression.next_threshold(4)).is_equal(210)
	assert_int(Progression.next_threshold(5)).is_equal(-1)


func test_PRO_021_subir_de_nivel_aumenta_e_enche_a_mana() -> void:
	var state := MagoState.new()
	assert_int(state.level).is_equal(1)
	assert_float(state.mana_max).is_equal(10.0)
	state.set_mana(3.0)
	var levels: Array[int] = []
	state.leveled_up.connect(func(level: int) -> void: levels.append(level))
	state.gain_xp(30)
	assert_int(state.level).is_equal(2)
	assert_float(state.mana_max).is_equal(12.0)
	assert_float(state.mana).is_equal(12.0)
	assert_array(levels).is_equal([2])
	assert_float(float(state.to_spell_mago()["mana_max"])).is_equal(12.0)


func test_PRO_022_varios_niveis_de_uma_vez_e_o_teto() -> void:
	var state := MagoState.new()
	var levels: Array[int] = []
	state.leveled_up.connect(func(level: int) -> void: levels.append(level))
	state.gain_xp(140)
	assert_int(state.level).is_equal(4)
	assert_float(state.mana_max).is_equal(16.0)
	assert_array(levels).is_equal([2, 3, 4])
	state.gain_xp(1000)
	assert_int(state.level).is_equal(5)
	assert_float(state.mana_max).is_equal(18.0)
	assert_int(state.xp).is_equal(1140)
	assert_array(levels).is_equal([2, 3, 4, 5])


func test_PRO_022_xp_nao_negativa() -> void:
	var state := MagoState.new()
	state.gain_xp(-5)
	assert_int(state.xp).is_equal(0)
