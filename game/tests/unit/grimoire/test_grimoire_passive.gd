extends GdUnitTestSuite
## Spec: docs/specs/magia/MAG-passivo.md (MAG-050), parte do modelo.

const P := Grimoire.Problem
const PATH := "user://tests/grimorio_passivo.json"

var grimoire: Grimoire


func before_test() -> void:
	grimoire = Grimoire.new()
	grimoire.create("Recarregar", "while mana < mana_max:\n    absorver_mana()")


func after_test() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func test_MAG_050_equipar_renomear_apagar() -> void:
	var changes := [0]
	grimoire.passive_changed.connect(func() -> void: changes[0] += 1)
	assert_str(grimoire.passive()).is_empty()
	assert_int(grimoire.set_passive("Nada")).is_equal(P.NOT_FOUND)
	assert_int(grimoire.set_passive("Recarregar")).is_equal(P.OK)
	grimoire.rename("Recarregar", "Recarga")
	assert_str(grimoire.passive()).is_equal("Recarga")
	grimoire.delete("Recarga")
	assert_str(grimoire.passive()).is_empty()
	assert_int(changes[0]).is_equal(3)


func test_MAG_050_salvar_e_carregar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	grimoire.set_passive("Recarregar")
	GrimoireStore.new(PATH).save(grimoire)
	assert_str(GrimoireStore.new(PATH).load_grimoire().passive()).is_equal("Recarregar")


func test_MAG_050_arquivo_sem_passivo_e_nome_que_sumiu() -> void:
	var old := Grimoire.from_dict({"versao": 1, "feiticos": [{"nome": "A", "codigo": ""}]})
	assert_str(old.passive()).is_empty()
	var stale := Grimoire.from_dict({"versao": 1, "feiticos": [{"nome": "A", "codigo": ""}], "passivo": "Sumiu"})
	assert_str(stale.passive()).is_empty()
	assert_object(Grimoire.from_dict({"versao": 1, "feiticos": [], "passivo": 3})).is_null()


func test_MAG_050_desequipar() -> void:
	grimoire.set_passive("Recarregar")
	grimoire.clear_passive()
	assert_str(grimoire.passive()).is_empty()
