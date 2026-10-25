extends GdUnitTestSuite
## Spec: docs/specs/grimorio/GRI-slots.md (GRI-030 a 032)

const P := Grimoire.Problem
const PATH := "user://tests/grimorio_slots.json"

var grimoire: Grimoire


func before_test() -> void:
	grimoire = Grimoire.new()
	grimoire.create("Fogo", "lancar(fogo, projetil)")
	grimoire.create("Gelo", "lancar(gelo, projetil)")


func after_test() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var file := ProjectSettings.globalize_path(PATH + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func test_GRI_030_equipar_e_esvaziar() -> void:
	assert_int(grimoire.equip(1, "Fogo")).is_equal(P.OK)
	assert_int(grimoire.equip(3, "Fogo")).is_equal(P.OK)
	grimoire.unequip(3)
	assert_array(grimoire.slots()).is_equal(["Fogo", "", "", "", ""])
	assert_str(grimoire.slot(1)).is_equal("Fogo")
	assert_int(grimoire.equip(2, "Nada")).is_equal(P.NOT_FOUND)
	assert_int(grimoire.equip(0, "Fogo")).is_equal(P.INVALID_SLOT)
	assert_int(grimoire.equip(6, "Fogo")).is_equal(P.INVALID_SLOT)


func test_GRI_031_renomear_e_apagar_mexem_nos_slots() -> void:
	grimoire.equip(1, "Fogo")
	grimoire.equip(2, "Gelo")
	var changes := [0]
	grimoire.slots_changed.connect(func() -> void: changes[0] += 1)
	grimoire.rename("Fogo", "Chama")
	grimoire.delete("Gelo")
	assert_array(grimoire.slots()).is_equal(["Chama", "", "", "", ""])
	assert_int(changes[0]).is_equal(2)


func test_GRI_032_slots_salvos() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	grimoire.equip(2, "Gelo")
	grimoire.equip(5, "Fogo")
	GrimoireStore.new(PATH).save(grimoire)
	assert_array(GrimoireStore.new(PATH).load_grimoire().slots()).is_equal(["", "Gelo", "", "", "Fogo"])


func test_GRI_032_arquivo_sem_slots_e_nomes_que_sumiram() -> void:
	var old := Grimoire.from_dict({"versao": 1, "feiticos": [{"nome": "A", "codigo": ""}]})
	assert_array(old.slots()).is_equal(["", "", "", "", ""])
	var stale := Grimoire.from_dict({"versao": 1, "feiticos": [{"nome": "A", "codigo": ""}], "slots": ["A", "Sumiu", "", "", ""]})
	assert_array(stale.slots()).is_equal(["A", "", "", "", ""])


func test_GRI_032_slots_com_formato_errado() -> void:
	assert_object(Grimoire.from_dict({"versao": 1, "feiticos": [], "slots": ["", ""]})).is_null()
	assert_object(Grimoire.from_dict({"versao": 1, "feiticos": [], "slots": [1, 2, 3, 4, 5]})).is_null()
