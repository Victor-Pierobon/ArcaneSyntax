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


func test_GRI_008_aviso_de_arquivo_ilegivel() -> void:
	ui.load_problem = "o arquivo do grimório estava ilegível"
	ui.open()
	assert_str(ui.status_label.text).contains(".bak")
