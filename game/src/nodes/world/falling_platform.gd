class_name FallingPlatform
extends StaticBody2D
## Plataforma que cai (spec MUN-plataformas, regras 7 a 9): o mago pisa, ela treme, cai e volta. O
## estado é do FallingPlatformRule; este nó só desenha e liga ou desliga a colisão.

const THICKNESS := 4.0
## Tremida enquanto vai cair e quanto ela desce ao cair (só o desenho).
const SHAKE := 1.0
const DROP := 24.0
const CRACK := Color("3a2a1c")
## Madeira avermelhada e escura: dá para ver de longe que esta cai (regressão da captura da Sprint 18).
const TINT := Color(1.0, 0.55, 0.45)

var width := 1
var rule := FallingPlatformRule.new()
## Quem pisa nela (o mago); null: ninguém pisa.
var player: CharacterBody2D
var tile_texture: Texture2D
var tile_region := Rect2()
## O desenho (treme e cai sem mexer na colisão).
var visual := Node2D.new()

var _shape := CollisionShape2D.new()
var _clock := 0.0
var _fall := 0.0


static func make(top_left: Vector2, p_width: int) -> FallingPlatform:
	var platform := FallingPlatform.new()
	platform.width = p_width
	platform.position = top_left
	return platform


func _ready() -> void:
	collision_layer = Room.PLATFORM_LAYER
	collision_mask = 0
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width * RoomLayout.TILE, THICKNESS)
	_shape.shape = rect
	_shape.position = Vector2(width * RoomLayout.TILE / 2.0, THICKNESS / 2.0)
	_shape.one_way_collision = true
	add_child(_shape)
	visual.draw.connect(_draw_visual)
	visual.self_modulate = TINT
	add_child(visual)


func _physics_process(delta: float) -> void:
	_clock += delta
	if _player_on_top():
		rule.step_on()
	if rule.tick(delta):
		_shape.set_deferred(&"disabled", not rule.solid())
		_fall = 0.0
	match rule.state:
		FallingPlatformRule.State.SHAKING:
			visual.position = Vector2(SHAKE * signf(sin(_clock * 70.0)), 0)
		FallingPlatformRule.State.FALLEN:
			_fall = minf(_fall + delta * 4.0, 1.0)
			visual.position = Vector2(0, DROP * _fall)
			visual.modulate.a = 1.0 - _fall
		_:
			visual.position = Vector2.ZERO
			visual.modulate.a = 1.0


## O mago em pé, com os pés nela (a colisão do quadro foi com esta plataforma).
func _player_on_top() -> bool:
	if player == null or not is_instance_valid(player) or not player.is_on_floor():
		return false
	for i in player.get_slide_collision_count():
		if player.get_slide_collision(i).get_collider() == self:
			return true
	return false


func _draw_visual() -> void:
	for i in width:
		var cell := Rect2(i * RoomLayout.TILE, 0, RoomLayout.TILE, RoomLayout.TILE)
		if tile_texture:
			visual.draw_texture_rect_region(tile_texture, cell, tile_region)
		else:
			visual.draw_rect(Rect2(cell.position, Vector2(RoomLayout.TILE, THICKNESS)), Color("8a6a44"))
		# Rachaduras (com o tom avermelhado): diferencia da plataforma fixa.
		visual.draw_line(cell.position + Vector2(4, 0), cell.position + Vector2(7, 4), CRACK, 2.0)
		visual.draw_line(cell.position + Vector2(11, 0), cell.position + Vector2(9, 4), CRACK, 2.0)
