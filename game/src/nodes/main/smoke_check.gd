class_name SmokeCheck
extends Node
## Teste de fumaça do jogo exportado (spec BLD-alpha, regra 4): `ArcaneSyntax.console.exe --headless --
## --fumaca`. Confere o que só quebra fora do editor: conteúdo que não foi exportado, salas `.remap`,
## textos sem tradução e o executor Python ao lado do `.exe`.

const ARG := "--fumaca"
const ROOMS_DIR := "res://content/rooms/"
const SPELL := "meditar()\nprint(\"fumaça\")"

## Caminho do Python; vazio usa o mesmo que o jogo (os testes trocam para simular um executor quebrado).
var python_path := ""


static func requested(args: PackedStringArray) -> bool:
	return ARG in args


## Os problemas encontrados; vazio se está tudo certo.
func run() -> Array[String]:
	var problems: Array[String] = []
	for error in Balance.errors():
		problems.append("balanceamento: " + error)
	for error in DialogueBook.load_file(DialogueBook.DEFAULT_PATH).errors:
		problems.append("diálogos: " + error)
	for error in HintBook.load_file(HintBook.DEFAULT_PATH).errors:
		problems.append("dicas: " + error)
	for error in ReferenceBook.load_file(ReferenceBook.DEFAULT_PATH).errors:
		problems.append("referência: " + error)
	if tr("MENU_TITULO") == "MENU_TITULO":
		problems.append("textos: o textos.csv não foi carregado")
	var area := AreaMap.load_dir(ROOMS_DIR)
	var walk := area.walkthrough("sala_01", "A")
	if area.room_ids().is_empty() or walk["rooms"].size() != area.room_ids().size():
		problems.append("mapa: %d salas carregadas, %d alcançadas" % [area.room_ids().size(), walk["rooms"].size()])
	var executor := PythonSpellExecutor.new()
	executor.python_path = python_path
	add_child(executor)
	var result: SpellResult = await executor.execute(SpellRequest.make(SPELL, {"vida": 5, "mana": 0.0, "mana_max": 10.0}))
	executor.queue_free()
	var vision := str(result.outputs[0].get("texto", "")) if not result.outputs.is_empty() else ""
	if not result.ok or vision != "fumaça" or float(result.mago.get("mana", 0)) <= 0.0:
		var reason := result.error.message if result.error else "visão '%s', mana %s" % [vision, result.mago.get("mana")]
		problems.append("executor: " + reason)
	return problems


## Escreve o resultado na saída, para o script de build ler.
static func report(problems: Array[String]) -> void:
	if problems.is_empty():
		print("FUMACA OK")
	else:
		for problem in problems:
			printerr("FUMACA FALHOU: " + problem)
