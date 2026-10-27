extends GdUnitTestSuite
## Spec: docs/specs/grimorio/GRI-slots.md (GRI-040 a 045)

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_conjurar.json"

var world: World
var fake: FakeSpellExecutor


func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	_cleanup()
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = "sala_alvos"
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	fake = auto_free(FakeSpellExecutor.new())
	add_child(fake)
	world.executor = fake
	world.grimoire.create("Fogo", "lancar(fogo, projetil, alvo)")
	world.grimoire.equip(1, "Fogo")
	for i in 3:
		await get_tree().physics_frame


func after_test() -> void:
	get_tree().paused = false
	_cleanup()


func _cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(GRIMOIRE_PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func test_GRI_040_conjurar_envia_o_estado_real() -> void:
	world.state.set_mana(7.0)
	await world.cast(1)
	assert_int(fake.requests.size()).is_equal(1)
	var request: SpellRequest = fake.requests[0]
	assert_str(request.code).is_equal("lancar(fogo, projetil, alvo)")
	assert_float(float(request.mago["mana"])).is_equal(7.0)
	assert_dict(request.target).is_equal({"id": "sala_alvos_alvo_1", "elemento": "fogo", "distancia": 3.0})
	# Tudo menos o que a serpente ensina (MAG-feixe, regra 8).
	var expected := Array(MagoState.ALL_PIECES).filter(func(piece: String) -> bool:
		return not piece in MagoState.LOCKED_AT_START)
	assert_array(Array(request.pieces)).is_equal(expected)


func test_GRI_041_mana_pela_variacao() -> void:
	world.state.set_mana(10.0)
	fake.delay_frames = 3
	fake.queue_result({"ok": true, "acoes": [], "saidas": [], "custo_mana": 3.1, "mago": {"vida": 5, "mana": 6.9, "mana_max": 10}})
	world.cast(1)  # sem await: a resposta demora 3 quadros
	world.state.set_mana(8.0)
	await world.spell_cast
	assert_float(world.state.mana).is_equal_approx(4.9, 0.0001)


func test_GRI_042_registro_de_conjuracao() -> void:
	world.state.set_mana(10.0)
	fake.queue_result({"ok": true, "custo_mana": 3.1, "mago": {"vida": 5, "mana": 6.9, "mana_max": 10},
		"acoes": [{"tipo": "lancar", "linha": 1, "elemento": "fogo", "forma": "projetil", "alvo": "sala_alvos_alvo_1"}],
		"saidas": [{"linha": 1, "texto": "fogo!"}]})
	await world.cast(1)
	var log_text := world.cast_log.text()
	assert_str(log_text).contains("[1] Fogo").contains("lancar fogo projetil").contains("fogo!")


func test_GRI_042_erro_vai_para_o_registro() -> void:
	fake.queue_result({"ok": false, "custo_mana": 0, "acoes": [], "saidas": [], "mago": {"vida": 5, "mana": 0, "mana_max": 10},
		"erro": {"tipo": "ManaEsgotada", "mensagem": "a mana acabou", "linha": 1, "coluna": null}})
	await world.cast(1)
	assert_str(world.cast_log.text()).contains(tr("ERRO_MANA") % 1)


func test_GRI_043_slot_vazio() -> void:
	await world.cast(2)
	assert_int(fake.requests.size()).is_equal(0)
	assert_str(world.cast_log.text()).contains(tr("CONJURAR_SLOT_VAZIO") % 2)


func test_GRI_044_pausado_nao_conjura() -> void:
	world.grimoire_ui.open()
	await world.cast(1)
	assert_int(fake.requests.size()).is_equal(0)


func test_GRI_053_erro_de_conjuracao_fica_guardado_para_o_grimorio() -> void:
	fake.queue_result({"ok": false, "custo_mana": 0, "acoes": [], "saidas": [], "mago": {"vida": 5, "mana": 0, "mana_max": 10},
		"erro": {"tipo": "NameError", "mensagem": "name 'x' is not defined", "linha": 1, "coluna": null}})
	await world.cast(1)
	world.grimoire_ui.open()
	world.grimoire_ui.select("Fogo")
	assert_int(world.grimoire_ui.marked_line).is_equal(1)
	assert_str(world.grimoire_ui.result_label.text).contains("NameError")


func test_GRI_045_de_ponta_a_ponta_com_o_python_de_verdade() -> void:
	var real := PythonSpellExecutor.new()
	add_child(real)
	world.executor = real
	world.grimoire.create("Meditar", "meditar()")
	world.grimoire.equip(2, "Meditar")
	world.state.set_mana(0.0)
	await world.cast(2)
	assert_float(world.state.mana).is_equal_approx(4.8, 0.0001)
	real.queue_free()
