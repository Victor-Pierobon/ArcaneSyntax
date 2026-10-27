extends GdUnitTestSuite
## Spec: docs/specs/build/BLD-alpha.md (BLD-001 a BLD-003): o teste de fumaça do jogo exportado,
## rodando no editor com o executor de verdade.


func test_BLD_001_fumaca_passa_no_editor() -> void:
	var smoke: SmokeCheck = auto_free(SmokeCheck.new())
	add_child(smoke)
	var problems: Array[String] = await smoke.run()
	assert_array(problems).is_empty()


func test_BLD_002_fumaca_aponta_o_executor() -> void:
	var smoke: SmokeCheck = auto_free(SmokeCheck.new())
	smoke.python_path = "C:/nao/existe/python.exe"
	add_child(smoke)
	var problems: Array[String] = await smoke.run()
	assert_int(problems.size()).is_equal(1)
	assert_str(problems[0]).contains("executor")


## Regressão (Sprint 15, build): no modo fumaça a Main criava os menus e nunca os punha na árvore; eles
## vazavam ao fechar o jogo exportado. O GdUnit4 acusa nós órfãos no fim do teste.
func test_BLD_003_fumaca_nao_cria_os_menus() -> void:
	var main: Main = auto_free(load("res://src/nodes/main/main.tscn").instantiate())
	main.user_args = PackedStringArray([SmokeCheck.ARG])
	main.quit_after_smoke = false
	add_child(main)
	assert_object(main.title_menu).is_null()
	assert_object(main.world).is_null()
	await main.smoke_finished
	for i in 2:
		await get_tree().process_frame


func test_BLD_003_pedido_pela_linha_de_comando() -> void:
	assert_bool(SmokeCheck.requested(PackedStringArray(["--fumaca"]))).is_true()
	assert_bool(SmokeCheck.requested(PackedStringArray([]))).is_false()
	assert_bool(SmokeCheck.requested(PackedStringArray(["--outra"]))).is_false()
