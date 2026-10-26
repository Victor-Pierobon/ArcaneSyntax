extends GdUnitTestSuite
## Spec: docs/specs/ui/UI-menus.md (UI-010 a UI-014, UI-016 e UI-017), com a cena principal e as salas do jogo.
## Teclas não chegam em headless: os testes apertam os botões pelo sinal e chamam `handle_cancel()`.

const MAIN := "res://src/nodes/main/main.tscn"
const ROOT := "user://tests/perfis_menu"
const PROFILE := ROOT + "/padrao"
const SAVE := PROFILE + "/save.json"

var main: Main


func before_test() -> void:
	_cleanup()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PROFILE))


func after_test() -> void:
	get_tree().paused = false
	_cleanup()


func _cleanup() -> void:
	for file_name in ["grimorio.json", "save.json", "opcoes.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			var path: String = PROFILE.path_join(file_name) + suffix
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for dir in [PROFILE, ROOT]:
		if DirAccess.dir_exists_absolute(dir):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _open_main() -> void:
	main = auto_free(load(MAIN).instantiate())
	main.profile_root = ROOT
	main.legacy_grimoire = ROOT + "/nao_existe.json"
	add_child(main)
	await _frames(2)


## Depois de subir o mundo pelo menu: o mago fica parado.
func _hold_still() -> void:
	main.world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	await _frames(3)


func _write_save(room: String, xp := 0) -> void:
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify({"versao": 1, "sala": room, "entrada": "A", "mago": {"xp": xp, "mana": 0}}))
	file.close()


func test_UI_010_menu_sem_save() -> void:
	await _open_main()
	assert_object(main.world).is_null()
	assert_bool(main.title_menu.is_showing()).is_true()
	assert_bool(main.title_menu.continue_button.visible).is_false()
	assert_bool(main.title_menu.new_game_button.has_focus()).is_true()
	main.title_menu.new_game_button.pressed.emit()
	await _hold_still()
	assert_object(main.world).is_not_null()
	assert_bool(main.title_menu.is_showing()).is_false()
	assert_str(main.world.current_room.room_id).is_equal("sala_01")
	assert_str(main.world.current_entry).is_equal("A")
	assert_str(main.world.save_path).is_equal(SAVE)
	assert_str(main.world.grimoire_path).is_equal(PROFILE + "/grimorio.json")


func test_UI_011_continuar() -> void:
	_write_save("sala_p03")
	await _open_main()
	assert_bool(main.title_menu.continue_button.visible).is_true()
	assert_bool(main.title_menu.continue_button.has_focus()).is_true()
	main.title_menu.continue_button.pressed.emit()
	await _hold_still()
	assert_str(main.world.current_room.room_id).is_equal("sala_p03")


func test_UI_012_novo_jogo_com_save_pede_confirmacao() -> void:
	_write_save("sala_p03", 85)
	var mine := Grimoire.new()
	mine.create("Meu", "meditar()")
	GrimoireStore.new(PROFILE + "/grimorio.json").save(mine)
	await _open_main()
	main.title_menu.new_game_button.pressed.emit()
	await _frames(1)
	assert_bool(main.title_menu.is_confirming()).is_true()
	assert_bool(main.title_menu.confirm_no.has_focus()).is_true()
	main.title_menu.confirm_no.pressed.emit()
	await _frames(1)
	assert_object(main.world).is_null()
	assert_bool(main.title_menu.is_confirming()).is_false()
	assert_bool(FileAccess.file_exists(SAVE)).is_true()
	main.title_menu.new_game_button.pressed.emit()
	main.title_menu.confirm_yes.pressed.emit()
	await _hold_still()
	assert_str(main.world.current_room.room_id).is_equal("sala_01")
	assert_int(main.world.state.xp).is_equal(0)
	assert_bool(main.world.grimoire.has_spell("Meu")).is_true()


