extends GdUnitTestSuite
## Spec: docs/specs/executor/EXE-protocolo.md (EXE-007, EXE-008), com o Python de verdade.

const MAGO := {"vida": 10, "mana": 5, "mana_max": 20}
const ALVO := {"id": "elemental_1", "elemento": "fogo", "distancia": 4.5}

var executor: PythonSpellExecutor


func before_test() -> void:
	executor = auto_free(PythonSpellExecutor.new())
	add_child(executor)


func test_EXE_007_lancar_volta_como_acao_na_linha_1() -> void:
	var result: SpellResult = await executor.execute(SpellRequest.make("lancar(fogo, projetil, alvo)", MAGO, ALVO))
	assert_bool(result.ok).override_failure_message(str(result.to_dict())).is_true()
	assert_int(result.actions.size()).is_equal(1)
	assert_str(result.actions[0]["tipo"]).is_equal("lancar")
	assert_int(result.actions[0]["linha"]).is_equal(1)
	assert_str(result.actions[0]["alvo"]).is_equal("elemental_1")


func test_EXE_007_reaproveita_o_mesmo_worker() -> void:
	await executor.execute(SpellRequest.make("meditar()", MAGO))
	var pid := executor.worker_pid()
	var result: SpellResult = await executor.execute(SpellRequest.make("meditar()\nmeditar()", MAGO))
	assert_int(result.actions.size()).is_equal(2)
	assert_int(executor.worker_pid()).is_equal(pid)


func test_EXE_007_erro_de_sintaxe_volta_com_a_linha() -> void:
	var result: SpellResult = await executor.execute(SpellRequest.make("x = 1\nif x\n    meditar()", MAGO))
	assert_bool(result.ok).is_false()
	assert_str(result.error.type).is_equal("SyntaxError")
	assert_int(result.error.line).is_equal(2)


func test_EXE_007_texto_com_acento_ida_e_volta() -> void:
	var result: SpellResult = await executor.execute(SpellRequest.make("print('visão ✨')", MAGO))
	assert_str(result.outputs[0]["texto"]).is_equal("visão ✨")


func test_EXE_007_chamadas_simultaneas_sao_atendidas_em_ordem() -> void:
	var results := []
	var run := func(code: String) -> void:
		results.append(await executor.execute(SpellRequest.make(code, MAGO)))
	run.call("mover(1)")
	await run.call("mover(1)\nmover(2)")
	await await_millis(200)
	assert_int(results.size()).is_equal(2)
	assert_int(results[0].actions.size()).is_equal(1)
	assert_int(results[1].actions.size()).is_equal(2)


func test_EXE_007_custo_de_mana_chega_ao_godot() -> void:
	var result: SpellResult = await executor.execute(SpellRequest.make("lancar(fogo, projetil, alvo)", MAGO, ALVO))
	assert_float(result.cost).is_equal_approx(3.1, 0.0001)
	assert_float(float(result.mago["mana"])).is_equal_approx(1.9, 0.0001)


func test_EXE_058_watchdog_mata_feitico_preso_em_codigo_c() -> void:
	executor.timeout_ms = 1500
	await executor.execute(SpellRequest.make("meditar()", MAGO))
	var old_pid := executor.worker_pid()
	var started := Time.get_ticks_msec()
	var stuck: SpellResult = await executor.execute(SpellRequest.make("x = 10 ** 10 ** 8", MAGO))
	assert_str(stuck.error.type).is_equal("TempoEsgotado")
	assert_int(Time.get_ticks_msec() - started).is_less(4000)
	var next: SpellResult = await executor.execute(SpellRequest.make("levitar(2)", MAGO))
	assert_bool(next.ok).is_true()
	assert_int(executor.worker_pid()).is_not_equal(old_pid)


func test_EXE_008_worker_morto_e_substituido() -> void:
	await executor.execute(SpellRequest.make("meditar()", MAGO))
	var old_pid := executor.worker_pid()
	OS.kill(old_pid)
	await await_millis(200)
	var result: SpellResult = await executor.execute(SpellRequest.make("levitar(2)", MAGO))
	assert_bool(result.ok).is_true()
	assert_int(executor.worker_pid()).is_not_equal(old_pid)
