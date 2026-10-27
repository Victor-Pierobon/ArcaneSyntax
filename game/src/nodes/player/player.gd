class_name Player
extends CharacterBody2D
## Liga a regra de movimento (PlayerMotor) à física do Godot. Origem do nó fica nos pés do mago.

var motor := PlayerMotor.new()
## De onde vem a intenção do quadro; testes e, no futuro, feitiços podem trocar.
var intent_source: Callable = PlayerIntent.from_input
## Qual animação o mago mostra (spec ART-esteira, regra 9).
var animation := PlayerAnimation.new()
var current_animation := "parado"

@onready var visual: PlayerVisual = $Visual


func _physics_process(delta: float) -> void:
	var intent: PlayerIntent = intent_source.call()
	velocity = motor.step(velocity, intent, is_on_floor(), delta)
	move_and_slide()
	animation.tick(delta)
	current_animation = animation.pick(is_on_floor(), velocity, motor.is_dodging(), not is_nan(intent.fly_y))
	visual.show_animation(current_animation, motor.facing)


## Uma ação do feitiço ou do cajado (`conjurar`, `meditar`, `cajado`) por `seconds` (negativo: o padrão).
func play_action(action: String, seconds: float = -1.0) -> void:
	animation.start_action(action, seconds)


func hurt() -> void:
	animation.hurt()
