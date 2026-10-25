class_name GrimoireUI
extends CanvasLayer
## O grimório na tela: lista de feitiços e editor (spec GRI-grimorio). Visual provisório.

const PROBLEM_TEXT := {
	Grimoire.Problem.EMPTY_NAME: "GRIMORIO_ERRO_NOME_VAZIO",
	Grimoire.Problem.NAME_TOO_LONG: "GRIMORIO_ERRO_NOME_LONGO",
	Grimoire.Problem.DUPLICATE_NAME: "GRIMORIO_ERRO_NOME_REPETIDO",
	Grimoire.Problem.NOT_FOUND: "GRIMORIO_ERRO_NAO_ENCONTRADO",
}

var spell_list := ItemList.new()
var name_field := LineEdit.new()
var editor := CodeEdit.new()
var status_label := Label.new()
## Motivo, se o arquivo do grimório estava ilegível; mostrado na primeira abertura (GRI-008).
var load_problem := ""

var _grimoire: Grimoire
var _store: GrimoireStore
var _selected := ""
var _root := PanelContainer.new()


func _init() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false


func bind(grimoire: Grimoire, store: GrimoireStore) -> void:
	_grimoire = grimoire
	_store = store
	_refresh_list()


func is_open() -> bool:
	return _root.visible


func open() -> void:
	if is_open():
		return
	_root.visible = true
	get_tree().paused = true
	status_label.text = ""
	if not load_problem.is_empty():
		status_label.text = tr("GRIMORIO_ARQUIVO_ILEGIVEL") % _store.backup_path()
		load_problem = ""
	var names := _grimoire.names()
	if not _grimoire.has_spell(_selected) and not names.is_empty():
		_selected = names[0]
	_refresh_list()
	_show_selected()


func close() -> void:
	if not is_open():
		return
	_commit_editor()
	_save()
	_root.visible = false
	get_tree().paused = false


func toggle() -> void:
	if is_open():
		close()
	else:
		open()


func selected_name() -> String:
	return _selected


func select(spell_name: String) -> void:
	if not _grimoire.has_spell(spell_name):
		return
	_commit_editor()
	_selected = spell_name
	_refresh_list()
	_show_selected()


func new_spell() -> void:
	_commit_editor()
	var spell_name := _grimoire.next_default_name(tr("GRIMORIO_NOME_PADRAO"))
	_grimoire.create(spell_name)
	_selected = spell_name
	_refresh_list()
	_show_selected()
	_save()


func rename_selected(new_name: String) -> Grimoire.Problem:
	if _selected.is_empty():
		return Grimoire.Problem.NOT_FOUND
	_commit_editor()
	var problem := _grimoire.rename(_selected, new_name)
	if problem != Grimoire.Problem.OK:
		status_label.text = tr(PROBLEM_TEXT[problem]) % Grimoire.MAX_NAME_LENGTH \
				if problem == Grimoire.Problem.NAME_TOO_LONG else tr(PROBLEM_TEXT[problem])
		return problem
	_selected = new_name.strip_edges()
	name_field.text = _selected
	status_label.text = ""
	_refresh_list()
	_save()
	return problem


func delete_selected() -> void:
	if _selected.is_empty():
		return
	var names := Array(_grimoire.names())
	var index := names.find(_selected)
	_grimoire.delete(_selected)
	names = Array(_grimoire.names())
	_selected = "" if names.is_empty() else names[mini(index, names.size() - 1)]
	_refresh_list()
	_show_selected()
	_save()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open() and event.is_action_pressed(&"grimoire"):
		open()
		get_viewport().set_input_as_handled()
	elif is_open() and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_open():
		_commit_editor()
		_save()


func _commit_editor() -> void:
	if _grimoire and is_open() and _grimoire.has_spell(_selected):
		_grimoire.set_code(_selected, editor.text)


func _save() -> void:
	if _store and _grimoire:
		var error := _store.save(_grimoire)
		if error != OK:
			status_label.text = tr("GRIMORIO_ERRO_SALVAR") % error_string(error)


func _refresh_list() -> void:
	spell_list.clear()
	for spell_name in _grimoire.names():
		var index := spell_list.add_item(spell_name)
		if spell_name == _selected:
			spell_list.select(index)


func _show_selected() -> void:
	var has_selection := _grimoire.has_spell(_selected)
	editor.text = _grimoire.code_of(_selected) if has_selection else ""
	editor.editable = has_selection
	name_field.text = _selected


func _on_list_selected(index: int) -> void:
	select(spell_list.get_item_text(index))


func _build() -> void:
	add_child(_root)
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.offset_left = 24
	_root.offset_top = 20
	_root.offset_right = -24
	_root.offset_bottom = -20
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1d1a26f2")
	style.border_color = Color("8a6d3b")
	style.set_border_width_all(2)
	style.set_content_margin_all(8)
	_root.add_theme_stylebox_override(&"panel", style)

	var column := VBoxContainer.new()
	_root.add_child(column)
	var title := Label.new()
	title.text = "GRIMORIO_TITULO"
	title.add_theme_font_size_override(&"font_size", 12)
	column.add_child(title)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(split)

	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(150, 0)
	split.add_child(side)
	spell_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spell_list.add_theme_font_size_override(&"font_size", 9)
	spell_list.item_selected.connect(_on_list_selected)
	side.add_child(spell_list)
	name_field.max_length = Grimoire.MAX_NAME_LENGTH + 8
	name_field.add_theme_font_size_override(&"font_size", 9)
	name_field.text_submitted.connect(func(text: String) -> void: rename_selected(text))
	side.add_child(name_field)
	var buttons := HBoxContainer.new()
	side.add_child(buttons)
	for entry in [["GRIMORIO_NOVO", new_spell], ["GRIMORIO_RENOMEAR", func() -> void: rename_selected(name_field.text)],
			["GRIMORIO_APAGAR", delete_selected], ["GRIMORIO_FECHAR", close]]:
		var button := Button.new()
		button.text = entry[0]
		button.add_theme_font_size_override(&"font_size", 8)
		button.pressed.connect(entry[1])
		buttons.add_child(button)

	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.syntax_highlighter = PythonHighlighter.build()
	editor.gutters_draw_line_numbers = true
	editor.indent_automatic = true
	editor.indent_use_spaces = true
	editor.indent_size = 4
	editor.auto_brace_completion_enabled = true
	editor.add_theme_font_size_override(&"font_size", 9)
	editor.editable = false
	split.add_child(editor)

	status_label.add_theme_font_size_override(&"font_size", 9)
	status_label.add_theme_color_override(&"font_color", Color("ff9a7a"))
	column.add_child(status_label)
