class_name Room
extends Node2D
## Uma sala da torre, montada a partir do layout em texto (spec MUN-salas).

signal exit_touched(target_room: String, target_entry: String)
signal hazard_touched
signal safe_point_touched(feet: Vector2)
## O puzzle da sala foi resolvido (spec PUZ-validacao).
signal puzzle_solved(puzzle_id: String)
## Um inimigo encostou no mago (spec COM-dano, regra 4); `from` é a posição do inimigo.
signal player_attacked(from: Vector2, amount: int)
## O chefe da sala foi derrotado (spec COM-chefe, regra 7).
signal boss_defeated(room_id: String)
## O mago abriu um baú (spec MUN-segredos).
signal secret_found(secret_id: String)

const TILESET := preload("res://assets/placeholder/tiles.tres")
const ATLAS_STONE := Vector2i(0, 0)
const ATLAS_PLATFORM := Vector2i(1, 0)
const ATLAS_SPIKES := Vector2i(2, 0)
const TILE := RoomLayout.TILE

@export var room_id: String = ""
@export_multiline var layout: String = ""
## Letra da saída → "sala:Entrada", ex.: {"b": "sala_02:A"}.
@export var exits: Dictionary = {}
## Dígito → o que ele é: elemento de boneco ({"1": "fogo"}, spec MUN-alvos), "cristal[:...]",
## "runa:<n>" ou "runa:?", "cadeado:soma", "gravura:<texto>" (spec PUZ-validacao) ou
## "inimigo:elemental[:<elemento>]", "inimigo:enxame[:<n>]", "inimigo:guardiao" (spec COM-dano) ou
## "inimigo:chefe" (spec COM-chefe) ou "serpente:<cena>" (spec NAR-dialogo) ou "segredo" (MUN-segredos) ou
## "fonte" (MUN-vida).
@export var targets: Dictionary = {}
## {"id": "p01_meditar", "condicoes": [{"tipo": "cristais_acesos"}]} ou vazio (spec PUZ-validacao).
@export var puzzle: Dictionary = {}
## Entrada pela qual o mago abre a porta de atalho (`%`) por trás, ex.: "C" (spec MUN-mapa, regra 5).
@export var atalho_entrada: String = ""

var data: RoomLayout
var tiles: TileMapLayer
var errors: Array[String] = []
## Sorteio das runas `?` e dos cristais mutáveis; o World passa o dele antes de pôr a sala na árvore.
var rng: RandomNumberGenerator
var bridge: Bridge
## O mago, para os inimigos reagirem a ele; o World passa antes de pôr a sala na árvore.
var player: Node2D
## Chefe já derrotado: a sala nasce sem ele e com a porta aberta; o World passa antes de pôr a sala na árvore.
var boss_beaten := false
## Baús já abertos (id → true): nascem abertos; o World passa antes de pôr a sala na árvore.
var found_secrets: Dictionary = {}

var _areas: Array[Area2D] = []
var _crystals: Dictionary = {}
var _door: RuneDoor
var _shortcut_door: RuneDoor
var _solved := false
## Runas da esquerda para a direita (empate: de cima para baixo), como `ler_runa` as numera.
var _runes: Array[Rune] = []
var _locks: Dictionary = {}
var _plates: Array[PressurePlate] = []
## Textos gravados na parede (regra 16), da esquerda para a direita.
var _engravings: Array[Label] = []
var _enemies: Array[Enemy] = []
var _serpents: Array[Serpent] = []
var _chests: Array[Chest] = []
var _fountains: Array[Fountain] = []


func _ready() -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
	data = RoomLayout.parse(layout)
	errors.append_array(data.errors)
	_build_tiles()
	_build_exits()
	_build_targets()
	_build_puzzle()
	if boss_beaten and _door:
		_door.open()
	for cell in data.spikes:
		_add_area(Rect2(cell.x * TILE + 2, cell.y * TILE + TILE / 2.0, TILE - 4, TILE / 2.0), hazard_touched.emit)
	for cell in data.safe_points:
		var feet := global_position + RoomLayout.cell_feet(cell)
		_add_area(Rect2(Vector2(cell * TILE), Vector2(TILE, TILE)), safe_point_touched.emit.bind(feet))
	for error in errors:
		push_warning("sala %s: %s" % [room_id, error])
	_activate_areas_after_first_frame()


