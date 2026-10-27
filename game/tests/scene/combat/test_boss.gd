extends GdUnitTestSuite
## Spec: docs/specs/combate/COM-chefe.md (COM-092, COM-085, COM-086, COM-087).
## sala_chefe: chão com topo em y = 176; plataforma (colunas 8 a 11) com topo em y = 96; entrada na
## coluna 2; chefe na coluna 15; pontos no alto nas colunas 10 e 18; investida nas colunas 4 e 24;
## porta na coluna 27. Os testes que esperam um ataque usam um balanceamento com tempos curtos.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_chefe.json"
const BALANCE_PATH := "user://tests/balanceamento_chefe.json"
const FLOOR_Y := 176.0
const PLATFORM := Vector2(9 * 16 + 8, 96)
const TILE := RoomLayout.TILE
## Tempos curtos: o ciclo começa logo e o chefe chega aos pontos quase na hora.
const FAST := {
	"inicio_s": 0.1, "velocidade": 3000, "descanso_s": [0.4, 0.4, 0.4], "leque_aviso_s": 0.2,
	"orbe_velocidade": 200, "pilar_aviso_s": 0.3, "pilar_intervalo_s": 0.3, "investida_aviso_s": 0.2,
}

var world: World
var player: Player


## `fast`: troca da seção `chefe` por cima de FAST; vazio usa o balanceamento do jogo.
func _start(fast: Variant = null) -> void:
	if fast != null:
		_use_balance(FAST.merged(fast, true))
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = "sala_chefe"
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	player = world.player
	player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	await _frames(3)


