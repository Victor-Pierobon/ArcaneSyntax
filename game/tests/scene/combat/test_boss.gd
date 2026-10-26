extends GdUnitTestSuite
## Spec: docs/specs/combate/COM-chefe.md (COM-084 a COM-087).
## sala_chefe: chão com topo em y = 80; entrada na coluna 2; chefe na coluna 12; porta na coluna 17.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_chefe.json"
const FLOOR_Y := 80.0
const TILE := RoomLayout.TILE

var world: World
var player: Player


func _start() -> void:
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = "sala_chefe"
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	player = world.player
	player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	await _frames(3)


func after_test() -> void:
	get_tree().paused = false
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(GRIMOIRE_PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


## Segundos de jogo (param com a árvore pausada).
func _seconds(value: float) -> void:
	await get_tree().create_timer(value, false, true).timeout


func _boss() -> Boss:
	var enemies := world.current_room.enemies()
	return null if enemies.is_empty() else enemies[0] as Boss


## Leva o chefe a vida 15 com três projéteis de gelo (o terceiro para no limite).
func _to_phase_two(boss: Boss) -> void:
	for i in 3:
		boss.hit("gelo", "projetil")


func test_COM_084_chefe_na_foto_do_mundo() -> void:
	await _start()
	var target: Dictionary = world.current_target()
	assert_str(target["id"]).is_equal("sala_chefe_alvo_1")
	assert_str(target["elemento"]).is_equal("fogo")
	assert_int(target["vida"]).is_equal(30)
	assert_that(target["escudo"]).is_null()
	assert_array(world.current_enemies()).has_size(1)


func test_COM_084_a_troca_de_fase_e_legivel() -> void:
	await _start()
	var boss := _boss()
	assert_str(boss.name_label.text).is_equal("fogo")
	_to_phase_two(boss)
	assert_int(boss.health.current).is_equal(15)
	assert_int(boss.last_damage).is_equal(3)
	assert_str(boss.phase_label.text).is_equal("Fase 2!")
	assert_bool(boss.phase_label.visible).is_true()
	assert_str(boss.name_label.text).is_equal("gelo")
	assert_str(world.current_target()["elemento"]).is_equal("gelo")
	# Na transição o golpe é bloqueado; depois dela, o corpo fica na cor do gelo.
	boss.hit("raio", "projetil")
	assert_bool(boss.last_blocked).is_true()
	assert_int(boss.health.current).is_equal(15)
	await _seconds(1.7)
	assert_that(boss.body_color()).is_equal(TrainingTarget.ELEMENT_COLORS["gelo"])
	assert_bool(boss.phase_label.visible).is_false()
	boss.hit("raio", "projetil")
	assert_int(boss.health.current).is_equal(9)


func test_COM_085_orbe_machuca_e_empurra() -> void:
	await _start()
	var boss := _boss()
	player.global_position = Vector2(boss.global_position.x - 6 * TILE, FLOOR_Y)
	await _frames(2)
	boss.phases.attack_left = 0.05
	var hurt := false
	for i in 150:
		await _frames(1)
		if world.state.health.current < 5:
			hurt = true
			break
	assert_bool(hurt).is_true()
	assert_int(world.state.health.current).is_equal(4)
	await _frames(1)
	assert_float(player.velocity.x).is_less(0.0)


func test_COM_085_escudo_bloqueia_o_orbe() -> void:
	await _start()
	var boss := _boss()
	player.global_position = Vector2(boss.global_position.x - 6 * TILE, FLOOR_Y)
	await _frames(2)
	world.state.health.shielded = true
	var blocked := [false]
	world.state.health.attack_blocked.connect(func() -> void: blocked[0] = true)
	boss.phases.attack_left = 0.05
	for i in 150:
		await _frames(1)
		if blocked[0]:
			break
	assert_bool(blocked[0]).is_true()
	assert_int(world.state.health.current).is_equal(5)
	assert_bool(world.state.health.shielded).is_false()


func test_COM_085_orbe_tem_a_cor_da_fase() -> void:
	await _start()
	var boss := _boss()
	_to_phase_two(boss)
	await _seconds(1.6)
	boss.phases.attack_left = 0.01
	await _frames(3)
	var bolts := get_tree().get_nodes_in_group(BossBolt.GROUP)
	assert_array(bolts).has_size(1)
	assert_str((bolts[0] as BossBolt).element).is_equal("gelo")


func test_COM_086_derrota_abre_a_porta_e_nao_volta() -> void:
	await _start()
	var boss := _boss()
	assert_bool(world.current_room.doors_open()).is_false()
	_to_phase_two(boss)
	await _seconds(1.6)
	boss.apply_damage(15)
	assert_bool(boss.is_defeated()).is_true()
	assert_bool(world.current_room.doors_open()).is_true()
	assert_str(world.cast_log.text()).contains(tr("CHEFE_DERROTADO"))
	world.go_to("sala_1", "A")
	await _frames(2)
	world.go_to("sala_chefe", "A")
	await _frames(2)
	assert_object(_boss()).is_null()
	assert_bool(world.current_room.doors_open()).is_true()


func test_COM_086_morrer_traz_o_chefe_de_volta() -> void:
	await _start()
	var boss := _boss()
	_to_phase_two(boss)
	world.state.health.damage(5, Health.Source.HAZARD)
	await _frames(3)
	var again := _boss()
	assert_object(again).is_not_null()
	assert_int(again.health.current).is_equal(30)
	assert_int(again.phases.phase).is_equal(1)
	assert_bool(world.current_room.doors_open()).is_false()


func test_COM_087_pausa_congela() -> void:
	await _start()
	var boss := _boss()
	player.global_position = Vector2(boss.global_position.x - 8 * TILE, FLOOR_Y)
	await _frames(2)
	boss.phases.attack_left = 0.01
	await _frames(3)
	_to_phase_two(boss)
	var bolt := get_tree().get_nodes_in_group(BossBolt.GROUP)[0] as BossBolt
	var before := bolt.position
	get_tree().paused = true
	await _frames(120)
	assert_vector(bolt.position).is_equal(before)
	assert_bool(boss.phases.in_transition()).is_true()
	assert_array(get_tree().get_nodes_in_group(BossBolt.GROUP)).has_size(1)
	get_tree().paused = false
	await _frames(5)
	assert_vector(bolt.position).is_not_equal(before)
