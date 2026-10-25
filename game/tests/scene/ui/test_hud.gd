extends GdUnitTestSuite
## Spec: docs/specs/ui/UI-hud.md

var hud: Hud
var state: MagoState


func before_test() -> void:
	hud = auto_free(Hud.new())
	add_child(hud)
	state = MagoState.new()
	hud.bind(state)


func test_UI_001_mostra_o_estado_inicial() -> void:
	assert_str(hud.life_label.text).contains("5/5")
	assert_str(hud.mana_label.text).contains("0.0/10.0")
	assert_float(hud.mana_bar.value).is_equal(0.0)


func test_GRI_034_hud_mostra_os_slots() -> void:
	var grimoire := Grimoire.new()
	grimoire.create("Fogo")
	hud.bind_slots(grimoire)
	grimoire.equip(1, "Fogo")
	assert_str(hud.slots_label.text).contains("1 Fogo").contains("2 —").contains("5 —")
	grimoire.rename("Fogo", "Chama")
	assert_str(hud.slots_label.text).contains("1 Chama")


## Regressão (Sprint 7, achado em captura de tela): o status do passivo ficava em cima do mago,
## perto do chão; ele fica no bloco do topo, junto da vida e da mana.
func test_MAG_057_status_do_passivo_fica_no_topo() -> void:
	hud.set_passive_status("Recarregar", false)
	await get_tree().process_frame
	assert_float(hud.passive_label.get_global_rect().end.y).is_less(80.0)


func test_UI_002_acompanha_mudancas() -> void:
	state.health.damage(2)
	state.set_mana(4.9)
	assert_str(hud.life_label.text).contains("3/5")
	assert_str(hud.mana_label.text).contains("4.9/10.0")
	assert_float(hud.mana_bar.value).is_equal_approx(49.0, 0.01)
