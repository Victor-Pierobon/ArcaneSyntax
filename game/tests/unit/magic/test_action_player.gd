extends GdUnitTestSuite
## Spec: docs/specs/magia/MAG-acoes.md (MAG-001 a 003)

var player: ActionPlayer
var port: FakeWorldPort


func before_test() -> void:
	port = auto_free(FakeWorldPort.new())
	add_child(port)
	player = auto_free(ActionPlayer.new())
	add_child(player)
	player.port = port


func test_MAG_001_ordem_uma_depois_da_outra() -> void:
	player.play([{"tipo": "meditar"}, {"tipo": "lancar"}, {"tipo": "mover"}])
	await player.finished
	assert_array(port.calls).is_equal([
		"início meditar", "fim meditar", "início lancar", "fim lancar", "início mover", "fim mover",
	])


func test_MAG_002_acao_desconhecida_e_pulada() -> void:
	player.play([{"tipo": "dancar"}, {"tipo": "meditar"}])
	await player.finished
	assert_array(port.calls).is_equal(["início meditar", "fim meditar"])


func test_MAG_003_segunda_fila_espera_a_primeira() -> void:
	player.play([{"tipo": "meditar"}])
	player.play([{"tipo": "absorver_mana"}])
	await player.finished
	assert_array(port.calls).is_equal(["início meditar", "fim meditar", "início absorver_mana", "fim absorver_mana"])
	assert_bool(player.is_playing()).is_false()


func test_PUZ_010_avisa_a_sequencia_e_cada_acao() -> void:
	var events := []
	player.sequence_started.connect(func(code: String) -> void: events.append("seq " + code))
	player.action_started.connect(func(action: Dictionary) -> void: events.append("ação %d" % action["linha"]))
	player.play([{"tipo": "meditar", "linha": 1}, {"tipo": "mover", "linha": 2}], "meditar()\nmover(1)")
	player.play([{"tipo": "meditar", "linha": 1}], "meditar()")
	await player.finished
	assert_array(events).is_equal(["seq meditar()\nmover(1)", "ação 1", "ação 2", "seq meditar()", "ação 1"])


func test_PUZ_011_pausa_entre_acoes() -> void:
	player.step_delay = 0.2
	var started := Time.get_ticks_msec()
	player.play([{"tipo": "meditar"}, {"tipo": "meditar"}])
	await player.finished
	assert_int(Time.get_ticks_msec() - started).is_greater_equal(380)
	player.step_delay = 0.0
	started = Time.get_ticks_msec()
	player.play([{"tipo": "meditar"}, {"tipo": "meditar"}])
	await player.finished
	assert_int(Time.get_ticks_msec() - started).is_less(200)


func test_fila_vazia_termina_na_hora() -> void:
	player.play([])
	assert_bool(player.is_playing()).is_false()
