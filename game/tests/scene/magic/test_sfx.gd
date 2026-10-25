extends GdUnitTestSuite
## Spec: docs/specs/magia/MAG-efeitos.md (MAG-060, 061)

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_sfx.json"


func after_test() -> void:
	var file := ProjectSettings.globalize_path(GRIMOIRE_PATH)
	if FileAccess.file_exists(file):
		DirAccess.remove_absolute(file)


func test_MAG_060_sons_para_cada_evento() -> void:
	var sfx: Sfx = auto_free(Sfx.new())
	add_child(sfx)
	for event in Sfx.EVENTS:
		assert_object(sfx.stream_for(event)).override_failure_message(event).is_not_null()
	assert_bool(sfx.play("conjurar", "gelo")).is_true()
	assert_bool(sfx.play("dancar")).is_false()


func test_MAG_061_conjurar_e_acertar_tocam() -> void:
	var world: World = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = "sala_alvos"
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	for i in 3:
		await get_tree().physics_frame
	world.action_player.play([{"tipo": "lancar", "elemento": "gelo", "forma": "projetil", "alvo": "sala_alvos_alvo_1", "linha": 1}])
	for i in 40:
		await get_tree().physics_frame
	assert_array(world.sfx.played).contains(["conjurar", "fraco"])
