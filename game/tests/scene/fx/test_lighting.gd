extends GdUnitTestSuite
## Spec: docs/specs/arte/ART-brilho.md (ART-060, ART-061).
## sala_luz: tocha na coluna 4, serpente na 7, fonte na 10, cristal na 15, elemental de fogo na 23.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_luz.json"

var world: World


func _start() -> void:
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = "sala_luz"
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	await get_tree().physics_frame
	await get_tree().physics_frame


func after_test() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(GRIMOIRE_PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func _first(kind: Variant) -> Node:
	for child in world.current_room.get_children():
		if is_instance_of(child, kind):
			return child
	return null


func _assert_light(light: PointLight2D, color: Color, radius: float, label: String) -> void:
	assert_object(light).override_failure_message(label).is_not_null()
	assert_bool(light.enabled).override_failure_message(label).is_true()
	assert_that(light.color).override_failure_message(label).is_equal(color)
	assert_float(Lighting.radius_of(light)).override_failure_message(label).is_equal_approx(radius, 0.5)


func test_ART_060_sala_escura_hud_clara() -> void:
	await _start()
	var shades := world.get_children().filter(func(n: Node) -> bool: return n is CanvasModulate)
	assert_int(shades.size()).is_equal(1)
	assert_that((shades[0] as CanvasModulate).color).is_equal(Lighting.AMBIENT)
	assert_object(world.hud).is_instanceof(CanvasLayer)
	assert_object(world.dialogue_box).is_instanceof(CanvasLayer)
	assert_object(world.grimoire_ui).is_instanceof(CanvasLayer)


func test_ART_061_quem_acende_luz() -> void:
	await _start()
	_assert_light((_first(Torch) as Torch).light, Lighting.TORCH, 80, "tocha")
	_assert_light((_first(Serpent) as Serpent).light, Lighting.SERPENT, 40, "serpente")
	_assert_light((_first(Fountain) as Fountain).light, Lighting.FOUNTAIN, 48, "fonte")
	var elemental := world.current_room.enemies()[0]
	_assert_light(elemental.light, TrainingTarget.ELEMENT_COLORS["fogo"], 32, "elemental")
	_assert_light(world.player.light, Lighting.MAGE, 56, "mago")
	var crystal: Crystal = _first(Crystal)
	assert_bool(crystal.glow.enabled).override_failure_message("cristal apagado").is_false()


func test_ART_061_cristal_aceso_projetil_e_escudo() -> void:
	await _start()
	var crystal: Crystal = _first(Crystal)
	crystal.hit("gelo", "projetil")
	_assert_light(crystal.glow, TrainingTarget.ELEMENT_COLORS["gelo"], 48, "cristal aceso")
	var projectile := Projectile.make("raio", Vector2.RIGHT)
	world.current_room.add_child(projectile)
	_assert_light(projectile.light, TrainingTarget.ELEMENT_COLORS["raio"], 32, "projétil")
	var shield := Shield.make("fogo")
	world.player.add_child(shield)
	_assert_light(shield.light, TrainingTarget.ELEMENT_COLORS["fogo"], 40, "escudo")
	shield.queue_free()
	projectile.queue_free()


func test_ART_061_chefe_troca_a_cor_da_luz() -> void:
	await _start()
	var boss: Boss = Boss.make_boss("chefe_luz")
	world.current_room.add_child(boss)
	_assert_light(boss.light, TrainingTarget.ELEMENT_COLORS["fogo"], 64, "chefe fase 1")
	while boss.health.current > 60:
		boss.hit("gelo", "projetil")
	_assert_light(boss.light, TrainingTarget.ELEMENT_COLORS["gelo"], 64, "chefe fase 2")
	var bolt := BossBolt.make("gelo", Vector2.RIGHT)
	world.current_room.add_child(bolt)
	_assert_light(bolt.light, TrainingTarget.ELEMENT_COLORS["gelo"], 24, "orbe")
	var pillar := BossPillar.make("gelo")
	world.current_room.add_child(pillar)
	assert_bool(pillar.light.enabled).override_failure_message("pilar na marca").is_false()
	pillar.rise()
	_assert_light(pillar.light, TrainingTarget.ELEMENT_COLORS["gelo"], 24, "pilar de pé")
	bolt.queue_free()
	pillar.queue_free()


## Regressão (captura de tela, Sprint 20): os textos do mundo escureciam com a sala, e o nome do
## elemento sobre o inimigo (o que o jogador lê para escolher o feitiço) quase sumia.
func test_ART_060_textos_do_mundo_nao_escurecem() -> void:
	await _start()
	world.player.global_position = (_first(Serpent) as Serpent).global_position + Vector2(-16, 0)
	await get_tree().physics_frame
	var labels: Array = world.current_room.find_children("*", "Label", true, false)
	assert_int(labels.size()).is_greater_equal(5)
	for label: Label in labels:
		assert_that(label.self_modulate).override_failure_message(str(label.get_path())).is_equal(Lighting.READABLE)
