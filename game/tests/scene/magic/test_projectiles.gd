extends GdUnitTestSuite
## Spec: docs/specs/magia/MAG-formas.md (regras 2, 3 e 9; MAG-015 a MAG-017).
## sala_tiro: chão com topo em y = 64, mago na coluna 2, bonecos de fogo na coluna 5 e de gelo na coluna 9.
## sala_alvos: bonecos de fogo na coluna 5 e de gelo na coluna 8.

const WORLD := "res://src/nodes/world/world.tscn"
const GRIMOIRE_PATH := "user://tests/grimorio_projeteis.json"

var world: World


func _start(room_id: String) -> void:
	world = auto_free(load(WORLD).instantiate())
	world.rooms_dir = "res://tests/fixtures/rooms/"
	world.start_room = room_id
	world.grimoire_path = GRIMOIRE_PATH
	add_child(world)
	world.player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	await _frames(3)


func after_test() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(GRIMOIRE_PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _launch(element: String, form: String, target_id: Variant) -> void:
	world.world_actions.act_lancar({"tipo": "lancar", "elemento": element, "forma": form, "alvo": target_id, "linha": 1})


func test_MAG_015_faisca() -> void:
	await _start("sala_tiro")
	var far := world.find_target("sala_tiro_alvo_2")
	_launch("raio", "projetil", far.target_id)
	_launch("gelo", "faisca", far.target_id)
	for i in 120:
		await _frames(1)
		if far.hits > 0:
			break
	assert_int(far.hits).is_equal(1)
	assert_str(far.last_hit_element).is_equal("gelo")
	assert_str(far.last_form).is_equal("faisca")


func test_MAG_015_faisca_e_mais_rapida() -> void:
	assert_float(Projectile.speed_of("faisca")).is_equal(300.0)
	assert_float(Projectile.speed_of("projetil")).is_equal(220.0)


func test_MAG_016_o_projetil_persegue_o_alvo() -> void:
	await _start("sala_alvos")
	var target := world.find_target("sala_alvos_alvo_2")
	_launch("fogo", "projetil", target.target_id)
	await _frames(2)
	target.position.y -= 32
	for i in 90:
		await _frames(1)
		if target.hits > 0:
			break
	assert_int(target.hits).is_equal(1)


func test_MAG_017_so_acerta_o_alvo_escolhido() -> void:
	await _start("sala_tiro")
	var near := world.find_target("sala_tiro_alvo_1")
	var far := world.find_target("sala_tiro_alvo_2")
	_launch("raio", "projetil", far.target_id)
	await _frames(60)
	assert_int(near.hits).is_equal(0)
	assert_int(far.hits).is_equal(1)


func test_MAG_017_sem_alvo_acerta_o_primeiro() -> void:
	await _start("sala_tiro")
	var near := world.find_target("sala_tiro_alvo_1")
	var far := world.find_target("sala_tiro_alvo_2")
	world.player.motor.facing = 1
	_launch("raio", "projetil", null)
	await _frames(60)
	assert_int(near.hits).is_equal(1)
	assert_int(far.hits).is_equal(0)
