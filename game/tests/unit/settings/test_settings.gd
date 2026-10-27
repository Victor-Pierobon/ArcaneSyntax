extends GdUnitTestSuite
## Spec: docs/specs/ui/UI-menus.md (regra 5, UI-015): as opções do jogador.

const PATH := "user://tests/opcoes_teste.json"


func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	_cleanup()


func after_test() -> void:
	_cleanup()


func _cleanup() -> void:
	for suffix in ["", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))


func _write(text: String) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_UI_015_padrao() -> void:
	var settings := Settings.load_file(PATH)
	assert_int(settings.text_size).is_equal(Settings.TextSize.NORMAL)
	assert_int(settings.text_delta()).is_equal(0)
	assert_int(settings.volume).is_equal(80)


func test_UI_015_grava_e_le_de_novo() -> void:
	var settings := Settings.load_file(PATH)
	settings.set_text_size(Settings.TextSize.HUGE)
	settings.set_volume(30)
	assert_bool(settings.save()).is_true()
	var again := Settings.load_file(PATH)
	assert_int(again.text_size).is_equal(Settings.TextSize.HUGE)
	assert_int(again.text_delta()).is_equal(3)
	assert_int(again.volume).is_equal(30)


func test_UI_015_tamanhos_somam_pontos() -> void:
	var settings := Settings.new()
	var deltas: Array[int] = []
	for size in [Settings.TextSize.NORMAL, Settings.TextSize.LARGE, Settings.TextSize.HUGE]:
		settings.set_text_size(size)
		deltas.append(settings.text_delta())
	assert_array(deltas).is_equal([0, 2, 3])


func test_UI_015_proximo_tamanho_da_a_volta() -> void:
	var settings := Settings.new()
	var seen: Array[int] = []
	for i in 3:
		settings.next_text_size()
		seen.append(settings.text_size)
	assert_array(seen).is_equal([Settings.TextSize.LARGE, Settings.TextSize.HUGE, Settings.TextSize.NORMAL])


func test_UI_015_volume_fica_na_faixa_de_10_em_10() -> void:
	var settings := Settings.new()
	settings.set_volume(130)
	assert_int(settings.volume).is_equal(100)
	settings.set_volume(-5)
	assert_int(settings.volume).is_equal(0)
	settings.set_volume(44)
	assert_int(settings.volume).is_equal(40)


func test_UI_015_arquivo_ilegivel_usa_o_padrao() -> void:
	_write("isto não é json")
	var settings := Settings.load_file(PATH)
	assert_int(settings.text_size).is_equal(Settings.TextSize.NORMAL)
	assert_int(settings.volume).is_equal(80)


func test_UI_015_valores_ruins_usam_o_padrao() -> void:
	_write("{\"tamanho_texto\": \"gigante\", \"volume\": \"alto\"}")
	var settings := Settings.load_file(PATH)
	assert_int(settings.text_size).is_equal(Settings.TextSize.NORMAL)
	assert_int(settings.volume).is_equal(80)
	_write("{\"tamanho_texto\": \"grande\", \"volume\": 250}")
	settings = Settings.load_file(PATH)
	assert_int(settings.text_size).is_equal(Settings.TextSize.LARGE)
	assert_int(settings.volume).is_equal(100)


func test_ART_064_tremer_a_tela_ligado_por_padrao_e_gravado() -> void:
	var settings := Settings.load_file(PATH)
	assert_bool(settings.screen_shake).is_true()
	settings.screen_shake = false
	assert_bool(settings.save()).is_true()
	assert_bool(Settings.load_file(PATH).screen_shake).is_false()
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	assert_bool(saved["tremer_tela"]).is_false()
