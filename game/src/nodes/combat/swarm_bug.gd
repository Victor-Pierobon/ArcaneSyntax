class_name SwarmBug
extends Enemy
## Bicho do enxame (spec COM-enxame): voa em volta da casa, mergulha no mago e recua depois de morder.

const DEFAULT_COUNT := 6
const MAX_COUNT := 9
const MAX_HEALTH := 2
const BODY := Vector2(6, 6)
const ELEMENT := "gelo"
## Do centro do mago até os pés.
const PLAYER_CENTER := Vector2(0, -15)

var brain: SwarmBugBrain


## `home`: centro da casa, em coordenadas da sala; `phase`: onde o bicho começa a volta.
static func make_bug(p_target_id: String, home: Vector2, phase: float) -> SwarmBug:
	var bug := SwarmBug.new()
	bug.setup(p_target_id, ELEMENT, MAX_HEALTH, BODY)
	bug.brain = SwarmBugBrain.new(home, phase)
	bug.position = bug.brain.start_position() + Vector2(0, BODY.y / 2)
	return bug


func _ready() -> void:
	super._ready()
	# Seis nomes "gelo" juntos poluíam a tela; a cor do bicho já mostra o elemento.
	name_label.visible = false


func _think(delta: float) -> void:
	var feet: Variant = _player_feet()
	var mago: Variant = null if feet == null else feet + PLAYER_CENTER
	position = brain.step(position - Vector2(0, BODY.y / 2), mago, delta) + Vector2(0, BODY.y / 2)


func _on_touched_player() -> void:
	brain.bite()