## As áreas nascem desligadas: no quadro em que a sala entra, o servidor de física ainda
## pode ter o mago na posição da sala anterior e disparar espinhos ou saídas por engano.
func _activate_areas_after_first_frame() -> void:
	await get_tree().physics_frame
	for area in _areas:
		if is_instance_valid(area):
			area.set_deferred(&"monitoring", true)
	for plate in _plates:
		plate.set_deferred(&"monitoring", true)


func has_puzzle() -> bool:
	return not puzzle.is_empty()


func puzzle_id() -> String:
	return str(puzzle.get("id", ""))


func is_solved() -> bool:
	return _solved


## Foto do estado da sala para o PuzzleValidator.
func puzzle_state() -> Dictionary:
	var crystals := {}
	for digit: String in _crystals:
		crystals[digit] = _crystals[digit].lit
	var locks := {}
	for digit: String in _locks:
		locks[digit] = _locks[digit].is_open
	var bridge_state := {"feitos": bridge.built() if bridge else 0, "total": bridge.total() if bridge else 0}
	return {
		"cristais": crystals,
		"cadeados": locks,
		"ponte": bridge_state,
		"placas": _plates.map(func(plate: PressurePlate) -> bool: return plate.is_pressed),
	}


## O que a sala mostra ao feitiço (EXE-protocolo, regra 7); vazio se não há nada.
func spell_room() -> Dictionary:
	if _runes.is_empty():
		return {}
	return {"runas": _runes.map(func(rune: Rune) -> int: return rune.value)}


## Inimigos ainda não derrotados.
func enemies() -> Array[Enemy]:
	var alive: Array[Enemy] = []
	for enemy in _enemies:
		if is_instance_valid(enemy) and not enemy.is_defeated():
			alive.append(enemy)
	return alive


func serpents() -> Array[Serpent]:
	return _serpents


func chests() -> Array[Chest]:
	return _chests


func fountains() -> Array[Fountain]:
	return _fountains


## A porta de atalho (`%`) está aberta; true se a sala não tem uma.
func shortcut_open() -> bool:
	return _shortcut_door == null or _shortcut_door.is_open


func open_shortcut() -> void:
	if _shortcut_door:
		_shortcut_door.open()


func runes() -> Array[Rune]:
	return _runes


func engravings() -> Array[String]:
	var texts: Array[String] = []
	for label in _engravings:
		texts.append(label.text)
	return texts


## `inscrever(valor)` vindo de `from` (os pés do mago): o cadeado mais perto no alcance recebe o valor.
## Devolve "aberto", "errado", "longe" ou "sem_cadeado".
func inscribe(value: float, from: Vector2) -> String:
	if _locks.is_empty():
		return "sem_cadeado"
	var best: RuneLock = null
	var best_distance := INF
	for lock: RuneLock in _locks.values():
		var distance := from.distance_to(lock.global_position)
		if distance < best_distance:
			best = lock
			best_distance = distance
	if best_distance > RuneLock.REACH_TILES * TILE + 0.5:
		return "longe"
	return "aberto" if best.inscribe(value, _rune_sum()) else "errado"


## `construir_bloco()`: false se a sala não tem ponte ou ela já está pronta.
func build_block() -> bool:
	return bridge != null and bridge.build_next()


func lock_position() -> Variant:
	return null if _locks.is_empty() else _locks.values()[0].global_position


func _rune_sum() -> int:
	var total := 0
	for rune in _runes:
		total += rune.value
	return total


## Sala de um puzzle já resolvido: cristais acesos e portas abertas, sem avisar de novo (PUZ-006).
func apply_solved() -> void:
	_solved = true
	for crystal: Crystal in _crystals.values():
		crystal.lit = true
		crystal._refresh_color()
	for lock: RuneLock in _locks.values():
		lock.open()
	if bridge:
		bridge.complete()
	for plate in _plates:
		plate.press()
	if _door:
		_door.open()


func doors_open() -> bool:
	return _door == null or _door.is_open


func bounds() -> Rect2:
	return Rect2(global_position, data.size_px())


func has_entry(letter: String) -> bool:
	return data.entries.has(letter)


func first_entry() -> String:
	return "" if data.entries.is_empty() else data.entries.keys()[0]


func entry_feet(letter: String) -> Vector2:
	return global_position + RoomLayout.cell_feet(data.entries[letter])


