extends GdUnitTestSuite
## Spec: docs/specs/magia/MAG-feixe.md (MAG-084 a MAG-086).
## sala_feixe: chão com topo em y = 80; mago na coluna 2; serpente ensino_feixe na 4; boneco de fogo na 8
## (o alvo); elemental de fogo na 12, na mesma linha; parede de 1 tile na 18 com um boneco atrás (21);
## um boneco no alto (coluna 10, em cima de uma plataforma), fora da linha.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_feixe.json"
const SAVE_PATH := "user://tests/save_feixe.json"

var world: World


func _start(save := "") -> void:
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = "sala_feixe"
	world.grimoire_path = GRIMOIRE_PATH
	world.save_path = save
	add_child(world)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	await _frames(3)


func after_test() -> void:
	get_tree().paused = false
	for path in [GRIMOIRE_PATH, SAVE_PATH]:
		for suffix in ["", ".bak", ".tmp"]:
			var file := ProjectSettings.globalize_path(path + suffix)
			if FileAccess.file_exists(file):
				DirAccess.remove_absolute(file)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _target(digit: String) -> TrainingTarget:
	for node in get_tree().get_nodes_in_group(TrainingTarget.GROUP):
		if (node as TrainingTarget).target_id == "sala_feixe_alvo_" + digit:
			return node
	return null


func _fire(element: String, target_digit: String) -> void:
	world.action_player.play([{"tipo": "lancar", "linha": 1, "elemento": element, "forma": "feixe",
			"alvo": "sala_feixe_alvo_" + target_digit}])


func test_MAG_084_carrega_parado_e_atravessa_a_linha() -> void:
	await _start()
	var first := _target("1")
	var elemental := _target("2") as Enemy
	var behind := _target("3")
	var above := _target("4")
	# O jogador segura a tecla de andar; a carga tira o controle dele.
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make(1.0)
	_fire("gelo", "1")
	await _frames(1)
	var start := world.player.global_position
	await get_tree().create_timer(0.4, false, true).timeout
	assert_float(absf(world.player.global_position.x - start.x)).is_less(1.0)
	assert_int(first.hits).is_equal(0)
	await get_tree().create_timer(0.3, false, true).timeout
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	assert_int(first.hits).is_equal(1)
	assert_str(first.last_hit_element).is_equal("gelo")
	assert_str(first.last_form).is_equal("feixe")
	assert_int(elemental.hits).is_equal(1)
	# Gelo contra fogo: 6 × 2.
	assert_int(elemental.last_damage).is_equal(12)
	assert_int(above.hits).is_equal(0)
	assert_int(behind.hits).override_failure_message("atrás da parede").is_equal(0)


func test_MAG_084_o_feixe_aparece_e_some() -> void:
	await _start()
	_fire("fogo", "1")
	await get_tree().create_timer(0.6, false, true).timeout
	assert_array(get_tree().get_nodes_in_group(Beam.GROUP)).has_size(1)
	await get_tree().create_timer(Beam.LIFETIME + 0.2, false, true).timeout
	assert_array(get_tree().get_nodes_in_group(Beam.GROUP)).is_empty()


func test_MAG_086_aprender_com_a_serpente() -> void:
	await _start(SAVE_PATH)
	assert_bool("feixe" in world.state.unlocked_pieces).is_false()
	assert_bool("feixe" in world.grimoire_ui.reference_pages()).is_false()
	var serpent: Serpent = world.current_room.serpents()[0]
	world.player.global_position = serpent.global_position + Vector2(-16, 0)
	await _frames(3)
	world.talk()
	assert_bool(world.dialogue_box.is_open()).is_true()
	while world.dialogue_box.is_open():
		world.dialogue_box.choose(1)
		world.dialogue_box.advance()
	await _frames(2)
	assert_bool("feixe" in world.state.unlocked_pieces).is_true()
	assert_str(world.cast_log.text()).contains(tr("FEIXE_APRENDIDO"))
	assert_bool("feixe" in world.grimoire_ui.reference_pages()).is_true()
	# Volta pelo save.
	var again: World = auto_free(load(WORLD).instantiate())
	again.rooms_dir = "res://tests/fixtures/rooms/"
	again.start_room = "sala_feixe"
	again.grimoire_path = GRIMOIRE_PATH
	again.save_path = SAVE_PATH
	add_child(again)
	await _frames(2)
	assert_bool("feixe" in again.state.unlocked_pieces).is_true()
