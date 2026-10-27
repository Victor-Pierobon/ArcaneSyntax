class_name CameraShake
extends RefCounted
## Tremida de câmera (spec ART-brilho, regra 6): um trauma de 0 a 1 que soma e cai com o tempo. O
## deslocamento é MAX_OFFSET × trauma², numa direção que só depende do tempo.

const MAX_OFFSET := 6.0
## Quanto o trauma cai por segundo.
const DECAY := 1.5

var trauma := 0.0
## Tempo corrido (o nó avança; os testes põem direto).
var time := 0.0


func add(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


func tick(delta: float) -> void:
	time += delta
	trauma = maxf(trauma - DECAY * delta, 0.0)


func offset() -> Vector2:
	if trauma <= 0.0:
		return Vector2.ZERO
	var amount := MAX_OFFSET * trauma * trauma
	# Duas ondas de frequências que não se repetem juntas: parece ruído, mas é sempre igual.
	return Vector2(sin(time * 47.0) * cos(time * 13.0), sin(time * 37.0 + 1.3) * cos(time * 17.0)) * amount
