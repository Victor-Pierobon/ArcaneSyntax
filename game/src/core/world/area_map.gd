class_name AreaMap
extends RefCounted
## A área como grafo de células (spec MUN-mapa): por onde o mago passa, o que cada porta exige e em que
## ordem os puzzles abrem. Usado pelos testes do mapa e pelo resumo do fim da demo (UI-menus).
## Toda célula que não é pedra nem porta fechada é passável nas quatro direções, sem gravidade: é o
## máximo que o mago alcança voando (regra 8).

const DOOR := "porta"
const SHORTCUT := "atalho"
const BOSS := "inimigo:chefe"
const SERPENT := "serpente:"
const SECRET := "segredo"
const STEPS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

## id → {"layout", "exits", "targets", "puzzle", "shortcut_entry", e os conjuntos de células "solid",
## "door", "shortcut" e "exit_at" (célula → letra)}.
var _rooms: Dictionary = {}


## Lê todas as salas de uma pasta (no jogo exportado, as cenas aparecem como `.tscn.remap`).
static func load_dir(dir: String) -> AreaMap:
	var area := AreaMap.new()
	for file_name in DirAccess.get_files_at(dir):
		file_name = file_name.trim_suffix(".remap")
		if file_name.get_extension() != "tscn":
			continue
		var room: Room = load(dir.path_join(file_name)).instantiate()
		area.add_room(file_name.get_basename(), room.layout, room.exits, room.targets, room.puzzle, room.atalho_entrada)
		room.free()
	return area


func add_room(id: String, layout_text: String, exits := {}, targets := {}, puzzle := {}, shortcut_entry := "") -> void:
	var layout := RoomLayout.parse(layout_text)
	var exit_at := {}
	for letter: String in layout.exits:
		for cell: Vector2i in layout.exits[letter]:
			exit_at[cell] = letter
	_rooms[id] = {
		"layout": layout, "exits": exits, "targets": targets, "puzzle": puzzle, "shortcut_entry": shortcut_entry,
		"solid": _cell_set(layout.solids), "door": _cell_set(layout.doors), "shortcut": _cell_set(layout.shortcut_doors),
		"exit_at": exit_at,
	}


func room_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_rooms.keys())
	return ids


## As salas para onde as saídas de `id` levam.
func neighbours(id: String) -> Array[String]:
	var found: Array[String] = []
	for target: Variant in _rooms[id]["exits"].values():
		var room := str(target).get_slice(":", 0)
		if not room in found:
			found.append(room)
	return found


## Sala → puzzle, só das salas que têm um.
func puzzles() -> Dictionary:
	var found := {}
	for id: String in _rooms:
		if not _rooms[id]["puzzle"].is_empty():
			found[id] = _rooms[id]["puzzle"]
	return found


## Ids dos baús (`<sala>_<dígito>`, MUN-segredos).
func secret_ids() -> Array[String]:
	var found: Array[String] = []
	for id: String in _rooms:
		var targets: Dictionary = _rooms[id]["targets"]
		for digit: String in targets:
			if str(targets[digit]) == SECRET:
				found.append("%s_%s" % [id, digit])
	return found


## Cenas das serpentes que ensinam (`ensino_*`).
func lesson_ids() -> Array[String]:
	var found: Array[String] = []
	for id: String in _rooms:
		for spec: Variant in _rooms[id]["targets"].values():
			var scene := str(spec).trim_prefix(SERPENT)
			if str(spec).begins_with(SERPENT) and scene.begins_with("ensino_") and not scene in found:
				found.append(scene)
	return found


