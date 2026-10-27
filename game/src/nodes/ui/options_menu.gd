class_name OptionsMenu
extends MenuPanel
## Opções (spec UI-menus, regra 5): tamanho do texto, volume e tremer a tela (ART-brilho, regra 8). Cada mudança grava e avisa na hora;
## o mesmo painel serve ao menu inicial e à pausa. Esc ou Voltar fecha.

signal changed
signal closed

var text_button: Button
var volume_label: Label
var volume_slider := HSlider.new()
var shake_button: Button
var back_button: Button

var _settings: Settings


func _init() -> void:
	super._init()
	layer = 21
	title_label.text = "OPCOES_TITULO"
	text_button = add_button("")
	volume_label = add_label("")
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.step = Settings.VOLUME_STEP
	volume_slider.custom_minimum_size = Vector2(160, 12)
	column.add_child(volume_slider)
	shake_button = add_button("")
	back_button = add_button("OPCOES_VOLTAR")
	text_button.pressed.connect(_on_text_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	shake_button.pressed.connect(_on_shake_pressed)
	back_button.pressed.connect(close)


func bind(settings: Settings) -> void:
	_settings = settings
	_refresh()


func is_open() -> bool:
	return is_showing()


func open() -> void:
	_refresh()
	show_panel()


func close() -> void:
	if not is_open():
		return
	hide_panel()
	closed.emit()


func _on_text_pressed() -> void:
	_settings.next_text_size()
	_commit()


func _on_shake_pressed() -> void:
	_settings.screen_shake = not _settings.screen_shake
	_commit()


func _on_volume_changed(value: float) -> void:
	if _settings == null or int(value) == _settings.volume:
		return
	_settings.set_volume(int(value))
	_commit()


func _commit() -> void:
	_settings.save()
	_refresh()
	changed.emit()


func _refresh() -> void:
	if _settings == null:
		return
	text_button.text = tr("OPCOES_TEXTO") % tr(Settings.LABELS[_settings.text_size])
	volume_label.text = tr("OPCOES_VOLUME") % _settings.volume
	volume_slider.set_value_no_signal(_settings.volume)
	shake_button.text = tr("OPCOES_TREMER") % tr("OPCOES_SIM" if _settings.screen_shake else "OPCOES_NAO")


func _unhandled_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