func test_UI_013_pausa() -> void:
	await _open_main()
	main.new_game()
	await _hold_still()
	main.pause_menu.handle_cancel()
	assert_bool(main.pause_menu.is_open()).is_true()
	assert_bool(get_tree().paused).is_true()
	assert_bool(main.pause_menu.resume_button.has_focus()).is_true()
	main.world.grimoire_ui.open()
	assert_bool(main.world.grimoire_ui.is_open()).is_false()
	main.pause_menu.handle_cancel()
	assert_bool(main.pause_menu.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()
	main.pause_menu.handle_cancel()
	main.pause_menu.resume_button.pressed.emit()
	assert_bool(main.pause_menu.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()


func test_UI_013_com_o_grimorio_aberto_esc_nao_pausa() -> void:
	await _open_main()
	main.new_game()
	await _hold_still()
	main.world.grimoire_ui.open()
	main.pause_menu.handle_cancel()
	assert_bool(main.pause_menu.is_open()).is_false()
	main.world.grimoire_ui.close()


func test_UI_014_voltar_ao_menu_salva() -> void:
	await _open_main()
	main.new_game()
	await _hold_still()
	main.world.go_to("sala_02", "A")
	await _frames(2)
	main.pause_menu.handle_cancel()
	main.pause_menu.menu_button.pressed.emit()
	await _frames(2)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	assert_str(saved["sala"]).is_equal("sala_02")
	assert_object(main.world).is_null()
	assert_bool(main.title_menu.is_showing()).is_true()
	assert_bool(main.title_menu.continue_button.visible).is_true()
	assert_bool(main.pause_menu.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()


func test_UI_016_opcoes_valem_na_hora_e_ficam_guardadas() -> void:
	await _open_main()
	main.new_game()
	await _hold_still()
	var base := main.world.dialogue_box.text_label.get_theme_font_size(&"font_size")
	main.pause_menu.handle_cancel()
	main.pause_menu.options_button.pressed.emit()
	assert_bool(main.options_menu.is_open()).is_true()
	main.options_menu.text_button.pressed.emit()
	assert_int(main.world.dialogue_box.text_label.get_theme_font_size(&"font_size")).is_equal(base + 2)
	main.options_menu.volume_slider.value = 30
	main.options_menu.back_button.pressed.emit()
	assert_bool(main.options_menu.is_open()).is_false()
	assert_bool(main.pause_menu.is_open()).is_true()
	var again := Settings.load_file(PROFILE + "/opcoes.json")
	assert_int(again.text_size).is_equal(Settings.TextSize.LARGE)
	assert_int(again.volume).is_equal(30)


func test_UI_016_opcoes_do_menu_inicial_valem_no_jogo() -> void:
	await _open_main()
	main.title_menu.options_button.pressed.emit()
	main.options_menu.text_button.pressed.emit()
	main.options_menu.text_button.pressed.emit()
	main.options_menu.back_button.pressed.emit()
	assert_bool(main.title_menu.new_game_button.has_focus()).is_true()
	main.new_game()
	await _hold_still()
	assert_int(main.world.grimoire_ui.editor.get_theme_font_size(&"font_size")).is_equal(9 + 3)


func test_UI_017_fim_da_demo() -> void:
	await _open_main()
	main.new_game()
	await _hold_still()
	var world := main.world
	world.solved_puzzles = {"p04_ponte": {"estrelas": 3}, "p06_revisao": {"estrelas": 1}}
	world.found_secrets = {"sala_02_8": true}
	world.go_to("sala_fim", "A")
	await _frames(3)
	var serpent: Serpent = world.current_room.serpents()[0]
	world.player.global_position = serpent.global_position + Vector2(-16, 0)
	await _frames(3)
	world.talk()
	assert_bool(world.dialogue_box.is_open()).is_true()
	while world.dialogue_box.is_open():
		world.dialogue_box.choose(1)
		world.dialogue_box.advance()
	await _frames(1)
	assert_bool(main.end_screen.is_showing()).is_true()
	var text := main.end_screen.summary_text()
	assert_str(text).contains(tr("FIM_PUZZLES") % [2, 6])
	assert_str(text).contains(tr("FIM_ESTRELAS") % 4)
	assert_str(text).contains(tr("FIM_SEGREDOS") % [1, 2])
	main.end_screen.confirm()
	await _frames(2)
	assert_object(main.world).is_null()
	assert_bool(main.title_menu.is_showing()).is_true()
	assert_bool(get_tree().paused).is_false()
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	assert_str(saved["sala"]).is_equal("sala_fim")
