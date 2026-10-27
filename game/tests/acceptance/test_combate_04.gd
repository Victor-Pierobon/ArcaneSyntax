extends GdUnitTestSuite
## Aceitação: docs/specs/combate/COM-chefe.md (COM-093, COM-088, COM-094, COM-095).
## Arena sala_c04 DO JOGO e Python de verdade.

const GRIMOIRE_PATH := "user://tests/grimorio_com04.json"
## Em cima da plataforma alta da esquerda: nada acima do mago para parar o projétil.
const HIGH_SPOT := Vector2i(12, 16)
## No chão, no meio da arena.
const FLOOR_SPOT := Vector2i(18, 20)
## Orçamento de referência: quinze conjurações de 3,4.
const MANA_BUDGET := 52.0
## XP da chegada ao chefe pelo caminho normal: nível 3, mana máxima 14 (COM-094).
const ARRIVAL_XP := 70
const FRAMES_PER_ACTION := 60
const MAX_FIGHT_FRAMES := 120 * 60

const DICIONARIO := """vence = {"fogo": gelo, "gelo": raio, "planta": fogo}
lancar(vence[alvo.elemento], projetil, alvo)"""

const IF_ELIF := """if alvo.elemento == "fogo":
    lancar(gelo, projetil, alvo)
elif alvo.elemento == "gelo":
    lancar(raio, projetil, alvo)
else:
    lancar(fogo, projetil, alvo)"""

## Custo do feitiço de referência (duas linhas com inscrição + lancar).
const SPELL_COST := 3.4

var driver: PuzzleDriver


func before_test() -> void:
	driver = auto_free(PuzzleDriver.new())
	add_child(driver)
	await driver.start("sala_c04", GRIMOIRE_PATH)


func after_test() -> void:
	driver.cleanup()


func _boss() -> Boss:
	return driver.room().enemies()[0] as Boss


func _plenty_of_life() -> void:
	driver.world.state.health.maximum = 99
	driver.world.state.health.restore_full()


# --- COM-093: a arena ---


func test_COM_093_arena_do_tamanho_da_tela() -> void:
	var room := driver.room()
	assert_int(room.data.width).is_equal(40)
	assert_int(room.data.height).is_equal(22)
	var specs := room.targets.values()
	assert_int(specs.count("inimigo:chefe")).is_equal(1)
	assert_int(specs.count("chefe:ponto")).is_equal(4)
	assert_int(specs.count("chefe:investida")).is_equal(2)
	assert_dict(room.exits).is_equal({"a": "sala_c03:B", "b": "sala_fim:A"})
	# Um ponto de investida em cada metade, no chão.
	var charges: Array = room.targets.keys().filter(func(d: Variant) -> bool: return room.targets[d] == "chefe:investida")
	var xs: Array = charges.map(func(d: Variant) -> int: return room.data.targets[d].x)
	xs.sort()
	assert_bool(xs[0] < 20 and xs[1] >= 20).is_true()
	for digit: Variant in charges:
		var below: Vector2i = room.data.targets[digit] + Vector2i.DOWN
		assert_bool(below in room.data.solids).override_failure_message("investida %s fora do chão" % digit).is_true()
	# Plataformas em dois níveis.
	var rows := {}
	for cell in room.data.platforms:
		rows[cell.y] = true
	assert_int(rows.size()).is_greater_equal(2)
	# Porta do chão ao teto.
	for y in range(1, room.data.height - 1):
		assert_bool(Vector2i(36, y) in room.data.doors).override_failure_message("porta na linha %d" % y).is_true()


func test_COM_093_camera_parada() -> void:
	var camera: Camera2D = driver.world.player.get_node("Camera2D")
	await driver.place(Vector2i(3, 20))
	await driver.frames(30)
	var left := camera.get_screen_center_position()
	await driver.place(Vector2i(34, 20))
	await driver.frames(30)
	assert_vector(camera.get_screen_center_position()).is_equal_approx(left, Vector2(1, 9))


# --- COM-088: o feitiço adaptável vence as três fases ---


## Conjura do lugar de sempre e espera a transição acabar, se ela começou.
func _cast(code: String, boss: Boss) -> SpellResult:
	await driver.place(HIGH_SPOT)
	await driver.wait_boss_above(boss)
	var result := await driver.cast(code, true, 150)
	while is_instance_valid(boss) and not boss.is_defeated() and boss.phases.in_transition():
		await driver.frames(1)
	return result


func _assert_beats(code: String, label: String) -> void:
	_plenty_of_life()
	var boss := _boss()
	# Pelos sinais: o chefe derrotado some depois do último golpe.
	var damages: Array[int] = []
	var defeated := [false]
	boss.was_hit.connect(func(_element: String, _effect: ElementTable.Effect) -> void: damages.append(boss.last_damage))
	boss.defeated.connect(func() -> void: defeated[0] = true)
	var spent := 0.0
	for i in 15:
		var result := await _cast(code, boss)
		assert_bool(result.ok).override_failure_message("%s: %s" % [label, result.error]).is_true()
		spent += result.cost
	var expected: Array[int] = []
	expected.resize(15)
	expected.fill(6)
	assert_array(damages).override_failure_message("%s: %s" % [label, damages]).is_equal(expected)
	assert_bool(defeated[0]).override_failure_message(label).is_true()
	assert_float(spent).override_failure_message("%s: gastou %.1f" % [label, spent]).is_less_equal(MANA_BUDGET)
	assert_bool(driver.room().doors_open()).is_true()


