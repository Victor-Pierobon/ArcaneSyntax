class_name Fx
extends RefCounted
## Partículas provisórias feitas por código (spec MAG-efeitos).


## Explosão curta de partículas que some sozinha.
static func burst(parent: Node, position: Vector2, color: Color, amount: int = 14, rising: bool = false) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.explosiveness = 0.0 if rising else 0.9
	particles.amount = amount
	particles.lifetime = 0.6 if rising else 0.35
	particles.position = position
	particles.color = color
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	if rising:
		particles.direction = Vector2.UP
		particles.spread = 25.0
		particles.gravity = Vector2(0, -20)
		particles.initial_velocity_min = 10.0
		particles.initial_velocity_max = 25.0
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		particles.emission_rect_extents = Vector2(8, 2)
	else:
		particles.spread = 180.0
		particles.gravity = Vector2.ZERO
		particles.initial_velocity_min = 30.0
		particles.initial_velocity_max = 70.0
	parent.add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)
	return particles
