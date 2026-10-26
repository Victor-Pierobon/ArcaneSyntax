class_name PauseMenu
extends MenuPanel
## Menu de pausa (spec UI-menus, regras 3 e 4): Esc no jogo abre e pausa o mundo. Com o grimório ou um
## diálogo aberto, o jogo já está pausado e Esc fica com eles. Com a pausa aberta, o grimório não abre.

signal options_chosen
signal menu_chosen

## O mundo em jogo; sem mundo (no menu inicial), Esc não faz nada.
var world: World
var resume_button: Button
var options_button: Button
var menu_button: Button


func _init() -> void:
	super._init()
	title_label.text = "PAUSA_TITULO"
	resume_button = add_button("PAUSA_CONTINUAR")
	options_button = add_button("PAUSA_OPCOES")
	menu_button = add_button("PAUSA_MENU")
	resume_button.pressed.connect(close)
	options_button.pressed.connect(options_chosen.emit)
	menu_button.pressed.connect(menu_chosen.emit)


func is_open() -> bool:
	return is_showing()


func open() -> void:
	if is_open() or world == null or get_tree().paused:
		return
	world.grimoire_ui.blocked = true
	get_tree().paused = true
	show_panel()


func close() -> void:
	if not is_open():
		return
	hide_panel()
	get_tree().paused = false
	if world:
		world.grimoire_ui.blocked = false


## Esc: fecha a pausa aberta ou abre com o jogo correndo.
func handle_cancel() -> bool:
	if is_open():
		close()
		return true
	if world == null or get_tree().paused:
		return false
	open()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and handle_cancel():
		get_viewport().set_input_as_handled()
