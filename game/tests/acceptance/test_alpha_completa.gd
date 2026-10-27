extends GdUnitTestSuite
## Aceitação: docs/specs/mundo/MUN-mapa.md (MUN-085). A Alpha inteira, do menu ao fim, com a cena
## principal, as salas do jogo e o Python de verdade. Dentro de cada sala o mago vai direto ao lugar de
## conjurar (como nos outros testes de aceitação); entre as salas ele sai andando pela saída, então a
## porta precisa estar aberta.

const MAIN := "res://src/nodes/main/main.tscn"
const ROOT := "user://tests/perfis_alpha"
const PROFILE := ROOT + "/padrao"

const CRISTAL := """vence = {"planta": fogo, "fogo": gelo, "gelo": raio}
lancar(vence[alvo.elemento], projetil, alvo)"""
const CHEFE := """vence = {"fogo": gelo, "gelo": raio, "planta": fogo}
lancar(vence[alvo.elemento], projetil, alvo)"""
const SOMA_RUNAS := "inscrever(ler_runa(1) + ler_runa(2) + ler_runa(3))"

var main: Main
var driver: PuzzleDriver
## Salas por onde o mago passou, na ordem.
var visited: Array[String] = []


func before_test() -> void:
	_cleanup()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PROFILE))
	main = auto_free(load(MAIN).instantiate())
	main.profile_root = ROOT
	main.legacy_grimoire = ROOT + "/nao_existe.json"
	add_child(main)
	await get_tree().physics_frame
	main.new_game()
	driver = auto_free(PuzzleDriver.new())
	driver.world = main.world
	add_child(driver)
	driver.stand_still()
	main.world.room_changed.connect(func(room_id: String) -> void: visited.append(room_id))
	# O que se testa é o caminho, não a esquiva: vida de sobra contra os inimigos.
	main.world.state.health.maximum = 99
	main.world.state.health.restore_full()
	await driver.frames(3)


func after_test() -> void:
	get_tree().paused = false
	_cleanup()


func _cleanup() -> void:
	for file_name in ["grimorio.json", "save.json", "opcoes.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			var path: String = PROFILE.path_join(file_name) + suffix
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for dir in [PROFILE, ROOT]:
		if DirAccess.dir_exists_absolute(dir):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))


func _room() -> String:
	return main.world.current_room.room_id


## Ouve a serpente do dígito até o fim, escolhendo sempre a primeira opção.
func _listen(digit: String) -> void:
	await driver.place(driver.cell_of(digit))
	main.world.talk()
	assert_bool(main.world.dialogue_box.is_open()).override_failure_message("serpente em %s" % _room()).is_true()
	while main.world.dialogue_box.is_open():
		main.world.dialogue_box.choose(1)
		main.world.dialogue_box.advance()
	await driver.frames(2)


## Sai andando pela saída `letter` (de 3 tiles antes dela) e devolve a sala nova.
func _leave(letter: String) -> String:
	var from := _room()
	var cells: Array = driver.room().data.exits[letter]
	var cell: Vector2i = cells[0]
	for candidate: Vector2i in cells:
		if candidate.y > cell.y:
			cell = candidate
	var direction := -1 if cell.x == 0 else 1
	await driver.place(cell - Vector2i(3 * direction, 0))
	main.world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make(direction)
	for i in 120:
		await get_tree().physics_frame
		if _room() != from:
			break
	driver.stand_still()
	await driver.frames(3)
	assert_str(_room()).override_failure_message("não saiu de %s pela saída %s" % [from, letter]).is_not_equal(from)
	return _room()


func _assert_solved(puzzle: String) -> void:
	assert_bool(main.world.is_puzzle_solved(puzzle)).override_failure_message("%s não resolvido" % puzzle).is_true()


