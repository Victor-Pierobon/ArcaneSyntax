class_name Enemy
extends TrainingTarget
## Inimigo (spec COM-dano): tem vida, sofre dano pelo elemento e pela forma do golpe, e machuca
## o mago por contato. Cada tipo (Elemental, SwarmBug, Guardian) decide como se mexe em `_think`.

signal defeated
## Encostou no mago neste quadro; a Room repassa para o World, que aplica o dano.
signal touched_player(enemy: Enemy)

const ENEMY_GROUP := &"inimigos"
## Depois de derrotado, o texto do último golpe fica um instante antes de sumir.
const DEFEAT_LINGER := 0.4
const BAR_HEIGHT := 2.0

var health: Health
var contact_damage := Balance.integer("dano", "contato")
## XP que o mago ganha ao derrotá-lo (spec PRO-xp).
var xp := 0
var last_damage := 0
var last_blocked := false
## O mago, para quem reage a ele; null quando não há mundo (testes de sala).
var player: Node2D
## Alvo a qualquer distância, fora do alcance de 12 tiles (o chefe na arena; COM-chefe, regra 6).
var any_distance := false

var _contact := Area2D.new()
var _bar_back := ColorRect.new()
var _bar := ColorRect.new()


## `kind`: o tipo no balanceamento (`elemental`, `enxame`, `guardiao`, `chefe`), que dá a vida
## (na seção do tipo) e a XP (seção `xp`).
func setup(p_target_id: String, p_element: String, kind: String, size: Vector2) -> void:
	target_id = p_target_id
	element = p_element
	name = p_target_id
	body_size = size
	health = Health.new(Balance.integer(kind, "vida"))
	health.invulnerable_time = 0.0
	xp = Balance.integer("xp", kind)


func _ready() -> void:
	super._ready()
	add_to_group(ENEMY_GROUP)
	_contact.name = "Contact"
	_contact.collision_layer = 0
	_contact.collision_mask = 1
	_contact.monitorable = false
	_contact.monitoring = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = body_size
	shape.shape = rect
	shape.position = Vector2(0, -body_size.y / 2)
	_contact.add_child(shape)
	add_child(_contact)
	for bar: ColorRect in [_bar_back, _bar]:
		bar.size = Vector2(body_size.x, BAR_HEIGHT)
		bar.position = Vector2(-body_size.x / 2, -top_height() - 4)
		add_child(bar)
	_bar_back.color = Color(0, 0, 0, 0.6)
	_bar.color = Color("e05050")
	# Nome e texto do golpe acima da barra, sem encostar nela (regressão: a barra cobria o nome).
	name_label.position.y = -top_height() - 4 - 1 - name_label.get_minimum_size().y
	effect_label.position.y = name_label.position.y - 12
	_activate_contact()


## Como as áreas da sala, o contato só liga depois do primeiro quadro (MUN-salas, regra 7).
func _activate_contact() -> void:
	await get_tree().physics_frame
	if is_inside_tree() and not is_defeated():
		_contact.set_deferred(&"monitoring", true)


func _physics_process(delta: float) -> void:
	if is_defeated():
		return
	var x_before := position.x
	_think(delta)
	# A arte olha para a direita; o inimigo vira para onde anda (ART-esteira, regra 3).
	if art_sprite and absf(position.x - x_before) > 0.01:
		art_sprite.flip_h = position.x < x_before
	if not _contact.monitoring:
		return
	for body in _contact.get_overlapping_bodies():
		if body is Player:
			_on_touched_player()
			touched_player.emit(self)
			return


## A animação de morte na pasta da arte (`morrer_<elemento>` no elemental); vazio: some na hora.
func _death_animation() -> String:
	for anim in _art().slice(1):
		if str(anim).begins_with("morrer"):
			return anim
	return ""


## Movimento do quadro; cada tipo de inimigo implementa.
func _think(_delta: float) -> void:
	pass


func _on_touched_player() -> void:
	pass


## Pés do mago em coordenadas da sala, ou null sem mago.
func _player_feet() -> Variant:
	if player == null or not is_instance_valid(player) or get_parent() == null:
		return null
	return (get_parent() as Node2D).to_local(player.global_position)


## Retângulo da barra de vida, em coordenadas do inimigo.
func life_bar_rect() -> Rect2:
	return Rect2(_bar_back.position, _bar_back.size)


func is_defeated() -> bool:
	return health.is_dead()


## Elemento do escudo, ou null (só o guardião tem; COM-guardiao).
func shield_element() -> Variant:
	return null


func hit(attack_element: String, form: String = "") -> void:
	if is_defeated():
		return
	last_hit_element = attack_element
	last_form = form
	hits += 1
	var result := _resolve(attack_element, form)
	last_effect = result["effect"]
	last_damage = result["damage"]
	last_blocked = result["blocked"]
	_show_hit(attack_element, _hit_text(result))
	was_hit.emit(attack_element, last_effect)
	apply_damage(last_damage)


## {"blocked", "damage", "effect"} do golpe (o guardião troca pelo escudo).
func _resolve(attack_element: String, form: String) -> Dictionary:
	return {
		"blocked": false,
		"damage": Damage.amount(attack_element, form, element),
		"effect": ElementTable.effect(attack_element, element),
	}


func _hit_text(result: Dictionary) -> String:
	if result["blocked"]:
		return tr("ALVO_BLOQUEOU")
	var label := tr(ElementTable.LABEL_KEYS[result["effect"]])
	return label if result["damage"] == 0 else "%s −%d" % [label, result["damage"]]


func apply_damage(amount: int) -> void:
	if is_defeated() or amount <= 0:
		return
	health.damage(amount)
	_bar.size.x = body_size.x * health.current / health.maximum
	if health.is_dead():
		_defeat()


## Sai dos grupos na hora (o próximo feitiço já não vê) e some depois de um instante (regra 2).
func _defeat() -> void:
	remove_from_group(TrainingTarget.GROUP)
	remove_from_group(ENEMY_GROUP)
	_contact.set_deferred(&"monitoring", false)
	var hurtbox: Area2D = get_node_or_null("Hurtbox")
	if hurtbox:
		hurtbox.set_deferred(&"monitorable", false)
	_body.visible = false
	var linger := DEFEAT_LINGER
	var death := _death_animation()
	if art_sprite and art_sprite.sprite_frames.has_animation(death):
		# ART-esteira, regra 23: toca a morte e só sai da cena quando ela termina.
		art_sprite.play(death)
		linger = maxf(linger, ArtLibrary.duration(art_sprite.sprite_frames, death))
	elif art_sprite:
		art_sprite.visible = false
	name_label.visible = false
	_bar.visible = false
	_bar_back.visible = false
	if get_parent():
		Fx.burst(get_parent(), position + Vector2(0, -body_size.y / 2), ELEMENT_COLORS.get(element, Color.WHITE), 24)
	defeated.emit()
	if is_inside_tree():
		get_tree().create_timer(linger, false, true).timeout.connect(queue_free)
	else:
		queue_free()
