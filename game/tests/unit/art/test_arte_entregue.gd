extends GdUnitTestSuite
## Spec: docs/specs/arte/ART-esteira.md (ART-004): toda arte em game/assets/ segue o contrato.
## Sem arte entregue, o teste passa vazio; a lista de problemas sai na mensagem.

const ASSETS := "res://assets/"
const PALETTE := "res://assets/paleta.png"


func test_ART_004_toda_arte_entregue_segue_o_contrato() -> void:
	var catalog := ArtCatalog.load_file(ArtCatalog.DEFAULT_PATH)
	var palette := {}
	if FileAccess.file_exists(PALETTE):
		palette = ArtCatalog.palette_of(Image.load_from_file(ProjectSettings.globalize_path(PALETTE)))
	var problems: Array[String] = []
	for folder in DirAccess.get_directories_at(ASSETS):
		if folder == "placeholder":
			continue
		for file in DirAccess.get_files_at(ASSETS.path_join(folder)):
			if file.get_extension() != "png":
				continue
			var image := Image.load_from_file(ProjectSettings.globalize_path(ASSETS.path_join(folder).path_join(file)))
			problems.append_array(catalog.check(folder, file.get_basename(), image, palette))
	assert_array(problems).override_failure_message("\n".join(problems)).is_empty()
