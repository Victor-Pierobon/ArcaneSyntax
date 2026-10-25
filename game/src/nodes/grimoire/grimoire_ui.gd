class_name GrimoireUI
extends CanvasLayer
## O grimório na tela: lista de feitiços, editor, slots, Testar e custo estimado
## (specs GRI-grimorio, GRI-slots, GRI-erros, GRI-autocompletar). Visual provisório.

const PROBLEM_TEXT := {
	Grimoire.Problem.EMPTY_NAME: "GRIMORIO_ERRO_NOME_VAZIO",
	Grimoire.Problem.NAME_TOO_LONG: "GRIMORIO_ERRO_NOME_LONGO",
	Grimoire.Problem.DUPLICATE_NAME: "GRIMORIO_ERRO_NOME_REPETIDO",
	Grimoire.Problem.NOT_FOUND: "GRIMORIO_ERRO_NAO_ENCONTRADO",
}
const MARK_COLOR := Color(0.75, 0.15, 0.15, 0.45)
const ESTIMATE_MANA := 1000.0
const ESTIMATE_TARGET := {"id": "estimativa", "elemento": "fogo", "distancia": 3.0}

var spell_list := ItemList.new()
var name_field := LineEdit.new()
var editor := CodeEdit.new()
var status_label := Label.new()
var result_label := Label.new()
var estimate_label := Label.new()
var slot_buttons: Array[Button] = []
var passive_button := Button.new()
## Espera meio segundo sem digitar antes de recalcular a estimativa (GRI-062).
var estimate_timer := Timer.new()
## Linha marcada no editor (1 = primeira), ou -1.
var marked_line := -1
## Motivo, se o arquivo do grimório estava ilegível; mostrado na primeira abertura (GRI-008).
var load_problem := ""

var _grimoire: Grimoire
var _store: GrimoireStore
var _executor: SpellExecutor
## Devolve {"mago", "target", "pieces"} com o estado atual do mundo.
var _context: Callable
## Último resultado (Testar ou conjuração) por feitiço (GRI-053).
var _last_results: Dictionary = {}
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


## Liga o executor e o estado do mundo, usados por Testar e pela estimativa.
func set_spell_runner(executor: SpellExecutor, context: Callable) -> void:
	_executor = executor
	_context = context


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
	estimate_timer.stop()
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
	var old_name := _selected
	var problem := _grimoire.rename(_selected, new_name)
	if problem != Grimoire.Problem.OK:
		status_label.text = tr(PROBLEM_TEXT[problem]) % Grimoire.MAX_NAME_LENGTH \
				if problem == Grimoire.Problem.NAME_TOO_LONG else tr(PROBLEM_TEXT[problem])
		return problem
	_selected = new_name.strip_edges()
	if _last_results.has(old_name):
		_last_results[_selected] = _last_results[old_name]
		_last_results.erase(old_name)
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
	_last_results.erase(_selected)
	_grimoire.delete(_selected)
	names = Array(_grimoire.names())
	_selected = "" if names.is_empty() else names[mini(index, names.size() - 1)]
	_refresh_list()
	_show_selected()
	_save()


func toggle_slot(slot_number: int) -> void:
	if not _grimoire.has_spell(_selected):
		return
	if _grimoire.slot(slot_number) == _selected:
		_grimoire.unequip(slot_number)
	else:
		_grimoire.equip(slot_number, _selected)
	_refresh_slot_buttons()
	_save()


## Equipa ou desequipa o selecionado no slot passivo (MAG-050).
func toggle_passive() -> void:
	if not _grimoire.has_spell(_selected):
		return
	if _grimoire.passive() == _selected:
		_grimoire.clear_passive()
	else:
		_grimoire.set_passive(_selected)
	_refresh_slot_buttons()
	_save()


## Guarda o resultado de uma conjuração para mostrar quando o feitiço for aberto (GRI-053).
func remember_result(spell_name: String, result: SpellResult) -> void:
	_last_results[spell_name] = result
	if is_open() and spell_name == _selected:
		_show_result(result)


## Executa o selecionado com o estado real, sem mudar o mundo (GRI-051).
func test_selected() -> void:
	if _executor == null or not _grimoire.has_spell(_selected):
		return
	_commit_editor()
	var context: Dictionary = _context.call()
	var request := SpellRequest.make(editor.text, context["mago"], context["target"], {}, context["pieces"])
	var spell_name := _selected
	result_label.text = tr("GRIMORIO_TESTANDO")
	var result: SpellResult = await _executor.execute(request)
	_last_results[spell_name] = result
	if spell_name == _selected:
		_show_result(result)


## Calcula o custo estimado agora (GRI-060).
func estimate_now() -> void:
	estimate_timer.stop()
	if _executor == null or not _grimoire.has_spell(_selected):
		estimate_label.text = ""
		return
	var code := editor.text
	var context: Dictionary = _context.call()
	var mago := {"vida": context["mago"].get("vida", 5), "mana": ESTIMATE_MANA, "mana_max": ESTIMATE_MANA}
	var request := SpellRequest.make(code, mago, ESTIMATE_TARGET, {}, context["pieces"])
	var result: SpellResult = await _executor.execute(request)
	if code != editor.text:
		return  # o código mudou enquanto estimava; outra estimativa vem a seguir
	if result.error:
		var line := "" if result.error.line == SpellError.NO_POSITION else str(result.error.line)
		estimate_label.text = tr("GRIMORIO_CUSTO_ERRO") % line
	else:
		estimate_label.text = tr("GRIMORIO_CUSTO") % SpellReport._number(result.cost)


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
	_set_marked_line(-1)
	result_label.text = ""
	if _last_results.has(_selected):
		_show_result(_last_results[_selected])
	_refresh_slot_buttons()
	estimate_label.text = ""
	if has_selection and _executor:
		estimate_timer.start()


