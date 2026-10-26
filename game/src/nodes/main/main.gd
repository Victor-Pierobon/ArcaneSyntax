class_name Main
extends Node
## Cena principal do jogo (spec SAV-progresso, regras 1, 2 e 5): escolhe a pasta do perfil, traz o
## grimório de antes da Sprint 13 e sobe o World com o save ligado. Os testes sobem o World direto,
## sem save.

const WORLD := preload("res://src/nodes/world/world.tscn")

@export var profile_root := "user://perfis"
## Um perfil só na Alpha.
@export var profile := "padrao"
## Onde o grimório ficava antes dos perfis.
@export var legacy_grimoire := GrimoireStore.DEFAULT_PATH

var world: World


func _ready() -> void:
	var folder := profile_root.path_join(profile)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var grimoire_path := folder.path_join("grimorio.json")
	if FileAccess.file_exists(legacy_grimoire) and not FileAccess.file_exists(grimoire_path):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(legacy_grimoire), ProjectSettings.globalize_path(grimoire_path))
	world = WORLD.instantiate()
	world.grimoire_path = grimoire_path
	world.save_path = folder.path_join("save.json")
	add_child(world)
