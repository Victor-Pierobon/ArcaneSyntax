class_name Serpent
extends Node2D
## A serpente na sala (spec NAR-dialogo, regra 5): mostra "E: falar" com o mago perto, e o World
## abre a cena dela. Visual provisório, desenhado por código. A origem fica nos pés.

const GROUP := &"serpentes"
const REACH := 2.0 * RoomLayout.TILE
const COLOR := Color("6fcf5a")

var scene_id := ""
## O mago, para mostrar o aviso; o World passa pela Room antes de entrar na árvore.
var player: Node2D
## A arte (`serpente/parada` e `falando`, ART-esteira, regra 8); null: o desenho provisório.
var art_sprite: AnimatedSprite2D

## Luz verde-água em volta (ART-brilho, regra 2).
var light: PointLight2D

var _prompt := Label.new()
var _time := 0.0


static func make(p_scene_id: String) -> Serpent:
	var serpent := Serpent.new()
	serpent.scene_id = p_scene_id
	serpent.name = "Serpente_" + p_scene_id
	return serpent


func _ready() -> void:
	add_to_group(GROUP)
	light = Lighting.make(Lighting.SERPENT, 40)
	light.position = Vector2(0, -10)
	add_child(light)
	_prompt.text = "DIALOGO_FALAR"
	Lighting.keep_readable(_prompt)
	_prompt.add_theme_font_size_override(&"font_size", 8)
	_prompt.add_theme_color_override(&"font_color", Color("ffd27a"))
	# Acima da cabeça do mago (30 px) ao lado dela; mais baixo, o mago cobria o aviso (regressão).
	_prompt.position = Vector2(-18, -44)
	_prompt.visible = false
	add_child(_prompt)
	art_sprite = ArtLibrary.sprite("serpente", ["parada", "falando"])
	if art_sprite:
		add_child(art_sprite)


## Com o diálogo dela aberto (o jogo pausa), a arte toca `falando` mesmo pausada.
func set_talking(talking: bool) -> void:
	if art_sprite == null:
		return
	art_sprite.process_mode = Node.PROCESS_MODE_ALWAYS if talking else Node.PROCESS_MODE_INHERIT
	art_sprite.play(&"falando" if talking else &"parada")


func _physics_process(delta: float) -> void:
	_time += delta
	_prompt.visible = in_reach()
	queue_redraw()


func in_reach() -> bool:
	return player != null and is_instance_valid(player) \
			and player.global_position.distance_to(global_position) <= REACH + 0.001


func prompt_visible() -> bool:
	return in_reach()


## Onde o aviso "E: falar" fica, em coordenadas globais.
func prompt_rect() -> Rect2:
	return Rect2(_prompt.global_position, _prompt.get_minimum_size())


## Corpo em S que balança devagar, cabeça com olho.
func _draw() -> void:
	if art_sprite:
		return
	var points := PackedVector2Array()
	for i in 9:
		var t := i / 8.0
		points.append(Vector2(-7 + 14 * t, -3 - 4 * sin(t * TAU + _time * 2.0) * (1.0 - t * 0.5)))
	draw_polyline(points, COLOR, 3.0, true)
	var head := Vector2(8, -12 + sin(_time * 2.0))
	draw_line(points[points.size() - 1], head, COLOR, 3.0, true)
	draw_circle(head, 3.5, COLOR)
	draw_circle(head + Vector2(1.5, -1), 0.9, Color.BLACK)
