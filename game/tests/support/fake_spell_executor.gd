class_name FakeSpellExecutor
extends SpellExecutor
## Executor de mentira para testar sistemas que conjuram sem subir o Python.
## Guarda as requisições e devolve respostas programadas (ou uma resposta vazia de sucesso).

var requests: Array[SpellRequest] = []
var next_results: Array[SpellResult] = []
## Quadros de espera antes de responder, para simular a demora do executor.
var delay_frames := 0


func execute(request: SpellRequest) -> SpellResult:
	requests.append(request)
	for i in delay_frames:
		await get_tree().process_frame
	if not next_results.is_empty():
		return next_results.pop_front()
	return SpellResult.from_dict({"ok": true, "acoes": [], "saidas": [], "mago": request.mago, "custo_mana": 0})


## Resposta pronta a partir de um dicionário no formato do protocolo.
func queue_result(data: Dictionary) -> void:
	next_results.append(SpellResult.from_dict(data))
