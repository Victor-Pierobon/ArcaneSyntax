class_name ActionPlayer
extends Node
## Toca a fila de ações devolvida pelo executor, uma depois da outra (spec MAG-acoes).
## Quem faz cada ação acontecer é o `port` (WorldActions no jogo, FakeWorldPort nos testes):
## um método `act_<tipo>(acao)` por tipo de ação.

signal finished

const KNOWN_ACTIONS := ["lancar", "mover", "levitar", "meditar", "absorver_mana"]

var port: Object

var _queue: Array[Dictionary] = []
var _playing := false


func is_playing() -> bool:
	return _playing


## Enfileira as ações; se nada estiver tocando, começa. Novas filas esperam a atual (MAG-003).
func play(actions: Array) -> void:
	for action in actions:
		_queue.append(action)
	if _playing or _queue.is_empty():
		return
	_playing = true
	while not _queue.is_empty():
		await _perform(_queue.pop_front())
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
