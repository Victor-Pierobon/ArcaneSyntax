extends GdUnitTestSuite
## Spec: docs/specs/grimorio/GRI-feiticos.md (GRI-020 a 024)
## Usa arquivos próprios em user://tests/ para nunca tocar no grimório real do jogador.

const PATH := "user://tests/grimorio_store.json"

var store: GrimoireStore


func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	_cleanup()
	store = GrimoireStore.new(PATH)


func after_test() -> void:
	_cleanup()


func _cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func _write_raw(text: String) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_GRI_020_salvar_e_carregar_preserva_tudo() -> void:
	var grimoire := Grimoire.new()
	grimoire.create("Bola de fogo", "lancar(fogo, projetil, alvo)")
	grimoire.create("Ação \"rápida\"", "while mana < mana_max:\n    absorver_mana()\n# visão ✨")
	assert_int(store.save(grimoire)).is_equal(OK)
	var loaded := GrimoireStore.new(PATH).load_grimoire()
	assert_array(Array(loaded.names())).is_equal(["Bola de fogo", "Ação \"rápida\""])
	assert_str(loaded.code_of("Ação \"rápida\"")).is_equal("while mana < mana_max:\n    absorver_mana()\n# visão ✨")


func test_GRI_021_arquivo_inexistente() -> void:
	var loaded := store.load_grimoire()
	assert_array(Array(loaded.names())).is_empty()
	assert_str(store.last_problem).is_empty()


func _assert_corrupted_is_preserved(raw: String) -> void:
	_write_raw(raw)
	var loaded := store.load_grimoire()
	assert_array(Array(loaded.names())).is_empty()
	assert_str(store.last_problem).is_not_empty()
	assert_bool(FileAccess.file_exists(PATH + ".bak")).is_true()
	assert_str(FileAccess.get_file_as_string(PATH + ".bak")).is_equal(raw)


func test_GRI_022_arquivo_que_nao_e_json() -> void:
	_assert_corrupted_is_preserved("isto não é json {")


func test_GRI_022_json_sem_feiticos() -> void:
	_assert_corrupted_is_preserved('{"versao": 1}')


func test_GRI_022_nomes_repetidos_no_arquivo() -> void:
	_assert_corrupted_is_preserved('{"versao": 1, "feiticos": [{"nome": "A", "codigo": ""}, {"nome": "a", "codigo": ""}]}')


func test_GRI_022_backup_sobrevive_ao_salvamento_seguinte() -> void:
	_write_raw("lixo")
	var loaded := store.load_grimoire()
	loaded.create("Novo")
	store.save(loaded)
	assert_str(FileAccess.get_file_as_string(PATH + ".bak")).is_equal("lixo")
	assert_array(Array(GrimoireStore.new(PATH).load_grimoire().names())).is_equal(["Novo"])


func test_GRI_023_versao_mais_nova() -> void:
	_assert_corrupted_is_preserved('{"versao": 2, "feiticos": []}')


func test_GRI_024_gravacao_atomica() -> void:
	var grimoire := Grimoire.new()
	grimoire.create("Primeiro")
	store.save(grimoire)
	grimoire.create("Segundo")
	assert_int(store.save(grimoire)).is_equal(OK)
	assert_bool(FileAccess.file_exists(PATH + ".tmp")).is_false()
	assert_array(Array(GrimoireStore.new(PATH).load_grimoire().names())).is_equal(["Primeiro", "Segundo"])
