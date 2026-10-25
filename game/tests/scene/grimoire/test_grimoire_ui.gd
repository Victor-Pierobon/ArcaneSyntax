extends GdUnitTestSuite
## Spec: docs/specs/grimorio/GRI-grimorio.md (GRI-001 a 005, 007, 008)
## Teclas não chegam em headless; os testes chamam a API da tela (open, new_spell, rename_selected…).

const PATH := "user://tests/grimorio_ui.json"

var ui: GrimoireUI
var grimoire: Grimoire
var store: GrimoireStore


func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	_cleanup()
	store = GrimoireStore.new(PATH)
	grimoire = store.load_grimoire()
	ui = auto_free(GrimoireUI.new())
	add_child(ui)
	ui.bind(grimoire, store)


func after_test() -> void:
	get_tree().paused = false
	_cleanup()


func _cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func _list_items() -> Array:
	var items := []
	for i in ui.spell_list.item_count:
		items.append(ui.spell_list.get_item_text(i))
	return items


func test_GRI_001_abrir_pausa_fechar_despausa() -> void:
	assert_bool(ui.is_open()).is_false()
	ui.open()
	assert_bool(ui.is_open()).is_true()
	assert_bool(get_tree().paused).is_true()
	ui.close()
	assert_bool(ui.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()


func test_GRI_002_funciona_com_o_jogo_pausado() -> void:
	var player: Node = auto_free(load("res://src/nodes/player/player.tscn").instantiate())
	add_child(player)
	ui.open()
	assert_bool(ui.can_process()).is_true()
	assert_bool(player.can_process()).is_false()


func test_GRI_003_novo_renomear_apagar() -> void:
	ui.open()
	ui.new_spell()
	ui.new_spell()
	assert_array(_list_items()).is_equal(["Feitiço 1", "Feitiço 2"])
	assert_int(ui.rename_selected("Raio")).is_equal(Grimoire.Problem.OK)
	ui.select("Feitiço 1")
	ui.delete_selected()
	assert_array(_list_items()).is_equal(["Raio"])
	assert_str(ui.selected_name()).is_equal("Raio")
	assert_array(Array(GrimoireStore.new(PATH).load_grimoire().names())).is_equal(["Raio"])


func test_GRI_003_campo_de_nome_acompanha_o_selecionado() -> void:
	ui.open()
	ui.new_spell()
	assert_str(ui.name_field.text).is_equal("Feitiço 1")
	ui.rename_selected("  Adaptável ")
	assert_str(ui.name_field.text).is_equal("Adaptável")


func test_GRI_003_nome_invalido_mostra_aviso() -> void:
	ui.open()
	ui.new_spell()
	assert_int(ui.rename_selected("   ")).is_equal(Grimoire.Problem.EMPTY_NAME)
	assert_str(ui.status_label.text).is_not_empty()
	assert_array(_list_items()).is_equal(["Feitiço 1"])


func test_GRI_004_edicao_guardada_ao_trocar_de_feitico() -> void:
	grimoire.create("Primeiro", "meditar()")
	grimoire.create("Segundo", "levitar(2)")
	ui.open()
	ui.select("Primeiro")
	ui.editor.text = "meditar()\nmeditar()"
	ui.select("Segundo")
	assert_str(grimoire.code_of("Primeiro")).is_equal("meditar()\nmeditar()")
	assert_str(ui.editor.text).is_equal("levitar(2)")


func test_GRI_005_fechar_salva_no_disco() -> void:
	ui.open()
	ui.new_spell()
	ui.editor.text = "while mana < mana_max:\n    absorver_mana()"
	ui.close()
	var loaded := GrimoireStore.new(PATH).load_grimoire()
	assert_str(loaded.code_of("Feitiço 1")).is_equal("while mana < mana_max:\n    absorver_mana()")


func test_GRI_007_lembra_o_selecionado() -> void:
	grimoire.create("Primeiro")
	grimoire.create("Segundo")
	ui.open()
	ui.select("Segundo")
	ui.close()
	ui.open()
	assert_str(ui.selected_name()).is_equal("Segundo")


func test_GRI_007_sem_selecao_abre_no_primeiro() -> void:
	grimoire.create("Primeiro")
	grimoire.create("Segundo")
	ui.open()
	assert_str(ui.selected_name()).is_equal("Primeiro")
	assert_bool(ui.editor.editable).is_true()


func _use_fake_executor(mana: float = 5.0) -> FakeSpellExecutor:
	var fake: FakeSpellExecutor = auto_free(FakeSpellExecutor.new())
	add_child(fake)
	var context := func() -> Dictionary:
		return {"mago": {"vida": 5, "mana": mana, "mana_max": 10}, "target": null, "pieces": MagoState.ALL_PIECES}
	ui.set_spell_runner(fake, context)
	return fake


func test_GRI_033_equipar_pelo_grimorio() -> void:
	grimoire.create("Fogo")
	ui.open()
	ui.select("Fogo")
	ui.toggle_slot(2)
	assert_str(grimoire.slot(2)).is_equal("Fogo")
	assert_bool(ui.slot_buttons[1].button_pressed).is_true()
	assert_str(GrimoireStore.new(PATH).load_grimoire().slot(2)).is_equal("Fogo")
	ui.toggle_slot(2)
	assert_str(grimoire.slot(2)).is_empty()
	assert_bool(ui.slot_buttons[1].button_pressed).is_false()


func test_GRI_051_testar_mostra_o_resultado_sem_gastar_mana() -> void:
	var fake := _use_fake_executor(5.0)
	grimoire.create("Teste", "print(\"oi\")\nlancar(fogo, projetil)")
	fake.queue_result({"ok": true, "custo_mana": 3.2, "mago": {"vida": 5, "mana": 1.8, "mana_max": 10},
		"acoes": [{"tipo": "lancar", "linha": 2, "elemento": "fogo", "forma": "projetil", "alvo": null}],
		"saidas": [{"linha": 1, "texto": "oi"}]})
	ui.open()
	ui.select("Teste")
	await ui.test_selected()
	assert_str(fake.requests[-1].code).is_equal("print(\"oi\")\nlancar(fogo, projetil)")
	assert_float(float(fake.requests[-1].mago["mana"])).is_equal(5.0)
	assert_str(ui.result_label.text).contains("oi").contains("lancar fogo projetil").contains("3.2")


## Regressão (Sprint 5, achado em captura de tela): a linha do custo ficava cortada no painel.
func test_GRI_051_painel_mostra_todas_as_linhas_do_resultado() -> void:
	var fake := _use_fake_executor()
	grimoire.create("Teste", "meditar()\nprint(\"olá\")\nlancar(agua, projetil)")
	fake.queue_result({"ok": false, "custo_mana": 0.2, "mago": {"vida": 5, "mana": 9.8, "mana_max": 10},
		"acoes": [{"tipo": "meditar", "linha": 1}], "saidas": [{"linha": 2, "texto": "olá"}],
		"erro": {"tipo": "NameError", "mensagem": "name 'agua' is not defined", "linha": 3, "coluna": null}})
	ui.open()
	ui.select("Teste")
	await ui.test_selected()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_int(ui.result_label.get_visible_line_count()).is_greater_equal(ui.result_label.get_line_count())


func test_GRI_052_linha_marcada_e_desmarcada() -> void:
	var fake := _use_fake_executor()
	grimoire.create("Teste", "x = 1\nprint(y)")
	fake.queue_result({"ok": false, "custo_mana": 0.1, "acoes": [], "saidas": [], "mago": {"vida": 5, "mana": 4.9, "mana_max": 10},
		"erro": {"tipo": "NameError", "mensagem": "name 'y' is not defined", "linha": 2, "coluna": null}})
	ui.open()
	ui.select("Teste")
	await ui.test_selected()
	assert_int(ui.marked_line).is_equal(2)
	assert_str(ui.result_label.text).contains("NameError")
	ui.editor.text = "x = 1\nprint(x)"
	ui.editor.text_changed.emit()
	assert_int(ui.marked_line).is_equal(-1)


func test_GRI_060_custo_estimado() -> void:
	var fake := _use_fake_executor()
	grimoire.create("Fogo", "lancar(fogo, projetil, alvo)")
	fake.queue_result({"ok": true, "custo_mana": 3.1, "acoes": [], "saidas": [], "mago": {"vida": 5, "mana": 996.9, "mana_max": 1000}})
	ui.open()
	ui.select("Fogo")
	await ui.estimate_now()
	var request: SpellRequest = fake.requests[-1]
	assert_float(float(request.mago["mana"])).is_equal(1000.0)
	assert_float(float(request.mago["mana_max"])).is_equal(1000.0)
	assert_str(request.target["elemento"]).is_equal("fogo")
	assert_str(ui.estimate_label.text).contains("3.1")


func test_GRI_061_estimativa_com_erro() -> void:
	var fake := _use_fake_executor()
	grimoire.create("Quebrado", "if mana < 5")
	fake.queue_result({"ok": false, "custo_mana": 0, "acoes": [], "saidas": [], "mago": {"vida": 5, "mana": 1000, "mana_max": 1000},
		"erro": {"tipo": "SyntaxError", "mensagem": "expected ':'", "linha": 1, "coluna": 12}})
	ui.open()
	ui.select("Quebrado")
	await ui.estimate_now()
	assert_str(ui.estimate_label.text).contains("—").contains("1")


func test_GRI_062_recalcula_depois_de_editar() -> void:
	_use_fake_executor()
	grimoire.create("Fogo", "meditar()")
	ui.open()
	ui.select("Fogo")
	ui.estimate_timer.stop()
	ui.editor.text = "meditar()\nmeditar()"
	ui.editor.text_changed.emit()
	assert_bool(ui.estimate_timer.is_stopped()).is_false()


func test_MAG_050_botao_passivo() -> void:
	grimoire.create("Recarregar")
	ui.open()
	ui.select("Recarregar")
	ui.toggle_passive()
	assert_str(grimoire.passive()).is_equal("Recarregar")
	assert_bool(ui.passive_button.button_pressed).is_true()
	assert_str(GrimoireStore.new(PATH).load_grimoire().passive()).is_equal("Recarregar")
	ui.toggle_passive()
	assert_str(grimoire.passive()).is_empty()
	assert_bool(ui.passive_button.button_pressed).is_false()


func test_GRI_074_editor_com_autocompletar() -> void:
	assert_bool(ui.editor.code_completion_enabled).is_true()


func test_GRI_008_aviso_de_arquivo_ilegivel() -> void:
	ui.load_problem = "o arquivo do grimório estava ilegível"
	ui.open()
	assert_str(ui.status_label.text).contains(".bak")
