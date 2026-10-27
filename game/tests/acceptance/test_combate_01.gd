extends GdUnitTestSuite
## Aceitação: docs/specs/combate/COM-elemental.md (COM-025).
## Sala sala_c01 DO JOGO e Python de verdade. Elementais de fogo e de gelo num fosso; o mago conjura
## da borda, 3 tiles acima, onde eles não o perseguem. Desde a Sprint 19 a sala tem outro grupo, a mais
## de 12 tiles da borda: o teste olha só para os dois do fosso.

const GRIMOIRE_PATH := "user://tests/grimorio_com01.json"
## Pés na beirada da borda (coluna 17, topo na linha 18).
const LEDGE := Vector2i(17, 17)
const PIT := ["1", "2"]
## Espera o alvo chegar a esta distância: o projétil anda no máximo 12 tiles.
const SAFE_DISTANCE := 10.0

const ADAPTAVEL := """if alvo.elemento == "fogo":
    lancar(gelo, projetil, alvo)
elif alvo.elemento == "gelo":
    lancar(raio, projetil, alvo)
else:
    lancar(fogo, projetil, alvo)"""

var driver: PuzzleDriver


func before_test() -> void:
	driver = auto_free(PuzzleDriver.new())
	add_child(driver)
	await driver.start("sala_c01", GRIMOIRE_PATH)
	await driver.place(LEDGE)


func after_test() -> void:
	driver.cleanup()


## Os elementais do fosso que ainda não caíram.
func _pit_alive() -> Array[Enemy]:
	var alive: Array[Enemy] = []
	for digit: String in PIT:
		var enemy := _enemy(digit)
		if enemy != null and not enemy.is_defeated():
			alive.append(enemy)
	return alive


func _enemy(digit: String) -> Enemy:
	for enemy in driver.room().enemies():
		if enemy.target_id == "sala_c01_alvo_" + digit:
			return enemy
	return null


## Espera até haver um alvo a no máximo SAFE_DISTANCE tiles (no máximo 10 s).
func _wait_for_target() -> void:
	for i in 600:
		var target: Variant = driver.world.current_target()
		if target != null and float(target["distancia"]) <= SAFE_DISTANCE:
			return
		await driver.frames(1)


func test_COM_025_feitico_adaptavel_vence_os_dois_com_quatro_conjuracoes() -> void:
	var casts := 0
	while not _pit_alive().is_empty() and casts < 6:
		await _wait_for_target()
		var result := await driver.cast(ADAPTAVEL, true, 60)
		assert_bool(result.ok).override_failure_message(str(result.error)).is_true()
		casts += 1
	assert_array(_pit_alive()).is_empty()
	assert_int(casts).is_equal(4)
	assert_int(driver.world.state.health.current).is_equal(5)


func test_COM_025_feitico_fixo_quase_nao_machuca_o_de_fogo() -> void:
	var fire := _enemy("1")
	# Espera o de fogo ser o alvo (o de gelo pode estar mais perto durante a patrulha).
	for i in 600:
		var target: Variant = driver.world.current_target()
		if target != null and target["id"] == fire.target_id and float(target["distancia"]) <= SAFE_DISTANCE:
			break
		await driver.frames(1)
	await driver.cast("lancar(fogo, projetil, alvo)", true, 60)
	assert_int(fire.health.current).is_equal(11)


func test_COM_025_cajado_precisa_de_doze_golpes() -> void:
	var fire := _enemy("1")
	for i in 11:
		fire.hit("cajado")
	assert_bool(fire.is_defeated()).is_false()
	fire.hit("cajado")
	assert_bool(fire.is_defeated()).is_true()
