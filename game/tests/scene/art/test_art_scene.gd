extends GdUnitTestSuite
## Spec: docs/specs/arte/ART-esteira.md (ART-011, 012, 021, 022, 030, 040): a arte (ou o provisório)
## no mago, nas paredes, no fundo e nos outros personagens. Sala de teste: tests/fixtures/rooms/sala_bordas.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_arte.json"
## sala_bordas: chão com topo em y = 160, plataforma na linha 7 (topo em y = 112, x de 80 a 128),
## bloco nas colunas 11 a 14 com topo em y = 64.
const FLOOR_Y := 160.0
const PLATFORM_Y := 112.0
const BLOCK_TOP := 64.0

var world: World
var player: Player


func before_test() -> void:
	ArtFixtures.clear()


func after_test() -> void:
	get_tree().paused = false
	ArtLibrary.reset()
	ArtFixtures.clear()
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(GRIMOIRE_PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func _start(room_id := "sala_bordas") -> void:
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = room_id
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	player = world.player
	player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	await _frames(3)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


## Regressão (2026-10-27, primeira arte gerada): os testes do provisório liam game/assets/ e quebraram
## quando a arte de verdade chegou. Todo teste de arte usa a pasta de teste.
func _use_art() -> void:
	ArtLibrary.use_root(ArtFixtures.ROOT)


func _walk(direction: float) -> void:
	player.intent_source = func() -> PlayerIntent: return PlayerIntent.make(direction)


func test_ART_011_mago_provisorio_segue_a_regra() -> void:
	_use_art()  # pasta de teste vazia: o jogo já pode ter arte de verdade em assets/
	await _start()
	assert_object(player.visual).is_not_null()
	assert_object(player.visual.sprite).is_null()
	assert_str(player.visual.shown_animation).is_equal("parado")
	_walk(1.0)
	await _frames(4)
	assert_str(player.visual.shown_animation).is_equal("andar")


func test_ART_011_mago_com_arte() -> void:
	_use_art()
	ArtFixtures.write("mago", "parado", ArtFixtures.strip(Vector2i(48, 48), 4))
	ArtFixtures.write("mago", "andar", ArtFixtures.strip(Vector2i(48, 48), 6))
	await _start()
	var sprite := player.visual.sprite
	assert_object(sprite).is_not_null()
	assert_str(sprite.animation).is_equal("parado")
	assert_bool(sprite.is_playing()).is_true()
	assert_float(sprite.position.y).is_equal(-22.0)
	_walk(-1.0)
	await _frames(4)
	assert_str(sprite.animation).is_equal("andar")
	assert_bool(sprite.flip_h).is_true()


func test_ART_012_conjurar_meditar_cajado_e_dano() -> void:
	await _start()
	var fake: FakeSpellExecutor = auto_free(FakeSpellExecutor.new())
	add_child(fake)
	world.executor = fake
	world.grimoire.create("Bola", "lancar(fogo, projetil)")
	world.grimoire.equip(1, "Bola")
	fake.queue_result({"ok": true, "custo_mana": 0, "mago": {"vida": 5, "mana": 10, "mana_max": 10}, "saidas": [],
		"acoes": [{"tipo": "lancar", "elemento": "fogo", "forma": "projetil", "alvo": null, "linha": 1}], "erro": null})
	await world.cast(1)
	await _frames(2)
	assert_str(player.current_animation).is_equal("conjurar")
	await get_tree().create_timer(0.4).timeout
	assert_str(player.current_animation).is_equal("parado")

	world.action_player.play([{"tipo": "meditar", "linha": 1}])
	await _frames(2)
	assert_str(player.current_animation).is_equal("meditar")
	await world.action_player.finished
	await _frames(2)
	assert_str(player.current_animation).is_equal("parado")

	world.world_actions.staff_attack()
	await _frames(2)
	assert_str(player.current_animation).is_equal("cajado")

	await get_tree().create_timer(0.4).timeout
	world.state.health.damage(1)
	await _frames(2)
	assert_str(player.current_animation).is_equal("dano")


func test_ART_021_formas_no_atlas() -> void:
	await _start()
	var room := world.current_room
	var solids := {}
	for cell in room.data.solids:
		solids[cell] = true
	var size := Vector2i(room.data.width, room.data.height)
	for cell in room.data.solids:
		var expected := TileShape.atlas(TileShape.mask(solids, cell, size))
		assert_that(room.tiles.get_cell_atlas_coords(cell)).override_failure_message(str(cell)).is_equal(expected)
	assert_that(room.tiles.get_cell_atlas_coords(Vector2i(15, 2))).is_equal(Vector2i(0, 0))
	assert_that(room.tiles.get_cell_atlas_coords(Vector2i(5, 10))).is_equal(TileShape.atlas(14))
	assert_that(room.tiles.get_cell_atlas_coords(Vector2i(5, 11))).is_equal(TileShape.atlas(15))
	assert_that(room.tiles.get_cell_atlas_coords(Vector2i(5, 7))).is_equal(TileShape.PLATFORM)
	assert_that(room.tiles.get_cell_atlas_coords(Vector2i(8, 9))).is_equal(TileShape.SPIKES)


func test_ART_021_colisoes() -> void:
	await _start()
	player.global_position = Vector2(12 * 16 + 8, BLOCK_TOP - 8)
	player.velocity = Vector2.ZERO
	await _frames(20)
	assert_bool(player.is_on_floor()).is_true()
	assert_float(player.global_position.y).is_equal_approx(BLOCK_TOP, 1.0)

	player.global_position = Vector2(6 * 16 + 8, FLOOR_Y)
	player.velocity = Vector2.ZERO
	await _frames(3)
	player.intent_source = func() -> PlayerIntent:
		var intent := PlayerIntent.make()
		intent.fly_y = -96.0
		return intent
	await _frames(40)
	assert_float(player.global_position.y).is_less(PLATFORM_Y - 8.0)
	player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	await _frames(40)
	assert_bool(player.is_on_floor()).is_true()
	assert_float(player.global_position.y).is_equal_approx(PLATFORM_Y, 1.0)


func test_ART_022_tiles_provisorios() -> void:
	_use_art()
	await _start()
	assert_str(world.current_room.tiles_source).is_equal(Room.PLACEHOLDER_TILES)


func test_ART_022_tiles_do_victor() -> void:
	_use_art()
	ArtFixtures.write("cenario", "tiles", ArtFixtures.strip(Vector2i(64, 80), 1))
	await _start()
	assert_str(world.current_room.tiles_source).is_equal(ArtFixtures.ROOT + "cenario/tiles.png")


func test_ART_030_fundo_em_tres_camadas() -> void:
	_use_art()
	ArtFixtures.write("cenario", "fundo_2", ArtFixtures.strip(Vector2i(640, 360), 1))
	await _start()
	var backdrop := world.backdrop
	assert_int(backdrop.layers.size()).is_equal(3)
	var factors := [0.2, 0.45, 0.7]
	for i in 3:
		var layer: Parallax2D = backdrop.layers[i]
		assert_float(layer.scroll_scale.x).is_equal_approx(factors[i], 0.001)
		assert_float(layer.repeat_size.x).is_equal(640.0)
	assert_str(backdrop.sources[0]).is_equal(Backdrop.PLACEHOLDER % 1)
	assert_str(backdrop.sources[1]).is_equal(ArtFixtures.ROOT + "cenario/fundo_2.png")
	assert_str(backdrop.sources[2]).is_equal(Backdrop.PLACEHOLDER % 3)
	assert_int(backdrop.z_index).is_less(0)


## Regressão (Sprint 16, captura de tela): nas salas menores que a tela, o fundo aparecia em volta da
## sala e ela parecia flutuar. Fora da sala é escuro.
func test_ART_031_fora_da_sala_e_escuro() -> void:
	await _start()
	var bounds := world.current_room.bounds()
	assert_float(bounds.size.x).is_less(640.0)
	var outside := [bounds.position + Vector2(-10, 50), Vector2(bounds.end.x + 10, 50),
		bounds.position + Vector2(50, -10), Vector2(50, bounds.end.y + 10), Vector2(bounds.end.x + 300, bounds.end.y + 300)]
	for point: Vector2 in outside:
		assert_bool(world.backdrop.covers_outside(point)).override_failure_message(str(point)).is_true()
	assert_bool(world.backdrop.covers_outside(bounds.get_center())).is_false()
	world.go_to("sala_aberta", "A")
	await _frames(2)
	var wide := world.current_room.bounds()
	assert_bool(world.backdrop.covers_outside(Vector2(wide.end.x + 10, 50))).is_true()
	assert_bool(world.backdrop.covers_outside(wide.get_center())).is_false()


## Regressão (Sprint 16, captura de tela): com a câmera suave, o nome do elemento sobre o inimigo ("fogo")
## caía entre pixels e saía embaralhado. O desenho 2D fica preso à grade de pixels.
func test_ART_032_desenho_preso_aos_pixels() -> void:
	assert_bool(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel", false)).is_true()
	assert_bool(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_vertices_to_pixel", false)).is_true()


func test_ART_040_personagens_com_arte() -> void:
	_use_art()
	ArtFixtures.write("serpente", "parada", ArtFixtures.strip(Vector2i(32, 32), 4))
	ArtFixtures.write("elemental", "andar_fogo", ArtFixtures.strip(Vector2i(32, 32), 4))
	ArtFixtures.write("magia", "projetil_gelo", ArtFixtures.strip(Vector2i(16, 16), 4))
	ArtFixtures.write("magia", "escudo_raio", ArtFixtures.strip(Vector2i(48, 48), 4))
	var serpent: Serpent = auto_free(Serpent.make("ola"))
	var elemental: Elemental = auto_free(Elemental.make_elemental("e1", "fogo"))
	var ice: Elemental = auto_free(Elemental.make_elemental("e2", "gelo"))
	var projectile: Projectile = auto_free(Projectile.make("gelo", Vector2.RIGHT))
	var shield: Shield = auto_free(Shield.make("raio"))
	for node: Node in [serpent, elemental, ice, projectile, shield]:
		add_child(node)
	assert_str(serpent.art_sprite.animation).is_equal("parada")
	assert_str(elemental.art_sprite.animation).is_equal("andar_fogo")
	assert_object(ice.art_sprite).is_null()
	assert_str(projectile.art_sprite.animation).is_equal("projetil_gelo")
	assert_str(shield.art_sprite.animation).is_equal("escudo_raio")
	assert_bool(elemental.art_sprite.is_playing()).is_true()
	assert_bool(elemental.body_visible()).is_false()
	assert_bool(ice.body_visible()).is_true()


func test_ART_040_sem_arte_fica_o_desenho_de_hoje() -> void:
	_use_art()
	var serpent: Serpent = auto_free(Serpent.make("ola"))
	var elemental: Elemental = auto_free(Elemental.make_elemental("e1", "fogo"))
	add_child(serpent)
	add_child(elemental)
	assert_object(serpent.art_sprite).is_null()
	assert_object(elemental.art_sprite).is_null()
	assert_bool(elemental.body_visible()).is_true()
