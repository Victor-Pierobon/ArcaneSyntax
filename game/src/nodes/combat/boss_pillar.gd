class_name BossPillar
extends Area2D
## Marca e pilar do chefe (spec COM-chefe, regra 12): a marca pisca no chão; quando o BossBrain
## manda, o pilar sobe dali e machuca o mago que estiver nele. O tempo é do BossBrain.

## O pilar acertou o mago; o chefe repassa para o World, que aplica o dano.
signal hit_player(from: Vector2, amount: int)

const GROUP := &"pilares_chefe"
const WIDTH := 16.0
const MARK_SIZE := Vector2(14, 3)
## A marca pisca 4 vezes por segundo.
const BLINK_RATE := 8.0
## Opacidade do contorno do pilar que vai subir.
const PREVIEW_ALPHA := 0.3

var element := ""
var risen := false
var height := Balance.number("chefe", "pilar_altura_tiles") * RoomLayout.TILE
var damage := Balance.integer("chefe", "pilar_dano")

var mark := ColorRect.new()
## O contorno do pilar que vai subir, enquanto a marca pisca (regressão: a marca sozinha ficava atrás
## do mago parado em cima dela).
var preview := ColorRect.new()
var column := ColorRect.new()
## A arte (`chefe/aviso` e `chefe/pilar`, regra 18); null: os retângulos.
var mark_art: AnimatedSprite2D
var column_art: AnimatedSprite2D
## Luz na cor da fase, só com o pilar de pé (ART-brilho, regra 2).
var light: PointLight2D
var _clock := 0.0


static func make(p_element: String) -> BossPillar:
	var pillar := BossPillar.new()
	pillar.element = p_element
	return pillar


func _ready() -> void:
	add_to_group(GROUP)
	# Na frente do mago: o aviso tem que aparecer para quem está em cima da marca.
	z_index = 1
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	monitoring = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WIDTH - 2.0, height)
	shape.shape = rect
	shape.position = Vector2(0, -height / 2)
	add_child(shape)
	var color: Color = TrainingTarget.ELEMENT_COLORS.get(element, Color.WHITE)
	mark.color = color.lightened(0.3)
	mark.size = MARK_SIZE
	mark.position = Vector2(-MARK_SIZE.x / 2, -MARK_SIZE.y)
	add_child(mark)
	preview.color = Color(color.lightened(0.3), PREVIEW_ALPHA)
	preview.size = Vector2(WIDTH, height)
	preview.position = Vector2(-WIDTH / 2, -height)
	add_child(preview)
	column.color = color
	column.size = Vector2(WIDTH, height)
	column.position = Vector2(-WIDTH / 2, -height)
	column.visible = false
	add_child(column)
	mark_art = ArtLibrary.sprite("chefe", ["aviso"])
	if mark_art:
		mark.visible = false
		add_child(mark_art)
	light = Lighting.make(color, 24)
	light.position = Vector2(0, -height / 2)
	light.enabled = false
	add_child(light)
	column_art = ArtLibrary.sprite("chefe", ["pilar"])
	if column_art:
		column_art.visible = false
		add_child(column_art)


func rise() -> void:
	risen = true
	light.enabled = true
	mark.visible = false
	preview.visible = false
	if mark_art:
		mark_art.visible = false
	if column_art:
		column_art.visible = true
	else:
		column.visible = true
	set_deferred(&"monitoring", true)


func _physics_process(delta: float) -> void:
	_clock += delta
	if not risen:
		var lit := int(_clock * BLINK_RATE) % 2 == 0
		mark.modulate.a = 1.0 if lit else 0.35
		preview.modulate.a = 1.0 if lit else 0.5
		return
	if not monitoring:
		return
	for body in get_overlapping_bodies():
		if body is Player:
			hit_player.emit(global_position, damage)
			return
