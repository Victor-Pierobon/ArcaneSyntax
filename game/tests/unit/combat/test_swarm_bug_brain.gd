extends GdUnitTestSuite
## Spec: docs/specs/combate/COM-enxame.md (regra 4, COM-040 a COM-042)

const DT := 1.0 / 60.0
const HOME := Vector2(400, 100)


func test_COM_040_pairando_em_volta_da_casa() -> void:
	var brain := SwarmBugBrain.new(HOME, 0.7)
	var pos := brain.start_position()
	assert_float(pos.distance_to(HOME)).is_equal_approx(24.0, 1.0)
	var start := pos
	var moved := 0.0
	for i in 120:
		var next := brain.step(pos, null, DT)
		moved = maxf(moved, next.distance_to(start))
		pos = next
		assert_float(pos.distance_to(HOME)).is_equal_approx(24.0, 1.0)
	# Uma volta em 2 s: andou longe e voltou ao começo.
	assert_float(moved).is_greater(40.0)
	assert_float(pos.distance_to(start)).is_less(1.0)
	assert_int(brain.state).is_equal(SwarmBugBrain.State.HOVER)


func test_COM_040_cada_bicho_com_a_sua_fase() -> void:
	var a := SwarmBugBrain.new(HOME, 0.0)
	var b := SwarmBugBrain.new(HOME, PI)
	assert_float(a.start_position().distance_to(b.start_position())).is_equal_approx(48.0, 0.5)


func test_COM_041_mergulha_no_mago_perto() -> void:
	var brain := SwarmBugBrain.new(HOME)
	var pos := brain.start_position()
	var mago := HOME + Vector2(-96, 0)
	var next := brain.step(pos, mago, DT)
	assert_int(brain.state).is_equal(SwarmBugBrain.State.DIVE)
	assert_float(next.distance_to(pos)).is_equal_approx(70.0 * DT, 0.01)
	assert_float(next.distance_to(mago)).is_less(pos.distance_to(mago))


func test_COM_041_mago_longe_nao_e_atacado() -> void:
	var brain := SwarmBugBrain.new(HOME)
	brain.step(brain.start_position(), HOME + Vector2(-128, 0), DT)
	assert_int(brain.state).is_equal(SwarmBugBrain.State.HOVER)


func test_COM_041_mago_sai_do_alcance_o_bicho_volta() -> void:
	var brain := SwarmBugBrain.new(HOME)
	var pos := brain.step(brain.start_position(), HOME + Vector2(-96, 0), DT)
	brain.step(pos, HOME + Vector2(-200, 0), DT)
	assert_int(brain.state).is_equal(SwarmBugBrain.State.RETREAT)


func test_COM_042_recua_depois_de_morder() -> void:
	var brain := SwarmBugBrain.new(HOME)
	var mago := HOME + Vector2(-40, 0)
	var pos := brain.start_position()
	for i in 30:
		pos = brain.step(pos, mago, DT)
	brain.bite()
	assert_int(brain.state).is_equal(SwarmBugBrain.State.RETREAT)
	# Até 1,5 s depois da mordida, não mergulha de novo, mesmo com o mago perto.
	var elapsed := 0.0
	while elapsed < 1.45:
		pos = brain.step(pos, mago, DT)
		elapsed += DT
		assert_int(brain.state).is_not_equal(SwarmBugBrain.State.DIVE)
	# Depois disso, volta a mergulhar.
	for i in 120:
		pos = brain.step(pos, mago, DT)
	assert_int(brain.state).is_equal(SwarmBugBrain.State.DIVE)


func test_COM_042_recuo_termina_pairando() -> void:
	var brain := SwarmBugBrain.new(HOME)
	var pos := brain.start_position() + Vector2(-60, 20)
	brain.bite()
	for i in 120:
		pos = brain.step(pos, null, DT)
	assert_int(brain.state).is_equal(SwarmBugBrain.State.HOVER)
	assert_float(pos.distance_to(HOME)).is_equal_approx(24.0, 1.0)
