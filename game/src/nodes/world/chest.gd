class_name Chest
extends Node2D
## Baú de um segredo (spec MUN-segredos): a Room abre quando o mago encosta. Visual provisório,
## desenhado por código. A origem fica nos pés.

const COLOR_WOOD := Color("8a5a2b")
const COLOR_GOLD := Color("ffd27a")

var secret_id := ""
var is_open := false
## `objetos/bau_fechado` e `bau_abrindo` (ART-esteira, regra 27); null: o baú desenhado.
var art_sprite: AnimatedSprite2D


static func make(p_secret_id: String, opened: bool) -> Chest:
	var chest := Chest.new()
	chest.secret_id = p_secret_id
	chest.name = "Bau_" + p_secret_id
	chest.is_open = opened
	return chest


func _ready() -> void:
	art_sprite = ArtLibrary.sprite("objetos", ["bau_fechado", "bau_abrindo"])
	if art_sprite and not art_sprite.sprite_frames.has_animation("bau_fechado"):
		art_sprite = null
	if art_sprite:
		add_child(art_sprite)
		_refresh_art(false)


## Aberto: o último quadro de `bau_abrindo` (tocado ao abrir) ou o fechado escurecido.
func _refresh_art(animate: bool) -> void:
	if art_sprite == null or not is_open:
		return
	if art_sprite.sprite_frames.has_animation("bau_abrindo"):
		art_sprite.play("bau_abrindo")
		if not animate:
			art_sprite.frame = art_sprite.sprite_frames.get_frame_count("bau_abrindo") - 1
			art_sprite.pause()
	else:
		art_sprite.modulate = Color(0.55, 0.55, 0.55)


## Devolve false se já estava aberto.
func open() -> bool:
	if is_open:
		return false
	is_open = true
	_refresh_art(true)
	queue_redraw()
	Fx.burst(self, Vector2(0, -10), COLOR_GOLD, 14, true)
	return true


func _draw() -> void:
	if art_sprite:
		return
	draw_rect(Rect2(-6, -9, 12, 9), COLOR_WOOD)
	draw_rect(Rect2(-6, -9, 12, 9), COLOR_GOLD, false, 1.0)
	if is_open:
		draw_rect(Rect2(-6, -14, 12, 3), COLOR_WOOD.darkened(0.3))
		draw_circle(Vector2(0, -9), 2.5, COLOR_GOLD)
	else:
		draw_rect(Rect2(-6, -12, 12, 4), COLOR_WOOD.lightened(0.15))
		draw_rect(Rect2(-1, -9, 2, 3), COLOR_GOLD)
