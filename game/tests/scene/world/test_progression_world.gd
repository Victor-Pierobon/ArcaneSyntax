extends GdUnitTestSuite
## Spec: docs/specs/progressao/PRO-xp.md (PRO-003 a PRO-005) e PRO-niveis.md (PRO-023, PRO-024).
## sala_xp: elemental de fogo (1), enxame de 2 bichos (2) e guardião (3). sala_puzzle: um cristal, sem estrelas.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_progressao.json"

var world: World


func _start(room_id: String) -> void:
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = room_id
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
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


func _defeat_all() -> void:
	for enemy in world.current_room.enemies():
		enemy.apply_damage(enemy.health.current)


func test_PRO_003_inimigos_dao_xp() -> void:
	await _start("sala_xp")
	assert_array(world.current_room.enemies()).has_size(4)
	_defeat_all()
	assert_int(world.state.xp).is_equal(29)
	assert_str(world.cast_log.text()).contains("+10 XP").contains("+15 XP")


func test_PRO_004_inimigo_que_reaparece_da_xp_de_novo() -> void:
	await _start("sala_xp")
	var first: Enemy = world.current_room.enemies()[0]
	first.apply_damage(first.health.current)
	var gained := world.state.xp
	world.go_to("sala_xp", "A")
	await _frames(2)
	var again: Enemy = world.current_room.enemies()[0]
	again.apply_damage(again.health.current)
	assert_int(world.state.xp).is_equal(gained * 2)


func test_PRO_005_puzzle_da_xp_so_na_primeira_vez() -> void:
	await _start("sala_puzzle")
	(world.find_target("sala_puzzle_alvo_5") as Crystal).light()
	await _frames(2)
	assert_bool(world.is_puzzle_solved("p_teste")).is_true()
	assert_int(world.state.xp).is_equal(20)
	assert_str(world.cast_log.text()).contains("+20 XP")
	world.go_to("sala_puzzle", "A")
	await _frames(3)
	assert_int(world.state.xp).is_equal(20)


func test_PRO_023_hud_e_registro_do_nivel() -> void:
	await _start("sala_xp")
	assert_str(world.hud.level_label.text).is_equal("Nível 1 · XP 0/30")
	world.state.gain_xp(45)
	assert_str(world.hud.level_label.text).is_equal("Nível 2 · XP 45/70")
	assert_str(world.hud.mana_label.text).contains("12.0/12.0")
	assert_str(world.cast_log.text()).contains("Nível 2! Mana máxima 12")
	world.state.gain_xp(1000)
	assert_str(world.hud.level_label.text).is_equal("Nível 5 · XP 1045")


func test_PRO_024_o_feitico_ve_a_mana_maxima_nova() -> void:
	await _start("sala_xp")
	world.state.gain_xp(30)
	assert_float(float(world.spell_context()["mago"]["mana_max"])).is_equal(12.0)
