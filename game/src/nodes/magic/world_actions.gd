class_name WorldActions
extends Node
## Faz as ações dos feitiços acontecerem no mundo (specs MAG-acoes e MAG-formas).
## É o `port` do ActionPlayer: um método `act_<tipo>` por ação. Respeita a pausa do jogo.

const CAST_DELAY := 0.15
const MEDITATE_TIME := 0.5
const ABSORB_TIME := 0.08
const INSCRIBE_TIME := 0.3
const BLOCK_TIME := 0.15
const FLY_SPEED := 96.0
const HOVER_TIME := 0.3
const STUCK_TIME := 0.3
const MAX_ACTION_TIME := 3.0
const VISION_TIME := 2.0
const MAX_VISIONS := 3
const STAFF_COOLDOWN := 0.35
const STAFF_ACTIVE_TIME := 0.15
const STAFF_SIZE := Vector2(16, 24)
const HAND_OFFSET := Vector2(8, -16)

var world: World

var _staff_ready_at := 0.0
## Levitar seguido de mover: o mago continua voando durante o mover (MAG-070).
## Guarda o controle que estava antes do levitar, para devolver no fim do mover.
var _flying := false
var _control_before_flight: Callable


func act_lancar(action: Dictionary) -> void:
	var element := str(action.get("elemento", ""))
	world.player.play_action("conjurar")
	if action.get("forma") == "escudo":
		_raise_shield(element)
		world.sfx.play("escudo")
	else:
		_launch_projectile(element, action.get("alvo"), str(action.get("forma", "projetil")))
		world.sfx.play("conjurar", element)
	await _wait(CAST_DELAY)


func act_mover(action: Dictionary) -> void:
	var player := world.player
	var flying := _flying
	_flying = false
	var saved: Callable = _control_before_flight if flying else player.intent_source
	var steps := float(action.get("passos", 0))
	if is_zero_approx(steps):
		player.intent_source = saved
		return
	var direction := signf(steps)
	var target_x := player.global_position.x + steps * RoomLayout.TILE
	player.intent_source = func() -> PlayerIntent:
		var intent := PlayerIntent.make(direction)
		if flying:
			intent.fly_y = 0.0
		return intent
	await _until(func() -> bool: return (target_x - player.global_position.x) * direction <= 1.0,
			func() -> float: return player.global_position.x)
	player.intent_source = saved


func act_levitar(action: Dictionary) -> void:
	var height := float(action.get("altura", 0)) * RoomLayout.TILE
	var player := world.player
	var start_y := player.global_position.y
	var saved := player.intent_source
	player.intent_source = func() -> PlayerIntent: return _fly(-FLY_SPEED)
	await _until(func() -> bool: return start_y - player.global_position.y >= height - 1.0,
			func() -> float: return player.global_position.y)
	player.intent_source = func() -> PlayerIntent: return _fly(0.0)
	if action.get("seguinte", "") == "mover":
		# Continua no ar: o mover seguinte voa na horizontal e devolve o controle (MAG-070).
		_flying = true
		_control_before_flight = saved
		return
	await _wait(HOVER_TIME)
	player.intent_source = saved


func act_meditar(_action: Dictionary) -> void:
	var player := world.player
	var saved := player.intent_source
	player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	player.play_action("meditar", MEDITATE_TIME)
	_flash_player(Color("b8a8ff"), MEDITATE_TIME)
	Fx.burst(player, Vector2(0, -2), Color("b8a8ff"), 18, true)
	world.sfx.play("mana")
	await _wait(MEDITATE_TIME)
	player.intent_source = saved


## Uma runa com o número vai até o cadeado mais perto (PUZ-validacao, regra 10).
func act_inscrever(action: Dictionary) -> void:
	var room := world.current_room
	var player := world.player
	player.play_action("conjurar")
	var status := room.inscribe(float(action.get("valor", 0)), player.global_position) if room else "sem_cadeado"
	match status:
		"sem_cadeado":
			world.cast_log.add_lines(PackedStringArray([tr("INSCREVER_SEM_CADEADO")]))
		"longe":
			world.cast_log.add_lines(PackedStringArray([tr("INSCREVER_LONGE")]))
		_:
			Fx.burst(room, room.to_local(room.lock_position()) + Vector2(0, -8), Color("c9b8ff"), 10)
			world.sfx.play("mana" if status == "aberto" else "cajado")
	await _wait(INSCRIBE_TIME)


## O próximo bloco da ponte aparece (PUZ-validacao, regra 11).
func act_construir_bloco(_action: Dictionary) -> void:
	var room := world.current_room
	if room and room.build_block():
		world.sfx.play("acerto")
	else:
		world.cast_log.add_lines(PackedStringArray([tr("PONTE_PRONTA" if room and room.bridge else "PONTE_SEM_VAO")]))
	await _wait(BLOCK_TIME)


