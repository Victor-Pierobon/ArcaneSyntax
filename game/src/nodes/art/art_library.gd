class_name ArtLibrary
extends RefCounted
## Lê a arte de `res://assets/<pasta>/<nome>.png` (spec ART-esteira, regras 7 e 8). Quem pede recebe
## null quando o arquivo não existe e usa o provisório. Os testes trocam a pasta com `use_root`.

const DEFAULT_ROOT := "res://assets/"

static var root := DEFAULT_ROOT
static var _catalog: ArtCatalog
static var _textures: Dictionary = {}


static func catalog() -> ArtCatalog:
	if _catalog == null:
		_catalog = ArtCatalog.load_file(ArtCatalog.DEFAULT_PATH)
	return _catalog


static func use_root(path: String) -> void:
	root = path
	_textures.clear()


static func reset() -> void:
	use_root(DEFAULT_ROOT)


static func path_of(folder: String, file_name: String) -> String:
	return root.path_join(folder).path_join(file_name + ".png")


## A imagem do arquivo, ou null se ele não existe. Arquivos importados vêm pelo ResourceLoader (no jogo
## exportado só eles existem); um PNG ainda não importado (ou numa pasta de teste) é lido direto.
static func texture(folder: String, file_name: String) -> Texture2D:
	var path := path_of(folder, file_name)
	if _textures.has(path):
		return _textures[path]
	var found: Texture2D = null
	if path.begins_with("res://") and ResourceLoader.exists(path):
		found = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image:
			found = ImageTexture.create_from_image(image)
	_textures[path] = found
	return found


## As animações `names` da pasta, cada uma com o arquivo dela ou o da reserva (regra 7); null se nenhuma
## tem arquivo.
static func sprite_frames(folder: String, names: Array) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var any := false
	for anim: String in names:
		var source := _resolve(folder, anim)
		if source.is_empty():
			continue
		any = true
		_add_animation(frames, folder, anim, source)
	return frames if any else null


## Um sprite animado com as animações `names`, tocando a primeira que existir; null sem arte.
## A base do quadro fica na origem, 2 px acima da borda de baixo (regra 3).
static func sprite(folder: String, names: Array) -> AnimatedSprite2D:
	var frames := sprite_frames(folder, names)
	if frames == null:
		return null
	var node := AnimatedSprite2D.new()
	node.name = "Arte"
	node.sprite_frames = frames
	var first: StringName = frames.get_animation_names()[0]
	for anim: String in names:
		if frames.has_animation(anim):
			first = anim
			break
	var height := frames.get_frame_texture(first, 0).get_height()
	node.position = Vector2(0, -height / 2.0 + 2.0)
	node.play(first)
	return node


## Efeito que toca uma vez em `at` (posição global) e sai da cena quando termina (regra 21); null sem
## arte ou sem `parent`.
static func effect(parent: Node, folder: String, file_name: String, at: Vector2) -> AnimatedSprite2D:
	if parent == null:
		return null
	var node := sprite(folder, [file_name])
	if node == null:
		return null
	node.name = "Impacto"
	node.sprite_frames.set_animation_loop(file_name, false)
	node.animation_finished.connect(node.queue_free)
	parent.add_child(node)
	node.global_position = at
	return node


## Quanto o desenho do primeiro quadro da animação atual sobe acima da origem do sprite (os pés),
## contando só os pixels opacos.
static func drawn_height(node: AnimatedSprite2D) -> float:
	var frame := node.sprite_frames.get_frame_texture(node.animation, 0)
	var image := frame.get_image()
	if image == null:
		return 0.0
	var used := image.get_used_rect()
	return -(node.position.y - frame.get_height() / 2.0 + used.position.y)


## Duração em segundos de uma vez da animação (quadros ÷ fps).
static func duration(frames: SpriteFrames, anim: String) -> float:
	var fps := frames.get_animation_speed(anim)
	return frames.get_frame_count(anim) / fps if fps > 0.0 else 0.0


## O arquivo que a animação usa: ela mesma ou a primeira reserva com arquivo; vazio se nenhum.
static func _resolve(folder: String, anim: String) -> String:
	var current := anim
	for i in 8:
		if texture(folder, current) != null:
			return current
		if not catalog().has_file(folder, current):
			return ""
		current = catalog().spec(folder, current)["reserva"]
		if current.is_empty():
			return ""
	return ""


static func _add_animation(frames: SpriteFrames, folder: String, anim: String, source: String) -> void:
	var sheet := texture(folder, source)
	var spec: Dictionary = catalog().spec(folder, source) if catalog().has_file(folder, source) else {}
	var frame: Vector2i = spec.get("quadro", Vector2i.ZERO)
	if frame == Vector2i.ZERO:
		frame = Vector2i(sheet.get_height(), sheet.get_height())
	frames.add_animation(anim)
	frames.set_animation_speed(anim, spec.get("fps", 8.0))
	frames.set_animation_loop(anim, spec.get("laco", true))
	for i in maxi(sheet.get_width() / frame.x, 1):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * frame.x, 0, frame.x, frame.y)
		frames.add_frame(anim, atlas)
