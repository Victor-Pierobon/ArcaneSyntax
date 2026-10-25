class_name ActionPlayer
extends Node
## Toca a fila de ações devolvida pelo executor, uma depois da outra (spec MAG-acoes).
## Quem faz cada ação acontecer é o `port` (WorldActions no jogo, FakeWorldPort nos testes):
## um método `act_<tipo>(acao)` por tipo de ação.

signal finished
## Uma nova sequência (feitiço) começou a tocar (spec PUZ-passo-a-passo).
signal sequence_started(code: String)
## Uma ação vai começar; tem a `linha` do código que a gerou.
signal action_started(action: Dictionary)

const KNOWN_ACTIONS := ["lancar", "mover", "levitar", "meditar", "absorver_mana"]

var port: Object
## Pausa depois de cada ação, para acompanhar o passo a passo nos puzzles (PUZ-011).
var step_delay := 0.0

## [{"code": String, "actions": Array}], uma entrada por conjuração.
var _queue: Array[Dictionary] = []
var _playing := false


func is_playing() -> bool:
	return _playing


## Enfileira as ações de uma conjuração; se nada estiver tocando, começa.
## Novas conjurações esperam a atual (MAG-003).
func play(actions: Array, code: String = "") -> void:
	if not actions.is_empty():
		_queue.append({"code": code, "actions": actions})
	if _playing or _queue.is_empty():
		return
	_playing = true
	while not _queue.is_empty():
		var sequence: Dictionary = _queue.pop_front()
		sequence_started.emit(sequence["code"])
		for action: Dictionary in sequence["actions"]:
			action_started.emit(action)
			await _perform(action)
			if step_delay > 0.0:
				await get_tree().create_timer(step_delay, false, true).timeout
	_playing = false
	finished.emit()


func _perform(action: Dictionary) -> void:
	var kind: String = action.get("tipo", "")
	if not kind in KNOWN_ACTIONS:
		push_warning("ação desconhecida ignorada: %s" % kind)
		return
	match kind:
		"lancar":
			await port.act_lancar(action)
		"mover":
			await port.act_mover(action)
		"levitar":
			await port.act_levitar(action)
		"meditar":
			await port.act_meditar(action)
		"absorver_mana":
			await port.act_absorver_mana(action)
