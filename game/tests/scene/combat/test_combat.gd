extends GdUnitTestSuite
## Spec: docs/specs/combate/COM-dano.md (COM-002 a COM-009), COM-elemental.md (regra 1, COM-024),
## COM-enxame.md (COM-043) e COM-guardiao.md (COM-063).
## sala_elementais: chão com topo em y = 80; entrada na coluna 2; elementais de fogo, gelo e planta
## nas colunas 12, 22 e 32. sala_combate: boneco na coluna 4, guardiões nas colunas 5, 8 e 16.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_combate.json"
const FLOOR_Y := 80.0

var world: World
var player: Player


func _start(room_id: String) -> void:
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = room_id
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	player = world.player
	_still()
	await _frames(3)


func after_test() -> void:
	get_tree().paused = false
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(GRIMOIRE_PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func _still() -> void:
	player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _enemy(digit: String) -> Enemy:
	for enemy in world.current_room.enemies():
		if enemy.target_id.ends_with("_alvo_" + digit):
			return enemy
	return null


func _place(x: float) -> void:
	player.global_position = Vector2(x, FLOOR_Y)
	player.velocity = Vector2.ZERO
	await _frames(2)


func test_COM_002_vida_e_derrota() -> void:
	await _start("sala_elementais")
	var fire := _enemy("1")
	var defeats := [0]
	fire.defeated.connect(func() -> void: defeats[0] += 1)
	assert_int(fire.health.current).is_equal(12)
	fire.hit("gelo", "projetil")
	assert_int(fire.health.current).is_equal(6)
	fire.hit("gelo", "projetil")
	assert_int(defeats[0]).is_equal(1)
	assert_bool(fire.is_defeated()).is_true()
	assert_bool(fire.is_in_group(TrainingTarget.GROUP)).is_false()
	assert_bool(fire.is_in_group(Enemy.ENEMY_GROUP)).is_false()
	fire.hit("gelo", "projetil")
	assert_int(defeats[0]).is_equal(1)
	await _frames(2)
	assert_array(world.current_room.enemies()).has_size(2)


func test_COM_003_o_golpe_mostra_o_dano() -> void:
	await _start("sala_elementais")
	var fire := _enemy("1")
	fire.hit("gelo", "projetil")
	assert_str(fire.effect_label.text).is_equal("Fraco! −6")
	assert_int(fire.last_damage).is_equal(6)
	fire.hit("fogo", "faisca")
	assert_str(fire.effect_label.text).is_equal("Resistiu")
	assert_int(fire.last_damage).is_equal(0)
	fire.hit("raio", "projetil")
	assert_str(fire.effect_label.text).is_equal("Acertou −3")
	fire.hit("fogo", "projetil")
	assert_str(fire.effect_label.text).is_equal("Resistiu −1")


func test_COM_024_cada_elemental_com_a_sua_fraqueza() -> void:
	await _start("sala_elementais")
	var weakness := {"1": ["fogo", "gelo"], "2": ["gelo", "raio"], "3": ["planta", "fogo"]}
	for digit: String in weakness:
		var enemy := _enemy(digit)
		assert_str(enemy.element).is_equal(weakness[digit][0])
		enemy.hit(weakness[digit][1], "projetil")
		enemy.hit(weakness[digit][1], "projetil")
		assert_bool(enemy.is_defeated()).override_failure_message(digit).is_true()


func test_COM_006_inimigos_na_foto() -> void:
	await _start("sala_combate")
	var enemies: Array = world.spell_context()["enemies"]
	assert_array(enemies.map(func(e: Dictionary) -> String: return e["id"])).is_equal(
			["sala_combate_alvo_3", "sala_combate_alvo_2"])
	assert_dict(enemies[0]).is_equal({"id": "sala_combate_alvo_3", "elemento": "pedra", "distancia": 3.0,
			"vida": 18, "escudo": "fogo"})
	assert_float(enemies[1]["distancia"]).is_equal(6.0)
	# O boneco é o alvo, sem vida nem escudo.
	assert_array(world.spell_context()["target"].keys()).contains_exactly_in_any_order(["id", "elemento", "distancia"])
	_enemy("3").apply_damage(18)
	await _frames(1)
	enemies = world.spell_context()["enemies"]
	assert_array(enemies.map(func(e: Dictionary) -> String: return e["id"])).is_equal(["sala_combate_alvo_2"])


func test_COM_007_alvo_inimigo_traz_vida_e_escudo() -> void:
	await _start("sala_elementais")
	await _place(9 * 16 + 8)
	var target: Dictionary = world.current_target()
	assert_str(target["id"]).is_equal("sala_elementais_alvo_1")
	assert_str(target["elemento"]).is_equal("fogo")
	assert_int(target["vida"]).is_equal(12)
	assert_that(target["escudo"]).is_null()


func test_COM_004_contato_machuca() -> void:
	await _start("sala_elementais")
	var fire := _enemy("1")
	await _place(fire.global_position.x - 12)
	var hurt_at := -1
	for i in 30:
		await _frames(1)
		if world.state.health.current < 5:
			hurt_at = i
			break
	assert_int(world.state.health.current).is_equal(4)
	# Empurrado para longe (o elemental está à direita).
	await _frames(1)
	assert_float(player.velocity.x).is_less(0.0)
	# A próxima mordida só depois da invencibilidade de 1 s.
	var second := -1
	for i in 150:
		await _frames(1)
		if world.state.health.current < 4:
			second = i
			break
	assert_int(hurt_at).is_not_equal(-1)
	assert_int(second).is_greater_equal(58)


func test_COM_005_escudo_bloqueia_o_contato() -> void:
	await _start("sala_elementais")
	var fire := _enemy("1")
	await _place(fire.global_position.x - 40)
	world.action_player.play([{"tipo": "lancar", "elemento": "raio", "forma": "escudo", "alvo": null, "linha": 1}])
	await _frames(2)
	assert_bool(world.state.health.shielded).is_true()
	player.global_position.x = fire.global_position.x - 12
	await _frames(10)
	assert_int(world.state.health.current).is_equal(5)
	assert_bool(world.state.health.shielded).is_false()


func test_COM_005_esquiva_evita_o_contato() -> void:
	await _start("sala_elementais")
	var fire := _enemy("1")
	await _place(fire.global_position.x - 24)
	var dodged := [false]
	player.intent_source = func() -> PlayerIntent:
		var intent := PlayerIntent.make()
		intent.dodge_pressed = not dodged[0]
		dodged[0] = true
		return intent
	for i in 9:
		await _frames(1)
		assert_int(world.state.health.current).override_failure_message("quadro %d" % i).is_equal(5)
	assert_float(player.global_position.x).is_greater(fire.global_position.x)


func test_COM_008_inimigos_reaparecem_ao_voltar() -> void:
	await _start("sala_elementais")
	_enemy("1").apply_damage(12)
	await _frames(1)
	assert_object(_enemy("1")).is_null()
	world.go_to("sala_elementais", "A")
	await _frames(2)
	assert_int(_enemy("1").health.current).is_equal(12)


func test_COM_008_inimigos_reaparecem_ao_morrer() -> void:
	await _start("sala_elementais")
	_enemy("1").apply_damage(12)
	world.state.health.damage(5, Health.Source.HAZARD)
	await _frames(3)
	assert_int(world.state.health.current).is_equal(5)
	assert_int(_enemy("1").health.current).is_equal(12)


func test_COM_009_pausa_congela() -> void:
	await _start("sala_elementais")
	await _frames(10)
	var fire := _enemy("1")
	var before := fire.position
	get_tree().paused = true
	await _frames(30)
	assert_vector(fire.position).is_equal(before)
	get_tree().paused = false
	await _frames(10)
	assert_vector(fire.position).is_not_equal(before)


func test_COM_043_bichos_do_enxame() -> void:
	await _start("sala_enxame")
	var bugs: Array[Enemy] = world.current_room.enemies()
	assert_array(bugs.map(func(e: Enemy) -> String: return e.target_id)).contains_exactly_in_any_order(
			["sala_enxame_alvo_4_1", "sala_enxame_alvo_4_2", "sala_enxame_alvo_4_3", "sala_enxame_alvo_4_4",
			"sala_enxame_alvo_4_5"])
	for bug: Enemy in bugs:
		assert_str(bug.element).is_equal("gelo")
		assert_int(bug.health.current).is_equal(2)


func test_COM_043_erros_de_autoria() -> void:
	for spec in ["inimigo:enxame:0", "inimigo:enxame:12", "inimigo:elemental:agua", "inimigo:dragao"]:
		var room: Room = auto_free(Room.new())
		room.room_id = "erro"
		room.layout = "#####\n#A.1#\n#####"
		room.targets = {"1": spec}
		add_child(room)
		assert_array(room.errors).override_failure_message(spec).is_not_empty()
		assert_array(room.enemies()).is_empty()
		remove_child(room)


func test_COM_063_escudo_na_foto() -> void:
	await _start("sala_combate")
	# Coluna 10: o guardião da coluna 8 fica a 2 tiles, o mais perto.
	await _place(10 * 16 + 8)
	var guardian := _enemy("2") as Guardian
	guardian.shield.time = 6.0
	var target: Dictionary = world.current_target()
	assert_str(target["id"]).is_equal("sala_combate_alvo_2")
	assert_str(target["escudo"]).is_equal("planta")
	guardian.shield.time = 4.5
	assert_that(world.current_target()["escudo"]).is_null()


## Regressão (Sprint 10, achado por captura de tela): a barra de vida ficava em cima do nome do elemento.
func test_COM_003_barra_de_vida_nao_cobre_o_nome() -> void:
	await _start("sala_combate")
	for enemy: Enemy in world.current_room.enemies():
		var name_rect := Rect2(enemy.name_label.position, enemy.name_label.get_minimum_size())
		assert_bool(enemy.life_bar_rect().intersects(name_rect)).override_failure_message(enemy.target_id).is_false()
	await _start("sala_elementais")
	var fire := _enemy("1")
	var name_rect := Rect2(fire.name_label.position, fire.name_label.get_minimum_size())
	assert_bool(fire.life_bar_rect().intersects(name_rect)).is_false()


## Achado pela mutação (Sprint 10): na posição de entrada, a ordem do layout já coincidia com a distância.
## Do outro lado da sala, as duas ordens se invertem.
func test_COM_006_inimigos_do_mais_perto_para_o_mais_longe() -> void:
	await _start("sala_combate")
	await _place(18 * 16 + 8)
	var enemies: Array = world.spell_context()["enemies"]
	assert_array(enemies.map(func(e: Dictionary) -> String: return e["id"])).is_equal(
			["sala_combate_alvo_4", "sala_combate_alvo_2"])