## Onde o mago chega a partir da entrada, com as portas de `open` abertas ({"sala:porta": true}).
## Devolve as salas, as células por sala, as entradas ("sala:Letra") e as portas fechadas encostadas.
func reach(room_id: String, entry: String, open: Dictionary) -> Dictionary:
	var cells := {}
	var entries := {}
	var doors := {}
	var queue: Array = []
	_enter(room_id, entry, cells, entries, queue)
	while not queue.is_empty():
		var item: Array = queue.pop_back()
		var id: String = item[0]
		var cell: Vector2i = item[1]
		var room: Dictionary = _rooms[id]
		if room["exit_at"].has(cell):
			var target := str(room["exits"].get(room["exit_at"][cell], "")).split(":")
			if target.size() == 2:
				_enter(target[0], target[1], cells, entries, queue)
		for step in STEPS:
			var next := cell + step
			if cells[id].has(next):
				continue
			var blocker := _blocker(id, next, open)
			if blocker.is_empty():
				cells[id][next] = true
				queue.append([id, next])
			elif blocker != "pedra":
				doors["%s:%s" % [id, blocker]] = true
	var rooms := {}
	for id: String in cells:
		rooms[id] = true
	return {"rooms": rooms, "cells": cells, "entries": entries, "doors": doors}


## Anda pelo mapa abrindo cada porta quando ela pode abrir (regra 7): a de puzzle com as serpentes das
## lições já alcançadas, a do chefe ao chegar nele, a de atalho ao chegar na entrada do atalho.
## Devolve as salas alcançadas, os puzzles na ordem em que abriram e as portas abertas e fechadas.
func walkthrough(room_id: String, entry: String) -> Dictionary:
	var open := {}
	var order: Array[String] = []
	while true:
		var reached := reach(room_id, entry, open)
		var changed := false
		for key: String in reached["doors"]:
			if open.has(key) or not _can_open(key, reached):
				continue
			open[key] = true
			changed = true
			var puzzle: Dictionary = _rooms[key.get_slice(":", 0)]["puzzle"]
			if key.ends_with(":" + DOOR) and not puzzle.is_empty():
				order.append(str(puzzle.get("id", "")))
		if not changed:
			var closed: Array[String] = []
			for key: String in reached["doors"]:
				if not open.has(key):
					closed.append(key)
			return {"rooms": reached["rooms"], "puzzles": order, "open": open, "closed": closed}
	return {}


func _can_open(key: String, reached: Dictionary) -> bool:
	var id := key.get_slice(":", 0)
	var room: Dictionary = _rooms[id]
	if key.ends_with(":" + SHORTCUT):
		return not room["shortcut_entry"].is_empty() and reached["entries"].has("%s:%s" % [id, room["shortcut_entry"]])
	if not room["puzzle"].is_empty():
		var lessons: Array = room["puzzle"].get("licoes", [])
		return not lessons.is_empty() and lessons.all(func(lesson: Variant) -> bool: return _serpent_reached(str(lesson), reached))
	return BOSS in room["targets"].values()


func _serpent_reached(lesson: String, reached: Dictionary) -> bool:
	for id: String in reached["cells"]:
		var room: Dictionary = _rooms[id]
		for digit: String in room["targets"]:
			if str(room["targets"][digit]) == SERPENT + lesson and reached["cells"][id].has(room["layout"].targets.get(digit)):
				return true
	return false


func _enter(id: String, entry: String, cells: Dictionary, entries: Dictionary, queue: Array) -> void:
	if not _rooms.has(id) or not _rooms[id]["layout"].entries.has(entry):
		return
	entries["%s:%s" % [id, entry]] = true
	if not cells.has(id):
		cells[id] = {}
	var cell: Vector2i = _rooms[id]["layout"].entries[entry]
	if not cells[id].has(cell):
		cells[id][cell] = true
		queue.append([id, cell])


## "" se a célula é passável; senão "pedra" ou o tipo da porta fechada.
func _blocker(id: String, cell: Vector2i, open: Dictionary) -> String:
	var room: Dictionary = _rooms[id]
	var layout: RoomLayout = room["layout"]
	if cell.x < 0 or cell.y < 0 or cell.x >= layout.width or cell.y >= layout.height or room["solid"].has(cell):
		return "pedra"
	if room["door"].has(cell) and not open.has("%s:%s" % [id, DOOR]):
		return DOOR
	if room["shortcut"].has(cell) and not open.has("%s:%s" % [id, SHORTCUT]):
		return SHORTCUT
	return ""


static func _cell_set(cells: Array[Vector2i]) -> Dictionary:
	var result := {}
	for cell in cells:
		result[cell] = true
	return result
