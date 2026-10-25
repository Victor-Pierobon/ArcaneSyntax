class_name Grimoire
extends RefCounted
## Os feitiços que o jogador escreveu (spec GRI-feiticos).

signal spell_created(spell_name: String)
signal spell_renamed(old_name: String, new_name: String)
signal spell_deleted(spell_name: String)
signal spell_code_changed(spell_name: String)

enum Problem { OK, EMPTY_NAME, NAME_TOO_LONG, DUPLICATE_NAME, NOT_FOUND }

const MAX_NAME_LENGTH := 24

## [{"name": String, "code": String}], na ordem de criação.
var _spells: Array[Dictionary] = []


func names() -> PackedStringArray:
	var result := PackedStringArray()
	for spell in _spells:
		result.append(spell["name"])
	return result


func has_spell(spell_name: String) -> bool:
	return _index_of(spell_name) != -1


func code_of(spell_name: String) -> String:
	var index := _index_of(spell_name)
	return "" if index == -1 else _spells[index]["code"]


func create(spell_name: String, code: String = "") -> Problem:
	var clean := spell_name.strip_edges()
	var problem := _check_name(clean, -1)
	if problem != Problem.OK:
		return problem
	_spells.append({"name": clean, "code": code})
	spell_created.emit(clean)
	return Problem.OK


func rename(old_name: String, new_name: String) -> Problem:
	var index := _index_of(old_name)
	if index == -1:
		return Problem.NOT_FOUND
	var clean := new_name.strip_edges()
	var problem := _check_name(clean, index)
	if problem != Problem.OK:
		return problem
	_spells[index]["name"] = clean
	spell_renamed.emit(old_name, clean)
	return Problem.OK


func delete(spell_name: String) -> Problem:
	var index := _index_of(spell_name)
	if index == -1:
		return Problem.NOT_FOUND
	_spells.remove_at(index)
	spell_deleted.emit(spell_name)
	return Problem.OK


func set_code(spell_name: String, code: String) -> Problem:
	var index := _index_of(spell_name)
	if index == -1:
		return Problem.NOT_FOUND
	if _spells[index]["code"] != code:
		_spells[index]["code"] = code
		spell_code_changed.emit(spell_name)
	return Problem.OK


## "Feitiço N" com o menor N livre (GRI-017).
func next_default_name(prefix: String) -> String:
	var n := 1
	while _find_ignoring_case("%s %d" % [prefix, n], -1) != -1:
		n += 1
	return "%s %d" % [prefix, n]


func to_dict() -> Dictionary:
	var spells := []
	for spell in _spells:
		spells.append({"nome": spell["name"], "codigo": spell["code"]})
	return {"versao": GrimoireStore.FORMAT_VERSION, "feiticos": spells}


## Monta a partir do formato do arquivo. Devolve null se qualquer coisa estiver errada.
static func from_dict(data: Variant) -> Grimoire:
	if not data is Dictionary or data.get("versao") != float(GrimoireStore.FORMAT_VERSION):
		return null
	if not data.get("feiticos") is Array:
		return null
	var grimoire := Grimoire.new()
	for entry: Variant in data["feiticos"]:
		if not entry is Dictionary or not entry.get("nome") is String or not entry.get("codigo") is String:
			return null
		if grimoire.create(entry["nome"], entry["codigo"]) != Problem.OK:
			return null
	return grimoire


func _check_name(clean: String, ignore_index: int) -> Problem:
	if clean.is_empty():
		return Problem.EMPTY_NAME
	if clean.length() > MAX_NAME_LENGTH:
		return Problem.NAME_TOO_LONG
	if _find_ignoring_case(clean, ignore_index) != -1:
		return Problem.DUPLICATE_NAME
	return Problem.OK


func _index_of(spell_name: String) -> int:
	for i in _spells.size():
		if _spells[i]["name"] == spell_name:
			return i
	return -1


func _find_ignoring_case(spell_name: String, ignore_index: int) -> int:
	var lowered := spell_name.to_lower()
	for i in _spells.size():
		if i != ignore_index and _spells[i]["name"].to_lower() == lowered:
			return i
	return -1
