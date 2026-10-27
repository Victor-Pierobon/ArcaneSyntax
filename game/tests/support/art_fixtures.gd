class_name ArtFixtures
extends RefCounted
## Arte de mentira para os testes da esteira (spec ART-esteira): tiras PNG gravadas numa pasta de
## `user://tests/`, que a ArtLibrary lê no lugar de `res://assets/`.

const ROOT := "user://tests/arte/"


## Tira horizontal de `frames` quadros de `frame`, pintada com `color` (opaca) e um pixel transparente
## no canto de cada quadro.
static func strip(frame: Vector2i, frames: int, color := Color("ff7a3d")) -> Image:
	var image := Image.create_empty(frame.x * frames, frame.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	for i in frames:
		image.set_pixel(i * frame.x, 0, Color(0, 0, 0, 0))
	return image


static func write(folder: String, file_name: String, image: Image) -> void:
	var dir := ROOT.path_join(folder)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	image.save_png(ProjectSettings.globalize_path(dir.path_join(file_name + ".png")))


## Apaga a pasta de teste inteira.
static func clear() -> void:
	_remove(ProjectSettings.globalize_path(ROOT))


static func _remove(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file in dir.get_files():
		dir.remove(file)
	for sub in dir.get_directories():
		_remove(path.path_join(sub))
	DirAccess.remove_absolute(path)