func act_absorver_mana(_action: Dictionary) -> void:
	world.player.play_action("meditar", ABSORB_TIME * 2)
	_flash_player(Color("8fd8ff"), ABSORB_TIME * 2)
	Fx.burst(world.player, Vector2(0, -15), Color("8fd8ff"), 6)
	world.sfx.play("mana")
	await _wait(ABSORB_TIME)


## Golpe de cajado à frente do mago, sem mana (MAG-014). Devolve false se ainda está em recarga.
func staff_attack() -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if now < _staff_ready_at:
		return false
	_staff_ready_at = now + STAFF_COOLDOWN
	world.sfx.play("cajado")
	var player := world.player
	player.play_action("cajado")
	var swing := Area2D.new()
	swing.collision_layer = 0
	swing.collision_mask = Projectile.HURTBOX_LAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = STAFF_SIZE
	shape.shape = rect
	swing.add_child(shape)
	swing.position = player.global_position + Vector2(player.motor.facing * 14.0, -STAFF_SIZE.y / 2)
	var struck := {}
	swing.area_entered.connect(func(area: Area2D) -> void:
		var target := area.get_parent() as TrainingTarget
		if target and not struck.has(target):
			struck[target] = true
			target.hit("cajado")
	)
	world.add_child(swing)
	get_tree().create_timer(STAFF_ACTIVE_TIME, false, true).timeout.connect(swing.queue_free)
	return true


## Visões (print) flutuando sobre o mago: as últimas 3, por 2 s (MAG-019).
func show_visions(texts: PackedStringArray) -> void:
	if texts.is_empty():
		return
	var player := world.player
	var label: Label = player.get_node_or_null("Visions")
	if label == null:
		label = Label.new()
		label.name = "Visions"
		Lighting.keep_readable(label)
		label.add_theme_font_size_override(&"font_size", 8)
		label.add_theme_color_override(&"font_color", Color("e8e0ff"))
		label.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.8))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size = Vector2(160, 40)
		player.add_child(label)
	var shown := texts.slice(maxi(texts.size() - MAX_VISIONS, 0))
	label.text = "\n".join(shown)
	label.position = Vector2(-80, -34 - 10 * shown.size())
	label.modulate = Color.WHITE
	var tween := label.create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(VISION_TIME)


func _launch_projectile(element: String, target_id: Variant, form: String) -> void:
	var player := world.player
	var target: TrainingTarget = world.find_target(str(target_id)) if target_id != null else null
	if target:
		# Vira para o alvo: a mão fica do lado dele, não da parede atrás (regressão MAG-010).
		var side := signf(target.center().x - player.global_position.x)
		if side != 0.0:
			player.motor.facing = int(side)
	var hand := player.global_position + Vector2(HAND_OFFSET.x * player.motor.facing, HAND_OFFSET.y)
	var direction := Vector2(player.motor.facing, 0)
	if target:
		direction = (target.center() - hand).normalized()
	var projectile := Projectile.make(element, direction, form, target)
	projectile.position = hand
	world.add_child(projectile)


func _raise_shield(element: String) -> void:
	var player := world.player
	var old: Shield = player.get_node_or_null("Shield")
	if old:
		old.expire()
	var shield := Shield.make(element)
	shield.expired.connect(func() -> void: world.state.health.shielded = false)
	player.add_child(shield)
	world.state.health.shielded = true


## Chamado pelo World quando o escudo bloqueia um ataque.
func on_attack_blocked() -> void:
	var shield: Shield = world.player.get_node_or_null("Shield")
	if shield:
		shield.expire()


func _flash_player(color: Color, duration: float) -> void:
	var visual: CanvasItem = world.player.visual
	visual.modulate = color
	var tween := visual.create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, duration)


static func _fly(speed: float) -> PlayerIntent:
	var intent := PlayerIntent.make()
	intent.fly_y = speed
	return intent


## Espera em tempo de jogo: para quando o jogo pausa (MAG-009).
func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false, true).timeout


## Espera até `done` ser verdade, ou o mago ficar 0,3 s sem avançar, ou passar 3 s (MAG-005).
func _until(done: Callable, progress: Callable) -> void:
	var elapsed := 0.0
	var stuck := 0.0
	var last: float = progress.call()
	while not done.call():
		await get_tree().physics_frame
		if get_tree().paused:
			continue
		var delta := get_physics_process_delta_time()
		elapsed += delta
		var now: float = progress.call()
		stuck = stuck + delta if absf(now - last) < 0.25 else 0.0
		last = now
		if stuck >= STUCK_TIME or elapsed >= MAX_ACTION_TIME:
			return
