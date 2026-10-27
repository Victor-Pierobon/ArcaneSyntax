class_name Lighting
extends RefCounted
## Luz das salas (spec ART-brilho, regras 1 a 3): o mundo escuro e quem acende luz em volta. Todas as
## luzes usam a mesma textura radial, gerada por código; o raio vem do `texture_scale`.

## Luz ambiente do mundo: escura e azulada.
const AMBIENT := Color(0.32, 0.30, 0.44)
const TORCH := Color("ff9a3d")
const SERPENT := Color("7fe0c4")
const FOUNTAIN := Color("6fb8ff")
const MAGE := Color("d8d2ff")
const TEXTURE_SIZE := 128
## Desfaz o escuro num texto do mundo: o nome do elemento, os números das runas e os avisos são
## informação de jogo (regressão da captura da Sprint 20).
const READABLE := Color(1.0 / AMBIENT.r, 1.0 / AMBIENT.g, 1.0 / AMBIENT.b)

static var _texture: Texture2D


static func texture() -> Texture2D:
	if _texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color.WHITE)
		gradient.set_color(1, Color(1, 1, 1, 0))
		var radial := GradientTexture2D.new()
		radial.gradient = gradient
		radial.fill = GradientTexture2D.FILL_RADIAL
		radial.fill_from = Vector2(0.5, 0.5)
		radial.fill_to = Vector2(1.0, 0.5)
		radial.width = TEXTURE_SIZE
		radial.height = TEXTURE_SIZE
		_texture = radial
	return _texture


## Uma luz de `radius` px na cor dada, para pôr como filha de quem brilha.
static func make(color: Color, radius: float, energy := 1.0) -> PointLight2D:
	var light := PointLight2D.new()
	light.name = "Luz"
	light.texture = texture()
	light.texture_scale = radius * 2.0 / TEXTURE_SIZE
	light.color = color
	light.energy = energy
	return light


static func radius_of(light: PointLight2D) -> float:
	return light.texture_scale * TEXTURE_SIZE / 2.0


## O texto lê como na luz cheia, mesmo na sala escura. Usa `self_modulate`: o `modulate` fica livre
## para quem anima a transparência.
static func keep_readable(item: CanvasItem) -> void:
	item.self_modulate = READABLE

