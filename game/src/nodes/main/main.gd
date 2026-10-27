class_name Main
extends Node
## Cena principal do jogo (specs SAV-progresso, regras 1, 2 e 5, e UI-menus): escolhe a pasta do perfil,
## traz o grimório de antes da Sprint 13, abre no menu inicial e sobe o World com o save ligado. Também
## cuida da pausa, das opções e da tela de fim. Os testes sobem o World direto, sem save.

## O teste de fumaça terminou (BLD-alpha); vazio = tudo certo.
signal smoke_finished(problems: Array[String])

const WORLD := preload("res://src/nodes/world/world.tscn")

@export var profile_root := "user://perfis"
## Um perfil só na Alpha.
@export var profile := "padrao"
## Onde o grimório ficava antes dos perfis.
@export var legacy_grimoire := GrimoireStore.DEFAULT_PATH

## O mundo em jogo; null no menu inicial.
var world: World
var settings: Settings
## Criados no `_ready`, depois da fumaça: criados antes, vazavam no modo fumaça (regressão, Sprint 15).
var title_menu: TitleMenu
var pause_menu: PauseMenu
var options_menu: OptionsMenu
var end_screen: EndScreen
## Argumentos depois de `--` na linha de comando; os testes trocam.
var user_args := OS.get_cmdline_user_args()
## Os testes rodam a fumaça sem fechar o Godot.
var quit_after_smoke := true

var _folder := ""


func _ready() -> void:
	# Build: `--fumaca` confere o jogo exportado e sai, sem abrir o menu (BLD-alpha, regra 4).
	if SmokeCheck.requested(user_args):
		_run_smoke()
		return
	title_menu = TitleMenu.new()
	pause_menu = PauseMenu.new()
	options_menu = OptionsMenu.new()
	end_screen = EndScreen.new()
	_folder = profile_root.path_join(profile)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_folder))
	if FileAccess.file_exists(legacy_grimoire) and not FileAccess.file_exists(grimoire_path()):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(legacy_grimoire), ProjectSettings.globalize_path(grimoire_path()))
	settings = Settings.load_file(_folder.path_join("opcoes.json"))
	_apply_volume()
	# As opções depois da pausa: Esc chega primeiro nelas (UI-menus, regra 5).
	for menu in [title_menu, end_screen, pause_menu, options_menu]:
		add_child(menu)
	options_menu.bind(settings)
	title_menu.continue_chosen.connect(continue_game)
	title_menu.new_game_chosen.connect(new_game)
	title_menu.confirm_yes.pressed.connect(_start.bind(true))
	title_menu.options_chosen.connect(options_menu.open)
	title_menu.quit_chosen.connect(func() -> void: get_tree().quit())
	pause_menu.options_chosen.connect(options_menu.open)
	pause_menu.menu_chosen.connect(return_to_menu)
	options_menu.changed.connect(_apply_settings)
	options_menu.closed.connect(_on_options_closed)
	end_screen.done.connect(return_to_menu)
	title_menu.open(has_save())


func _run_smoke() -> void:
	var smoke := SmokeCheck.new()
	add_child(smoke)
	var problems: Array[String] = await smoke.run()
	SmokeCheck.report(problems)
	smoke_finished.emit(problems)
	if quit_after_smoke:
		# Um quadro para o executor sair da árvore antes de fechar.
		await get_tree().process_frame
		get_tree().quit(0 if problems.is_empty() else 1)


func grimoire_path() -> String:
	return _folder.path_join("grimorio.json")


func save_path() -> String:
	return _folder.path_join("save.json")


func has_save() -> bool:
	return FileAccess.file_exists(save_path())


## Continuar: o mundo carrega o save do perfil (sem save, começa do zero).
func continue_game() -> void:
	_start(false)


## Novo jogo: com save, pergunta antes (UI-menus, regra 2).
func new_game() -> void:
	if has_save():
		title_menu.ask_new_game()
	else:
		_start(true)


## Salva, fecha o mundo e volta ao menu inicial (UI-menus, regra 4).
func return_to_menu() -> void:
	if world:
		world.save_progress()
		remove_child(world)
		world.queue_free()
		world = null
	pause_menu.world = null
	pause_menu.close()
	end_screen.hide_panel()
	get_tree().paused = false
	title_menu.open(has_save())


func _start(fresh: bool) -> void:
	if world:
		return
	# O grimório nunca é apagado: os feitiços são do jogador.
	if fresh and has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path()))
	title_menu.hide_panel()
	world = WORLD.instantiate()
	world.grimoire_path = grimoire_path()
	world.save_path = save_path()
	add_child(world)
	move_child(world, 0)
	world.demo_finished.connect(_on_demo_finished)
	pause_menu.world = world
	_apply_settings()


## A conversa do fim terminou: o mundo para e o resumo aparece (UI-menus, regra 7).
func _on_demo_finished() -> void:
	get_tree().paused = true
	end_screen.show_summary(world.summary())


func _apply_settings() -> void:
	_apply_volume()
	if world:
		world.grimoire_ui.set_text_delta(settings.text_delta())
		world.dialogue_box.set_text_delta(settings.text_delta())


func _apply_volume() -> void:
	AudioServer.set_bus_mute(0, settings.volume == 0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(settings.volume, 1) / 100.0))


func _on_options_closed() -> void:
	if pause_menu.is_open():
		pause_menu.focus_first()
	elif title_menu.is_showing():
		title_menu.focus_first()
