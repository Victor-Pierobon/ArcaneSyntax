class_name DialogueRun
extends RefCounted
## Leitura de uma cena de diálogo (spec NAR-dialogo, regra 4): fala atual, avançar e escolher.
## A cena já foi validada pelo DialogueBook. Guarda as falas que apareceram (lição e dica, NAR-serpente
## e NAR-dicas, contam pela fala vista).

var line_id := ""

var _lines: Dictionary
var _seen := {}


func _init(scene: Dictionary) -> void:
	_lines = scene.get("falas", {})
	_go_to(str(scene.get("inicio", "")))


func is_finished() -> bool:
	return not _lines.has(line_id)


## Se a fala `id` já apareceu nesta leitura.
func has_seen(id: String) -> bool:
	return _seen.has(id)


## {"quem", "texto", "opcoes"}, com os textos traduzidos; vazio quando a cena acabou.
func current() -> Dictionary:
	if is_finished():
		return {}
	var line: Dictionary = _lines[line_id]
	var options := []
	for option: Dictionary in line.get("opcoes", []):
		options.append(tr(str(option["texto"])))
	return {"quem": str(line.get("quem", "serpente")), "texto": tr(str(line["texto"])), "opcoes": options}


## Vai para a próxima fala; numa fala com opções não faz nada; na última, termina.
func advance() -> void:
	if is_finished():
		return
	var line: Dictionary = _lines[line_id]
	if line.has("opcoes"):
		return
	_go_to(str(line.get("proxima", "")))


## Segue a opção `number` (a partir de 1); número fora das opções não faz nada.
func choose(number: int) -> void:
	if is_finished():
		return
	var options: Array = _lines[line_id].get("opcoes", [])
	if number < 1 or number > options.size():
		return
	_go_to(str(options[number - 1]["proxima"]))


func _go_to(id: String) -> void:
	line_id = id
	if _lines.has(id):
		_seen[id] = true
