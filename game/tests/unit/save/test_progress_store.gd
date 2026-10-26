extends GdUnitTestSuite
## Spec: docs/specs/save/SAV-progresso.md (regras 4 e 6, SAV-003, SAV-004): o arquivo do save.

const PATH := "user://tests/save_store.json"


func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	_cleanup()


func after_test() -> void:
	_cleanup()


func _cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))


func _write(text: String) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_SAV_001_ida_e_volta_do_arquivo() -> void:
	var store := ProgressStore.new(PATH)
	assert_bool(store.save({"sala": "sala_p03", "mago": {"xp": 85}})).is_true()
	assert_bool(FileAccess.file_exists(PATH + ".tmp")).is_false()
	var data := ProgressStore.new(PATH).load_data()
	assert_int(int(data["versao"])).is_equal(ProgressStore.VERSION)
	assert_str(data["sala"]).is_equal("sala_p03")
	assert_int(int(data["mago"]["xp"])).is_equal(85)


func test_SAV_001_sem_arquivo_e_jogo_novo() -> void:
	var store := ProgressStore.new(PATH)
	assert_dict(store.load_data()).is_empty()
	assert_str(store.last_problem).is_empty()


func test_SAV_003_save_ilegivel() -> void:
	_write("{ isto não é json")
	var store := ProgressStore.new(PATH)
	assert_dict(store.load_data()).is_empty()
	assert_str(store.last_problem).is_not_empty()
	assert_str(FileAccess.get_file_as_string(PATH + ".bak")).is_equal("{ isto não é json")


func test_SAV_003_save_que_nao_e_objeto_ou_sem_versao() -> void:
	for text in ["[1, 2]", "{\"sala\": \"sala_01\"}"]:
		_write(text)
		var store := ProgressStore.new(PATH)
		assert_dict(store.load_data()).override_failure_message(text).is_empty()
		assert_str(store.last_problem).override_failure_message(text).is_not_empty()


func test_SAV_004_versao_nova_demais() -> void:
	_write("{\"versao\": 99, \"sala\": \"sala_01\"}")
	var store := ProgressStore.new(PATH)
	assert_dict(store.load_data()).is_empty()
	assert_str(store.last_problem).contains("99")
	assert_bool(FileAccess.file_exists(PATH + ".bak")).is_true()
