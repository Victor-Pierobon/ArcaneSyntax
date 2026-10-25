class_name GrimoireStore
extends RefCounted
## Lê e grava o grimório em disco sem nunca perder o arquivo do jogador (spec GRI-feiticos).

const FORMAT_VERSION := 1
const DEFAULT_PATH := "user://grimorio.json"

var path: String
## Vazio se a última leitura deu certo; senão, o motivo.
var last_problem := ""


func _init(p_path: String = DEFAULT_PATH) -> void:
	path = p_path


func load_grimoire() -> Grimoire:
	last_problem = ""
	if not FileAccess.file_exists(path):
		return Grimoire.new()
	var text := FileAccess.get_file_as_string(path)
	var grimoire := Grimoire.from_dict(JSON.parse_string(text))
	if grimoire == null:
		last_problem = "o arquivo do grimório estava ilegível"
		_backup_original()
		return Grimoire.new()
	return grimoire


## Grava num .tmp e só então troca pelo arquivo final (GRI-024).
func save(grimoire: Grimoire) -> Error:
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(grimoire.to_dict(), "\t") + "\n")
	file.close()
	return DirAccess.rename_absolute(_absolute(tmp), _absolute(path))


func backup_path() -> String:
	return path + ".bak"


func _backup_original() -> void:
	var error := DirAccess.copy_absolute(_absolute(path), _absolute(backup_path()))
	if error != OK:
		push_warning("não foi possível guardar a cópia do grimório ilegível: %s" % error_string(error))


static func _absolute(p: String) -> String:
	return ProjectSettings.globalize_path(p)
