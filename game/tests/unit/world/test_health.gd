extends GdUnitTestSuite
## Spec: docs/specs/mundo/MUN-vida.md

var health: Health


func before_test() -> void:
	health = Health.new(5)


func test_MUN_020_dano_e_limites() -> void:
	health.damage(2)
	assert_int(health.current).is_equal(3)
	health.heal(10)
	assert_int(health.current).is_equal(5)
	health.tick(2.0)
	health.damage(10)
	assert_int(health.current).is_equal(0)


func test_MUN_021_morte_uma_vez() -> void:
	var deaths := [0]
	health.died.connect(func() -> void: deaths[0] += 1)
	health.damage(4)
	health.tick(2.0)
	health.damage(1)
	health.tick(2.0)
	health.damage(1)
	assert_int(deaths[0]).is_equal(1)
	assert_int(health.current).is_equal(0)
	assert_bool(health.is_dead()).is_true()


func test_MUN_022_invencibilidade_pos_dano() -> void:
	assert_bool(health.damage(1)).is_true()
	health.tick(0.5)
	assert_bool(health.damage(1)).is_false()
	assert_int(health.current).is_equal(4)
	health.tick(0.6)
	assert_bool(health.damage(1)).is_true()
	assert_int(health.current).is_equal(3)


func test_MUN_023_esquiva_protege_de_ataque_mas_nao_de_espinho() -> void:
	health.dodging = true
	assert_bool(health.damage(1)).is_false()
	assert_bool(health.damage(1, Health.Source.HAZARD)).is_true()
	assert_int(health.current).is_equal(4)


func test_MAG_013_escudo_bloqueia_um_ataque_mas_nao_espinho() -> void:
	var blocked := [0]
	health.attack_blocked.connect(func() -> void: blocked[0] += 1)
	health.shielded = true
	assert_bool(health.damage(1, Health.Source.HAZARD)).is_true()
	health.tick(2.0)
	assert_bool(health.shielded).is_true()
	assert_bool(health.damage(1)).is_false()
	assert_bool(health.shielded).is_false()
	assert_int(blocked[0]).is_equal(1)
	assert_int(health.current).is_equal(4)
	health.tick(1.1)
	assert_bool(health.damage(1)).is_true()


## Regressão (Sprint 10, achado pelo COM-005): o escudo bloqueava a mordida, mas o inimigo
## continuava encostado e mordia no quadro seguinte. Bloquear dá a mesma invencibilidade do dano.
func test_MAG_013_bloquear_da_invencibilidade() -> void:
	health.shielded = true
	assert_bool(health.damage(1)).is_false()
	assert_bool(health.damage(1)).is_false()
	assert_int(health.current).is_equal(5)
	health.tick(0.9)
	assert_bool(health.damage(1)).is_false()
	health.tick(0.2)
	assert_bool(health.damage(1)).is_true()
	assert_int(health.current).is_equal(4)


func test_sinal_changed_avisa_vida_atual_e_maxima() -> void:
	var seen := []
	health.changed.connect(func(current: int, maximum: int) -> void: seen.append([current, maximum]))
	health.damage(2)
	health.restore_full()
	assert_array(seen).is_equal([[3, 5], [5, 5]])
