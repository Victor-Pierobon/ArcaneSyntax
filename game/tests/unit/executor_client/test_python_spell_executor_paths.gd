extends GdUnitTestSuite
## Onde o cliente procura executor/ e runtime/ (docs/sprints/sprint-02-executor-custo-sandbox.md, build de fumaça).


func test_no_editor_usa_a_raiz_do_repositorio() -> void:
	var dir := PythonSpellExecutor.base_dir(true, "C:/repo/ArcaneSyntax/game/", "C:/Godot/godot.exe")
	assert_str(dir).is_equal("C:/repo/ArcaneSyntax")


func test_no_jogo_exportado_usa_a_pasta_do_executavel() -> void:
	var dir := PythonSpellExecutor.base_dir(false, "res://", "C:/Jogos/ArcaneSyntax/ArcaneSyntax.exe")
	assert_str(dir).is_equal("C:/Jogos/ArcaneSyntax")
