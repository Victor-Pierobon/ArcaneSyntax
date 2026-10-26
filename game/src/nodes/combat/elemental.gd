class_name Elemental
extends Enemy
## Elemental (spec COM-elemental): patrulha o chão em que nasceu e persegue o mago por perto.

const ELEMENTS := ["fogo", "gelo", "planta"]
const BODY := Vector2(14, 20)

var brain: ElementalBrain
## Layout da sala, para não entrar em paredes nem sair do chão; null: chão sem fim.
var layout: RoomLayout


static func make_elemental(p_target_id: String, p_element: String) -> Elemental:
	var elemental := Elemental.new()
	elemental.setup(p_target_id, p_element, Balance.integer("elemental", "vida"), BODY)
	return elemental


func _ready() -> void:
	super._ready()
	brain = ElementalBrain.new(position.x)


func _think(delta: float) -> void:
	var feet := position
	var ahead := func(direction: int) -> bool:
		return layout == null or ElementalBrain.can_walk(layout, feet, direction, BODY.x / 2)
	position.x += brain.velocity_x(feet, _player_feet(), ahead) * delta
