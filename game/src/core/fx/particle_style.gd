class_name ParticleStyle
extends RefCounted
## Como as partículas de cada elemento se mexem (spec ART-brilho, regra 4): fogo, brasas que sobem;
## gelo, flocos que caem devagar; raio, faíscas rápidas e curtas; planta, folhas que vão para o lado.

var color := Color.WHITE
var gravity := Vector2(0, 120)
## Velocidade inicial máxima, em px/s.
var speed := 60.0
## Segundos de vida de cada partícula.
var lifetime := 0.45
## Tamanho do quadrado, em px.
var size := 2.0


static func for_element(element: String) -> ParticleStyle:
	var style := ParticleStyle.new()
	style.color = TrainingTarget.ELEMENT_COLORS.get(element, Color.WHITE)
	match element:
		"fogo":
			style.gravity = Vector2(0, -60)
			style.speed = 40.0
			style.lifetime = 0.7
		"gelo":
			style.gravity = Vector2(0, 30)
			style.speed = 30.0
			style.lifetime = 0.9
			style.size = 1.5
		"raio":
			style.gravity = Vector2.ZERO
			style.speed = 140.0
			style.lifetime = 0.2
			style.size = 1.0
		"planta":
			style.gravity = Vector2(40, 50)
			style.speed = 35.0
			style.lifetime = 0.8
	return style