func _build_tiles() -> void:
	tiles = TileMapLayer.new()
	tiles.name = "Tiles"
	tiles.tile_set = TILESET
	add_child(tiles)
	for cell in data.solids:
		tiles.set_cell(cell, 0, ATLAS_STONE)
	for cell in data.platforms:
		tiles.set_cell(cell, 0, ATLAS_PLATFORM)
	for cell in data.spikes:
		tiles.set_cell(cell, 0, ATLAS_SPIKES)


func _build_exits() -> void:
	for letter: String in data.exits:
		var target := str(exits.get(letter, ""))
		var parts := target.split(":")
		if parts.size() != 2:
			errors.append("saída '%s' sem destino válido (use \"sala:Entrada\")" % letter)
			continue
		for cell: Vector2i in data.exits[letter]:
			_add_area(Rect2(Vector2(cell * TILE), Vector2(TILE, TILE)), exit_touched.emit.bind(parts[0], parts[1]))


func _build_targets() -> void:
	for digit: String in data.targets:
		if not targets.has(digit):
			errors.append("boneco '%s' sem elemento (use targets = {\"%s\": \"fogo\"})" % [digit, digit])
			continue
		var spec := str(targets[digit])
		var cell: Vector2i = data.targets[digit]
		if spec.begins_with("runa:"):
			_add_rune(spec.trim_prefix("runa:"), cell)
			continue
		if spec.begins_with("gravura:"):
			_add_engraving(spec.trim_prefix("gravura:"), cell)
			continue
		if spec.begins_with("inimigo:"):
			_add_enemies(digit, spec, cell)
			continue
		if spec.begins_with("serpente:"):
			var serpent := Serpent.make(spec.trim_prefix("serpente:"))
			serpent.position = RoomLayout.cell_feet(cell)
			serpent.player = player
			_serpents.append(serpent)
			add_child(serpent)
			continue
		if spec == "segredo":
			_add_chest(digit, cell)
			continue
		if spec == "fonte":
			var fountain := Fountain.new()
			fountain.position = RoomLayout.cell_feet(cell)
			fountain.player = player
			_fountains.append(fountain)
			add_child(fountain)
			continue
		if spec.begins_with("cadeado"):
			var lock := RuneLock.make()
			lock.position = RoomLayout.cell_feet(cell)
			lock.opened.connect(_check_puzzle)
			_locks[digit] = lock
			add_child(lock)
			continue
		var target_id := "%s_alvo_%s" % [room_id, digit]
		var target: TrainingTarget
		if spec.begins_with("cristal"):
			var crystal := Crystal.make_crystal(target_id, spec, rng)
			crystal.lit_changed.connect(func(_lit: bool) -> void: _check_puzzle())
			_crystals[digit] = crystal
			target = crystal
		else:
			target = TrainingTarget.make(target_id, spec)
		target.position = RoomLayout.cell_feet(cell)
		add_child(target)
	_runes.sort_custom(func(a: Rune, b: Rune) -> bool:
		return a.position.x < b.position.x or (a.position.x == b.position.x and a.position.y < b.position.y)
	)
	_engravings.sort_custom(func(a: Label, b: Label) -> bool: return a.position.x < b.position.x)


## Um dígito pode virar vários inimigos (o enxame); erros de autoria não criam nada (COM-dano, regra 8).
func _add_enemies(digit: String, spec: String, cell: Vector2i) -> void:
	var parts := spec.split(":")
	var target_id := "%s_alvo_%s" % [room_id, digit]
	var created: Array[Enemy] = []
	match parts[1]:
		"elemental":
			var enemy_element := parts[2] if parts.size() > 2 else "fogo"
			if not enemy_element in Elemental.ELEMENTS:
				errors.append("elemental '%s' com elemento desconhecido (use fogo, gelo ou planta)" % enemy_element)
				return
			var elemental := Elemental.make_elemental(target_id, enemy_element)
			elemental.layout = data
			elemental.position = RoomLayout.cell_feet(cell)
			created.append(elemental)
		"enxame":
			var count := SwarmBug.DEFAULT_COUNT
			if parts.size() > 2:
				count = parts[2].to_int() if parts[2].is_valid_int() else 0
			if count < 1 or count > SwarmBug.MAX_COUNT:
				errors.append("enxame com '%s' bichos (use de 1 a %d)" % [parts[2], SwarmBug.MAX_COUNT])
				return
			for n in count:
				created.append(SwarmBug.make_bug("%s_%d" % [target_id, n + 1], RoomLayout.cell_center(cell), TAU * n / count))
		"guardiao":
			var guardian := Guardian.make_guardian(target_id)
			guardian.position = RoomLayout.cell_feet(cell)
			created.append(guardian)
		"chefe":
			if boss_beaten:
				return
			var boss := Boss.make_boss(target_id)
			boss.position = RoomLayout.cell_feet(cell)
			boss.bolt_hit.connect(player_attacked.emit)
			boss.defeated.connect(_on_boss_defeated)
			created.append(boss)
		_:
			errors.append("inimigo desconhecido '%s' (use elemental, enxame, guardiao ou chefe)" % parts[1])
			return
	for enemy in created:
		enemy.player = player
		enemy.touched_player.connect(func(by: Enemy) -> void: player_attacked.emit(by.global_position, by.contact_damage))
		_enemies.append(enemy)
		add_child(enemy)


