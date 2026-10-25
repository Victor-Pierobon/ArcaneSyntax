extends GdUnitTestSuite
## Specs: docs/specs/magia/MAG-acoes.md (MAG-004 a 009, 019), MAG-formas.md (MAG-010 a 014)
## e MAG-elementos.md (MAG-033). Salas de teste em res://tests/fixtures/rooms/.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_acoes.json"
## sala_aberta: chão com topo em y = 144, entrada A em x = 40, boneco de fogo em x = 136.
const FLOOR_Y := 144.0

var world: World
var player: Player


func _start(room_id: String) -> void:
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = room_id
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	player = world.player
	player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	await _frames(3)


func after_test() -> void:
	get_tree().paused = false
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(GRIMOIRE_PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _teleport(position: Vector2) -> void:
	player.global_position = position
	player.velocity = Vector2.ZERO
	await _frames(3)


func _play(actions: Array) -> void:
	world.action_player.play(actions)
	if world.action_player.is_playing():
		await world.action_player.finished


func _projectiles() -> Array:
	return get_tree().get_nodes_in_group(Projectile.GROUP)


func _target(id: String) -> TrainingTarget:
	return world.find_target(id)


func test_MAG_004_mover_para_os_dois_lados() -> void:
	await _start("sala_aberta")
	await _teleport(Vector2(120, FLOOR_Y))
	await _play([{"tipo": "mover", "passos": 3, "linha": 1}])
	assert_float(player.global_position.x).is_equal_approx(168.0, 4.0)
	await _play([{"tipo": "mover", "passos": -2, "linha": 1}])
	assert_float(player.global_position.x).is_equal_approx(136.0, 4.0)


func test_MAG_005_mover_contra_a_parede_termina() -> void:
	await _start("sala_aberta")
	await _teleport(Vector2(290, FLOOR_Y))
	var control_before := player.intent_source
	var started := Time.get_ticks_msec()
	await _play([{"tipo": "mover", "passos": 5, "linha": 1}])
	assert_int(Time.get_ticks_msec() - started).is_less(1000)
	assert_bool(player.intent_source == control_before).is_true()


func test_MAG_006_levitar_sobe_e_volta() -> void:
	await _start("sala_aberta")
	var peak := [player.global_position.y]
	var watch := func() -> void: peak[0] = minf(peak[0], player.global_position.y)
	get_tree().physics_frame.connect(watch)
	await _play([{"tipo": "levitar", "altura": 2, "linha": 1}])
	await _frames(60)
	get_tree().physics_frame.disconnect(watch)
	assert_float(FLOOR_Y - peak[0]).is_equal_approx(32.0, 4.0)
	assert_float(player.global_position.y).is_equal_approx(FLOOR_Y, 1.0)


func test_MAG_007_meditar_segura_o_mago_parado() -> void:
	await _start("sala_aberta")
	player.intent_source = func() -> PlayerIntent: return PlayerIntent.make(1.0)
	var start_x := player.global_position.x
	await _play([{"tipo": "meditar", "linha": 1}])
	assert_float(player.global_position.x).is_equal_approx(start_x, 1.0)
	await _frames(10)
	assert_float(player.global_position.x).is_greater(start_x + 10.0)


func test_MAG_008_acoes_parciais_acontecem() -> void:
	await _start("sala_aberta")
	var fake: FakeSpellExecutor = auto_free(FakeSpellExecutor.new())
	add_child(fake)
	world.executor = fake
	world.grimoire.create("Quebrado", "mover(2)\nprint(x)")
	world.grimoire.equip(1, "Quebrado")
	fake.queue_result({"ok": false, "custo_mana": 1.1, "mago": {"vida": 5, "mana": 0, "mana_max": 10}, "saidas": [],
		"acoes": [{"tipo": "mover", "passos": 2, "linha": 1}],
		"erro": {"tipo": "NameError", "mensagem": "name 'x' is not defined", "linha": 2, "coluna": null}})
	var start_x := player.global_position.x
	await world.cast(1)
	if world.action_player.is_playing():
		await world.action_player.finished
	assert_float(player.global_position.x - start_x).is_equal_approx(32.0, 4.0)


func test_MAG_009_pausa_congela_o_projetil() -> void:
	await _start("sala_aberta")
	world.action_player.play([{"tipo": "lancar", "elemento": "fogo", "forma": "projetil", "alvo": null, "linha": 1}])
	await _frames(15)
	var projectile: Projectile = _projectiles()[0]
	get_tree().paused = true
	var frozen_at := projectile.global_position
	await _frames(10)
	assert_vector(projectile.global_position).is_equal(frozen_at)
	get_tree().paused = false
	await _frames(5)
	assert_float(projectile.global_position.x).is_greater(frozen_at.x)


func test_MAG_009_pausa_congela_a_fila_de_acoes() -> void:
	await _start("sala_aberta")
	world.action_player.play([{"tipo": "meditar", "linha": 1}])
	await _frames(2)
	get_tree().paused = true
	await get_tree().create_timer(0.8, true).timeout
	assert_bool(world.action_player.is_playing()).is_true()
	get_tree().paused = false
	await world.action_player.finished
	assert_bool(world.action_player.is_playing()).is_false()


func test_MAG_010_projetil_mira_o_alvo_mesmo_de_costas() -> void:
	await _start("sala_alvos")
	player.motor.facing = -1
	world.action_player.play([{"tipo": "lancar", "elemento": "fogo", "forma": "projetil", "alvo": "sala_alvos_alvo_1", "linha": 1}])
	await _frames(3)
	var projectile: Projectile = _projectiles()[0]
	assert_float(projectile.direction.x).is_greater(0.0)
	await _frames(40)
	assert_str(_target("sala_alvos_alvo_1").last_hit_element).is_equal("fogo")


## Regressão (Sprint 8, achado pelo PUZ-005): de costas para o alvo e encostado na parede,
## o projétil nascia na mão do lado da parede e sumia na hora.
func test_MAG_010_projetil_de_costas_encostado_na_parede() -> void:
	await _start("sala_aberta")
	await _teleport(Vector2(23, FLOOR_Y))
	player.motor.facing = -1
	world.action_player.play([{"tipo": "lancar", "elemento": "gelo", "forma": "projetil", "alvo": "sala_aberta_alvo_1", "linha": 1}])
	await _frames(45)
	assert_str(_target("sala_aberta_alvo_1").last_hit_element).is_equal("gelo")


func test_MAG_010_projetil_acerta_o_alvo() -> void:
	await _start("sala_alvos")
	await _play([{"tipo": "lancar", "elemento": "gelo", "forma": "projetil", "alvo": "sala_alvos_alvo_1", "linha": 1}])
	await _frames(30)
	var target := _target("sala_alvos_alvo_1")
	assert_str(target.last_hit_element).is_equal("gelo")
	assert_int(target.last_effect).is_equal(ElementTable.Effect.WEAK)
	assert_array(_projectiles()).is_empty()


func test_MAG_011_projetil_sem_alvo_voa_para_a_frente_e_some_na_parede() -> void:
	await _start("sala_aberta")
	player.motor.facing = -1
	world.action_player.play([{"tipo": "lancar", "elemento": "fogo", "forma": "projetil", "alvo": null, "linha": 1}])
	await _frames(12)
	assert_array(_projectiles()).is_empty()
	assert_str(_target("sala_aberta_alvo_1").last_hit_element).is_empty()


func test_MAG_012_alvo_que_sumiu_voa_para_a_frente() -> void:
	await _start("sala_aberta")
	world.action_player.play([{"tipo": "lancar", "elemento": "raio", "forma": "projetil", "alvo": "nao_existe", "linha": 1}])
	await _frames(12)
	var projectile: Projectile = _projectiles()[0]
	assert_float(projectile.direction.x).is_equal(1.0)
	assert_float(projectile.direction.y).is_equal(0.0)


func test_MAG_013_escudo_bloqueia_um_ataque() -> void:
	await _start("sala_aberta")
	await _play([{"tipo": "lancar", "elemento": "raio", "forma": "escudo", "alvo": null, "linha": 1}])
	var shield: Shield = player.get_node_or_null("Shield")
	assert_object(shield).is_not_null()
	assert_str(shield.element).is_equal("raio")
	assert_bool(world.state.health.damage(1)).is_false()
	assert_int(world.state.health.current).is_equal(5)
	await _frames(2)
	assert_object(player.get_node_or_null("Shield")).is_null()


func test_MAG_013_escudo_some_sozinho() -> void:
	await _start("sala_aberta")
	await _play([{"tipo": "lancar", "elemento": "gelo", "forma": "escudo", "alvo": null, "linha": 1}])
	await get_tree().create_timer(2.2).timeout
	assert_object(player.get_node_or_null("Shield")).is_null()
	assert_bool(world.state.health.shielded).is_false()


func test_MAG_014_cajado() -> void:
	await _start("sala_aberta")
	await _teleport(Vector2(120, FLOOR_Y))
	var mana_before := world.state.mana
	assert_bool(world.world_actions.staff_attack()).is_true()
	await _frames(5)
	var target := _target("sala_aberta_alvo_1")
	assert_str(target.last_hit_element).is_equal("cajado")
	assert_int(target.last_effect).is_equal(ElementTable.Effect.NORMAL)
	assert_float(world.state.mana).is_equal(mana_before)
	assert_bool(world.world_actions.staff_attack()).is_false()


func test_MAG_019_visoes_sobre_o_mago() -> void:
	await _start("sala_aberta")
	world.world_actions.show_visions(PackedStringArray(["a", "b", "c", "d"]))
	var vision: Label = player.get_node("Visions")
	assert_str(vision.text).is_equal("b\nc\nd")


func test_MAG_033_boneco_mostra_o_efeito() -> void:
	await _start("sala_aberta")
	var target := _target("sala_aberta_alvo_1")
	target.hit("gelo")
	assert_str(target.last_hit_element).is_equal("gelo")
	assert_int(target.last_effect).is_equal(ElementTable.Effect.WEAK)
	assert_str(target.effect_label.text).is_equal(tr("ALVO_FRACO"))


func test_MAG_070_levitar_e_mover_voa_na_horizontal() -> void:
	await _start("sala_aberta")
	await _teleport(Vector2(120, FLOOR_Y))
	await _play([{"tipo": "levitar", "altura": 3, "linha": 1}, {"tipo": "mover", "passos": 2, "linha": 2}])
	assert_float(FLOOR_Y - player.global_position.y).is_equal_approx(48.0, 4.0)
	assert_float(player.global_position.x).is_equal_approx(152.0, 4.0)
	await _frames(60)
	assert_float(player.global_position.y).is_equal_approx(FLOOR_Y, 1.0)


func test_MAG_070_levitar_e_meditar_cai_antes() -> void:
	await _start("sala_aberta")
	await _teleport(Vector2(120, FLOOR_Y))
	var heights := []
	world.action_player.action_started.connect(func(action: Dictionary) -> void:
		if action["tipo"] == "meditar":
			heights.append(FLOOR_Y - player.global_position.y)
	)
	await _play([{"tipo": "levitar", "altura": 3, "linha": 1}, {"tipo": "meditar", "linha": 2}])
	# Ao começar a meditar ele ainda está no ar, mas já sem voo: cai durante a meditação.
	assert_float(player.global_position.y).is_equal_approx(FLOOR_Y, 1.0)
	assert_int(heights.size()).is_equal(1)
