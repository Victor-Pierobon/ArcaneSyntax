extends GdUnitTestSuite
## Aceitação: docs/specs/mundo/MUN-segredos.md (MUN-092 a MUN-095).
## Salas sala_02 e sala_03 DO JOGO: cada baú abre com um feitiço (Python de verdade) e só com movimento.
## O baú não olha como o mago chegou, só se chegou (pedido do Victor, Sprint 14).

const GRIMOIRE_PATH := "user://tests/grimorio_segredos.json"
## Quadro do salto em que a esquiva no ar é apertada (perto do alto do pulo).
const DODGE_FRAME := 16

var driver: PuzzleDriver


func before_test() -> void:
	driver = auto_free(PuzzleDriver.new())
	add_child(driver)


func after_test() -> void:
	driver.cleanup()


func _found(room_id: String) -> bool:
	return driver.world.found_secrets.has(room_id + "_8")


## Pula na direção `direction`, esquiva no ar e continua andando por `frames` quadros.
func _jump_and_dodge(direction: float, frames := 100) -> void:
	var frame := [0]
	driver.world.player.intent_source = func() -> PlayerIntent:
		var intent := PlayerIntent.make(direction, frame[0] == 0, true)
		intent.dodge_pressed = frame[0] == DODGE_FRAME
		frame[0] += 1
		return intent
	for i in frames:
		await get_tree().physics_frame
	driver.stand_still()


func test_MUN_092_sala_02_com_feitico() -> void:
	await driver.start("sala_02", GRIMOIRE_PATH)
	await driver.place(Vector2i(13, 20))
	await driver.cast("levitar(11)\nmover(-4)", true, 90)
	assert_bool(_found("sala_02")).is_true()


func test_MUN_093_sala_02_so_com_movimento() -> void:
	await driver.start("sala_02", GRIMOIRE_PATH)
	# A plataforma mais alta da escada, na beirada da esquerda.
	await driver.place(Vector2i(18, 10))
	await _jump_and_dodge(-1.0)
	assert_bool(_found("sala_02")).override_failure_message("o mago parou em %s" % driver.world.player.global_position).is_true()


func test_MUN_093_sala_02_sem_esquiva_nao_alcanca() -> void:
	await driver.start("sala_02", GRIMOIRE_PATH)
	await driver.place(Vector2i(18, 10))
	var frame := [0]
	driver.world.player.intent_source = func() -> PlayerIntent:
		frame[0] += 1
		return PlayerIntent.make(-1.0, frame[0] == 1, true)
	for i in 100:
		await get_tree().physics_frame
	assert_bool(_found("sala_02")).is_false()


func test_MUN_094_sala_03_com_feitico() -> void:
	await driver.start("sala_03", GRIMOIRE_PATH)
	await driver.place(Vector2i(22, 20))
	await driver.cast("levitar(13)\nmover(-3)", true, 90)
	assert_bool(_found("sala_03")).is_true()


func test_MUN_095_sala_03_so_com_movimento() -> void:
	await driver.start("sala_03", GRIMOIRE_PATH)
	# A borda da entrada, na beirada da direita.
	await driver.place(Vector2i(10, 8))
	await _jump_and_dodge(1.0)
	assert_bool(_found("sala_03")).override_failure_message("o mago parou em %s" % driver.world.player.global_position).is_true()


# --- Segredos da Alpha 1.1 (Sprint 18, MUN-096 a MUN-098) ---


## Pula sem esquivar na direção `direction` e anda por 100 quadros.
func _jump_without_dodge(direction: float) -> void:
	var frame := [0]
	driver.world.player.intent_source = func() -> PlayerIntent:
		frame[0] += 1
		return PlayerIntent.make(direction, frame[0] == 1, true)
	for i in 100:
		await get_tree().physics_frame
	driver.stand_still()


## Põe o mago em `cell` em cima da plataforma que se move e espera ela chegar ao alto.
func _ride_to_top(cell: Vector2i) -> void:
	var platform: MovingPlatform = driver.room().moving_platforms()[0]
	await driver.place(cell)
	var top := platform.path.end.y
	for i in 600:
		await get_tree().physics_frame
		if platform.position.y - platform.origin.y <= top + 0.5:
			break
	await driver.frames(2)


func test_MUN_096_sala_01_com_feitico() -> void:
	await driver.start("sala_01", GRIMOIRE_PATH)
	await driver.place(Vector2i(16, 20))
	await driver.cast("levitar(10)\nmover(4)", true, 90)
	assert_bool(_found("sala_01")).is_true()


func test_MUN_096_sala_01_so_com_movimento() -> void:
	await driver.start("sala_01", GRIMOIRE_PATH)
	# A plataforma mais alta da escada, na beirada da esquerda.
	await driver.place(Vector2i(30, 10))
	await _jump_and_dodge(-1.0)
	assert_bool(_found("sala_01")).override_failure_message("o mago parou em %s" % driver.world.player.global_position).is_true()


func test_MUN_096_sala_01_sem_esquiva_nao_alcanca() -> void:
	await driver.start("sala_01", GRIMOIRE_PATH)
	await driver.place(Vector2i(30, 10))
	await _jump_without_dodge(-1.0)
	assert_bool(_found("sala_01")).is_false()


func test_MUN_097_sala_p03_com_feitico() -> void:
	await driver.start("sala_p03", GRIMOIRE_PATH)
	await driver.place(Vector2i(22, 20))
	await driver.cast("levitar(14)\nmover(4)", true, 90)
	assert_bool(_found("sala_p03")).is_true()


func test_MUN_097_sala_p03_so_com_movimento() -> void:
	await driver.start("sala_p03", GRIMOIRE_PATH)
	# Na beirada da direita da plataforma que sobe; lá em cima, salta para a prateleira.
	await _ride_to_top(Vector2i(17, 18))
	await _jump_and_dodge(1.0)
	assert_bool(_found("sala_p03")).override_failure_message("o mago parou em %s" % driver.world.player.global_position).is_true()


func test_MUN_097_sala_p03_sem_esquiva_nao_alcanca() -> void:
	await driver.start("sala_p03", GRIMOIRE_PATH)
	await _ride_to_top(Vector2i(17, 18))
	await _jump_without_dodge(1.0)
	assert_bool(_found("sala_p03")).is_false()


func test_MUN_098_sala_p06_com_feitico() -> void:
	await driver.start("sala_p06", GRIMOIRE_PATH)
	await driver.place(Vector2i(5, 19))
	await driver.cast("levitar(12)\nmover(-3)", true, 90)
	assert_bool(_found("sala_p06")).is_true()


func test_MUN_098_sala_p06_so_com_movimento() -> void:
	await driver.start("sala_p06", GRIMOIRE_PATH)
	await _ride_to_top(Vector2i(10, 17))
	await _jump_and_dodge(-1.0)
	assert_bool(_found("sala_p06")).override_failure_message("o mago parou em %s" % driver.world.player.global_position).is_true()


func test_MUN_098_sala_p06_sem_esquiva_nao_alcanca() -> void:
	await driver.start("sala_p06", GRIMOIRE_PATH)
	await _ride_to_top(Vector2i(10, 17))
	await _jump_without_dodge(-1.0)
	assert_bool(_found("sala_p06")).is_false()
