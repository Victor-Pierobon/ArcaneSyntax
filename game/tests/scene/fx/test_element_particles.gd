extends GdUnitTestSuite
## Spec: docs/specs/arte/ART-brilho.md (regras 4 e 5, ART-062 na cena).


func _particles(node: Node) -> Array:
	return node.get_children().filter(func(n: Node) -> bool: return n is CPUParticles2D)


func test_ART_062_a_explosao_segue_o_estilo_do_elemento() -> void:
	var parent: Node2D = auto_free(Node2D.new())
	add_child(parent)
	for element: String in ["fogo", "gelo", "raio", "planta"]:
		var style := ParticleStyle.for_element(element)
		var particles := Fx.element_burst(parent, Vector2.ZERO, element)
		assert_vector(particles.gravity).override_failure_message(element).is_equal(style.gravity)
		assert_that(particles.color).override_failure_message(element).is_equal(style.color)
		assert_float(particles.lifetime).override_failure_message(element).is_equal(style.lifetime)
		assert_float(particles.initial_velocity_max).override_failure_message(element).is_equal(style.speed)


func test_ART_062_golpe_e_derrota_usam_o_elemento() -> void:
	var room: Node2D = auto_free(Node2D.new())
	add_child(room)
	var elemental := Elemental.make_elemental("e", "planta")
	room.add_child(elemental)
	elemental.hit("fogo", "projetil")
	var on_hit := _particles(elemental)
	assert_bool(on_hit.any(func(p: CPUParticles2D) -> bool:
		return p.gravity == ParticleStyle.for_element("fogo").gravity)).override_failure_message("golpe de fogo").is_true()
	elemental.apply_damage(99)
	assert_bool(_particles(room).any(func(p: CPUParticles2D) -> bool:
		return p.gravity == ParticleStyle.for_element("planta").gravity)).override_failure_message("derrota da planta").is_true()


func test_ART_062_cristal_aceso_solta_o_elemento() -> void:
	var room: Node2D = auto_free(Node2D.new())
	add_child(room)
	var crystal := Crystal.make_crystal("c", "cristal", RandomNumberGenerator.new())
	room.add_child(crystal)
	crystal.light("raio")
	assert_bool(_particles(crystal).any(func(p: CPUParticles2D) -> bool:
		return p.gravity == ParticleStyle.for_element("raio").gravity and p.lifetime == ParticleStyle.for_element("raio").lifetime)) \
			.is_true()
