class_name FakeWorldPort
extends Node
## Mundo de mentira para testar o ActionPlayer: registra o começo e o fim de cada ação.

var calls: Array[String] = []
## Quadros que cada ação demora.
var frames_per_action := 2
## Para cada levitar, a ação que vem depois (MAG-070).
var next_after_levitar: Array[String] = []


func act_lancar(action: Dictionary) -> void:
	await _run("lancar", action)


func act_mover(action: Dictionary) -> void:
	await _run("mover", action)


func act_levitar(action: Dictionary) -> void:
	next_after_levitar.append(str(action.get("seguinte", "")))
	await _run("levitar", action)


func act_meditar(action: Dictionary) -> void:
	await _run("meditar", action)


func act_absorver_mana(action: Dictionary) -> void:
	await _run("absorver_mana", action)


func act_inscrever(action: Dictionary) -> void:
	await _run("inscrever", action)


func act_construir_bloco(action: Dictionary) -> void:
	await _run("construir_bloco", action)


func _run(kind: String, _action: Dictionary) -> void:
	calls.append("início " + kind)
	for i in frames_per_action:
		await get_tree().process_frame
	calls.append("fim " + kind)
