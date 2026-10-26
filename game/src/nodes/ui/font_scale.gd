class_name FontScale
extends RefCounted
## Soma pontos à fonte de todos os controles de um nó (spec UI-menus, regra 5). O tamanho original
## fica guardado no próprio controle, então dá para trocar de tamanho quantas vezes quiser.

const FONT_KEYS: Array[StringName] = [&"font_size", &"normal_font_size", &"bold_font_size", &"mono_font_size"]


static func apply(root: Node, delta: int) -> void:
	if root is Control:
		for key in FONT_KEYS:
			var control := root as Control
			if not control.has_theme_font_size_override(key):
				continue
			var meta := StringName("base_" + key)
			if not control.has_meta(meta):
				control.set_meta(meta, control.get_theme_font_size(key))
			control.add_theme_font_size_override(key, int(control.get_meta(meta)) + delta)
	for child in root.get_children():
		apply(child, delta)
