class_name DialogueBook
extends RefCounted
## As cenas de diálogo do jogo (spec NAR-dialogo, regras 1 a 3): content/dialogos.json, com os
## erros de autoria de cada cena. Cena com erro não toca.

const DEFAULT_PATH := "res://content/dialogos.json"
const MAX_OPTIONS := 3

var errors: Array[String] = []

var _scenes: Dictionary = {}
var _broken: Dictionary = {}


static func load_file(path: String) -> DialogueBook:
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text) if not text.is_empty() else null
	if data == null:
		var book := DialogueBook.new()
		book.errors.append("diálogos: não deu para ler %s" % path)
		return book
	return from_data(data)


## `has_text`: se a chave existe no textos.csv (os testes trocam).
static func from_data(data: Variant, has_text := Callable()) -> DialogueBook:
	var book := DialogueBook.new()
	book.errors = validate(data, has_text)
	if data is Dictionary:
		book._scenes = data
		for scene_id: String in data:
			var prefix := "diálogo %s:" % scene_id
			var prefix_line := "diálogo %s," % scene_id
			for error in book.errors:
				if error.begins_with(prefix) or error.begins_with(prefix_line):
					book._broken[scene_id] = true
	return book


func can_play(scene_id: String) -> bool:
	return _scenes.has(scene_id) and not _broken.has(scene_id)


## A leitura da cena, ou null se ela não existe ou tem erro.
func start(scene_id: String) -> DialogueRun:
	return DialogueRun.new(_scenes[scene_id]) if can_play(scene_id) else null


static func validate(data: Variant, has_text := Callable()) -> Array[String]:
	if not has_text.is_valid():
		has_text = DialogueBook._has_text
	var found: Array[String] = []
	if not data is Dictionary:
		found.append("diálogos: o arquivo precisa ser um objeto JSON")
		return found
	for scene_id: String in data:
		found.append_array(_validate_scene(scene_id, data[scene_id], has_text))
	return found


static func _validate_scene(scene_id: String, scene: Variant, has_text: Callable) -> Array[String]:
	var found: Array[String] = []
	var lines: Variant = scene.get("falas") if scene is Dictionary else null
	if not lines is Dictionary or (lines as Dictionary).is_empty():
		found.append("diálogo %s: falta \"falas\"" % scene_id)
		return found
	if not (scene as Dictionary).has("inicio"):
		found.append("diálogo %s: falta \"inicio\"" % scene_id)
		return found
	var start := str(scene["inicio"])
	if not lines.has(start):
		found.append("diálogo %s: fala inicial \"%s\" não existe" % [scene_id, start])
		return found
	for line_id: String in lines:
		found.append_array(_validate_line(scene_id, line_id, lines[line_id], lines, has_text))
	if not found.is_empty():
		return found
	found.append_array(_validate_flow(scene_id, start, lines))
	return found


static func _validate_line(scene_id: String, line_id: String, line: Variant, lines: Dictionary,
		has_text: Callable) -> Array[String]:
	var found: Array[String] = []
	var where := "diálogo %s, fala %s:" % [scene_id, line_id]
	if not line is Dictionary or not (line as Dictionary).has("texto"):
		found.append("%s falta \"texto\"" % where)
		return found
	if not has_text.call(str(line["texto"])):
		found.append("%s texto \"%s\" não existe em textos.csv" % [where, line["texto"]])
	if line.has("proxima") and line.has("opcoes"):
		found.append("%s use \"proxima\" ou \"opcoes\", não as duas" % where)
	if line.has("proxima") and not lines.has(str(line["proxima"])):
		found.append("%s próxima fala \"%s\" não existe" % [where, line["proxima"]])
	var options: Variant = line.get("opcoes", [])
	if not options is Array:
		found.append("%s \"opcoes\" precisa ser uma lista" % where)
		return found
	if (options as Array).size() > MAX_OPTIONS:
		found.append("%s no máximo %d opções" % [where, MAX_OPTIONS])
	for i in (options as Array).size():
		var option: Variant = options[i]
		if not option is Dictionary or not (option as Dictionary).has("proxima"):
			found.append("%s opção %d sem \"proxima\"" % [where, i + 1])
			continue
		if not lines.has(str(option["proxima"])):
			found.append("%s opção %d: próxima fala \"%s\" não existe" % [where, i + 1, option["proxima"]])
		if not has_text.call(str(option.get("texto", ""))):
			found.append("%s texto \"%s\" não existe em textos.csv" % [where, option.get("texto", "")])
	return found


## Toda fala é alcançada a partir do início e toda fala chega a um fim (NAR-004).
static func _validate_flow(scene_id: String, start: String, lines: Dictionary) -> Array[String]:
	var found: Array[String] = []
	var reached := {start: true}
	var queue: Array[String] = [start]
	while not queue.is_empty():
		for next in _next_lines(lines[queue.pop_front()]):
			if not reached.has(next):
				reached[next] = true
				queue.append(next)
	# Quem chega a um fim: as falas finais e, de trás para frente, quem leva a elas.
	var ends := {}
	var changed := true
	while changed:
		changed = false
		for line_id: String in lines:
			if ends.has(line_id):
				continue
			var nexts := _next_lines(lines[line_id])
			if nexts.is_empty() or nexts.any(func(next: String) -> bool: return ends.has(next)):
				ends[line_id] = true
				changed = true
	for line_id: String in lines:
		if not reached.has(line_id):
			found.append("diálogo %s, fala %s: nunca é alcançada" % [scene_id, line_id])
		elif not ends.has(line_id):
			found.append("diálogo %s, fala %s: não chega a um fim" % [scene_id, line_id])
	return found


static func _next_lines(line: Dictionary) -> Array[String]:
	var nexts: Array[String] = []
	if line.has("proxima"):
		nexts.append(str(line["proxima"]))
	for option: Dictionary in line.get("opcoes", []):
		nexts.append(str(option["proxima"]))
	return nexts


static func _has_text(key: String) -> bool:
	return TranslationServer.translate(key) != key
