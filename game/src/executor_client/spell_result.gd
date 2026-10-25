class_name SpellResult
extends RefCounted
## Resposta do executor (spec EXE-protocolo). Ações e saídas ficam como Dictionary;
## só "linha" é convertida para int, porque o JSON do Godot lê todo número como float.

var id: Variant = null
var ok: bool = false
var actions: Array[Dictionary] = []
var outputs: Array[Dictionary] = []
## Estado do mago no fim da execução; vazio quando a requisição foi recusada.
var mago: Dictionary = {}
## Mana gasta em instruções e peças (spec EXE-custo).
var cost: float = 0.0
## null quando ok.
var error: SpellError = null


static func from_dict(data: Dictionary) -> SpellResult:
	var result := SpellResult.new()
	result.id = data.get("id")
	result.ok = bool(data.get("ok", false))
	for action: Dictionary in data.get("acoes", []):
		result.actions.append(_with_int_line(action))
	for output: Dictionary in data.get("saidas", []):
		result.outputs.append(_with_int_line(output))
	if data.get("mago") is Dictionary:
		result.mago = data["mago"]
	result.cost = float(data.get("custo_mana", 0.0))
	if data.get("erro") is Dictionary:
		result.error = SpellError.from_dict(data["erro"])
	return result


## Falha detectada do lado do Godot (executor fora do ar, resposta ilegível).
static func failure(type: String, message: String) -> SpellResult:
	var result := SpellResult.new()
	result.error = SpellError.make(type, message)
	return result


static func _with_int_line(entry: Dictionary) -> Dictionary:
	var copy := entry.duplicate()
	if copy.get("linha") != null:
		copy["linha"] = int(copy["linha"])
	return copy


func to_dict() -> Dictionary:
	return {
		"versao": SpellRequest.PROTOCOL_VERSION,
		"id": id,
		"ok": ok,
		"acoes": actions,
		"saidas": outputs,
		"mago": null if mago.is_empty() else mago,
		"custo_mana": cost,
		"erro": null if error == null else error.to_dict(),
	}
