extends GdUnitTestSuite
## Spec: docs/specs/narrativa/NAR-serpente.md (regra 3, NAR-021 a NAR-023) e NAR-dicas.md (regra 4, NAR-042).
## sala_licao: entrada na coluna 2, serpente (ensino_sequencia) na 3, cristal do P1 na 5. O mago fica ao alcance.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_licoes.json"
const PUZZLE := "p01_meditar"
const LESSON := "ensino_sequencia"

var world: World
var box: DialogueBox


func before_test() -> void:
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = "sala_licao"
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


## Conversa inteira escolhendo sempre a opção `option` quando houver.
func _talk_choosing(option: int) -> void:
	world.talk()
	assert_bool(box.is_open()).override_failure_message("a caixa não abriu").is_true()
	var guard := 0
	while box.is_open() and guard < 50:
		box.choose(option)
		box.advance()
		guard += 1


func test_NAR_021_primeira_conversa_e_a_licao() -> void:
	assert_object(world.serpent_in_reach()).is_not_null()
	world.talk()
	assert_str(box.text_label.text).is_equal(tr("SERPENTE_OLA_1"))
	while box.is_open():
		box.choose(1)
		box.advance()
	assert_bool(world.seen_lessons.has(LESSON)).is_true()


func test_NAR_021_recusar_antes_da_licao_nao_conta() -> void:
	_talk_choosing(2)
	assert_bool(world.seen_lessons.has(LESSON)).is_false()
	world.talk()
	assert_str(box.text_label.text).is_equal(tr("SERPENTE_OLA_1"))


func test_NAR_022_depois_da_licao_a_dica() -> void:
	world.seen_lessons[LESSON] = true
	world.talk()
	assert_str(box.text_label.text).is_equal(tr("SERPENTE_DICA_PERGUNTA_1"))


func test_NAR_023_puzzle_resolvido_repete_a_licao() -> void:
	world.seen_lessons[LESSON] = true
	(world.find_target("sala_licao_alvo_5") as Crystal).light()
	await _frames(2)
	assert_bool(world.is_puzzle_solved(PUZZLE)).is_true()
	world.talk()
	assert_str(box.text_label.text).is_equal(tr("SERPENTE_OLA_1"))


func test_NAR_042_niveis_avancam_so_quando_a_dica_aparece() -> void:
	world.seen_lessons[LESSON] = true
	var hints := world.hints.hints(PUZZLE)
	_talk_choosing(2)
	assert_int(world.hints_used.get(PUZZLE, 0)).is_equal(0)
	for level in [1, 2, 3, 3]:
		world.talk()
		assert_str(box.text_label.text).override_failure_message("nível %d" % level) \
				.is_equal(tr("SERPENTE_DICA_PERGUNTA_%d" % level))
		box.choose(1)
		assert_str(box.text_label.text).is_equal(tr(hints[level - 1]))
		box.advance()
		assert_bool(box.is_open()).is_false()
		assert_int(world.hints_used[PUZZLE]).is_equal(level)
