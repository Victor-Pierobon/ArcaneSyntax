extends GdUnitTestSuite
## Aceitação: docs/specs/combate/COM-chefe.md (COM-088).
## Sala sala_c04 DO JOGO e Python de verdade. O mago conjura a 8 tiles do chefe; volta para o lugar
## antes de cada conjuração (os orbes o empurram) e tem vida de sobra (o que se testa é o feitiço).

const GRIMOIRE_PATH := "user://tests/grimorio_com04.json"
const SPOT := Vector2i(6, 5)
## Orçamento de referência: seis conjurações de 3,4.
const MANA_BUDGET := 21.0

const DICIONARIO := """vence = {"fogo": gelo, "gelo": raio, "planta": fogo}
lancar(vence[alvo.elemento], projetil, alvo)"""

const IF_ELIF := """if alvo.elemento == "fogo":
    lancar(gelo, projetil, alvo)
elif alvo.elemento == "gelo":
    lancar(raio, projetil, alvo)
else:
    lancar(fogo, projetil, alvo)"""

var driver: PuzzleDriver


func before_test() -> void:
	driver = auto_free(PuzzleDriver.new())
	add_child(driver)
	await driver.start("sala_c04", GRIMOIRE_PATH)
	driver.world.state.health.maximum = 99
	driver.world.state.health.restore_full()


func after_test() -> void:
	driver.cleanup()


func _boss() -> Boss:
	return driver.room().enemies()[0] as Boss


## Conjura do lugar de sempre e espera a transição acabar, se ela começou.
func _cast(code: String, boss: Boss) -> SpellResult:
	await driver.place(SPOT)
	var result := await driver.cast(code, true, 60)
	while is_instance_valid(boss) and not boss.is_defeated() and boss.phases.in_transition():
		await driver.frames(1)
	return result


func _assert_beats(code: String, label: String) -> void:
	var boss := _boss()
	# Pelos sinais: o chefe derrotado some 0,4 s depois do último golpe. O terceiro golpe para no
	# limite da troca (3); o último mostra o dano inteiro, como em qualquer inimigo.
	var damages: Array[int] = []
	var defeated := [false]
	boss.was_hit.connect(func(_element: String, _effect: ElementTable.Effect) -> void: damages.append(boss.last_damage))
	boss.defeated.connect(func() -> void: defeated[0] = true)
	var spent := 0.0
	for i in 6:
		var result := await _cast(code, boss)
		assert_bool(result.ok).override_failure_message("%s: %s" % [label, result.error]).is_true()
		spent += result.cost
	assert_array(damages).override_failure_message("%s: %s" % [label, damages]).is_equal([6, 6, 3, 6, 6, 6])
	assert_bool(defeated[0]).override_failure_message(label).is_true()
	assert_float(spent).override_failure_message("%s: gastou %.1f" % [label, spent]).is_less_equal(MANA_BUDGET)
	assert_bool(driver.room().doors_open()).is_true()


func test_COM_088_feitico_com_dicionario_vence_as_duas_fases() -> void:
	await _assert_beats(DICIONARIO, "dicionário")


func test_COM_088_feitico_com_if_vence_as_duas_fases() -> void:
	await _assert_beats(IF_ELIF, "if/elif")


func test_COM_088_feitico_fixo_emperra_na_fase_2() -> void:
	var boss := _boss()
	for i in 3:
		await _cast("lancar(gelo, projetil, alvo)", boss)
	assert_int(boss.phases.phase).is_equal(2)
	assert_int(boss.health.current).is_equal(15)
	await _cast("lancar(gelo, projetil, alvo)", boss)
	assert_int(boss.health.current).is_equal(14)
	assert_int(boss.last_damage).is_equal(1)


func test_COM_088_o_feitico_ve_o_elemento_da_fase() -> void:
	var boss := _boss()
	var result := await driver.cast("print(alvo.elemento, alvo.vida, alvo.escudo)", true, 5)
	assert_str(result.outputs[0]["texto"]).is_equal("fogo 30 None")
	for i in 3:
		boss.hit("gelo", "projetil")
	result = await driver.cast("print(alvo.elemento, alvo.vida)", true, 5)
	assert_str(result.outputs[0]["texto"]).is_equal("gelo 15")
