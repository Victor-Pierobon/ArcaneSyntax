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
## Letra maiúscula → célula, na ordem de leitura.
var entries: Dictionary = {}
## Letra minúscula → Array[Vector2i] com as células da saída.
var exits: Dictionary = {}
## Dígito → célula de um boneco de treino (spec MUN-alvos).
var targets: Dictionary = {}
var errors: Array[String] = []


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
	return layout


## Posição dos pés de quem fica em pé no fundo da célula.
static func cell_feet(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)


func size_px() -> Vector2:
	return Vector2(width * TILE, height * TILE)


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
