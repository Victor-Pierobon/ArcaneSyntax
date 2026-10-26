class_name Hud
extends CanvasLayer
## Vida e mana na tela (spec UI-hud). Visual provisório até a arte da interface.

var life_label := Label.new()
var mana_label := Label.new()
var mana_bar := ProgressBar.new()
## Nível e XP (spec PRO-niveis, regra 6).
var level_label := Label.new()
## Os 5 slots e o feitiço de cada um (spec GRI-slots, GRI-034).
var slots_label := Label.new()
## Feitiço passivo e se está ligado (spec MAG-passivo, MAG-057).
var passive_label := Label.new()

var _grimoire: Grimoire


func _init() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(8, 6)
	box.add_theme_constant_override(&"separation", 1)
	add_child(box)
	for label in [life_label, mana_label]:
		label.add_theme_font_size_override(&"font_size", 9)
	level_label.add_theme_font_size_override(&"font_size", 8)
	mana_bar.custom_minimum_size = Vector2(80, 5)
	mana_bar.show_percentage = false
	mana_bar.max_value = 100.0
	box.add_child(life_label)
	box.add_child(mana_label)
	box.add_child(mana_bar)
	box.add_child(level_label)
	# Dica de controles enquanto não há menu nem tutorial.
	var hint := Label.new()
	hint.text = "PROTOTIPO_DICA"
	hint.position = Vector2(8, 344)
	hint.add_theme_font_size_override(&"font_size", 8)
	hint.modulate = Color(1, 1, 1, 0.6)
	add_child(hint)
	slots_label.position = Vector2(8, 330)
	slots_label.add_theme_font_size_override(&"font_size", 8)
	add_child(slots_label)
	# No bloco do topo: perto do chão o texto cobria o mago (regressão MAG-057).
	passive_label.add_theme_font_size_override(&"font_size", 8)
	passive_label.text = "HUD_PASSIVO_VAZIO"
	box.add_child(passive_label)


func bind(state: MagoState) -> void:
	state.health.changed.connect(_on_life_changed)
	state.mana_changed.connect(_on_mana_changed)
	state.xp_changed.connect(_on_xp_changed)
	_on_life_changed(state.health.current, state.health.maximum)
	_on_mana_changed(state.mana, state.mana_max)
	_on_xp_changed(state.xp, state.level)


func bind_slots(grimoire: Grimoire) -> void:
	_grimoire = grimoire
	grimoire.slots_changed.connect(_on_slots_changed)
	_on_slots_changed()


func set_passive_status(spell_name: String, disabled: bool) -> void:
	if spell_name.is_empty():
		passive_label.text = tr("HUD_PASSIVO_VAZIO")
	elif disabled:
		passive_label.text = tr("HUD_PASSIVO_DESLIGADO") % spell_name
	else:
		passive_label.text = tr("HUD_PASSIVO") % spell_name


func _on_slots_changed() -> void:
	var parts := PackedStringArray()
	var slots := _grimoire.slots()
	for i in slots.size():
		parts.append("%d %s" % [i + 1, slots[i] if slots[i] != "" else "—"])
	slots_label.text = "   ".join(parts)


func _on_life_changed(current: int, maximum: int) -> void:
	life_label.text = tr("HUD_VIDA") % [current, maximum]


func _on_xp_changed(xp: int, level: int) -> void:
	var next := Progression.next_threshold(level)
	if next < 0:
		level_label.text = tr("HUD_NIVEL_MAXIMO") % [level, xp]
	else:
		level_label.text = tr("HUD_NIVEL") % [level, xp, next]


func _on_mana_changed(mana: float, mana_max: float) -> void:
	mana_label.text = tr("HUD_MANA") % [mana, mana_max]
	mana_bar.value = 0.0 if mana_max <= 0.0 else mana / mana_max * 100.0
