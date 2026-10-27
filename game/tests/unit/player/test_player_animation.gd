extends GdUnitTestSuite
## Spec: docs/specs/arte/ART-esteira.md (ART-010): a regra que escolhe a animação do mago.

var anim: PlayerAnimation


func before_test() -> void:
	anim = PlayerAnimation.new()


func test_ART_010_chao() -> void:
	assert_str(anim.pick(true, Vector2.ZERO, false, false)).is_equal("parado")
	assert_str(anim.pick(true, Vector2(5, 0), false, false)).is_equal("parado")
	assert_str(anim.pick(true, Vector2(-120, 0), false, false)).is_equal("andar")


func test_ART_010_ar() -> void:
	assert_str(anim.pick(false, Vector2(0, -200), false, false)).is_equal("pular")
	assert_str(anim.pick(false, Vector2(50, 100), false, false)).is_equal("cair")
	assert_str(anim.pick(false, Vector2(96, 0), false, true)).is_equal("pular")


func test_ART_010_acoes_e_tempo() -> void:
	anim.start_action("meditar", 0.5)
	assert_str(anim.pick(false, Vector2(0, 100), false, false)).is_equal("meditar")
	anim.tick(0.6)
	assert_str(anim.pick(true, Vector2.ZERO, false, false)).is_equal("parado")
	anim.start_action("conjurar")
	anim.tick(PlayerAnimation.ACTION_TIMES["conjurar"] - 0.05)
	assert_str(anim.pick(true, Vector2(120, 0), false, false)).is_equal("conjurar")
	anim.tick(0.1)
	assert_str(anim.pick(true, Vector2(120, 0), false, false)).is_equal("andar")


func test_ART_010_prioridade() -> void:
	anim.start_action("conjurar", 1.0)
	assert_str(anim.pick(true, Vector2.ZERO, true, false)).is_equal("esquivar")
	anim.hurt()
	assert_str(anim.pick(true, Vector2.ZERO, true, false)).is_equal("dano")
	anim.tick(PlayerAnimation.HURT_TIME + 0.01)
	assert_str(anim.pick(true, Vector2.ZERO, false, false)).is_equal("conjurar")
