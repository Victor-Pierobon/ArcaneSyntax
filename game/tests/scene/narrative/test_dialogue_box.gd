extends GdUnitTestSuite
## Spec: docs/specs/narrativa/NAR-dialogo.md (regras 5 e 6, NAR-005, NAR-006).
## sala_serpente: chão com topo em y = 80; entrada na coluna 2; serpente_ola na coluna 11;
## serpente com cena inexistente na coluna 21. Teclas não chegam em headless: os testes chamam `talk()`.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_dialogo.json"
const FLOOR_Y := 80.0
const TILE := RoomLayout.TILE
## Altura do corpo do mago (a colisão em player.tscn).
const PLAYER_HEIGHT := 30.0

var world: World
var box: DialogueBox


func before_test() -> void:
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = "sala_serpente"
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	box = world.dialogue_box
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


func _stand_at_column(column: float) -> void:
	world.player.global_position = Vector2(column * TILE + TILE / 2.0, FLOOR_Y)
	world.player.velocity = Vector2.ZERO
	await _frames(2)


func test_NAR_005_longe_nao_abre() -> void:
	await _stand_at_column(5)
	assert_object(world.serpent_in_reach()).is_null()
	world.talk()
	assert_bool(box.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()


func test_NAR_005_falar_com_a_serpente() -> void:
	await _stand_at_column(9.5)
	var serpent := world.serpent_in_reach()
	assert_object(serpent).is_not_null()
	assert_bool(serpent.prompt_visible()).is_true()
	world.talk()
	assert_bool(box.is_open()).is_true()
	assert_bool(get_tree().paused).is_true()
	assert_str(box.speaker_label.text).is_equal(tr("DIALOGO_SERPENTE"))
	assert_str(box.text_label.text).is_equal(tr("SERPENTE_OLA_1"))
	box.advance()
	assert_str(box.text_label.text).is_equal(tr("SERPENTE_OLA_2"))
	assert_str(box.options_label.text).contains("1. " + tr("SERPENTE_OLA_OPCAO_QUEM"))
	box.advance()
	assert_str(box.text_label.text).is_equal(tr("SERPENTE_OLA_2"))
	box.choose(1)
	assert_str(box.text_label.text).is_equal(tr("SERPENTE_OLA_3"))
	while box.is_open():
		box.advance()
	assert_bool(get_tree().paused).is_false()


func test_NAR_005_grimorio_nao_abre_durante_o_dialogo() -> void:
	await _stand_at_column(9.5)
	world.talk()
	world.grimoire_ui.open()
	assert_bool(world.grimoire_ui.is_open()).is_false()
	while box.is_open():
		box.advance()
		box.choose(2)
	world.grimoire_ui.open()
	assert_bool(world.grimoire_ui.is_open()).is_true()
	world.grimoire_ui.close()


## Regressão (Sprint 12, captura de tela): o mago ao lado da serpente cobria o "E: falar".
func test_NAR_005_aviso_fica_acima_do_mago() -> void:
	await _stand_at_column(10.5)
	var serpent := world.serpent_in_reach()
	var prompt := serpent.prompt_rect()
	var player_top := world.player.global_position.y - PLAYER_HEIGHT
	assert_float(prompt.end.y).override_failure_message("aviso termina em %s, mago começa em %s" % [prompt.end.y, player_top]) \
			.is_less_equal(player_top)


## Regressão (Sprint 12, captura de tela): a caixa embaixo cobria o mago e a serpente (o chão
## das salas fica no rodapé da tela) e encostava na linha dos slots.
func test_NAR_005_caixa_no_alto_sem_cobrir_o_hud() -> void:
	await _stand_at_column(9.5)
	world.talk()
	var rect := box.panel_rect()
	var screen := box.get_viewport().get_visible_rect().size
	assert_float(rect.end.y).override_failure_message("caixa termina em %s" % rect.end.y).is_less_equal(screen.y / 2)
	var hud_bottom := world.hud.passive_label.get_global_rect().end.y
	assert_float(rect.position.y).override_failure_message("caixa em %s, HUD até %s" % [rect.position.y, hud_bottom]) \
			.is_greater_equal(hud_bottom)


func test_NAR_006_cena_com_erro_nao_trava() -> void:
	await _stand_at_column(20)
	assert_object(world.serpent_in_reach()).is_not_null()
	world.talk()
	assert_bool(box.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()
	assert_str(" ".join(world.authoring_errors)).contains("nao_existe")
