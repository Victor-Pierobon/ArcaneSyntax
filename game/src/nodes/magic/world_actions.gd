class_name WorldActions
extends Node
## Faz as ações dos feitiços acontecerem no mundo (specs MAG-acoes e MAG-formas).
## É o `port` do ActionPlayer: um método `act_<tipo>` por ação. Respeita a pausa do jogo.

const CAST_DELAY := 0.15
const MEDITATE_TIME := 0.5
const ABSORB_TIME := 0.08
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


func act_lancar(action: Dictionary) -> void:
	var element := str(action.get("elemento", ""))
	if action.get("forma") == "escudo":
		_raise_shield(element)
	else:
		_launch_projectile(element, action.get("alvo"))
	await _wait(CAST_DELAY)


func act_mover(action: Dictionary) -> void:
	var steps := float(action.get("passos", 0))
	if is_zero_approx(steps):
		return
	var player := world.player
	var direction := signf(steps)
	var target_x := player.global_position.x + steps * RoomLayout.TILE
	var saved := player.intent_source
	player.intent_source = func() -> PlayerIntent: return PlayerIntent.make(direction)
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
	await _wait(HOVER_TIME)
	player.intent_source = saved


func act_meditar(_action: Dictionary) -> void:
	var player := world.player
	var saved := player.intent_source
	player.intent_source = func() -> PlayerIntent: return PlayerIntent.make()
	_flash_player(Color("b8a8ff"), MEDITATE_TIME)
	await _wait(MEDITATE_TIME)
	player.intent_source = saved


func act_absorver_mana(_action: Dictionary) -> void:
	_flash_player(Color("8fd8ff"), ABSORB_TIME * 2)
	await _wait(ABSORB_TIME)


## Golpe de cajado à frente do mago, sem mana (MAG-014). Devolve false se ainda está em recarga.
func staff_attack() -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if now < _staff_ready_at:
		return false
	_staff_ready_at = now + STAFF_COOLDOWN
	var player := world.player
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


func _launch_projectile(element: String, target_id: Variant) -> void:
	var player := world.player
	var hand := player.global_position + Vector2(HAND_OFFSET.x * player.motor.facing, HAND_OFFSET.y)
	var direction := Vector2(player.motor.facing, 0)
	var target: TrainingTarget = world.find_target(str(target_id)) if target_id != null else null
	if target:
		direction = (target.center() - hand).normalized()
	var projectile := Projectile.make(element, direction)
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
	var visual: CanvasItem = world.player.get_node_or_null("Placeholder")
	if visual == null:
		return
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
