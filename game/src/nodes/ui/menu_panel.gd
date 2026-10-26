class_name MenuPanel
extends CanvasLayer
## Base dos menus (spec UI-menus): painel centralizado com título e uma coluna de botões, que funciona
## com o jogo pausado e só com o teclado. Visual provisório.

const BORDER := Color("6fcf5a")

var title_label := Label.new()
var column := VBoxContainer.new()

var _root := Control.new()
var _panel := PanelContainer.new()


func _init() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_root)
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color("0b0a12d0")
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1d1a26f2")
	style.border_color = BORDER
	style.set_border_width_all(2)
	style.set_content_margin_all(10)
	_panel.add_theme_stylebox_override(&"panel", style)
	_panel.custom_minimum_size = Vector2(200, 0)
	center.add_child(_panel)
	column.add_theme_constant_override(&"separation", 4)
	_panel.add_child(column)
	title_label.add_theme_font_size_override(&"font_size", 14)
	title_label.add_theme_color_override(&"font_color", BORDER)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title_label)
	_root.visible = false


func is_showing() -> bool:
	return _root.visible


func show_panel() -> void:
	_root.visible = true
	focus_first()


func hide_panel() -> void:
	_root.visible = false


## Põe o foco no primeiro botão visível (UI-menus, regra 1).
func focus_first() -> void:
	for child in column.get_children():
		if child is Button and child.visible:
			child.grab_focus()
			return


func add_button(key: String) -> Button:
	var button := Button.new()
	button.text = key
	button.add_theme_font_size_override(&"font_size", 10)
	column.add_child(button)
	return button


func add_label(key: String, size := 8) -> Label:
	var label := Label.new()
	label.text = key
	label.add_theme_font_size_override(&"font_size", size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(label)
	return label
