class_name ContractFixtures
extends RefCounted
## Lê as fixtures compartilhadas em tests/contract/ (na raiz do repositório, fora de res://).


static func directory() -> String:
	return ProjectSettings.globalize_path("res://").path_join("../tests/contract").simplify_path()


static func load_all() -> Dictionary:
	var fixtures := {}
	for file_name in DirAccess.get_files_at(directory()):
		if file_name.get_extension() == "json":
			var text := FileAccess.get_file_as_string(directory().path_join(file_name))
			fixtures[file_name.get_basename()] = JSON.parse_string(text)
	return fixtures


## Passa um valor pelo JSON do Godot, que lê todo número como float, para comparar com as fixtures.
static func normalize(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))
