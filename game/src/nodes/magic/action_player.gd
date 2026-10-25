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

const KNOWN_ACTIONS := ["lancar", "mover", "levitar", "meditar", "absorver_mana", "inscrever", "construir_bloco"]

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
		var sequence_actions: Array = sequence["actions"]
		for i in sequence_actions.size():
			var action: Dictionary = sequence_actions[i]
			action_started.emit(action)
			var next_kind: String = sequence_actions[i + 1].get("tipo", "") if i + 1 < sequence_actions.size() else ""
			await _perform(action, next_kind)
			if step_delay > 0.0:
				await get_tree().create_timer(step_delay, false, true).timeout
	_playing = false
	finished.emit()


## `next_kind`: o tipo da ação seguinte da mesma conjuração; levitar seguido de mover voa (MAG-070).
func _perform(action: Dictionary, next_kind: String) -> void:
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
			var levitation := action.duplicate()
			levitation["seguinte"] = next_kind
			await port.act_levitar(levitation)
		"meditar":
			await port.act_meditar(action)
		"absorver_mana":
			await port.act_absorver_mana(action)
		"inscrever":
			await port.act_inscrever(action)
		"construir_bloco":
			await port.act_construir_bloco(action)