## Chefe derrotado: a porta abre e o World guarda para não montar o chefe de novo (COM-chefe, regra 7).
func _on_boss_defeated() -> void:
	boss_beaten = true
	if _door:
		_door.open()
	boss_defeated.emit(room_id)


## Encostar no baú fechado abre e avisa o World uma vez (MUN-segredos, regras 1 e 2).
func _add_chest(digit: String, cell: Vector2i) -> void:
	var secret_id := "%s_%s" % [room_id, digit]
	var chest := Chest.make(secret_id, found_secrets.has(secret_id))
	chest.position = RoomLayout.cell_feet(cell)
	_chests.append(chest)
	add_child(chest)
	_add_area(Rect2(Vector2(cell * TILE), Vector2(TILE, TILE)), func() -> void:
		if chest.open():
			secret_found.emit(secret_id)
	)


func _add_engraving(text: String, cell: Vector2i) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", 10)
	label.add_theme_color_override(&"font_color", Color("ffd27a"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(TILE, TILE)
	label.position = Vector2(cell * TILE)
	_engravings.append(label)
	add_child(label)


func _add_rune(value_spec: String, cell: Vector2i) -> void:
	var value := rng.randi_range(1, 9) if value_spec == "?" else value_spec.to_int()
	if value_spec != "?" and not value_spec.is_valid_int():
		errors.append("runa com valor inválido '%s' (use runa:4 ou runa:?)" % value_spec)
	var rune := Rune.make(value)
	rune.position = RoomLayout.cell_feet(cell)
	_runes.append(rune)
	add_child(rune)


func _build_puzzle() -> void:
	if not data.doors.is_empty():
		_door = RuneDoor.make(data.doors)
		add_child(_door)
	if not data.shortcut_doors.is_empty():
		_shortcut_door = RuneDoor.make(data.shortcut_doors, RuneDoor.COLOR_SHORTCUT)
		_shortcut_door.name = "ShortcutDoor"
		add_child(_shortcut_door)
	if not data.bridge_cells.is_empty():
		bridge = Bridge.make(data.bridge_cells)
		bridge.changed.connect(_check_puzzle)
		add_child(bridge)
	# Da esquerda para a direita, empate de cima para baixo, como as runas (regra 12); não na ordem de leitura.
	var plate_cells := data.plates.duplicate()
	plate_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	for cell: Vector2i in plate_cells:
		var plate := PressurePlate.make(cell)
		plate.pressed.connect(_check_puzzle)
		_plates.append(plate)
		add_child(plate)
	if has_puzzle():
		errors.append_array(PuzzleValidator.authoring_errors(puzzle.get("condicoes", [])))
		if puzzle_id().is_empty():
			errors.append("puzzle sem id")


func _check_puzzle() -> void:
	if _solved or not has_puzzle():
		return
	if PuzzleValidator.evaluate(puzzle.get("condicoes", []), puzzle_state()):
		_solved = true
		if _door:
			_door.open()
		puzzle_solved.emit(puzzle_id())


func _add_area(rect: Rect2, on_player_enter: Callable) -> void:
	var area := Area2D.new()
	area.monitorable = false
	area.monitoring = false
	_areas.append(area)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	shape.position = rect.get_center()
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(func(body: Node2D) -> void:
		if body is Player:
			on_player_enter.call()
	)