func _use_balance(changes: Dictionary) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Balance.DEFAULT_PATH))
	for key: String in changes:
		data["chefe"][key] = changes[key]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	var file := FileAccess.open(BALANCE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	Balance.use_file(BALANCE_PATH)


func after_test() -> void:
	get_tree().paused = false
	Balance.reset()
	ArtLibrary.reset()
	ArtFixtures.clear()
	for path in [GRIMOIRE_PATH, BALANCE_PATH]:
		for suffix in ["", ".bak", ".tmp"]:
			var file := ProjectSettings.globalize_path(path + suffix)
			if FileAccess.file_exists(file):
				DirAccess.remove_absolute(file)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


## Segundos de jogo (param com a árvore pausada).
func _seconds(value: float) -> void:
	await get_tree().create_timer(value, false, true).timeout


## Espera até `condition` ou `max_frames`; devolve se aconteceu.
func _until(condition: Callable, max_frames := 600) -> bool:
	for i in max_frames:
		if condition.call():
			return true
		await _frames(1)
	return condition.call()


func _boss() -> Boss:
	var enemies := world.current_room.enemies()
	return null if enemies.is_empty() else enemies[0] as Boss


func _put_player(at: Vector2) -> void:
	player.global_position = at
	player.velocity = Vector2.ZERO
	await _frames(2)


## Golpes de `element` até a vida chegar a `health` (cada um dá 6; nenhum é cortado).
func _hit_to(boss: Boss, element: String, health: int) -> void:
	while boss.health.current > health:
		boss.hit(element, "projetil")


func _hurt() -> bool:
	return world.state.health.current < 5


# --- COM-092: o chefe na sala ---


func test_COM_092_chefe_e_alvo_a_qualquer_distancia() -> void:
	await _start()
	var boss := _boss()
	assert_float(player.global_position.distance_to(boss.global_position)).is_greater(12 * TILE)
	var target: Dictionary = world.current_target()
	assert_str(target["id"]).is_equal("sala_chefe_alvo_1")
	assert_str(target["elemento"]).is_equal("fogo")
	assert_int(target["vida"]).is_equal(90)
	assert_that(target["escudo"]).is_null()
	# A distância é a de verdade, não a do limite do alcance.
	assert_float(target["distancia"]).is_greater(12.0)
	assert_array(world.current_enemies()).has_size(1)


## Regressão (Sprint 17): o projétil sumia depois de 12 tiles e não alcançava o chefe longe.
func test_COM_092_projetil_alcanca_o_chefe_longe() -> void:
	await _start()
	var boss := _boss()
	var from := player.global_position + Vector2(0, -15)
	var projectile := Projectile.make("gelo", boss.center() - from, "projetil", boss)
	projectile.global_position = from
	world.current_room.add_child(projectile)
	assert_bool(await _until(func() -> bool: return boss.hits > 0, 240)).is_true()
	assert_int(boss.health.current).is_equal(84)


func test_COM_092_as_trocas_de_fase_sao_legiveis() -> void:
	await _start()
	var boss := _boss()
	assert_str(boss.name_label.text).is_equal("fogo")
	_hit_to(boss, "gelo", 60)
	assert_int(boss.health.current).is_equal(60)
	assert_str(boss.phase_label.text).is_equal("Fase 2!")
	assert_bool(boss.phase_label.visible).is_true()
	assert_str(boss.name_label.text).is_equal("gelo")
	assert_str(world.current_target()["elemento"]).is_equal("gelo")
	# Na transição o golpe é bloqueado; depois dela, o corpo fica na cor do gelo.
	boss.hit("raio", "projetil")
	assert_bool(boss.last_blocked).is_true()
	await _seconds(1.7)
	assert_that(boss.body_color()).is_equal(TrainingTarget.ELEMENT_COLORS["gelo"])
	assert_bool(boss.phase_label.visible).is_false()
	_hit_to(boss, "raio", 30)
	assert_int(boss.health.current).is_equal(30)
	assert_str(boss.phase_label.text).is_equal("Fase 3!")
	assert_str(boss.name_label.text).is_equal("planta")
	assert_str(world.current_target()["elemento"]).is_equal("planta")


func test_COM_092_voa_entre_os_pontos() -> void:
	await _start()
	var boss := _boss()
	var start := boss.position
	await _seconds(1.9)
	assert_vector(boss.position).is_equal(start)
	var first := RoomLayout.cell_feet(Vector2i(10, 2))
	var second := RoomLayout.cell_feet(Vector2i(18, 2))
	assert_bool(await _until(func() -> bool: return boss.position == first, 300)).is_true()
	assert_bool(await _until(func() -> bool: return boss.position == second, 600)).is_true()


# --- COM-085: os ataques machucam; escudo e esquiva protegem ---


func test_COM_085_o_orbe_do_meio_acerta_quem_esta_parado() -> void:
	await _start({})
	await _put_player(Vector2(6 * TILE, FLOOR_Y))
	assert_bool(await _until(_hurt)).is_true()
	assert_int(world.state.health.current).is_equal(4)
	await _frames(1)
	assert_float(player.velocity.x).is_not_equal(0.0)


func test_COM_085_escudo_bloqueia_o_orbe() -> void:
	await _start({})
	await _put_player(Vector2(6 * TILE, FLOOR_Y))
	world.state.health.shielded = true
	var blocked := [false]
	world.state.health.attack_blocked.connect(func() -> void: blocked[0] = true)
	assert_bool(await _until(func() -> bool: return blocked[0])).is_true()
	assert_int(world.state.health.current).is_equal(5)
	assert_bool(world.state.health.shielded).is_false()


func test_COM_085_esquiva_evita_o_orbe() -> void:
	# Um orbe só, para a esquiva não cair no caminho de outro.
	await _start({"leque_orbes": [1, 1, 1]})
	await _put_player(Vector2(6 * TILE, FLOOR_Y))
	var dodged := [false]
	# Esquiva na direção do orbe quando ele está perto: atravessa o orbe invulnerável.
	player.intent_source = func() -> PlayerIntent:
		var intent := PlayerIntent.make()
		for bolt in get_tree().get_nodes_in_group(BossBolt.GROUP):
			var at := (bolt as Node2D).global_position
			if not dodged[0] and at.distance_to(player.global_position + Vector2(0, -15)) < 32:
				intent.move_x = signf(at.x - player.global_position.x)
				intent.dodge_pressed = true
				dodged[0] = true
		return intent
	assert_bool(await _until(func() -> bool: return dodged[0])).is_true()
	await _seconds(0.6)
	assert_int(world.state.health.current).is_equal(5)


func test_COM_085_pilar_acerta_quem_fica_na_marca() -> void:
	await _start({"ataques": [["pilares"], ["pilares"], ["pilares"]], "pilar_marcas": [1, 1, 1]})
	await _put_player(Vector2(6 * TILE, FLOOR_Y))
	var boss := _boss()
	assert_bool(await _until(func() -> bool: return not boss.pillars().is_empty())).is_true()
	var pillar := boss.pillars()[0]
	assert_float(pillar.position.y).is_equal(FLOOR_Y)
	assert_float(absf(pillar.position.x - player.global_position.x)).is_less_equal(TILE / 2.0)
	assert_bool(pillar.risen).is_false()
	assert_bool(_hurt()).is_false()
	assert_bool(await _until(_hurt, 120)).is_true()
	assert_int(world.state.health.current).is_equal(4)


## Regressão (captura de tela, Sprint 17): a marca de 3 px ficava atrás do mago parado em cima dela,
## e o aviso não aparecia justamente para quem precisava dele.
func test_COM_085_aviso_do_pilar_aparece_na_frente_do_mago() -> void:
	await _start({"ataques": [["pilares"], ["pilares"], ["pilares"]], "pilar_marcas": [1, 1, 1]})
	await _put_player(Vector2(6 * TILE, FLOOR_Y))
	var boss := _boss()
	assert_bool(await _until(func() -> bool: return not boss.pillars().is_empty())).is_true()
	var pillar := boss.pillars()[0]
	# O contorno do pilar que vai subir: a área inteira, acima da cabeça do mago.
	assert_bool(pillar.preview.visible).is_true()
	assert_vector(pillar.preview.size).is_equal(Vector2(BossPillar.WIDTH, pillar.height))
	var above_head := player.global_position + Vector2(0, -40)
	assert_bool(pillar.preview.get_global_rect().has_point(Vector2(pillar.global_position.x, above_head.y))).is_true()
	# Desenhado na frente do mago.
	assert_int(pillar.z_index).is_greater(player.z_index)
	assert_bool(await _until(func() -> bool: return pillar.risen, 120)).is_true()
	assert_bool(pillar.preview.visible).is_false()


func test_COM_085_pilar_nao_acerta_quem_sai_da_marca() -> void:
	await _start({"ataques": [["pilares"], ["pilares"], ["pilares"]], "pilar_marcas": [1, 1, 1],
			"descanso_s": [5.0, 5.0, 5.0]})
	await _put_player(Vector2(6 * TILE, FLOOR_Y))
	var boss := _boss()
	assert_bool(await _until(func() -> bool: return not boss.pillars().is_empty())).is_true()
	var pillar := boss.pillars()[0]
	await _put_player(Vector2(14 * TILE, FLOOR_Y))
	assert_bool(await _until(func() -> bool: return pillar.risen, 120)).is_true()
	await _seconds(0.6)
	assert_int(world.state.health.current).is_equal(5)


func test_COM_085_investida_acerta_no_chao() -> void:
	await _start({"ataques": [["investida"], ["investida"], ["investida"]]})
	await _put_player(Vector2(14 * TILE, FLOOR_Y))
	var boss := _boss()
	assert_bool(await _until(func() -> bool: return boss.warning == "investida")).is_true()
	assert_bool(await _until(_hurt, 240)).is_true()
	assert_int(world.state.health.current).is_equal(4)


func test_COM_085_investida_nao_alcanca_a_plataforma() -> void:
	await _start({"ataques": [["investida"], ["investida"], ["investida"]], "descanso_s": [5.0, 5.0, 5.0]})
	await _put_player(PLATFORM)
	var boss := _boss()
	assert_bool(await _until(func() -> bool: return boss.brain.charging())).is_true()
	assert_bool(await _until(func() -> bool: return not boss.brain.charging(), 240)).is_true()
	assert_int(world.state.health.current).is_equal(5)


# --- COM-086: derrota, porta e memória ---


func test_COM_086_derrota_abre_a_porta_limpa_e_nao_volta() -> void:
	await _start({"ataques": [["pilares"], ["pilares"], ["pilares"]], "pilar_marcas": [1, 1, 1],
			"descanso_s": [5.0, 5.0, 5.0]})
	await _put_player(Vector2(6 * TILE, FLOOR_Y))
	var boss := _boss()
	assert_bool(await _until(func() -> bool: return not boss.pillars().is_empty())).is_true()
	assert_bool(world.current_room.doors_open()).is_false()
	boss.apply_damage(90)
	assert_bool(boss.is_defeated()).is_true()
	assert_bool(world.current_room.doors_open()).is_true()
	assert_str(world.cast_log.text()).contains(tr("CHEFE_DERROTADO"))
	await _frames(2)
	assert_array(get_tree().get_nodes_in_group(BossPillar.GROUP)).is_empty()
	assert_array(get_tree().get_nodes_in_group(BossBolt.GROUP)).is_empty()
	world.go_to("sala_1", "A")
	await _frames(2)
	world.go_to("sala_chefe", "A")
	await _frames(2)
	assert_object(_boss()).is_null()
	assert_bool(world.current_room.doors_open()).is_true()


func test_COM_086_morrer_traz_o_chefe_de_volta() -> void:
	await _start()
	var boss := _boss()
	var start := boss.position
	_hit_to(boss, "gelo", 60)
	await _seconds(1.7)
	_hit_to(boss, "raio", 30)
	world.state.health.damage(5, Health.Source.HAZARD)
	await _frames(3)
	var again := _boss()
	assert_object(again).is_not_null()
	assert_int(again.health.current).is_equal(90)
	assert_int(again.phases.phase).is_equal(1)
	assert_vector(again.position).is_equal(start)
	assert_int(again.brain.state).is_equal(BossBrain.State.START)
	assert_bool(world.current_room.doors_open()).is_false()


# --- COM-087: pausa congela ---


func test_COM_087_pausa_congela_movimento_e_marca() -> void:
	await _start({"velocidade": 60, "ataques": [["pilares"], ["pilares"], ["pilares"]], "pilar_marcas": [3, 3, 3]})
	await _put_player(Vector2(6 * TILE, FLOOR_Y))
	var boss := _boss()
	# Voando para o primeiro ponto.
	assert_bool(await _until(func() -> bool: return boss.brain.state == BossBrain.State.MOVE)).is_true()
	await _frames(5)
	get_tree().paused = true
	var before := boss.position
	await _frames(60)
	assert_vector(boss.position).is_equal(before)
	get_tree().paused = false
	# Marca piscando.
	assert_bool(await _until(func() -> bool: return not boss.pillars().is_empty(), 600)).is_true()
	get_tree().paused = true
	var mark_time: float = boss.brain.marks[0]["tempo"]
	await _frames(90)
	assert_float(boss.brain.marks[0]["tempo"]).is_equal(mark_time)
	assert_bool(boss.pillars()[0].risen).is_false()
	get_tree().paused = false
	assert_bool(await _until(func() -> bool: return boss.pillars().is_empty() or boss.pillars()[0].risen, 120)).is_true()


func test_COM_087_pausa_congela_o_orbe() -> void:
	await _start({"orbe_velocidade": 60})
	await _put_player(Vector2(26 * TILE, FLOOR_Y))
	assert_bool(await _until(func() -> bool: return not get_tree().get_nodes_in_group(BossBolt.GROUP).is_empty())).is_true()
	var bolt := get_tree().get_nodes_in_group(BossBolt.GROUP)[0] as BossBolt
	var count := get_tree().get_nodes_in_group(BossBolt.GROUP).size()
	var before := bolt.position
	get_tree().paused = true
	await _frames(120)
	assert_vector(bolt.position).is_equal(before)
	assert_int(get_tree().get_nodes_in_group(BossBolt.GROUP).size()).is_equal(count)
	get_tree().paused = false
	await _frames(5)
	assert_vector(bolt.position).is_not_equal(before)


# --- COM-096: arte ---


func test_COM_096_chefe_usa_a_arte() -> void:
	ArtFixtures.clear()
	for anim in ["parado_fogo", "orbe_fogo", "parado_gelo"]:
		ArtFixtures.write("chefe", anim, ArtFixtures.strip(Vector2i(96, 96), 2))
	ArtFixtures.write("chefe", "aviso", ArtFixtures.strip(Vector2i(16, 16), 2))
	ArtFixtures.write("chefe", "pilar", ArtFixtures.strip(Vector2i(16, 64), 2))
	ArtFixtures.write("chefe", "orbe_voando_fogo", ArtFixtures.strip(Vector2i(16, 16), 2))
	ArtLibrary.use_root(ArtFixtures.ROOT)
	await _start({"ataques": [["leque", "pilares"], ["leque"], ["leque"]], "pilar_marcas": [1, 1, 1],
			"leque_aviso_s": 0.5})
	await _put_player(Vector2(6 * TILE, FLOOR_Y))
	var boss := _boss()
	assert_object(boss.art_sprite).is_not_null()
	assert_bool(boss.body_visible()).is_false()
	assert_str(boss.art_sprite.animation).is_equal("parado_fogo")
	assert_bool(await _until(func() -> bool: return boss.warning == "leque")).is_true()
	await _frames(1)
	assert_str(boss.art_sprite.animation).is_equal("orbe_fogo")
	assert_bool(await _until(func() -> bool: return not get_tree().get_nodes_in_group(BossBolt.GROUP).is_empty())).is_true()
	assert_object((get_tree().get_nodes_in_group(BossBolt.GROUP)[0] as BossBolt).art_sprite).is_not_null()
	assert_bool(await _until(func() -> bool: return not boss.pillars().is_empty())).is_true()
	var pillar := boss.pillars()[0]
	assert_bool(pillar.mark_art.visible).is_true()
	assert_bool(pillar.mark.visible).is_false()
	assert_bool(await _until(func() -> bool: return pillar.risen, 120)).is_true()
	assert_bool(pillar.column_art.visible).is_true()
	assert_bool(pillar.column.visible).is_false()
	_hit_to(boss, "gelo", 60)
	await _seconds(1.7)
	assert_str(boss.art_sprite.animation).is_equal("parado_gelo")
