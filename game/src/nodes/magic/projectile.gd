class_name Projectile
extends Area2D
## Projétil elemental (spec MAG-formas): voa reto, aplica o elemento no primeiro alvo que toca
## e some numa parede ou depois de 12 tiles.

const GROUP := &"projeteis"
const SPEED := 220.0
const MAX_DISTANCE := 12.0 * RoomLayout.TILE
## Camada das áreas que recebem golpes (bonecos e, no futuro, inimigos).
const HURTBOX_LAYER := 4

var element := ""
var direction := Vector2.RIGHT

var _travelled := 0.0


static func make(p_element: String, p_direction: Vector2) -> Projectile:
	var projectile := Projectile.new()
	projectile.element = p_element
	projectile.direction = p_direction.normalized()
	return projectile


func _ready() -> void:
	add_to_group(GROUP)
	collision_layer = 0
	collision_mask = 1 | HURTBOX_LAYER
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 3.0
	shape.shape = circle
	add_child(shape)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	var color: Color = TrainingTarget.ELEMENT_COLORS.get(element, Color.WHITE)
	draw_circle(Vector2.ZERO, 4.0, color)
	draw_circle(Vector2.ZERO, 2.0, color.lightened(0.6))


func _physics_process(delta: float) -> void:
	var step := SPEED * delta
	position += direction * step
	_travelled += step
	if _travelled >= MAX_DISTANCE:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	var target := area.get_parent() as TrainingTarget
	if target and not is_queued_for_deletion():
		target.hit(element)
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		queue_free()
