class_name ProgressStore
extends RefCounted
## O arquivo do save (spec SAV-progresso, regras 3, 4 e 6): grava de forma atômica e, se o arquivo
## estiver ilegível ou for de uma versão que o jogo não conhece, guarda uma cópia `.bak` e devolve vazio.

const VERSION := 1

var path: String
## Motivo de o último `load_data` ter devolvido vazio com um arquivo presente.
var last_problem := ""


func _init(p_path: String) -> void:
	path = p_path


## Grava `data` com a versão; devolve false se não conseguiu.
func save(data: Dictionary) -> bool:
	var content := data.duplicate(true)
	content["versao"] = VERSION
	DirAccess.make_dir_recursive_absolute(_absolute(path.get_base_dir()))
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(content, "  "))
	file.close()
	return DirAccess.rename_absolute(_absolute(tmp), _absolute(path)) == OK


## O conteúdo do save, já migrado para a versão atual; vazio sem arquivo ou com problema.
func load_data() -> Dictionary:
	last_problem = ""
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return _reject(tr("SAVE_ILEGIVEL"))
	var version: Variant = parsed.get("versao")
	if not (version is float or version is int):
		return _reject(tr("SAVE_ILEGIVEL"))
	if int(version) > VERSION:
		return _reject(tr("SAVE_VERSAO_NOVA") % int(version))
	# Migrações de versões anteriores entram aqui, em ordem; a 1 é a primeira.
	if int(version) < VERSION:
		return _reject(tr("SAVE_ILEGIVEL"))
	return parsed


func _reject(reason: String) -> Dictionary:
	last_problem = reason
	DirAccess.copy_absolute(_absolute(path), _absolute(path + ".bak"))
	return {}


static func _absolute(p: String) -> String:
	return ProjectSettings.globalize_path(p)
