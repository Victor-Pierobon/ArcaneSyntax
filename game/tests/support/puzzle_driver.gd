class_name PuzzleDriver
extends Node
## Joga uma sala de puzzle DO JOGO com o Python de verdade, como um jogador faria:
## posiciona o mago, conjura feitiços pelo grimório e espera as ações acontecerem.
## Usado pelos testes de aceitação (tests/acceptance/).

const WORLD := "res://src/nodes/world/world.tscn"

var world: World
var grimoire_path := ""

var _spell_count := 0


## Sobe o mundo na sala, com a semente fixa e o mago parado na entrada A.
func start(room_id: String, p_grimoire_path: String, seed := 42) -> void:
	grimoire_path = p_grimoire_path
	world = load(WORLD).instantiate()
	world.start_room = room_id
	world.grimoire_path = grimoire_path
	world.rng.seed = seed
	add_child(world)
	stand_still()
	await frames(3)


func cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(grimoire_path + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func stand_still() -> void:
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()


func room() -> Room:
	return world.current_room


## Célula do dígito no layout da sala atual.
func cell_of(digit: String) -> Vector2i:
	return room().data.targets[digit]


## Põe os pés do mago no fundo da célula.
func place(cell: Vector2i) -> void:
	world.player.global_position = room().global_position + RoomLayout.cell_feet(cell)
	world.player.velocity = Vector2.ZERO
	await frames(3)


## Anda até encostar em algo ou chegar em `x` (no máximo `max_frames`).
func walk_until_x(x: float, max_frames := 240) -> void:
	var direction := signf(x - world.player.global_position.x)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make(direction)
	var last := world.player.global_position.x
	var stuck := 0
	for i in max_frames:
		await get_tree().physics_frame
		var now := world.player.global_position.x
		if (x - now) * direction <= 1.0:
			break
		stuck = stuck + 1 if absf(now - last) < 0.1 else 0
		last = now
		if stuck > 10:
			break
	stand_still()
	await frames(5)


## Fixa os valores das runas (o sorteio de verdade é testado à parte, PUZ-019).
func set_runes(values: Array) -> void:
	var runes := room().runes()
	for i in values.size():
		runes[i].value = values[i]


## Conjura `code` pelo slot 1. `fill_mana`: enche a mana antes (o que se testa é a lógica).
func cast(code: String, fill_mana := true, wait_frames := 45) -> SpellResult:
	if fill_mana:
		world.state.set_mana(world.state.mana_max)
	_spell_count += 1
	var spell_name := "Solução %d" % _spell_count
	world.grimoire.create(spell_name, code)
	world.grimoire.equip(1, spell_name)
	var results: Array[SpellResult] = []
	world.spell_cast.connect(func(_slot: int, result: SpellResult) -> void: results.append(result), CONNECT_ONE_SHOT)
	await world.cast(1)
	if world.action_player.is_playing():
		await world.action_player.finished
	await frames(wait_frames)
	return results[0] if not results.is_empty() else null


## Liga `code` como passivo e espera `seconds` de jogo, enchendo a mana a cada quadro.
func run_passive(code: String, seconds: float) -> void:
	_spell_count += 1
	var spell_name := "Passivo %d" % _spell_count
	world.grimoire.create(spell_name, code)
	world.grimoire.set_passive(spell_name)
	var frame_count := int(seconds * Engine.physics_ticks_per_second)
	for i in frame_count:
		world.state.set_mana(world.state.mana_max)
		await get_tree().physics_frame
	world.grimoire.clear_passive()
	await frames(45)
