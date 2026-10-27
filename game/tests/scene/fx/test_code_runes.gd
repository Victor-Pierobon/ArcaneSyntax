extends GdUnitTestSuite
## Spec: docs/specs/arte/ART-brilho.md (regra 9, ART-066).

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_runas.json"

var world: World


func _start() -> void:
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = "sala_1"
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	await get_tree().physics_frame
	await get_tree().physics_frame


func after_test() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(GRIMOIRE_PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func _runes() -> Array:
	return get_tree().get_nodes_in_group(CodeRune.GROUP)


func test_ART_066_cada_acao_solta_a_runa_da_linha() -> void:
	await _start()
	# O que cada runa tinha ao nascer: [linha, cor, altura acima dos pés do mago].
	var seen := {}
	world.action_player.action_started.connect(func(_action: Dictionary) -> void:
		for rune: CodeRune in _runes():
			if not seen.has(rune.get_instance_id()):
				seen[rune.get_instance_id()] = [rune.line, rune.color,
						world.player.global_position.y - rune.global_position.y])
	world.action_player.play([
		{"tipo": "lancar", "linha": 1, "elemento": "fogo", "forma": "escudo"},
		{"tipo": "meditar", "linha": 2},
	])
	if world.action_player.is_playing():
		await world.action_player.finished
	assert_int(seen.size()).is_equal(2)
	var lines := seen.values().map(func(data: Array) -> int: return data[0])
	assert_array(lines).contains_exactly_in_any_order([1, 2])
	for data: Array in seen.values():
		var expected: Color = TrainingTarget.ELEMENT_COLORS["fogo"] if data[0] == 1 else CodeRune.NEUTRAL
		assert_that(data[1]).override_failure_message("linha %d" % data[0]).is_equal(expected)
		# Acima do mago.
		assert_float(data[2]).override_failure_message("linha %d" % data[0]).is_greater(24.0)
	await get_tree().create_timer(CodeRune.LIFETIME + 0.6, false, true).timeout
	assert_array(_runes()).is_empty()


func test_ART_066_sem_linha_nao_solta() -> void:
	await _start()
	world.action_player.play([{"tipo": "meditar"}])
	await get_tree().physics_frame
	assert_array(_runes()).is_empty()
