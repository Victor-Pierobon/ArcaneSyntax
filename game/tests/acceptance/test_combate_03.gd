extends GdUnitTestSuite
## Aceitação: docs/specs/combate/COM-guardiao.md (COM-064).
## Sala sala_c03 DO JOGO e Python de verdade. O mago conjura a 10 tiles do guardião; o relógio do escudo
## é posto no começo de cada fase para escolher qual escudo ele terá (o projétil leva ~0,7 s).

const GRIMOIRE_PATH := "user://tests/grimorio_com03.json"
const SPOT := Vector2i(8, 5)
## Início de cada escudo + 1 s: fogo, planta, gelo.
const FIRE_TIME := 1.0
const PLANT_TIME := 6.0
const ICE_TIME := 11.0

const DICIONARIO := """vence = {"fogo": gelo, "planta": fogo, "gelo": raio}
if alvo.escudo is None:
    lancar(fogo, projetil, alvo)
else:
    lancar(vence[alvo.escudo], projetil, alvo)"""

const IF_ELIF := """if alvo.escudo == "fogo":
    lancar(gelo, projetil, alvo)
elif alvo.escudo == "planta":
    lancar(fogo, projetil, alvo)
elif alvo.escudo == "gelo":
    lancar(raio, projetil, alvo)
else:
    lancar(raio, faisca, alvo)"""

var driver: PuzzleDriver


func before_test() -> void:
	driver = auto_free(PuzzleDriver.new())
	add_child(driver)
	await driver.start("sala_c03", GRIMOIRE_PATH)
	await driver.place(SPOT)


func after_test() -> void:
	driver.cleanup()


func _guardian() -> Guardian:
	return driver.room().enemies()[0] as Guardian


func _cast_at(shield_time: float, code: String) -> SpellResult:
	_guardian().shield.time = shield_time
	return await driver.cast(code, true, 60)


func _assert_beats(code: String, label: String) -> void:
	var guardian := _guardian()
	# Pelos sinais: o guardião derrotado some 0,4 s depois do último golpe.
	var damages: Array[int] = []
	var defeated := [false]
	guardian.was_hit.connect(func(_element: String, _effect: ElementTable.Effect) -> void: damages.append(guardian.last_damage))
	guardian.defeated.connect(func() -> void: defeated[0] = true)
	for shield_time in [FIRE_TIME, PLANT_TIME, ICE_TIME]:
		var result := await _cast_at(shield_time, code)
		assert_bool(result.ok).override_failure_message("%s: %s" % [label, result.error]).is_true()
	assert_array(damages).override_failure_message(label).is_equal([6, 6, 6])
	assert_bool(defeated[0]).override_failure_message(label).is_true()


func test_COM_064_feitico_com_dicionario_vence_em_tres() -> void:
	await _assert_beats(DICIONARIO, "dicionário")


func test_COM_064_feitico_com_if_vence_em_tres() -> void:
	await _assert_beats(IF_ELIF, "if/elif")


func test_COM_064_feitico_fixo_so_passa_pelo_escudo_de_fogo() -> void:
	var guardian := _guardian()
	await _cast_at(FIRE_TIME, "lancar(gelo, projetil, alvo)")
	assert_int(guardian.health.current).is_equal(12)
	await _cast_at(PLANT_TIME, "lancar(gelo, projetil, alvo)")
	assert_int(guardian.health.current).is_equal(12)
	assert_bool(guardian.last_blocked).is_true()
	await _cast_at(ICE_TIME, "lancar(gelo, projetil, alvo)")
	assert_int(guardian.health.current).is_equal(12)


func test_COM_064_alvo_escudo_le_o_escudo_da_hora() -> void:
	_guardian().shield.time = PLANT_TIME
	var result := await driver.cast("print(alvo.escudo, alvo.vida)", true, 5)
	assert_str(result.outputs[0]["texto"]).is_equal("planta 18")
