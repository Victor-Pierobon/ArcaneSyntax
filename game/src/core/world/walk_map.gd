class_name WalkMap
extends RefCounted
## Alcance a pé numa sala (spec MUN-salas, regra 9): andar, cair de beiradas e pular, com limites um
## pouco abaixo do pulo de verdade. Serve ao level design: pega degrau alto demais e sala sem volta,
## que o AreaMap (sem gravidade) não pega. As células são as dos pés do mago.

## Vão (tiles vazios entre as beiradas) que o pulo atravessa, pela altura do chão de chegada:
## mesma altura ou abaixo, 1 acima, 2 acima.
const MAX_GAP := [4, 3, 2]
const MAX_RISE := 2

var layout: RoomLayout
## Puzzle resolvido: portas abertas.
var solved: bool
## Ponte construída (por padrão, junto com o puzzle resolvido; a ponte é parte do puzzle da sala).
var bridge_built: bool

var _blocked := {}
var _deadly := {}
var _support := {}
## Ligações que o pulo não explica (as pontas da plataforma que se move na vertical).
var _links := {}


func _init(p_layout: RoomLayout, p_solved := true, p_bridge_built: Variant = null) -> void:
	layout = p_layout
	solved = p_solved
	bridge_built = p_solved if p_bridge_built == null else p_bridge_built
	for cell in layout.solids:
		_blocked[cell] = true
		_support[cell] = true
	for cell in layout.doors + layout.shortcut_doors:
		if not solved:
			_blocked[cell] = true
			_support[cell] = true
	for cell in layout.bridge_cells:
		if bridge_built:
			_blocked[cell] = true
			_support[cell] = true
	for cell in layout.spikes:
		_deadly[cell] = true
	for cell in layout.platforms:
		_support[cell] = true
	for rect in layout.falling_platforms:
		for x in range(rect.position.x, rect.end.x):
			_support[Vector2i(x, rect.position.y)] = true
	for mover in layout.moving_platforms:
		_add_mover(mover)


func _add_mover(mover: Dictionary) -> void:
	var start: Vector2i = mover["start"]
	var end: Vector2i = mover["end"]
	var width: int = mover["width"]
	if start.y == end.y:
		for x in range(mini(start.x, end.x), maxi(start.x, end.x) + width):
			_support[Vector2i(x, start.y)] = true
		return
	for x in range(start.x, start.x + width):
		var low := Vector2i(x, start.y)
		var high := Vector2i(x, end.y)
		_support[low] = true
		_support[high] = true
		_link(low + Vector2i.UP, high + Vector2i.UP)
		_link(high + Vector2i.UP, low + Vector2i.UP)


func _link(from: Vector2i, to: Vector2i) -> void:
	if not _links.has(from):
		_links[from] = []
	_links[from].append(to)


func _inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < layout.width and cell.y < layout.height


## O corpo cabe na célula (pés) e na de cima (cabeça).
func _fits(cell: Vector2i) -> bool:
	var head := cell + Vector2i.UP
	return _inside(cell) and _inside(head) and not _blocked.has(cell) and not _blocked.has(head) \
			and not _deadly.has(cell)


## Dá para ficar em pé com os pés nesta célula.
func standable(cell: Vector2i) -> bool:
	return _fits(cell) and _support.has(cell + Vector2i.DOWN)


## Todas as células de pés alcançáveis a pé a partir de `from` ({célula: true}).
func reach(from: Vector2i) -> Dictionary:
	var seen := {}
	var queue: Array[Vector2i] = []
	var first: Variant = from if standable(from) else _fall(from)
	if first == null:
		return seen
	seen[first] = true
	queue.append(first)
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for next in _neighbours(cell):
			if not seen.has(next):
				seen[next] = true
				queue.append(next)
	return seen


func _neighbours(cell: Vector2i) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for direction in [-1, 1]:
		var side := cell + Vector2i(direction, 0)
		if standable(side):
			found.append(side)
		elif _fits(side):
			var landing: Variant = _fall(side)
			if landing != null:
				found.append(landing)
	for dx in range(-MAX_GAP[0] - 1, MAX_GAP[0] + 2):
		for y in range(cell.y - MAX_RISE, layout.height):
			var target := Vector2i(cell.x + dx, y)
			if target == cell or not standable(target):
				continue
			var rise := cell.y - target.y
			var gap := absi(dx) - 1
			if gap > MAX_GAP[clampi(rise, 0, MAX_RISE)]:
				continue
			if _clear(cell + Vector2i.UP, target + Vector2i.UP):
				found.append(target)
	for linked: Vector2i in _links.get(cell, []):
		if standable(linked):
			found.append(linked)
	return found


## Cai em linha reta da célula até o primeiro chão; null se cair em espinho ou fora da sala.
func _fall(from: Vector2i) -> Variant:
	var cell := from
	while _inside(cell):
		if _deadly.has(cell) or _blocked.has(cell):
			return null
		if standable(cell):
			return cell
		cell += Vector2i.DOWN
	return null


## A linha da cabeça de um lugar ao outro não passa por pedra.
func _clear(from: Vector2i, to: Vector2i) -> bool:
	var steps := maxi(absi(to.x - from.x), absi(to.y - from.y)) * 2
	for i in range(1, steps):
		var point := Vector2(from).lerp(Vector2(to), float(i) / steps)
		if _blocked.has(Vector2i(roundi(point.x), roundi(point.y))):
			return false
	return true
