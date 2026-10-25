extends GdUnitTestSuite
## Spec: docs/specs/puzzles/PUZ-passo-a-passo.md (PUZ-012 a 014)

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_passo.json"
const CODE := "meditar()\nmeditar()\nmover(1)"

var world: World
var fake: FakeSpellExecutor


func _start(room_id: String) -> void:
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = room_id
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	fake = auto_free(FakeSpellExecutor.new())
	add_child(fake)
	world.executor = fake
	world.grimoire.create("Passos", CODE)
	world.grimoire.equip(1, "Passos")
	fake.queue_result({"ok": true, "custo_mana": 1.3, "saidas": [], "mago": world.state.to_spell_mago(), "acoes": [
		{"tipo": "meditar", "linha": 1}, {"tipo": "meditar", "linha": 2}, {"tipo": "mover", "passos": 1, "linha": 3},
	]})
	for i in 3:
		await get_tree().physics_frame


func after_test() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(GRIMOIRE_PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func test_PUZ_012_painel_destaca_a_linha() -> void:
	await _start("sala_puzzle")
	await world.cast(1)
	assert_bool(world.step_view.is_showing()).is_true()
	assert_str(world.step_view.code_text()).is_equal(CODE)
	await world.action_player.finished
	assert_array(world.step_view.highlighted_lines).is_equal([1, 2, 3])


## Regressão (Sprint 8, achado em captura de tela): o painel cobria a metade de baixo da tela,
## onde ficam o mago, o cristal e a porta. Ele fica no alto, sem cobrir o HUD nem o registro.
func test_PUZ_012_painel_nao_cobre_a_acao() -> void:
	await _start("sala_puzzle")
	await world.cast(1)
	await get_tree().process_frame
	var panel := world.step_view.panel_rect()
	assert_float(panel.end.y).is_less_equal(180.0)
	assert_float(panel.position.x).is_greater_equal(96.0)
	assert_float(panel.end.x).is_less_equal(330.0)


func test_PUZ_013_velocidade() -> void:
	await _start("sala_puzzle")
	assert_float(world.action_player.step_delay).is_equal_approx(0.3, 0.001)
	world.cycle_step_speed()
	assert_float(world.step_speed).is_equal(2.0)
	assert_float(world.action_player.step_delay).is_equal_approx(0.15, 0.001)
	world.cycle_step_speed()
	assert_float(world.step_speed).is_equal(0.5)
	assert_float(world.action_player.step_delay).is_equal_approx(0.6, 0.001)
	world.cycle_step_speed()
	assert_float(world.step_speed).is_equal(1.0)
	assert_str(world.step_view.speed_text()).contains("1")


func test_PUZ_014_fora_de_puzzle_nao_aparece() -> void:
	await _start("sala_aberta")
	assert_float(world.action_player.step_delay).is_equal(0.0)
	await world.cast(1)
	assert_bool(world.step_view.is_showing()).is_false()
