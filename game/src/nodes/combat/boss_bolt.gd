class_name BossBolt
extends Area2D
## Orbe do chefe (spec COM-chefe, regra 6): voa reto para onde o mago estava e tira vida como ataque.
## Some numa parede, no mago ou depois do alcance.

## Acertou o mago; quem criou o orbe repassa para o World, que aplica o dano.
signal hit_player(from: Vector2, amount: int)

const GROUP := &"orbes_chefe"
const RADIUS := 4.0

var element := ""
var direction := Vector2.RIGHT
var speed := Balance.number("chefe", "orbe_velocidade")
var max_distance := Balance.number("chefe", "orbe_alcance_tiles") * RoomLayout.TILE
var damage := Balance.integer("chefe", "orbe_dano")

var _travelled := 0.0


static func make(p_element: String, p_direction: Vector2) -> BossBolt:
	var bolt := BossBolt.new()
	bolt.element = p_element
	bolt.direction = p_direction.normalized()
	return bolt


func _ready() -> void:
	add_to_group(GROUP)
	# Nenhuma camada: os projéteis do mago não acertam o orbe.
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	var color: Color = TrainingTarget.ELEMENT_COLORS.get(element, Color.WHITE)
	draw_circle(Vector2.ZERO, RADIUS + 1.0, Color(color, 0.35))
	draw_circle(Vector2.ZERO, RADIUS - 1.0, color)


func _physics_process(delta: float) -> void:
	var step := speed * delta
	position += direction * step
	_travelled += step
	if _travelled >= max_distance:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if is_queued_for_deletion():
		return
	if body is Player:
		hit_player.emit(global_position, damage)
	queue_free()
