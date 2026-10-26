class_name HintBook
extends RefCounted
## Dicas em três níveis por puzzle (spec NAR-dicas): content/dicas.json, e a cena que a serpente
## toca para oferecer cada uma.

const DEFAULT_PATH := "res://content/dicas.json"
const LEVELS := 3
## A fala da cena que conta a dica como usada (regra 4).
const HINT_LINE := "dica"

var errors: Array[String] = []

var _hints: Dictionary = {}


static func load_file(path: String) -> HintBook:
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text) if not text.is_empty() else null
	if data == null:
		var book := HintBook.new()
		book.errors.append("dicas: não deu para ler %s" % path)
		return book
	return from_data(data)


## `has_text`: se a chave existe no textos.csv (os testes trocam).
static func from_data(data: Variant, has_text := Callable()) -> HintBook:
	var book := HintBook.new()
	book.errors = validate(data, has_text)
	if data is Dictionary:
		for puzzle_id: String in data:
			if data[puzzle_id] is Array and (data[puzzle_id] as Array).size() == LEVELS:
				book._hints[puzzle_id] = data[puzzle_id]
	return book


func has_hints(puzzle_id: String) -> bool:
	return _hints.has(puzzle_id)


## As chaves das dicas do puzzle, do nível 1 ao 3.
func hints(puzzle_id: String) -> Array:
	return _hints.get(puzzle_id, [])


## A cena que oferece a dica `level` (1 a 3; acima disso, a 3), no formato de NAR-dialogo; vazia se
## o puzzle não tem dicas (regra 3).
func scene(puzzle_id: String, level: int) -> Dictionary:
	if not has_hints(puzzle_id):
		return {}
	var n := clampi(level, 1, LEVELS)
	return {"inicio": "pergunta", "falas": {
		"pergunta": {"quem": "serpente", "texto": "SERPENTE_DICA_PERGUNTA_%d" % n, "opcoes": [
			{"texto": "SERPENTE_DICA_SIM", "proxima": HINT_LINE},
			{"texto": "SERPENTE_DICA_NAO", "proxima": "nao"},
		]},
		HINT_LINE: {"quem": "serpente", "texto": str(_hints[puzzle_id][n - 1])},
		"nao": {"quem": "serpente", "texto": "SERPENTE_DICA_DEPOIS"},
	}}


static func validate(data: Variant, has_text := Callable()) -> Array[String]:
	if not has_text.is_valid():
		has_text = func(key: String) -> bool: return TranslationServer.translate(key) != key
	var found: Array[String] = []
	if not data is Dictionary:
		found.append("dicas: o arquivo precisa ser um objeto JSON")
		return found
	for puzzle_id: String in data:
		var keys: Array = data[puzzle_id] if data[puzzle_id] is Array else []
		if keys.size() != LEVELS:
			found.append("dicas, puzzle %s: precisa de %d dicas (tem %d)" % [puzzle_id, LEVELS, keys.size()])
		for key: Variant in keys:
			if not has_text.call(str(key)):
				found.append("dicas, puzzle %s: texto \"%s\" não existe em textos.csv" % [puzzle_id, key])
	return found