func test_MUN_085_a_alpha_inteira() -> void:
	# sala_01: apresentação e sequência; P1.
	await _listen("4")
	await driver.place(Vector2i(46, 20))
	await driver.cast("meditar()\nlancar(fogo, projetil, alvo)")
	_assert_solved("p01_meditar")
	assert_str(await _leave("b")).is_equal("sala_02")
	# Corredores, com os dois baús.
	await driver.place(Vector2i(13, 20))
	await driver.cast("levitar(11)\nmover(-4)", true, 90)
	assert_str(await _leave("c")).is_equal("sala_03")
	await driver.place(Vector2i(22, 20))
	await driver.cast("levitar(13)\nmover(-3)", true, 90)
	assert_dict(main.world.found_secrets).is_equal({"sala_02_8": true, "sala_03_8": true})
	assert_str(await _leave("b")).is_equal("sala_p02")
	# P2: variáveis.
	await _listen("9")
	await driver.place(driver.cell_of("7") - Vector2i(2, 0))
	await driver.cast("a = ler_runa(1)\nb = ler_runa(2)\nc = ler_runa(3)\ninscrever(a + b + c)")
	_assert_solved("p02_runas")
	assert_str(await _leave("b")).is_equal("sala_p03")
	# P3: condicionais (um acerto por conjuração).
	await _listen("9")
	await driver.place(driver.cell_of("5") - Vector2i(6, 0))
	for i in 3:
		await driver.cast(CRISTAL)
	_assert_solved("p03_simbolo")
	assert_str(await _leave("b")).is_equal("sala_p04")
	# P4: loops.
	await _listen("9")
	await driver.place(Vector2i(6, 5))
	await driver.cast("for i in range(12):\n    construir_bloco()")
	_assert_solved("p04_ponte")
	assert_str(await _leave("b")).is_equal("sala_p05")
	# P5: funções.
	await _listen("9")
	await driver.place(main.world.current_room.data.entries["A"])
	await driver.walk_until_x(7 * 16.0)
	await driver.cast("def subir(altura):\n    meditar()\n    levitar(altura)\n    mover(2)\n\nsubir(5)\nsubir(7)\nsubir(6)", true, 60)
	_assert_solved("p05_elevador")
	assert_str(await _leave("b")).is_equal("sala_p06")
	# P6: revisão.
	await _listen("9")
	await driver.place(Vector2i(10, 13))
	await driver.cast(SOMA_RUNAS)
	await driver.place(Vector2i(14, 13))
	await driver.cast("for i in range(8):\n    construir_bloco()")
	await driver.walk_until_x(26 * 16.0 + 8)
	for i in 2:
		await driver.cast(CRISTAL)
	await driver.walk_until_x(35 * 16.0)
	await driver.cast("def subir(h):\n    levitar(h)\n    mover(2)\n\nsubir(5)\nsubir(6)", true, 60)
	_assert_solved("p06_revisao")
	assert_str(await _leave("b")).is_equal("sala_c01")
	# Atalho: sobe para a sala_01, abre a porta por trás e volta.
	assert_str(await _leave("c")).is_equal("sala_01")
	assert_bool(main.world.current_room.shortcut_open()).is_true()
	assert_str(await _leave("d")).is_equal("sala_c01")
	assert_str(await _leave("b")).is_equal("sala_c02")
	assert_str(await _leave("b")).is_equal("sala_c03")
	# A fonte antes do chefe.
	main.world.state.set_mana(0.0)
	await driver.place(driver.cell_of("2"))
	main.world.talk()
	assert_float(main.world.state.mana).is_equal(main.world.state.mana_max)
	assert_str(await _leave("b")).is_equal("sala_c04")
	# O chefe, com o mesmo feitiço do dicionário.
	var boss := driver.room().enemies()[0] as Boss
	var defeated := [false]
	boss.defeated.connect(func() -> void: defeated[0] = true)
	for i in 20:
		if defeated[0]:
			break
		# Em cima da plataforma alta: nada acima do mago para parar o projétil.
		await driver.place(Vector2i(12, 16))
		await driver.cast(CHEFE, true, 150)
		while is_instance_valid(boss) and not boss.is_defeated() and boss.phases.in_transition():
			await driver.frames(1)
	assert_bool(defeated[0]).override_failure_message("o chefe não caiu").is_true()
	assert_str(await _leave("b")).is_equal("sala_fim")
	# A despedida e o resumo.
	await _listen("9")
	assert_bool(main.end_screen.is_showing()).is_true()
	var text := main.end_screen.summary_text()
	assert_str(text).contains(tr("FIM_PUZZLES") % [6, 6])
	assert_str(text).contains(tr("FIM_LICOES") % [6, 6])
	assert_str(text).contains(tr("FIM_SEGREDOS") % [2, 2])
	assert_array(visited).contains(["sala_01", "sala_02", "sala_03", "sala_p02", "sala_p03", "sala_p04", "sala_p05",
			"sala_p06", "sala_c01", "sala_c02", "sala_c03", "sala_c04", "sala_fim"])
	main.end_screen.confirm()
	await driver.frames(2)
	assert_bool(main.title_menu.is_showing()).is_true()
	assert_bool(main.title_menu.continue_button.visible).is_true()
