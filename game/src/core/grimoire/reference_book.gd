class_name ReferenceBook
extends RefCounted
## Páginas de referência do grimório (spec GRI-referencia, regras 1 a 4): content/referencia.json.
## Título e texto são as chaves REF_<ID>_TITULO e REF_<ID>_TEXTO do textos.csv.

const DEFAULT_PATH := "res://content/referencia.json"

var errors: Array[String] = []

var _pages: Array = []


static func load_file(path: String) -> ReferenceBook:
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text) if not text.is_empty() else null
	if data == null:
		var book := ReferenceBook.new()
		book.errors.append("referência: não deu para ler %s" % path)
		return book
	return from_data(data)


## `has_text`: se a chave existe no textos.csv (os testes trocam).
static func from_data(data: Variant, has_text := Callable()) -> ReferenceBook:
	var book := ReferenceBook.new()
	book.errors = validate(data, has_text)
	if data is Array:
		book._pages = (data as Array).filter(func(page: Variant) -> bool: return page is Dictionary and page.has("id"))
	return book


## Ids das páginas cujas peças estão todas desbloqueadas, na ordem do arquivo (regra 3).
func visible_pages(unlocked: PackedStringArray) -> Array[String]:
	var ids: Array[String] = []
	for page: Dictionary in _pages:
		var required: Array = page.get("requer", [])
		if required.all(func(piece: Variant) -> bool: return str(piece) in unlocked):
			ids.append(str(page["id"]))
	return ids


func title(page_id: String) -> String:
	return tr(title_key(page_id))


func text(page_id: String) -> String:
	return tr(text_key(page_id))


static func title_key(page_id: String) -> String:
	return "REF_%s_TITULO" % page_id.to_upper()


static func text_key(page_id: String) -> String:
	return "REF_%s_TEXTO" % page_id.to_upper()


static func validate(data: Variant, has_text := Callable()) -> Array[String]:
	if not has_text.is_valid():
		has_text = func(key: String) -> bool: return TranslationServer.translate(key) != key
	var found: Array[String] = []
	if not data is Array:
		found.append("referência: o arquivo precisa ser uma lista de páginas")
		return found
	var seen := {}
	for i in (data as Array).size():
		var page: Variant = data[i]
		if not page is Dictionary or not (page as Dictionary).has("id"):
			found.append("referência, página %d: falta \"id\"" % (i + 1))
			continue
		var page_id := str(page["id"])
		var where := "referência, página %s:" % page_id
		if seen.has(page_id):
			found.append("%s id repetido" % where)
			continue
		seen[page_id] = true
		for piece: Variant in page.get("requer", []):
			if not str(piece) in MagoState.ALL_PIECES:
				found.append("%s peça \"%s\" não existe" % [where, piece])
		for key in [title_key(page_id), text_key(page_id)]:
			if not has_text.call(key):
				found.append("%s texto \"%s\" não existe em textos.csv" % [where, key])
	return found
