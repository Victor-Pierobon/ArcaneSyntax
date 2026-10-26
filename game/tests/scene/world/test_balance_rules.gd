extends GdUnitTestSuite
## Spec: docs/specs/balanceamento/BAL-valores.md (regra 3, BAL-004): as regras do executor vêm do arquivo.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_balanceamento.json"

var world: World
var fake: FakeSpellExecutor


func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
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
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(GRIMOIRE_PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func test_BAL_004_toda_requisicao_leva_as_regras_do_arquivo() -> void:
	world.grimoire.create("Fogo", "lancar(fogo, projetil)")
	world.grimoire.equip(1, "Fogo")
	await world.cast(1)
	world.grimoire.create("Passivo", "absorver_mana()")
	world.grimoire.set_passive("Passivo")
	await get_tree().create_timer(1.3).timeout
	world.grimoire.clear_passive()
	world.grimoire_ui.open()
	world.grimoire_ui.select("Fogo")
	await world.grimoire_ui.test_selected()
	await world.grimoire_ui.estimate_now()
	world.grimoire_ui.close()
	var codes := fake.requests.map(func(request: SpellRequest) -> String: return request.code)
	assert_array(codes).contains(["lancar(fogo, projetil)", "absorver_mana()"])
	assert_int(fake.requests.size()).is_greater_equal(4)
	for request in fake.requests:
		assert_dict(request.rules).override_failure_message(request.code).is_equal(Balance.rules())
		assert_dict(request.to_dict(1)["regras"]).is_equal(Balance.rules())
