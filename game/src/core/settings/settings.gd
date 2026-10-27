class_name Settings
extends RefCounted
## As opções do jogador (spec UI-menus, regra 5): tamanho do texto, volume e, desde a Sprint 20, tremer a
## tela (ART-brilho, regra 8), em `<perfil>/opcoes.json`.
## Arquivo ilegível ou valor fora da faixa usa o padrão; a gravação é atômica, como a do grimório.

enum TextSize { NORMAL, LARGE, HUGE }

## Pontos somados à fonte do grimório e dos diálogos, por tamanho.
const DELTAS := {TextSize.NORMAL: 0, TextSize.LARGE: 2, TextSize.HUGE: 3}
## Como cada tamanho fica no arquivo e qual texto o menu mostra.
const NAMES := {TextSize.NORMAL: "normal", TextSize.LARGE: "grande", TextSize.HUGE: "muito_grande"}
const LABELS := {TextSize.NORMAL: "OPCOES_TEXTO_NORMAL", TextSize.LARGE: "OPCOES_TEXTO_GRANDE",
		TextSize.HUGE: "OPCOES_TEXTO_MUITO_GRANDE"}
const DEFAULT_VOLUME := 80
const VOLUME_STEP := 10

var text_size: TextSize = TextSize.NORMAL
## De 0 a 100, de 10 em 10.
var volume := DEFAULT_VOLUME
## A câmera treme nos golpes (ART-brilho, regra 8).
var screen_shake := true
var path := ""


static func load_file(p_path: String) -> Settings:
	var settings := Settings.new()
	settings.path = p_path
	if not FileAccess.file_exists(p_path):
		return settings
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(p_path))
	if not data is Dictionary:
		return settings
	var size_name: Variant = data.get("tamanho_texto")
	for size: TextSize in NAMES:
		if NAMES[size] == size_name:
			settings.text_size = size
	var saved_volume: Variant = data.get("volume")
	if saved_volume is int or saved_volume is float:
		settings.set_volume(int(saved_volume))
	var shake: Variant = data.get("tremer_tela")
	if shake is bool:
		settings.screen_shake = shake
	return settings


func save() -> bool:
	if path.is_empty():
		return false
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"versao": 1, "tamanho_texto": NAMES[text_size], "volume": volume,
			"tremer_tela": screen_shake}, "  "))
	file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) == OK


func text_delta() -> int:
	return delta_for(text_size)


func delta_for(size: TextSize) -> int:
	return DELTAS[size]


func set_text_size(size: TextSize) -> void:
	text_size = size


## Normal → Grande → Muito grande → Normal.
func next_text_size() -> void:
	text_size = ((text_size + 1) % DELTAS.size()) as TextSize


func set_volume(value: int) -> void:
	volume = clampi(value / VOLUME_STEP * VOLUME_STEP, 0, 100)
