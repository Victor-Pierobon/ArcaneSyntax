class_name RoomLayout
extends RefCounted
## Lê o layout em texto de uma sala, um caractere por tile (spec MUN-salas).

const TILE := 16

var width := 0
var height := 0
var solids: Array[Vector2i] = []
var platforms: Array[Vector2i] = []
var spikes: Array[Vector2i] = []
var safe_points: Array[Vector2i] = []
## Células de porta de runas (`|`, spec PUZ-validacao).
var doors: Array[Vector2i] = []
## Células da porta de atalho (`%`, Sprint 14, spec MUN-mapa).
var shortcut_doors: Array[Vector2i] = []
## Vãos de ponte (`~`) e placas de pressão (`_`), Sprint 9 (spec PUZ-validacao).
var bridge_cells: Array[Vector2i] = []
var plates: Array[Vector2i] = []
## Letra maiúscula → célula, na ordem de leitura.
var entries: Dictionary = {}
## Letra minúscula → Array[Vector2i] com as células da saída.
var exits: Dictionary = {}
## Dígito → célula de um boneco de treino (spec MUN-alvos).
var targets: Dictionary = {}
var errors: Array[String] = []
## Plataformas que se movem: {"start": primeira célula, "width", "end": primeira célula no outro extremo}
## (MUN-plataformas, regra 1).
var moving_platforms: Array[Dictionary] = []
## Plataformas que caem: um retângulo de uma linha por plataforma.
var falling_platforms: Array[Rect2i] = []

var _movers: Array[Vector2i] = []
var _path_ends: Array[Vector2i] = []
var _fallers: Array[Vector2i] = []


static func parse(text: String) -> RoomLayout:
	var layout := RoomLayout.new()
	var lines := text.split("\n")
	if not lines.is_empty() and lines[-1].strip_edges().is_empty():
		lines.remove_at(lines.size() - 1)
	layout.height = lines.size()
	for y in lines.size():
		var line: String = lines[y].trim_suffix("\r")
		layout.width = maxi(layout.width, line.length())
		for x in line.length():
			layout._read(line[x], Vector2i(x, y))
	layout._build_platforms()
	return layout


## Posição dos pés de quem fica em pé no fundo da célula.
static func cell_feet(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)


func size_px() -> Vector2:
	return Vector2(width * TILE, height * TILE)


## Topo do primeiro chão (`#` ou `=`) na coluna de `point`, da célula dele para baixo, no meio da
## coluna (pilares do chefe, COM-chefe, regra 12). Sem chão, o fundo da sala.
func floor_below(point: Vector2) -> Vector2:
	var column := floori(point.x / TILE)
	for y in range(maxi(floori(point.y / TILE), 0), height):
		var cell := Vector2i(column, y)
		if cell in solids or cell in platforms:
			return Vector2(column * TILE + TILE / 2.0, y * TILE)
	return Vector2(column * TILE + TILE / 2.0, height * TILE)


func _read(c: String, cell: Vector2i) -> void:
	match c:
		"#":
			solids.append(cell)
		"=":
			platforms.append(cell)
		"^":
			spikes.append(cell)
		"*":
			safe_points.append(cell)
		"|":
			doors.append(cell)
		"%":
			shortcut_doors.append(cell)
		"~":
			bridge_cells.append(cell)
		"_":
			plates.append(cell)
		"-":
			_fallers.append(cell)
		">":
			_movers.append(cell)
		"+":
			_path_ends.append(cell)
		".", " ":
			pass
		_:
			if c >= "A" and c <= "Z":
				if entries.has(c):
					errors.append("entrada %s repetida na linha %d, coluna %d" % [c, cell.y + 1, cell.x + 1])
				else:
					entries[c] = cell
			elif c >= "1" and c <= "9":
				if targets.has(c):
					errors.append("boneco %s repetido na linha %d, coluna %d" % [c, cell.y + 1, cell.x + 1])
				else:
					targets[c] = cell
			elif c >= "a" and c <= "z":
				if not exits.has(c):
					exits[c] = [] as Array[Vector2i]
				exits[c].append(cell)
			else:
				errors.append("caractere desconhecido '%s' na linha %d, coluna %d" % [c, cell.y + 1, cell.x + 1])


## Junta as células `-` e `>` em plataformas e dá a cada `>` o `+` dela (MUN-plataformas, regras 1 e 2).
func _build_platforms() -> void:
	for run in _runs(_fallers):
		falling_platforms.append(Rect2i(run[0], Vector2i(run[1], 1)))
	var free_ends := _path_ends.duplicate()
	for run in _runs(_movers):
		var start: Vector2i = run[0]
		var width: int = run[1]
		var best: Variant = null
		var best_distance := 0
		for end in free_ends:
			var distance := -1
			if end.y == start.y and end.x > start.x + width - 1:
				distance = end.x - (start.x + width - 1)
			elif end.y == start.y and end.x < start.x:
				distance = start.x - end.x
			elif end.x == start.x and end.y != start.y:
				distance = absi(end.y - start.y)
			if distance > 0 and (best == null or distance < best_distance):
				best = end
				best_distance = distance
		var destination := start
		if best == null:
			errors.append("plataforma que se move sem + no caminho na linha %d, coluna %d" % [start.y + 1, start.x + 1])
		else:
			free_ends.erase(best)
			var end: Vector2i = best
			if end.y != start.y:
				destination = Vector2i(start.x, end.y)
			elif end.x > start.x:
				destination = Vector2i(end.x - width + 1, start.y)
			else:
				destination = end
		moving_platforms.append({"start": start, "width": width, "end": destination})
	for end in free_ends:
		errors.append("+ sem plataforma que se move na linha %d, coluna %d" % [end.y + 1, end.x + 1])


## Sequências na mesma linha: [[primeira célula, largura], ...], em ordem de leitura.
static func _runs(cells: Array[Vector2i]) -> Array:
	var sorted := cells.duplicate()
	sorted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	var runs := []
	for cell: Vector2i in sorted:
		if not runs.is_empty():
			var last: Array = runs[-1]
			if last[0].y == cell.y and last[0].x + last[1] == cell.x:
				last[1] += 1
				continue
		runs.append([cell, 1])
	return runs
