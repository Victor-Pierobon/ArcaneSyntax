extends GdUnitTestSuite
## Spec: docs/specs/combate/COM-chefe.md (regras 4 e 7 a 13; COM-082, COM-083, COM-089 a COM-091)

const STEP := 1.0 / 60.0
## Velocidade e descansos do balanceamento do jogo (calibrados na Sprint 20: o mago parado vencia por pouco).
const SPEED := 100.0
const RESTS := [1.0, 0.8, 0.6]
## Um quadro de folga nas contas de tempo.
const SLACK := 0.03
const START := Vector2(320, 200)
const POINTS: Array[Vector2] = [Vector2(320, 150), Vector2(520, 150), Vector2(120, 150), Vector2(320, 80)]
const CHARGE: Array[Vector2] = [Vector2(64, 336), Vector2(576, 336)]
const PLAYER := Vector2(320, 321)


func _brain() -> BossBrain:
	return BossBrain.new(START, POINTS, CHARGE)


## Roda `seconds` de quadro em quadro; devolve [[tempo, evento], ...]. `player` é um Vector2 ou um
## Callable(tempo) -> Vector2, para o mago que anda.
func _run(brain: BossBrain, seconds: float, player: Variant = PLAYER) -> Array:
	var log := []
	var elapsed := 0.0
	for i in roundi(seconds / STEP):
		var at: Vector2 = player.call(elapsed) if player is Callable else player
		elapsed += STEP
		for event: Dictionary in brain.tick(STEP, at):
			log.append([elapsed, event])
	return log


func _of(log: Array, kind: String) -> Array:
	return log.filter(func(entry: Array) -> bool: return entry[1]["tipo"] == kind)


## Leva o cérebro até um quadro antes do fim da transição para a fase `target`: o primeiro "mover"
## da fase fica para o teste ver.
func _brain_in_phase(target: int) -> BossBrain:
	var brain := _brain()
	_run(brain, 2.0 + STEP)
	for i in target - 1:
		brain.after_damage([60, 30][i])
		_run(brain, 1.5 - (STEP if i == target - 2 else -STEP))
	return brain


# --- COM-083: ciclo ---


func test_COM_083_espera_2_s_antes_de_comecar() -> void:
	var brain := _brain()
	assert_array(_run(brain, 1.9)).is_empty()
	assert_vector(brain.position).is_equal(START)
	var log := _run(brain, 0.2)
	assert_int(log.size()).is_equal(1)
	assert_dict(log[0][1]).is_equal({"tipo": "mover", "ataque": "leque", "destino": POINTS[0]})


func test_COM_083_fase_1_move_avisa_lanca_e_descansa() -> void:
	var brain := _brain()
	var log := _run(brain, 12.0)
	var first_leg := START.distance_to(POINTS[0]) / SPEED
	var warn: Array = _of(log, "aviso")
	assert_dict(warn[0][1]).is_equal({"tipo": "aviso", "ataque": "leque"})
	assert_float(warn[0][0]).is_equal_approx(2.0 + first_leg, SLACK)
	var fans: Array = _of(log, "leque")
	assert_float(fans[0][0]).is_equal_approx(2.0 + first_leg + 0.6, SLACK)
	# Descansa 1,5 s e vai ao próximo ponto.
	var moves: Array = _of(log, "mover")
	assert_float(moves[1][0]).is_equal_approx(2.0 + first_leg + 0.6 + RESTS[0], SLACK)
	assert_vector(moves[1][1]["destino"]).is_equal(POINTS[1])
	assert_str(moves[1][1]["ataque"]).is_equal("leque")


func test_COM_083_voa_na_velocidade_do_balanceamento() -> void:
	var brain := _brain()
	_run(brain, 2.0 + 0.25)
	# Um quarto de segundo de voo na direção do ponto 1.
	assert_float(brain.position.distance_to(START)).is_equal_approx(SPEED * 0.25, 1.5)
	_run(brain, 1.0)
	assert_vector(brain.position).is_equal(POINTS[0])


func test_COM_083_pontos_em_ordem_e_em_volta() -> void:
	var brain := _brain()
	var moves: Array = _of(_run(brain, 40.0), "mover")
	var targets := moves.map(func(entry: Array) -> Vector2: return entry[1]["destino"])
	assert_array(targets.slice(0, 5)).is_equal([POINTS[0], POINTS[1], POINTS[2], POINTS[3], POINTS[0]])


func test_COM_083_ordem_dos_ataques_na_fase_2() -> void:
	var brain := _brain_in_phase(2)
	var moves: Array = _of(_run(brain, 30.0), "mover")
	var attacks := moves.map(func(entry: Array) -> String: return entry[1]["ataque"])
	assert_array(attacks.slice(0, 4)).is_equal(["pilares", "leque", "pilares", "leque"])


