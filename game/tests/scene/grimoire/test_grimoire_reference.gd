extends GdUnitTestSuite
## Spec: docs/specs/grimorio/GRI-referencia.md (regra 5, GRI-083, GRI-084)

const PATH := "user://tests/grimorio_referencia.json"

var ui: GrimoireUI
var grimoire: Grimoire
var pieces := PackedStringArray(MagoState.ALL_PIECES)


func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	_cleanup()
	var store := GrimoireStore.new(PATH)
	grimoire = store.load_grimoire()
	ui = auto_free(GrimoireUI.new())
	add_child(ui)
	ui.bind(grimoire, store)
	var fake: FakeSpellExecutor = auto_free(FakeSpellExecutor.new())
	add_child(fake)
	ui.set_spell_runner(fake, func() -> Dictionary:
		return {"mago": {"vida": 5, "mana": 5, "mana_max": 10}, "target": null, "pieces": pieces})


func after_test() -> void:
	get_tree().paused = false
	_cleanup()


func _cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func _titles() -> Array:
	var titles := []
	for i in ui.reference_list.item_count:
		titles.append(ui.reference_list.get_item_text(i))
	return titles


func test_GRI_083_aba_de_referencia() -> void:
	grimoire.create("Fogo", "lancar(fogo, projetil)")
	ui.open()
	ui.select("Fogo")
	ui.editor.text = "lancar(gelo, projetil)"
	ui.show_reference()
	assert_bool(ui.is_showing_reference()).is_true()
	assert_int(ui.reference_list.item_count).is_equal(13)
	assert_str(_titles()[0]).is_equal(tr("REF_LANCAR_TITULO"))
	assert_str(ui.reference_text.text).is_equal(tr("REF_LANCAR_TEXTO"))
	ui.select_page("levitar")
	assert_str(ui.reference_text.text).is_equal(tr("REF_LEVITAR_TEXTO"))
	ui.show_spells()
	assert_bool(ui.is_showing_reference()).is_false()
	assert_str(ui.selected_name()).is_equal("Fogo")
	assert_str(ui.editor.text).is_equal("lancar(gelo, projetil)")


func test_GRI_084_peca_bloqueada_esconde_a_pagina() -> void:
	var without := PackedStringArray(MagoState.ALL_PIECES)
	without.remove_at(without.find("levitar"))
	pieces = without
	ui.open()
	ui.show_reference()
	assert_array(_titles()).not_contains([tr("REF_LEVITAR_TITULO")])
	assert_int(ui.reference_list.item_count).is_equal(12)
