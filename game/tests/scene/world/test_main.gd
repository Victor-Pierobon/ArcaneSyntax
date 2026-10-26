extends GdUnitTestSuite
## Spec: docs/specs/save/SAV-progresso.md (regras 1, 2 e 5, SAV-006): a cena principal e o perfil.

const MAIN := "res://src/nodes/main/main.tscn"
const ROOT := "user://tests/perfis"
const LEGACY := "user://tests/grimorio_antigo.json"


func before_test() -> void:
	_cleanup()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))


func after_test() -> void:
	get_tree().paused = false
	_cleanup()


func _cleanup() -> void:
	for path in [LEGACY, ROOT + "/padrao/grimorio.json", ROOT + "/padrao/save.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	for dir in [ROOT + "/padrao", ROOT]:
		if DirAccess.dir_exists_absolute(dir):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))


func _main() -> Main:
	var main: Main = auto_free(load(MAIN).instantiate())
	main.profile_root = ROOT
	main.legacy_grimoire = LEGACY
	add_child(main)
	main.world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	for i in 3:
		await get_tree().physics_frame
	return main


func test_SAV_006_perfil_padrao() -> void:
	var main := await _main()
	assert_str(main.world.grimoire_path).is_equal(ROOT + "/padrao/grimorio.json")
	assert_str(main.world.save_path).is_equal(ROOT + "/padrao/save.json")
	assert_bool(FileAccess.file_exists(ROOT + "/padrao/save.json")).is_true()
	assert_str(main.world.current_room.room_id).is_equal("sala_01")


func test_SAV_006_migra_o_grimorio_antigo() -> void:
	var old := Grimoire.new()
	old.create("Antigo", "meditar()")
	GrimoireStore.new(LEGACY).save(old)
	var main := await _main()
	assert_bool(main.world.grimoire.has_spell("Antigo")).is_true()
	assert_bool(FileAccess.file_exists(ROOT + "/padrao/grimorio.json")).is_true()
	assert_bool(FileAccess.file_exists(LEGACY)).is_true()


func test_SAV_006_grimorio_do_perfil_nao_e_sobrescrito() -> void:
	var old := Grimoire.new()
	old.create("Antigo", "meditar()")
	GrimoireStore.new(LEGACY).save(old)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT + "/padrao"))
	var mine := Grimoire.new()
	mine.create("Meu", "absorver_mana()")
	GrimoireStore.new(ROOT + "/padrao/grimorio.json").save(mine)
	var main := await _main()
	assert_bool(main.world.grimoire.has_spell("Meu")).is_true()
	assert_bool(main.world.grimoire.has_spell("Antigo")).is_false()