func _show_result(result: SpellResult) -> void:
	result_label.text = SpellReport.full_text(result)
	var line := -1
	if result.error and result.error.line != SpellError.NO_POSITION:
		line = result.error.line
	_set_marked_line(line)


func _set_marked_line(line: int) -> void:
	if marked_line > 0 and marked_line <= editor.get_line_count():
		editor.set_line_background_color(marked_line - 1, Color(0, 0, 0, 0))
	marked_line = line
	if marked_line > 0 and marked_line <= editor.get_line_count():
		editor.set_line_background_color(marked_line - 1, MARK_COLOR)


func _refresh_slot_buttons() -> void:
	for i in slot_buttons.size():
		slot_buttons[i].set_pressed_no_signal(_selected != "" and _grimoire.slot(i + 1) == _selected)
	passive_button.set_pressed_no_signal(_selected != "" and _grimoire.passive() == _selected)


func _on_list_selected(index: int) -> void:
	select(spell_list.get_item_text(index))


func _on_editor_text_changed() -> void:
	if marked_line != -1:
		_set_marked_line(-1)
		_last_results.erase(_selected)
	if _executor and _grimoire and _grimoire.has_spell(_selected):
		estimate_timer.start()
	if editor.has_focus():
		editor.request_code_completion()


func _on_completion_requested() -> void:
	var line := editor.get_line(editor.get_caret_line()).substr(0, editor.get_caret_column())
	var prefix := CompletionProvider.prefix_before_caret(line)
	var unlocked: Variant = MagoState.ALL_PIECES
	if _context.is_valid():
		unlocked = _context.call()["pieces"]
	for option in CompletionProvider.suggest(prefix, unlocked):
		var kind := CodeEdit.KIND_FUNCTION if option["insert"].ends_with("(") else CodeEdit.KIND_CONSTANT
		if option["group"] == CompletionProvider.Group.KEYWORD:
			kind = CodeEdit.KIND_PLAIN_TEXT
		editor.add_code_completion_option(kind, option["display"], option["insert"])
	editor.update_code_completion_options(false)


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

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(right)
	var toolbar := HBoxContainer.new()
	right.add_child(toolbar)
	var equip_label := Label.new()
	equip_label.text = "GRIMORIO_EQUIPAR"
	equip_label.add_theme_font_size_override(&"font_size", 8)
	toolbar.add_child(equip_label)
	for i in Grimoire.SLOT_COUNT:
		var slot_button := Button.new()
		slot_button.text = str(i + 1)
		slot_button.toggle_mode = true
		slot_button.add_theme_font_size_override(&"font_size", 8)
		slot_button.pressed.connect(toggle_slot.bind(i + 1))
		toolbar.add_child(slot_button)
		slot_buttons.append(slot_button)
	passive_button.text = "GRIMORIO_PASSIVO"
	passive_button.toggle_mode = true
	passive_button.add_theme_font_size_override(&"font_size", 8)
	passive_button.pressed.connect(toggle_passive)
	toolbar.add_child(passive_button)
	var test_button := Button.new()
	test_button.text = "GRIMORIO_TESTAR"
	test_button.add_theme_font_size_override(&"font_size", 8)
	test_button.pressed.connect(test_selected)
	toolbar.add_child(test_button)
	estimate_label.add_theme_font_size_override(&"font_size", 8)
	estimate_label.add_theme_color_override(&"font_color", Color("ffcb6b"))
	toolbar.add_child(estimate_label)

	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor.syntax_highlighter = PythonHighlighter.build()
	editor.gutters_draw_line_numbers = true
	editor.indent_automatic = true
	editor.indent_use_spaces = true
	editor.indent_size = 4
	editor.auto_brace_completion_enabled = true
	editor.code_completion_enabled = true
	editor.add_theme_font_size_override(&"font_size", 9)
	editor.editable = false
	editor.text_changed.connect(_on_editor_text_changed)
	editor.code_completion_requested.connect(_on_completion_requested)
	right.add_child(editor)

	# Com rolagem: resultados com muitas ações não cabem em altura fixa (regressão GRI-051).
	var result_scroll := ScrollContainer.new()
	result_scroll.custom_minimum_size = Vector2(0, 80)
	result_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(result_scroll)
	result_label.add_theme_font_size_override(&"font_size", 8)
	result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_scroll.add_child(result_label)

	estimate_timer.one_shot = true
	estimate_timer.wait_time = 0.5
	estimate_timer.timeout.connect(estimate_now)
	add_child(estimate_timer)

	status_label.add_theme_font_size_override(&"font_size", 9)
	status_label.add_theme_color_override(&"font_color", Color("ff9a7a"))
	column.add_child(status_label)
