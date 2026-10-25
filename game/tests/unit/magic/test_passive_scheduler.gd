extends GdUnitTestSuite
## Spec: docs/specs/magia/MAG-passivo.md (MAG-051, 052, 054, 055) — regras do agendador sem cena.

const O := PassiveScheduler.Outcome

var scheduler: PassiveScheduler


func before_test() -> void:
	scheduler = PassiveScheduler.new()


func _result(error_type: String = "") -> SpellResult:
	var data := {"ok": error_type.is_empty(), "acoes": [], "saidas": [], "custo_mana": 0}
	if not error_type.is_empty():
		data["erro"] = {"tipo": error_type, "mensagem": "x", "linha": 1, "coluna": null}
	return SpellResult.from_dict(data)


func test_MAG_051_dispara_a_cada_segundo() -> void:
	assert_bool(scheduler.tick(0.6)).is_false()
	assert_bool(scheduler.tick(0.5)).is_true()
	assert_bool(scheduler.tick(0.5)).is_false()
	assert_bool(scheduler.tick(0.5)).is_true()


func test_MAG_052_nao_dispara_enquanto_ocupado() -> void:
	scheduler.tick(1.0)
	scheduler.mark_started()
	assert_bool(scheduler.tick(5.0)).is_false()
	scheduler.mark_finished(_result())
	assert_bool(scheduler.tick(1.0)).is_true()


func test_MAG_054_erro_desliga_e_reset_religa() -> void:
	scheduler.mark_started()
	assert_int(scheduler.mark_finished(_result("NameError"))).is_equal(O.DISABLED)
	assert_bool(scheduler.is_disabled()).is_true()
	assert_bool(scheduler.tick(10.0)).is_false()
	scheduler.reset()
	assert_bool(scheduler.is_disabled()).is_false()
	assert_bool(scheduler.tick(1.0)).is_true()


func test_MAG_055_mana_esgotada_nao_desliga_e_avisa_so_a_primeira() -> void:
	scheduler.mark_started()
	assert_int(scheduler.mark_finished(_result("ManaEsgotada"))).is_equal(O.MANA_OUT_FIRST)
	scheduler.mark_started()
	assert_int(scheduler.mark_finished(_result("ManaEsgotada"))).is_equal(O.MANA_OUT_REPEAT)
	assert_bool(scheduler.is_disabled()).is_false()
	scheduler.mark_started()
	assert_int(scheduler.mark_finished(_result())).is_equal(O.OK)
	scheduler.mark_started()
	assert_int(scheduler.mark_finished(_result("ManaEsgotada"))).is_equal(O.MANA_OUT_FIRST)


func test_executor_fora_do_ar_nao_desliga() -> void:
	scheduler.mark_started()
	assert_int(scheduler.mark_finished(_result("ExecutorIndisponivel"))).is_equal(O.TRANSIENT)
	assert_bool(scheduler.is_disabled()).is_false()
