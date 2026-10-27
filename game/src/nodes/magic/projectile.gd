class_name Projectile
extends Area2D
## Projétil ou faísca elemental (spec MAG-formas): persegue o alvo escolhido e só acerta ele;
## sem alvo, voa reto e acerta o primeiro que tocar. Some numa parede ou depois de 12 tiles (menos
## quando persegue o chefe, que é alvo a qualquer distância).

const GROUP := &"projeteis"
const SPEED := 220.0
const SPARK_SPEED := 300.0
const MAX_DISTANCE := 12.0 * RoomLayout.TILE
## Camada das áreas que recebem golpes (bonecos, cristais e inimigos).
const HURTBOX_LAYER := 4

var element := ""
var form := "projetil"
var direction := Vector2.RIGHT
## O alvo do feitiço; null se não tinha ou se ele sumiu no caminho (regra 3).
var target: TrainingTarget
## A arte (`magia/projetil_<elemento>` ou `faisca_<elemento>`, ART-esteira, regra 8); null: o círculo.
var art_sprite: AnimatedSprite2D
## Luz na cor do elemento (ART-brilho, regra 2); some com o projétil.
var light: PointLight2D

var _travelled := 0.0


static func make(p_element: String, p_direction: Vector2, p_form: String = "projetil",
		p_target: TrainingTarget = null) -> Projectile:
	var projectile := Projectile.new()
	projectile.element = p_element
	projectile.form = p_form
	projectile.direction = p_direction.normalized()
	projectile.target = p_target
	return projectile


static func speed_of(p_form: String) -> float:
	return SPARK_SPEED if p_form == "faisca" else SPEED


func _ready() -> void:
	add_to_group(GROUP)
	light = Lighting.make(TrainingTarget.ELEMENT_COLORS.get(element, Color.WHITE), 32)
	add_child(light)
	collision_layer = 0
	collision_mask = 1 | HURTBOX_LAYER
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 2.0 if form == "faisca" else 3.0
	shape.shape = circle
	add_child(shape)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	art_sprite = ArtLibrary.sprite("magia", ["%s_%s" % [form, element]])
	if art_sprite:
		art_sprite.position = Vector2.ZERO
		art_sprite.rotation = direction.angle()
		add_child(art_sprite)


func _draw() -> void:
	if art_sprite:
		return
	var color: Color = TrainingTarget.ELEMENT_COLORS.get(element, Color.WHITE)
	if form == "faisca":
		draw_circle(Vector2.ZERO, 2.5, color.lightened(0.3))
		return
	draw_circle(Vector2.ZERO, 4.0, color)
	draw_circle(Vector2.ZERO, 2.0, color.lightened(0.6))


func _physics_process(delta: float) -> void:
	# Um alvo liberado não passa no `target != null`: confere se ainda existe (regressão da Sprint 20,
	# o chefe liberado no meio do voo quando o mago morre).
	if not _target_alive():
		target = null
	if target != null:
		direction = (target.center() - global_position).normalized()
	var step := speed_of(form) * delta
	position += direction * step
	if art_sprite:
		art_sprite.rotation = direction.angle()
	_travelled += step
	# Perseguindo quem é alvo a qualquer distância (o chefe), o alcance não vale (COM-chefe, regra 6).
	var chasing_far := target is Enemy and (target as Enemy).any_distance
	if _travelled >= MAX_DISTANCE and not chasing_far:
		queue_free()


func _target_alive() -> bool:
	return is_instance_valid(target) and target.is_inside_tree() and target.is_in_group(TrainingTarget.GROUP)


func _on_area_entered(area: Area2D) -> void:
	var touched := area.get_parent() as TrainingTarget
	if touched == null or is_queued_for_deletion():
		return
	if target != null and _target_alive() and touched != target:
		return  # atravessa quem não é o alvo escolhido
	touched.hit(element, form)
	_impact()
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body is Player and not is_queued_for_deletion():
		_impact()
		queue_free()


## `magia/impacto_<elemento>` no ponto do acerto (ART-esteira, regra 21).
func _impact() -> void:
	ArtLibrary.effect(get_parent(), "magia", "impacto_" + element, global_position)
