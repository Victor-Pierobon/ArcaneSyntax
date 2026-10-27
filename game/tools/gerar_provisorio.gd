extends SceneTree
## Gera a arte provisória da esteira (spec ART-esteira, regras 15 e 17): o tileset com bordas
## (assets/placeholder/tiles_bordas.png, 64×80) e as três camadas do fundo (fundo_1..3.png, 640×360).
## Determinístico: rodar de novo dá os mesmos arquivos.
##   godot --headless --path game -s res://tools/gerar_provisorio.gd   (depois, --import)

const OUT := "res://assets/placeholder/"
const T := 16

const STONE := Color("34324a")
const MORTAR := Color("26243a")
const SPECK := Color("3e3c58")
const LIP := Color("6e6c8e")
const LIP_LOW := Color("545270")
const SIDE := Color("24223a")
const UNDER := Color("1a1826")
const MOSS := Color("4f7a4a")
const MOSS_LIGHT := Color("6b9a5a")


func _init() -> void:
	_save(_tiles(), "tiles_bordas")
	_save(_far(), "fundo_1")
	_save(_middle(), "fundo_2")
	_save(_near(), "fundo_3")
	print("provisório gerado em ", OUT)
	quit()


func _save(image: Image, file_name: String) -> void:
	image.save_png(ProjectSettings.globalize_path(OUT + file_name + ".png"))


func _tiles() -> Image:
	var image := Image.create_empty(T * 4, T * 5, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for shape in 16:
		_stone(image, Vector2i(shape % 4, shape / 4) * T, shape)
	_platform(image, TileShape.PLATFORM * T)
	_spikes(image, TileShape.SPIKES * T)
	return image


## Pedra em tijolos; cada lado sem vizinho ganha a sua borda (topo claro com musgo, base escura).
func _stone(image: Image, at: Vector2i, shape: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + shape
	image.fill_rect(Rect2i(at, Vector2i(T, T)), STONE)
	for x in T:
		image.set_pixelv(at + Vector2i(x, 7), MORTAR)
		image.set_pixelv(at + Vector2i(x, 15), MORTAR)
	for y in 7:
		image.set_pixelv(at + Vector2i(3, y), MORTAR)
		image.set_pixelv(at + Vector2i(11, y + 8), MORTAR)
	for i in 6:
		image.set_pixelv(at + Vector2i(rng.randi_range(0, T - 1), rng.randi_range(0, T - 1)), SPECK)
	if shape & TileShape.LEFT == 0:
		for y in T:
			image.set_pixelv(at + Vector2i(0, y), SIDE)
	if shape & TileShape.RIGHT == 0:
		for y in T:
			image.set_pixelv(at + Vector2i(T - 1, y), SIDE)
	if shape & TileShape.DOWN == 0:
		for x in T:
			image.set_pixelv(at + Vector2i(x, T - 1), UNDER)
	if shape & TileShape.UP == 0:
		for x in T:
			image.set_pixelv(at + Vector2i(x, 0), LIP)
			image.set_pixelv(at + Vector2i(x, 1), LIP_LOW)
		for i in 5:
			var x := rng.randi_range(0, T - 1)
			image.set_pixelv(at + Vector2i(x, 0), MOSS_LIGHT)
			image.set_pixelv(at + Vector2i(x, 1), MOSS)
			if rng.randf() < 0.5:
				image.set_pixelv(at + Vector2i(x, 2), MOSS)


## Laje de madeira de 4 px no topo (a colisão da plataforma).
func _platform(image: Image, at: Vector2i) -> void:
	for x in T:
		image.set_pixelv(at + Vector2i(x, 0), Color("a07a52"))
		image.set_pixelv(at + Vector2i(x, 1), Color("7a5a3c"))
		image.set_pixelv(at + Vector2i(x, 2), Color("7a5a3c") if x % 8 != 7 else Color("4a3424"))
		image.set_pixelv(at + Vector2i(x, 3), Color("4a3424"))
	for y in range(4, 7):
		image.set_pixelv(at + Vector2i(3, y), Color("4a3424"))
		image.set_pixelv(at + Vector2i(12, y), Color("4a3424"))


## Quatro pontas de 4 px na metade de baixo (onde fica a área que machuca).
func _spikes(image: Image, at: Vector2i) -> void:
	for spike in 4:
		for height in 8:
			var half := (8 - height) / 4.0
			var center := spike * 4 + 1.5
			for x in range(int(center - half + 0.5), int(center + half + 0.5) + 1):
				if x < 0 or x >= T:
					continue
				var color := Color("c8c4d8") if x <= center else Color("7e7a92")
				image.set_pixelv(at + Vector2i(x, T - 1 - height), color)
	for x in T:
		image.set_pixelv(at + Vector2i(x, T - 1), Color("4a4660"))


## Camada de longe: degradê frio e arcos enormes, quase sumindo.
func _far() -> Image:
	var image := Image.create_empty(640, 360, false, Image.FORMAT_RGBA8)
	for y in 360:
		var color := Color("141226").lerp(Color("1f1b35"), y / 359.0)
		for x in 640:
			image.set_pixel(x, y, color)
	var arch := Color("1a1730")
	for base in range(0, 640, 160):
		for x in range(base + 20, base + 140):
			var dx := (x - (base + 80)) / 60.0
			var top := int(120 - sqrt(maxf(0.0, 1.0 - dx * dx)) * 60.0)
			for y in range(top, top + 6):
				image.set_pixel(x, y, arch)
		image.fill_rect(Rect2i(base + 14, 120, 12, 240), arch)
		image.fill_rect(Rect2i(base + 134, 120, 12, 240), arch)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 60:
		image.set_pixel(rng.randi_range(0, 639), rng.randi_range(0, 359), Color("2c2848"))
	return image


## Camada do meio: colunas e arcos quebrados em silhueta.
func _middle() -> Image:
	var image := Image.create_empty(640, 360, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var pillar := Color("110f1e")
	var edge := Color("1c1930")
	var heights: Array[int] = [210, 150, 260, 180, 230]
	for i in 5:
		var x := 40 + i * 128
		var top := 360 - heights[i]
		image.fill_rect(Rect2i(x, top, 22, heights[i]), pillar)
		image.fill_rect(Rect2i(x - 4, top, 30, 8), pillar)
		image.fill_rect(Rect2i(x - 4, top, 30, 1), edge)
		for y in range(top + 14, 360, 18):
			image.fill_rect(Rect2i(x, y, 22, 1), edge)
	return image


## Camada de perto: correntes e raízes penduradas do teto.
func _near() -> Image:
	var image := Image.create_empty(640, 360, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var dark := Color("0a0914")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 9:
		var x := 30 + i * 70 + rng.randi_range(-10, 10)
		var length := rng.randi_range(40, 140)
		if i % 2 == 0:
			for y in length:
				image.set_pixel(x + (1 if y % 6 < 3 else 0), y, dark)
			image.fill_rect(Rect2i(x - 2, length, 5, 4), dark)
		else:
			var wiggle := 0.0
			for y in length:
				wiggle += rng.randf_range(-0.4, 0.4)
				image.fill_rect(Rect2i(x + int(wiggle), y, 2 if y < length - 10 else 1, 1), dark)
	return image
