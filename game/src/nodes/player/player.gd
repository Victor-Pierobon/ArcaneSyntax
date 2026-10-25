class_name Player
extends CharacterBody2D
## Liga a regra de movimento (PlayerMotor) à física do Godot. Origem do nó fica nos pés do mago.

var motor := PlayerMotor.new()
## De onde vem a intenção do quadro; testes e, no futuro, feitiços podem trocar.
var intent_source: Callable = PlayerIntent.from_input


func _physics_process(delta: float) -> void:
	var intent: PlayerIntent = intent_source.call()
	velocity = motor.step(velocity, intent, is_on_floor(), delta)
	move_and_slide()
