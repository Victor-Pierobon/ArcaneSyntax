extends GdUnitTestSuite
## Spec: docs/specs/arte/ART-esteira.md (ART-041 a ART-047): impacto, aura de meditar, morte dos
## inimigos, mergulho do enxame, escudo do guardião, cristal, porta, baú e tocha com a arte.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_arte_leva1.json"


func before_test() -> void:
	ArtFixtures.clear()
	ArtLibrary.use_root(ArtFixtures.ROOT)


func after_test() -> void:
	ArtLibrary.reset()
	ArtFixtures.clear()
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(GRIMOIRE_PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _art(folder: String, file_name: String, size: Vector2i, frames: int) -> void:
	ArtFixtures.write(folder, file_name, ArtFixtures.strip(size, frames))


## Um projétil de fogo saindo da origem de uma sala de mentira contra um boneco a 40 px.
func _shoot() -> Node2D:
	var place: Node2D = auto_free(Node2D.new())
	add_child(place)
	var target := TrainingTarget.make("boneco", "planta")
	target.position = Vector2(40, 12)
	place.add_child(target)
	await _frames(2)
	place.add_child(Projectile.make("fogo", Vector2.RIGHT))
	await _frames(20)
	return place


func _impacts(place: Node) -> Array:
	return place.get_children().filter(func(n: Node) -> bool: return n.name.begins_with("Impacto"))


func test_ART_041_impacto_do_projetil() -> void:
	_art("magia", "impacto_fogo", Vector2i(16, 16), 3)
	var place := await _shoot()
	var impacts := _impacts(place)
	assert_int(impacts.size()).is_equal(1)
	var impact: AnimatedSprite2D = impacts[0]
	assert_str(impact.animation).is_equal("impacto_fogo")
	assert_bool(impact.sprite_frames.get_animation_loop("impacto_fogo")).is_false()
	await get_tree().create_timer(0.4).timeout
	assert_int(_impacts(place).size()).is_equal(0)


func test_ART_041_sem_arte_sem_impacto() -> void:
	var place := await _shoot()
	assert_int(_impacts(place).size()).is_equal(0)


func test_ART_042_aura_de_meditar() -> void:
	_art("magia", "meditar", Vector2i(48, 48), 4)
	var world: World = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = "sala_bordas"
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	await _frames(3)
	var aura: AnimatedSprite2D = world.player.visual.aura
	assert_object(aura).is_not_null()
	assert_bool(aura.visible).is_false()
	world.player.play_action("meditar", 0.3)
	await _frames(2)
	assert_bool(aura.visible).is_true()
	assert_bool(aura.is_playing()).is_true()
	await get_tree().create_timer(0.4).timeout
	await _frames(2)
	assert_bool(aura.visible).is_false()


func test_ART_043_inimigo_morre_com_a_animacao() -> void:
	_art("elemental", "andar_fogo", Vector2i(32, 32), 4)
	_art("elemental", "morrer_fogo", Vector2i(32, 32), 8)  # 8 quadros a 10 fps: 0,8 s
	var elemental: Elemental = Elemental.make_elemental("e1", "fogo")
	add_child(elemental)
	await _frames(2)
	elemental.apply_damage(elemental.health.current)
	assert_bool(elemental.is_in_group(TrainingTarget.GROUP)).is_false()
	assert_str(elemental.art_sprite.animation).is_equal("morrer_fogo")
	assert_bool(elemental.art_sprite.visible).is_true()
	await get_tree().create_timer(0.5).timeout
	assert_bool(is_instance_valid(elemental)).is_true()
	await get_tree().create_timer(0.5).timeout
	assert_bool(is_instance_valid(elemental)).is_false()


func test_ART_043_sem_morrer_some_na_hora() -> void:
	_art("elemental", "andar_fogo", Vector2i(32, 32), 4)
	var elemental: Elemental = auto_free(Elemental.make_elemental("e1", "fogo"))
	add_child(elemental)
	await _frames(2)
	elemental.apply_damage(elemental.health.current)
	assert_bool(elemental.art_sprite.visible).is_false()


func test_ART_044_enxame_mergulha() -> void:
	_art("enxame", "voar", Vector2i(16, 16), 4)
	_art("enxame", "mergulhar", Vector2i(16, 16), 4)
	var place: Node2D = auto_free(Node2D.new())  # o bicho lê o mago nas coordenadas da sala
	add_child(place)
	var bug: SwarmBug = SwarmBug.make_bug("b1", Vector2(100, 100), 0.0)
	place.add_child(bug)
	await _frames(2)
	assert_str(bug.art_sprite.animation).is_equal("voar")
	var mago := Node2D.new()
	place.add_child(mago)
	mago.global_position = Vector2(100, 115)  # na casa do enxame: o bicho mergulha
	bug.player = mago
	await _frames(1)
	assert_int(bug.brain.state).is_equal(SwarmBugBrain.State.DIVE)
	assert_str(bug.art_sprite.animation).is_equal("mergulhar")
	bug.brain.bite()
	await _frames(1)
	assert_str(bug.art_sprite.animation).is_equal("voar")


func test_ART_045_escudo_do_guardiao() -> void:
	_art("guardiao", "escudo_fogo", Vector2i(32, 32), 4)
	var guardian: Guardian = auto_free(Guardian.make_guardian("g1"))
	add_child(guardian)
	await _frames(2)
	assert_str(guardian.shield.current()).is_equal("fogo")
	assert_object(guardian.shield_sprite).is_not_null()
	assert_bool(guardian.shield_sprite.visible).is_true()
	assert_str(guardian.shield_sprite.animation).is_equal("escudo_fogo")
	assert_bool(guardian.draws_shield_circle()).is_false()
	guardian.shield.time = guardian.shield.shield_time + 0.1
	await _frames(1)
	assert_str(guardian.shield.current()).is_empty()
	assert_bool(guardian.shield_sprite.visible).is_false()
	assert_bool(guardian.draws_shield_circle()).is_false()  # mutação: na brecha saía um círculo branco


func test_ART_046_cristal_apagado_e_aceso() -> void:
	_art("objetos", "cristal_apagado", Vector2i(16, 16), 1)
	_art("objetos", "cristal_aceso_fogo", Vector2i(16, 16), 4)  # mutação: com uma arte só, a reserva escondia o erro
	_art("objetos", "cristal_aceso_gelo", Vector2i(16, 16), 4)
	var crystal: Crystal = auto_free(Crystal.make_crystal("c1", "cristal"))
	add_child(crystal)
	assert_str(crystal.art_sprite.animation).is_equal("cristal_apagado")
	assert_bool(crystal.body_visible()).is_false()
	crystal.hit("gelo", "projetil")
	assert_bool(crystal.lit).is_true()
	assert_str(crystal.art_sprite.animation).is_equal("cristal_aceso_gelo")


func test_ART_047_porta_bau_e_tocha() -> void:
	_art("objetos", "porta", Vector2i(16, 16), 1)
	_art("objetos", "bau_fechado", Vector2i(32, 32), 1)
	_art("objetos", "tocha", Vector2i(16, 16), 4)
	var door: RuneDoor = auto_free(RuneDoor.make([Vector2i(2, 3), Vector2i(2, 4)] as Array[Vector2i]))
	add_child(door)
	assert_int(door.art_sprites.size()).is_equal(2)
	assert_bool(door.uses_art()).is_true()
	var chest: Chest = auto_free(Chest.make("s1", false))
	add_child(chest)
	assert_object(chest.art_sprite).is_not_null()
	assert_str(chest.art_sprite.animation).is_equal("bau_fechado")
	chest.open()
	assert_bool(chest.art_sprite.modulate.v < 1.0).is_true()
	var torch: Torch = auto_free(Torch.new())
	add_child(torch)
	assert_str(torch.art_sprite.animation).is_equal("tocha")
	assert_bool(torch.art_sprite.sprite_frames.get_animation_loop("tocha")).is_true()
	assert_bool(torch.is_in_group(TrainingTarget.GROUP)).is_false()


func test_ART_047_sem_arte_fica_o_provisorio() -> void:
	var door: RuneDoor = auto_free(RuneDoor.make([Vector2i(2, 3)] as Array[Vector2i]))
	add_child(door)
	assert_bool(door.uses_art()).is_false()
	var torch: Torch = auto_free(Torch.new())
	add_child(torch)
	assert_object(torch.art_sprite).is_null()


func test_ART_047_tocha_na_sala() -> void:
	var room: Room = auto_free(Room.new())
	room.room_id = "sala_tocha"
	room.layout = "#####\n#.1.#\n#A..#\n#####"
	room.targets = {"1": "tocha"}
	add_child(room)
	var torches := room.get_children().filter(func(n: Node) -> bool: return n is Torch)
	assert_int(torches.size()).is_equal(1)
	assert_array(room.errors).is_empty()
	assert_int(get_tree().get_nodes_in_group(TrainingTarget.GROUP).size()).is_equal(0)


## Regressão (2026-10-27, captura com a primeira leva): o nome e a barra de vida ficavam na altura do
## colisor e caíam em cima da arte, que é mais alta (o "fogo" sobre a cabeça do guardião). Com arte,
## eles ficam acima do pixel mais alto do desenho.
func test_ART_048_nome_e_barra_acima_da_arte() -> void:
	var tall := Image.create_empty(48, 48, false, Image.FORMAT_RGBA8)
	tall.fill_rect(Rect2i(14, 6, 20, 40), Color("8a8a8a"))  # 40 px de altura, base 2 px acima da borda
	ArtFixtures.write("guardiao", "andar", tall)
	var guardian: Guardian = auto_free(Guardian.make_guardian("g1"))
	add_child(guardian)
	assert_float(guardian.top_height()).is_equal(40.0)
	assert_float(guardian.life_bar_rect().end.y).is_less_equal(-40.0)
	assert_float(guardian.name_label.position.y + guardian.name_label.size.y).is_less_equal(guardian.life_bar_rect().position.y)


func test_ART_048_sem_arte_usa_o_corpo() -> void:
	var guardian: Guardian = auto_free(Guardian.make_guardian("g1"))
	add_child(guardian)
	assert_float(guardian.top_height()).is_equal(guardian.body_size.y)


func test_MUN_112_tocha_do_layout_na_sala() -> void:
	var room: Room = auto_free(Room.new())
	room.room_id = "sala_tocha"
	room.layout = "#####\n#!.!#\n#A..#\n#####"
	add_child(room)
	var torches := room.get_children().filter(func(n: Node) -> bool: return n is Torch)
	assert_int(torches.size()).is_equal(2)
	assert_vector(torches[0].position).is_equal(RoomLayout.cell_feet(Vector2i(1, 1)))
	assert_array(room.errors).is_empty()
	assert_int(get_tree().get_nodes_in_group(TrainingTarget.GROUP).size()).is_equal(0)
