extends GdUnitTestSuite
## Spec: docs/specs/puzzles/PUZ-validacao.md, mecanismos da Sprint 9 (PUZ-009, PUZ-015, PUZ-016, PUZ-018, PUZ-019)
## e docs/specs/magia/MAG-acoes.md (MAG-071).
## sala_runas: chão com topo em y = 80, runas 4, 7 e 2, cadeado na coluna 14 (x = 232), porta na coluna 15.
## sala_ponte: chão com topo em y = 64, vão nas colunas 5 a 8. sala_placa: chão em y = 48, placa na coluna 7.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_mecanismos.json"
const MAGO_CHEIO := {"vida": 5, "mana": 10, "mana_max": 10}

var world: World
var player: Player


func _start(room_id: String) -> void:
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = room_id
	world.grimoire_path = GRIMOIRE_PATH
	world.rng.seed = 42
	add_child(world)
	player = world.player
	_walk(0.0)
	await _frames(3)


func after_test() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(GRIMOIRE_PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func _walk(move_x: float) -> void:
	player.intent_source = func() -> PlayerIntent: return PlayerIntent.make(move_x)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _play(actions: Array) -> void:
	world.action_player.play(actions)
	if world.action_player.is_playing():
		await world.action_player.finished
	await _frames(3)


func _inscribe(value: int) -> void:
	await _play([{"tipo": "inscrever", "valor": value, "linha": 1}])


func _blocks(count: int) -> Array:
	var actions := []
	for i in count:
		actions.append({"tipo": "construir_bloco", "linha": i + 1})
	return actions


func test_PUZ_009_runas_vao_para_o_executor_e_nao_sao_alvo() -> void:
	await _start("sala_runas")
	var context := world.spell_context()
	assert_dict(context["room"]).is_equal({"runas": [4, 7, 2]})
	assert_that(context["target"]).is_null()


func test_PUZ_009_cadeado_abre_com_a_soma() -> void:
	await _start("sala_runas")
	player.global_position = Vector2(13 * 16 + 8, 80)
	await _frames(3)
	await _inscribe(12)
	assert_bool(world.current_room.doors_open()).is_false()
	await _inscribe(13)
	assert_bool(world.is_puzzle_solved("p_runas")).is_true()
	assert_bool(world.current_room.doors_open()).is_true()


func test_PUZ_009_cadeado_longe_nao_recebe() -> void:
	await _start("sala_runas")
	player.global_position = Vector2(9 * 16 + 8, 80)  # a 5 tiles do cadeado
	await _frames(3)
	await _inscribe(13)
	assert_bool(world.is_puzzle_solved("p_runas")).is_false()


func test_PUZ_015_ponte_bloco_a_bloco() -> void:
	await _start("sala_ponte")
	var bridge := world.current_room.bridge
	await _play(_blocks(2))
	assert_array(bridge.built_cells()).contains_exactly([Vector2i(5, 4), Vector2i(6, 4)])
	await _play(_blocks(3))  # o quinto bloco só avisa
	assert_int(bridge.built_cells().size()).is_equal(4)
	assert_bool(world.is_puzzle_solved("p_ponte")).is_true()
	_walk(1.0)
	await _frames(80)
	_walk(0.0)
	assert_float(player.global_position.x).is_greater(9 * 16.0)
	assert_float(player.global_position.y).is_equal_approx(64.0, 2.0)


func test_PUZ_015_sem_ponte_o_mago_cai() -> void:
	await _start("sala_ponte")
	_walk(1.0)
	await _frames(70)
	_walk(0.0)
	assert_int(world.state.health.current).is_less(5)


func test_PUZ_016_placa_fica_pisada() -> void:
	await _start("sala_placa")
	assert_bool(world.is_puzzle_solved("p_placa")).is_false()
	player.global_position = Vector2(7 * 16 + 8, 48)
	await _frames(5)
	player.global_position = Vector2(3 * 16 + 8, 48)
	await _frames(5)
	assert_array(world.current_room.puzzle_state()["placas"]).is_equal([true])
	assert_bool(world.is_puzzle_solved("p_placa")).is_true()


func test_PUZ_018_estrelas_pela_mana_gasta() -> void:
	await _start("sala_ponte")
	var fake: FakeSpellExecutor = auto_free(FakeSpellExecutor.new())
	add_child(fake)
	world.executor = fake
	world.state.set_mana(10.0)
	world.grimoire.create("Feitiço", "x")
	world.grimoire.equip(1, "Feitiço")
	fake.queue_result({"ok": true, "acoes": [{"tipo": "meditar", "linha": 1}], "saidas": [], "mago": MAGO_CHEIO, "custo_mana": 0.2})
	fake.queue_result({"ok": true, "acoes": _blocks(2), "saidas": [], "mago": MAGO_CHEIO, "custo_mana": 1.2})
	fake.queue_result({"ok": true, "acoes": _blocks(2), "saidas": [], "mago": MAGO_CHEIO, "custo_mana": 2.0})
	for i in 3:
		await world.cast(1)
		if world.action_player.is_playing():
			await world.action_player.finished
	await _frames(3)
	assert_bool(world.is_puzzle_solved("p_ponte")).is_true()
	assert_float(world.room_mana_spent).is_equal_approx(3.2, 0.001)
	assert_int(world.puzzle_stars("p_ponte")).is_equal(2)


func test_PUZ_018_sair_sem_resolver_zera_a_soma() -> void:
	await _start("sala_ponte")
	var fake: FakeSpellExecutor = auto_free(FakeSpellExecutor.new())
	add_child(fake)
	world.executor = fake
	world.grimoire.create("Feitiço", "x")
	world.grimoire.equip(1, "Feitiço")
	fake.queue_result({"ok": true, "acoes": _blocks(1), "saidas": [], "mago": MAGO_CHEIO, "custo_mana": 0.7})
	world.state.set_mana(10.0)
	await world.cast(1)
	assert_float(world.room_mana_spent).is_equal_approx(0.7, 0.001)
	world.go_to("sala_alvos", "A")
	await _frames(3)
	world.go_to("sala_ponte", "A")
	await _frames(3)
	assert_float(world.room_mana_spent).is_equal(0.0)


func test_PUZ_019_runa_sorteada() -> void:
	await _start("sala_sorteio")
	var first: int = world.spell_context()["room"]["runas"][0]
	assert_int(first).is_between(1, 9)
	assert_int(world.current_room.runes()[0].value).is_equal(first)
	var seen := {first: true}
	for i in 8:
		world.go_to("sala_alvos", "A")
		await _frames(2)
		world.go_to("sala_sorteio", "A")
		await _frames(2)
		seen[world.spell_context()["room"]["runas"][0]] = true
	assert_int(seen.size()).is_greater(1)


func test_MAG_071_sala_sem_cadeado_nem_ponte_so_avisa() -> void:
	await _start("sala_placa")
	await _play([{"tipo": "inscrever", "valor": 3, "linha": 1}, {"tipo": "construir_bloco", "linha": 2}, {"tipo": "meditar", "linha": 3}])
	assert_bool(world.action_player.is_playing()).is_false()


## Regressão (Sprint 9): as placas eram numeradas na ordem de leitura do layout (de cima para baixo),
## e não da esquerda para a direita como as runas (PUZ-validacao, regra 12).
func test_PUZ_016_placas_numeradas_da_esquerda_para_a_direita() -> void:
	await _start("sala_placas")
	player.global_position = Vector2(5 * 16 + 8, 64)
	await _frames(5)
	assert_array(world.current_room.puzzle_state()["placas"]).is_equal([true, false])


## Teste fraco achado pela mutação (Sprint 9): nada conferia que a placa só conta com o mago no chão.
func test_PUZ_016_placa_nao_conta_com_o_mago_no_ar() -> void:
	await _start("sala_placa")
	player.intent_source = func() -> PlayerIntent:
		var hover := PlayerIntent.make()
		hover.fly_y = 0.0
		return hover
	player.global_position = Vector2(7 * 16 + 8, 48 - 4)  # pairando 4 px acima da placa
	await _frames(10)
	assert_bool(player.is_on_floor()).is_false()
	assert_array(world.current_room.puzzle_state()["placas"]).is_equal([false])
	_walk(0.0)
	await _frames(20)
	assert_array(world.current_room.puzzle_state()["placas"]).is_equal([true])
