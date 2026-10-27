class_name TitleMenu
extends MenuPanel
## Menu inicial (spec UI-menus, regras 1 e 2): Continuar (só com save), Novo jogo, Opções e Sair.
## Novo jogo com save pergunta antes; a cena principal decide o que cada botão faz.

signal continue_chosen
signal new_game_chosen
signal options_chosen
signal quit_chosen

var continue_button: Button
var new_game_button: Button
var options_button: Button
var quit_button: Button
var confirm_label: Label
var confirm_yes: Button
var confirm_no: Button
## O logo do Victor (`ui/logo`), no lugar do título em texto; null sem o arquivo (ART-brilho, regra 11).
var logo: TextureRect

var _main_buttons: Array[Button] = []
var _confirming := false
var _has_save := false


func _init() -> void:
	super._init()
	title_label.text = "MENU_TITULO"
	var logo_texture := UiSkin.logo()
	if logo_texture:
		logo = TextureRect.new()
		logo.texture = logo_texture
		logo.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		column.add_child(logo)
		column.move_child(logo, title_label.get_index())
		title_label.visible = false
	add_label("MENU_SUBTITULO")
	continue_button = add_button("MENU_CONTINUAR")
	new_game_button = add_button("MENU_NOVO_JOGO")
	options_button = add_button("MENU_OPCOES")
	quit_button = add_button("MENU_SAIR")
	_main_buttons = [continue_button, new_game_button, options_button, quit_button]
	confirm_label = add_label("MENU_CONFIRMA_NOVO", 9)
	confirm_yes = add_button("MENU_SIM")
	confirm_no = add_button("MENU_NAO")
	add_label("MENU_DICA_TECLAS", 7).modulate = Color(1, 1, 1, 0.6)
	continue_button.pressed.connect(continue_chosen.emit)
	new_game_button.pressed.connect(new_game_chosen.emit)
	options_button.pressed.connect(options_chosen.emit)
	quit_button.pressed.connect(quit_chosen.emit)
	confirm_no.pressed.connect(cancel_confirm)
	_show_confirm(false)


## Mostra o menu; Continuar só aparece com save.
func open(has_save: bool) -> void:
	_has_save = has_save
	_show_confirm(false)
	show_panel()


## "O progresso salvo será apagado. Começar de novo?" com o foco no Não.
func ask_new_game() -> void:
	_show_confirm(true)
	confirm_no.grab_focus()


func cancel_confirm() -> void:
	_show_confirm(false)
	new_game_button.grab_focus()


func is_confirming() -> bool:
	return _confirming


func _show_confirm(confirming: bool) -> void:
	_confirming = confirming
	for button in _main_buttons:
		button.visible = not confirming
	continue_button.visible = _has_save and not confirming
	confirm_label.visible = confirming
	confirm_yes.visible = confirming
	confirm_no.visible = confirming


func _unhandled_input(event: InputEvent) -> void:
	if is_showing() and _confirming and event.is_action_pressed(&"ui_cancel"):
		cancel_confirm()
		get_viewport().set_input_as_handled()