func test_COM_083_ordem_dos_ataques_na_fase_3() -> void:
	var brain := _brain_in_phase(3)
	var moves: Array = _of(_run(brain, 40.0), "mover")
	var attacks := moves.map(func(entry: Array) -> String: return entry[1]["ataque"])
	assert_array(attacks.slice(0, 4)).is_equal(["investida", "pilares", "leque", "investida"])


func test_COM_083_descanso_por_fase() -> void:
	for phase: int in [2, 3]:
		var brain := _brain_in_phase(phase)
		# O primeiro leque da fase: o descanso vai do leque até o próximo "mover".
		var log := _run(brain, 30.0)
		var fan_at: float = _of(log, "leque")[0][0]
		var next_moves := _of(log, "mover").filter(func(entry: Array) -> bool: return entry[0] > fan_at)
		var expected: float = RESTS[phase - 1]
		assert_float(next_moves[0][0] - fan_at).override_failure_message("fase %d" % phase) \
				.is_equal_approx(expected, SLACK)


# --- COM-089: leque ---


func test_COM_089_direcoes_do_leque() -> void:
	var angles := func(count: int) -> Array:
		return BossBrain.fan(Vector2.RIGHT, count, 15.0).map(
				func(direction: Vector2) -> int: return roundi(rad_to_deg(direction.angle())))
	assert_array(angles.call(5)).is_equal([-30, -15, 0, 15, 30])
	assert_array(angles.call(3)).is_equal([-15, 0, 15])
	assert_array(angles.call(7)).is_equal([-45, -30, -15, 0, 15, 30, 45])
	for direction: Vector2 in BossBrain.fan(Vector2(0, 40), 3, 15.0):
		assert_float(direction.length()).is_equal_approx(1.0, 0.001)


func test_COM_089_orbes_por_fase() -> void:
	for phase: int in [1, 2, 3]:
		var brain := _brain_in_phase(phase)
		var fans: Array = _of(_run(brain, 30.0), "leque")
		assert_int((fans[0][1]["direcoes"] as Array).size()).override_failure_message("fase %d" % phase) \
				.is_equal([3, 5, 7][phase - 1])


func test_COM_089_mira_no_fim_do_aviso() -> void:
	var brain := _brain()
	var first_leg := START.distance_to(POINTS[0]) / SPEED
	var warn_at := 2.0 + first_leg
	# O mago está à esquerda durante o aviso e pula para a direita antes do fim dele.
	var player := func(elapsed: float) -> Vector2:
		return Vector2(600, 150) if elapsed > warn_at + 0.3 else Vector2(40, 150)
	var fans: Array = _of(_run(brain, warn_at + 1.0, player), "leque")
	var middle: Vector2 = fans[0][1]["direcoes"][1]
	assert_vector(middle).is_equal_approx(Vector2.RIGHT, Vector2(0.001, 0.001))


# --- COM-090: pilares ---


func test_COM_090_marcas_seguem_o_mago_e_os_pilares_sobem_depois() -> void:
	var brain := _brain_in_phase(2)
	brain.floor_finder = func(center: Vector2) -> Vector2: return Vector2(center.x, 336)
	# O mago anda 2 px por quadro para a direita: cada marca fica onde ele está naquele momento.
	var player := func(elapsed: float) -> Vector2: return Vector2(100 + elapsed * 120.0, 321)
	var log := _run(brain, 12.0, player)
	var marks: Array = _of(log, "marca")
	assert_int(marks.size()).is_equal(3)
	assert_float(marks[1][0] - marks[0][0]).is_equal_approx(0.6, SLACK)
	assert_float(marks[2][0] - marks[1][0]).is_equal_approx(0.6, SLACK)
	for entry: Array in marks:
		var x_then: float = 100 + (entry[0] - STEP) * 120.0
		assert_float(entry[1]["posicao"].x).is_equal_approx(x_then, 2.5)
		assert_float(entry[1]["posicao"].y).is_equal(336.0)
	var rises: Array = _of(log, "pilar")
	var ends: Array = _of(log, "pilar_fim")
	for i in 3:
		var id: int = marks[i][1]["id"]
		assert_int(rises[i][1]["id"]).is_equal(id)
		assert_float(rises[i][0] - marks[i][0]).is_equal_approx(0.8, SLACK)
		assert_float(ends[i][0] - rises[i][0]).is_equal_approx(0.5, SLACK)
	# Os ids são diferentes, e o descanso começa quando o último pilar desce.
	assert_int(marks[0][1]["id"]).is_not_equal(marks[1][1]["id"])
	assert_array(brain.marks).is_empty()


func test_COM_090_quatro_marcas_na_fase_3() -> void:
	var brain := _brain_in_phase(3)
	assert_int(_of(_run(brain, 20.0), "marca").size()).is_equal(4)