func test_COM_088_feitico_com_dicionario_vence_as_tres_fases() -> void:
	await _assert_beats(DICIONARIO, "dicionário")


func test_COM_088_feitico_com_if_vence_as_tres_fases() -> void:
	await _assert_beats(IF_ELIF, "if/elif/else")


func test_COM_088_feitico_fixo_emperra_na_fase_2() -> void:
	_plenty_of_life()
	var boss := _boss()
	for i in 5:
		await _cast("lancar(gelo, projetil, alvo)", boss)
	assert_int(boss.phases.phase).is_equal(2)
	assert_int(boss.health.current).is_equal(60)
	await _cast("lancar(gelo, projetil, alvo)", boss)
	assert_int(boss.health.current).is_equal(59)
	assert_int(boss.last_damage).is_equal(1)


func test_COM_088_o_feitico_ve_o_elemento_da_fase() -> void:
	var boss := _boss()
	var result := await driver.cast("print(alvo.elemento, alvo.vida, alvo.escudo)", true, 5)
	assert_str(result.outputs[0]["texto"]).is_equal("fogo 90 None")
	while boss.health.current > 60:
		boss.hit("gelo", "projetil")
	result = await driver.cast("print(alvo.elemento, alvo.vida)", true, 5)
	assert_str(result.outputs[0]["texto"]).is_equal("gelo 60")


# --- COM-094 e COM-095: a luta com a vida de jogo ---


## Uma ação por segundo: o feitiço de referência se a mana dá, senão meditar. Devolve
## {"venceu", "morreu", "vida", "segundos"}.
func _fight() -> Dictionary:
	driver.world.state.restore_progress(ARRIVAL_XP, 14.0)
	assert_float(driver.world.state.mana_max).is_equal(14.0)
	var boss := _boss()
	var outcome := {"venceu": false, "morreu": false}
	boss.defeated.connect(func() -> void: outcome["venceu"] = true)
	driver.world.state.health.died.connect(func() -> void: outcome["morreu"] = true, CONNECT_ONE_SHOT)
	var start := Engine.get_physics_frames()
	while not outcome["venceu"] and not outcome["morreu"] and Engine.get_physics_frames() - start < MAX_FIGHT_FRAMES:
		var began := Engine.get_physics_frames()
		var code := DICIONARIO if driver.world.state.mana >= SPELL_COST else "meditar()"
		await driver.cast(code, false, 0)
		var used := Engine.get_physics_frames() - began
		if used < FRAMES_PER_ACTION:
			await driver.frames(FRAMES_PER_ACTION - used)
	outcome["vida"] = driver.world.state.health.current
	outcome["segundos"] = (Engine.get_physics_frames() - start) / 60.0
	return outcome


func test_COM_094_parado_perde() -> void:
	await driver.place(FLOOR_SPOT)
	var outcome := await _fight()
	assert_bool(outcome["morreu"]).override_failure_message(str(outcome)).is_true()
	assert_bool(outcome["venceu"]).override_failure_message(str(outcome)).is_false()


func test_COM_095_quem_se_protege_vence() -> void:
	await driver.place(FLOOR_SPOT)
	var boss := _boss()
	driver.world.player.intent_source = _protector(boss)
	var outcome := await _fight()
	assert_bool(outcome["venceu"]).override_failure_message(str(outcome)).is_true()
	assert_bool(outcome["morreu"]).is_false()
	assert_int(outcome["vida"]).override_failure_message(str(outcome)).is_greater_equal(2)


## O mago que presta atenção nos avisos: sai de toda marca de pilar e esquiva atravessando o orbe
## que chega perto e o chefe que vem na investida. No resto do tempo, fica parado.
func _protector(boss: Boss) -> Callable:
	var player := driver.world.player
	var width := driver.room().data.width * RoomLayout.TILE
	return func() -> PlayerIntent:
		var intent := PlayerIntent.make()
		if not is_instance_valid(boss) or boss.is_defeated():
			return intent
		var feet := player.global_position
		var center := feet + Vector2(0, -15)
		for bolt in get_tree().get_nodes_in_group(BossBolt.GROUP):
			var at := (bolt as Node2D).global_position
			if at.distance_to(center) < 32:
				return _dodge_toward(intent, at.x - feet.x)
		if boss.brain.charging():
			var gap := boss.global_position.x - feet.x
			var coming := signf(boss.brain.destination().x - boss.global_position.x) == -signf(gap)
			if coming and absf(gap) < 48:
				return _dodge_toward(intent, gap)
		for pillar in boss.pillars():
			var dx := feet.x - pillar.global_position.x
			if absf(dx) < 1.5 * RoomLayout.TILE:
				var away := signf(dx) if dx != 0.0 else 1.0
				# Encostado numa parede, foge para o meio.
				if feet.x < 3 * RoomLayout.TILE:
					away = 1.0
				elif feet.x > width - 6 * RoomLayout.TILE:
					away = -1.0
				intent.move_x = away
		return intent


static func _dodge_toward(intent: PlayerIntent, dx: float) -> PlayerIntent:
	intent.move_x = signf(dx) if dx != 0.0 else 1.0
	intent.dodge_pressed = true
	return intent
