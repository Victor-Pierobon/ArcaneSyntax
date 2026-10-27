class_name ArtCatalog
extends RefCounted
## O contrato dos arquivos de arte (spec ART-esteira, regras 1 a 6): content/arte.json diz, por pasta,
## o tamanho do quadro e as animações; `check` confere um PNG entregue.

const DEFAULT_PATH := "res://content/arte.json"

var errors: Array[String] = []

## pasta → nome do arquivo → {"quadro": Vector2i, "fps", "laco", "reserva", "imagem", "tamanho"}.
var _files: Dictionary = {}


static func load_file(path: String) -> ArtCatalog:
	var text := FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
	var data: Variant = JSON.parse_string(text) if not text.is_empty() else null
	if data == null:
		var catalog := ArtCatalog.new()
		catalog.errors.append("não deu para ler %s" % path)
		return catalog
	return from_data(data)


static func from_data(data: Variant) -> ArtCatalog:
	var catalog := ArtCatalog.new()
	if not data is Dictionary:
		catalog.errors.append("o contrato tem que ser um objeto de pastas")
		return catalog
	for folder: String in data:
		catalog._read_folder(folder, data[folder])
	return catalog


## As cores (RGB, sem alfa) dos pixels opacos de uma imagem de paleta.
static func palette_of(image: Image) -> Dictionary:
	var colors := {}
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a8 == 255:
				colors[_rgb(color)] = true
	return colors


func folders() -> PackedStringArray:
	return PackedStringArray(_files.keys())


func has_file(folder: String, file_name: String) -> bool:
	return _files.has(folder) and _files[folder].has(file_name)


func spec(folder: String, file_name: String) -> Dictionary:
	return _files[folder][file_name]


func frame_count(folder: String, file_name: String, width: int) -> int:
	var frame: Vector2i = spec(folder, file_name)["quadro"]
	return 1 if frame == Vector2i.ZERO else width / frame.x


## Os problemas do arquivo `<pasta>/<nome>.png`; vazio se segue o contrato. Com `palette` (de
## `palette_of`), toda cor opaca tem que estar nela.
func check(folder: String, file_name: String, image: Image, palette: Dictionary = {}) -> Array[String]:
	var file := "%s/%s.png: " % [folder, file_name]
	if not _files.has(folder):
		return [file + "pasta que o contrato não tem"]
	if not _files[folder].has(file_name):
		return [file + "nome que o contrato não tem nessa pasta"]
	var entry: Dictionary = spec(folder, file_name)
	var problems: Array[String] = []
	var width := image.get_width()
	var height := image.get_height()
	if entry["imagem"]:
		var size: Vector2i = entry["tamanho"]
		if size != Vector2i.ZERO and Vector2i(width, height) != size:
			problems.append(file + "tamanho %d×%d, o contrato pede %d×%d" % [width, height, size.x, size.y])
	else:
		var frame: Vector2i = entry["quadro"]
		if height != frame.y:
			problems.append(file + "altura %d, o quadro tem %d" % [height, frame.y])
		if width == 0 or width % frame.x != 0:
			problems.append(file + "largura %d não é múltipla do quadro (%d)" % [width, frame.x])
	problems.append_array(_check_pixels(file, image, palette))
	return problems


func _check_pixels(file: String, image: Image, palette: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	if image.is_compressed():
		image = image.duplicate() as Image
		image.decompress()
	var translucent := ""
	var off_palette := ""
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a8 == 0:
				continue
			if color.a8 != 255:
				if translucent.is_empty():
					translucent = file + "pixel semitransparente em (%d, %d); use só opaco ou transparente" % [x, y]
			elif not palette.is_empty() and off_palette.is_empty() and not palette.has(_rgb(color)):
				off_palette = file + "cor #%s fora da paleta em (%d, %d)" % [color.to_html(false), x, y]
	for problem in [translucent, off_palette]:
		if not problem.is_empty():
			problems.append(problem)
	return problems


static func _rgb(color: Color) -> int:
	return (color.r8 << 16) | (color.g8 << 8) | color.b8


func _read_folder(folder: String, value: Variant) -> void:
	if not value is Dictionary or not value.get("animacoes") is Dictionary:
		errors.append("%s: falta \"animacoes\"" % folder)
		return
	var folder_frame: Variant = _read_frame(value.get("quadro"))
	var anims: Dictionary = value["animacoes"]
	_files[folder] = {}
	for anim: String in anims:
		var raw: Variant = anims[anim]
		if not raw is Dictionary:
			errors.append("%s/%s: tem que ser um objeto" % [folder, anim])
			continue
		var entry := _read_anim("%s/%s" % [folder, anim], raw, folder_frame)
		if entry.is_empty():
			continue
		var variants: Array = raw.get("elementos", [])
		if variants.is_empty():
			_files[folder][anim] = entry
		for variant: Variant in variants:
			var copy := entry.duplicate()
			var reserve: String = copy["reserva"]
			if not reserve.is_empty() and anims.get(reserve, {}) is Dictionary and str(variant) in anims[reserve].get("elementos", []):
				copy["reserva"] = "%s_%s" % [reserve, variant]
			_files[folder]["%s_%s" % [anim, variant]] = copy
	for anim: String in anims:
		var reserve := str(anims[anim].get("reserva", "")) if anims[anim] is Dictionary else ""
		if not reserve.is_empty() and not anims.has(reserve):
			errors.append("%s/%s: reserva \"%s\" não existe na pasta" % [folder, anim, reserve])


## Um quadro: número (quadrado) ou [largura, altura]; null se não veio ou é inválido.
static func _read_frame(value: Variant) -> Variant:
	if (value is float or value is int) and value > 0:
		return Vector2i(int(value), int(value))
	if value is Array and value.size() == 2 and value[0] > 0 and value[1] > 0:
		return Vector2i(int(value[0]), int(value[1]))
	return null


func _read_anim(where: String, raw: Dictionary, folder_frame: Variant) -> Dictionary:
	var still := bool(raw.get("imagem", false))
	var entry := {"imagem": still, "quadro": Vector2i.ZERO, "tamanho": Vector2i.ZERO,
		"fps": 1.0, "laco": false, "reserva": str(raw.get("reserva", ""))}
	if still:
		var size: Variant = _read_frame(raw.get("tamanho"))
		entry["tamanho"] = size if size != null else Vector2i.ZERO
		return entry
	var frame: Variant = _read_frame(raw.get("quadro")) if raw.has("quadro") else folder_frame
	if frame == null:
		errors.append("%s: sem quadro" % where)
		return {}
	var fps: Variant = raw.get("fps")
	if not (fps is float or fps is int) or fps <= 0:
		errors.append("%s: fps tem que ser maior que zero" % where)
		return {}
	entry["quadro"] = frame
	entry["fps"] = float(fps)
	entry["laco"] = bool(raw.get("laco", false))
	return entry