func test_COM_090_os_pilares_avisam_pelas_marcas() -> void:
	var brain := _brain_in_phase(2)
	var log := _run(brain, 8.0)
	# O chefe chega ao ponto e já marca o chão: não há "aviso" antes dos pilares.
	var first_mark: float = _of(log, "marca")[0][0]
	assert_array(_of(log, "aviso").filter(func(entry: Array) -> bool: return entry[0] <= first_mark)).is_empty()


func test_COM_090_chao_abaixo_do_mago() -> void:
	var layout := RoomLayout.parse("""#########
#.......#
#.......#
#..===..#
#.......#
#########""")
	# Centro do mago no ar, na coluna 4 (acima da plataforma) e na coluna 1 (acima do chão).
	assert_vector(layout.floor_below(Vector2(4 * 16 + 3, 1 * 16 + 5))).is_equal(Vector2(4 * 16 + 8, 3 * 16))
	assert_vector(layout.floor_below(Vector2(1 * 16 + 8, 2 * 16))).is_equal(Vector2(1 * 16 + 8, 5 * 16))
	# Em pé no chão: o centro está uma célula acima dele.
	assert_vector(layout.floor_below(Vector2(6 * 16 + 8, 4 * 16 + 1))).is_equal(Vector2(6 * 16 + 8, 5 * 16))


# --- COM-091: investida ---


func test_COM_091_investida_sai_do_lado_de_la() -> void:
	var brain := _brain_in_phase(3)
	var near_left := Vector2(90, 321)
	var log := _run(brain, 12.0, near_left)
	var moves: Array = _of(log, "mover")
	assert_dict(moves[0][1]).is_equal({"tipo": "mover", "ataque": "investida", "destino": CHARGE[1]})
	var warn: Array = _of(log, "aviso")
	assert_dict(warn[0][1]).is_equal({"tipo": "aviso", "ataque": "investida"})
	var charge: Array = _of(log, "investida")
	assert_float(charge[0][0] - warn[0][0]).is_equal_approx(0.8, SLACK)
	assert_vector(charge[0][1]["destino"]).is_equal(CHARGE[0])
	# Atravessa a 240 px/s e só então descansa.
	var crossing := CHARGE[0].distance_to(CHARGE[1]) / 240.0
	var next_move: Array = moves[1]
	assert_float(next_move[0] - charge[0][0]).is_equal_approx(crossing + RESTS[2], SLACK * 2)


func test_COM_091_investida_pelo_outro_lado() -> void:
	var brain := _brain_in_phase(3)
	var moves: Array = _of(_run(brain, 5.0, Vector2(560, 321)), "mover")
	assert_vector(moves[0][1]["destino"]).is_equal(CHARGE[0])


func test_COM_091_atacando_esta_atacando() -> void:
	var brain := _brain_in_phase(3)
	var log := _run(brain, 12.0, Vector2(90, 321))
	assert_bool(brain.charging()).is_false()
	var other := _brain_in_phase(3)
	var charge_at: float = _of(log, "investida")[0][0]
	_run(other, charge_at + 0.2, Vector2(90, 321))
	assert_bool(other.charging()).is_true()


# --- COM-082: a troca cancela o ataque ---


func test_COM_082_troca_cancela_marcas_e_recomeca_pela_fase_nova() -> void:
	var brain := _brain_in_phase(2)
	var log := _run(brain, 30.0)
	var first_mark: float = _of(log, "marca")[0][0]
	var fresh := _brain_in_phase(2)
	_run(fresh, first_mark + 0.1)
	assert_int(fresh.marks.size()).is_equal(1)
	assert_bool(fresh.after_damage(30)).is_true()
	assert_array(fresh.marks).is_empty()
	var position := fresh.position
	var during := _run(fresh, 1.4)
	assert_dict(during[0][1]).is_equal({"tipo": "cancelar"})
	assert_int(during.size()).is_equal(1)
	assert_vector(fresh.position).is_equal(position)
	var after := _run(fresh, 0.2)
	assert_str(_of(after, "mover")[0][1]["ataque"]).is_equal("investida")


func test_COM_082_troca_no_aviso_nao_solta_o_leque() -> void:
	var brain := _brain()
	var first_leg := START.distance_to(POINTS[0]) / SPEED
	_run(brain, 2.0 + first_leg + 0.3)
	assert_int(brain.state).is_equal(BossBrain.State.WARN)
	brain.after_damage(60)
	var log := _run(brain, 1.0)
	assert_array(_of(log, "leque")).is_empty()
	assert_int(brain.state).is_equal(BossBrain.State.TRANSITION)


func test_COM_082_golpe_passa_pelas_fases() -> void:
	var brain := _brain()
	assert_int(brain.resolve("gelo", "projetil", 90)["damage"]).is_equal(6)
	brain.after_damage(60)
	assert_bool(brain.resolve("raio", "projetil", 60)["blocked"]).is_true()
	assert_int(brain.phases.phase).is_equal(2)
