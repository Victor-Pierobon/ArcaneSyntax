extends GdUnitTestSuite
## Aceitação: docs/specs/puzzles/PUZ-01-meditar.md (PUZ-020 a 022).
## Usa a sala_01 DO JOGO e o Python de verdade: soluções que devem passar e que devem falhar.
## O jogo nunca compara código com gabarito; só o estado do mundo decide.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_puz01.json"
const PUZZLE := "p01_meditar"
## Perto do cristal (coluna 50 da sala_01), olhando para ele.
const NEAR_CRYSTAL := Vector2(46 * 16 + 8, 21 * 16)

var world: World


func before_test() -> void:
	world = auto_free(load(WORLD).instantiate())
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	for i in 3:
		await get_tree().physics_frame
	world.player.global_position = NEAR_CRYSTAL
	world.state.set_mana(0.0)
	for i in 3:
		await get_tree().physics_frame


func after_test() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(GRIMOIRE_PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func _cast(slot_number: int, code: String) -> void:
	var spell_name := "Solução %d" % slot_number
	world.grimoire.create(spell_name, code)
	world.grimoire.equip(slot_number, spell_name)
	await world.cast(slot_number)
	if world.action_player.is_playing():
		await world.action_player.finished
	for i in 45:
		await get_tree().physics_frame


func _assert_solved(expected: bool, label: String) -> void:
	assert_bool(world.is_puzzle_solved(PUZZLE)).override_failure_message("solução %s" % label).is_equal(expected)
	assert_bool(world.current_room.doors_open()).override_failure_message("porta, solução %s" % label).is_equal(expected)


func test_PUZ_020_A_sequencia_num_feitico() -> void:
	await _cast(1, "meditar()\nlancar(fogo, projetil, alvo)")
	_assert_solved(true, "A")


func test_PUZ_020_B_dois_feiticos() -> void:
	await _cast(1, "meditar()")
	await _cast(2, "lancar(gelo, projetil, alvo)")
	_assert_solved(true, "B")


func test_PUZ_020_C_loop_para_juntar_mana() -> void:
	await _cast(1, "while mana < 5:\n    absorver_mana()\nlancar(raio, projetil, alvo)")
	_assert_solved(true, "C")


func test_PUZ_021_X_sem_mana() -> void:
	await _cast(1, "lancar(fogo, projetil, alvo)")
	_assert_solved(false, "X")


func test_PUZ_021_Y_escudo_nao_atinge() -> void:
	await _cast(1, "meditar()\nlancar(fogo, escudo)")
	_assert_solved(false, "Y")


func test_PUZ_022_cajado_nao_resolve() -> void:
	world.player.global_position = Vector2(50 * 16 + 8 - 14, 21 * 16)
	for i in 3:
		await get_tree().physics_frame
	world.world_actions.staff_attack()
	for i in 10:
		await get_tree().physics_frame
	_assert_solved(false, "cajado")
