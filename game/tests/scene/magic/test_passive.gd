extends GdUnitTestSuite
## Spec: docs/specs/magia/MAG-passivo.md (MAG-051 a 059), com o mundo de verdade.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_passivo_mundo.json"

var world: World
var fake: FakeSpellExecutor


func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	_cleanup()
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = "sala_aberta"
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	fake = auto_free(FakeSpellExecutor.new())
	add_child(fake)
	world.executor = fake


func after_test() -> void:
	get_tree().paused = false
	_cleanup()


func _cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(GRIMOIRE_PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func _seconds(value: float) -> void:
	await get_tree().create_timer(value).timeout


func _equip_passive(code: String) -> void:
	world.grimoire.create("Passivo", code)
	world.grimoire.set_passive("Passivo")


func _error(type: String) -> Dictionary:
	return {"ok": false, "custo_mana": 0, "acoes": [], "saidas": [], "mago": world.state.to_spell_mago(),
		"erro": {"tipo": type, "mensagem": "x", "linha": 1, "coluna": null}}


func test_MAG_051_roda_a_cada_segundo_com_o_estado_real() -> void:
	world.state.set_mana(3.0)
	_equip_passive("absorver_mana()")
	fake.queue_result({"ok": true, "acoes": [], "saidas": [], "custo_mana": 0.1, "mago": {"vida": 5, "mana": 3.9, "mana_max": 10}})
	await _seconds(1.3)
	assert_int(fake.requests.size()).is_equal(1)
	assert_str(fake.requests[0].code).is_equal("absorver_mana()")
	assert_float(float(fake.requests[0].mago["mana"])).is_equal(3.0)
	assert_float(world.state.mana).is_equal_approx(3.9, 0.0001)
	await _seconds(1.0)
	assert_int(fake.requests.size()).is_equal(2)


func test_MAG_052_sem_sobreposicao() -> void:
	_equip_passive("absorver_mana()")
	fake.delay_frames = 150  # ~2,5 s por execução
	await _seconds(2.6)
	assert_int(fake.requests.size()).is_equal(1)


func test_MAG_053_pausado_nao_roda() -> void:
	_equip_passive("absorver_mana()")
	world.grimoire_ui.open()
	await _seconds(1.5)
	# O grimório aberto pede a estimativa de custo (mana 1000); essa pode. O passivo não.
	var passive_requests := fake.requests.filter(func(r: SpellRequest) -> bool: return float(r.mago["mana_max"]) != GrimoireUI.ESTIMATE_MANA)
	assert_array(passive_requests).is_empty()


func test_MAG_054_erro_desliga_e_editar_religa() -> void:
	_equip_passive("print(x)")
	fake.queue_result(_error("NameError"))
	await _seconds(2.5)
	assert_int(fake.requests.size()).is_equal(1)
	assert_str(world.cast_log.text()).contains(tr("PASSIVO_DESLIGADO") % "Passivo")
	world.grimoire.set_code("Passivo", "absorver_mana()")
	await _seconds(1.2)
	assert_int(fake.requests.size()).is_equal(2)


func test_MAG_055_mana_esgotada_nao_desliga() -> void:
	_equip_passive("lancar(fogo, projetil)")
	fake.queue_result(_error("ManaEsgotada"))
	fake.queue_result(_error("ManaEsgotada"))
	await _seconds(2.3)
	assert_int(fake.requests.size()).is_equal(2)
	var log_text := world.cast_log.text()
	assert_int(log_text.count(tr("PASSIVO_SEM_MANA") % "Passivo")).is_equal(1)
	assert_bool(world.passive_scheduler.is_disabled()).is_false()


func test_MAG_056_nao_atrasa_as_conjuracoes() -> void:
	_equip_passive("meditar()")
	fake.queue_result({"ok": true, "custo_mana": 0, "saidas": [], "mago": world.state.to_spell_mago(), "acoes": [{"tipo": "meditar", "linha": 1}]})
	await _seconds(1.1)
	assert_bool(world.passive_player.is_playing()).is_true()
	world.grimoire.create("Andar", "mover(1)")
	world.grimoire.equip(1, "Andar")
	fake.queue_result({"ok": true, "custo_mana": 1.1, "saidas": [], "mago": world.state.to_spell_mago(), "acoes": [{"tipo": "mover", "passos": 1, "linha": 1}]})
	await world.cast(1)
	assert_bool(world.action_player.is_playing()).is_true()


func test_MAG_057_hud_mostra_o_passivo() -> void:
	assert_str(world.hud.passive_label.text).is_equal(tr("HUD_PASSIVO_VAZIO"))
	_equip_passive("print(x)")
	await get_tree().process_frame
	assert_str(world.hud.passive_label.text).is_equal(tr("HUD_PASSIVO") % "Passivo")
	fake.queue_result(_error("NameError"))
	await _seconds(1.3)
	assert_str(world.hud.passive_label.text).is_equal(tr("HUD_PASSIVO_DESLIGADO") % "Passivo")


func _use_real_executor() -> PythonSpellExecutor:
	var real := PythonSpellExecutor.new()
	add_child(real)
	world.executor = real
	return real


func test_MAG_058_passivo_do_gdd_enche_a_mana() -> void:
	var real := _use_real_executor()
	world.state.set_mana(0.0)
	_equip_passive("while mana < mana_max:\n    absorver_mana()")
	await _seconds(3.0)
	assert_float(world.state.mana).is_equal(world.state.mana_max)
	real.queue_free()


func test_MAG_059_checar_antes_economiza_e_o_ruim_e_desligado() -> void:
	var real := _use_real_executor()
	world.state.set_mana(10.0)
	_equip_passive("if mana < mana_max:\n    absorver_mana()")
	await _seconds(2.3)
	assert_float(world.state.mana).is_equal(10.0)
	world.grimoire.create("Ruim", "while True:\n    absorver_mana()")
	world.grimoire.set_passive("Ruim")
	await _seconds(2.0)
	assert_bool(world.passive_scheduler.is_disabled()).is_true()
	assert_str(world.cast_log.text()).contains("LimiteExcedido")
	real.queue_free()
