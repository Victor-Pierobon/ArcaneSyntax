class_name Sfx
extends Node
## Sons provisórios gerados por código, um por evento (spec MAG-efeitos).
## Nenhum arquivo de áudio: tudo some quando a trilha definitiva chegar.

const EVENTS := ["conjurar", "acerto", "fraco", "escudo", "cajado", "mana"]
const MIX_RATE := 22050
const VOICES := 4
const BUS := &"SFX"
const MAX_HISTORY := 50

enum Wave { SINE, SQUARE, NOISE }

## Eventos tocados, para testes e depuração.
var played: Array[String] = []

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_voice := 0


func _ready() -> void:
	_streams = {
		"conjurar_fogo": _tone(180.0, 120.0, 0.18, Wave.SQUARE, 0.25),
		"conjurar_gelo": _tone(900.0, 1300.0, 0.16, Wave.SINE, 0.3),
		"conjurar_raio": _tone(440.0, 220.0, 0.14, Wave.NOISE, 0.22),
		"acerto": _tone(320.0, 260.0, 0.08, Wave.SQUARE, 0.2),
		"fraco": _tone(660.0, 990.0, 0.14, Wave.SINE, 0.35),
		"escudo": _tone(520.0, 520.0, 0.3, Wave.SINE, 0.25),
		"cajado": _tone(200.0, 120.0, 0.06, Wave.NOISE, 0.25),
		"mana": _tone(1040.0, 1180.0, 0.07, Wave.SINE, 0.12),
		"derrota": _tone(520.0, 140.0, 0.25, Wave.SQUARE, 0.25),
	}
	_streams["conjurar"] = _streams["conjurar_fogo"]
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = BUS if AudioServer.get_bus_index(BUS) != -1 else &"Master"
		add_child(player)
		_players.append(player)


func stream_for(event: String, element: String = "") -> AudioStreamWAV:
	if event == "conjurar" and _streams.has("conjurar_" + element):
		return _streams["conjurar_" + element]
	return _streams.get(event)


## Toca o som do evento; devolve false para evento desconhecido (MAG-060).
func play(event: String, element: String = "") -> bool:
	var stream := stream_for(event, element)
	if stream == null:
		push_warning("som desconhecido: %s" % event)
		return false
	played.append(event)
	if played.size() > MAX_HISTORY:
		played.remove_at(0)
	var player := _players[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	player.stream = stream
	player.play()
	return true


static func _tone(freq_start: float, freq_end: float, duration: float, wave: Wave, volume: float) -> AudioStreamWAV:
	var count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(freq_start * 1000.0)
	for i in count:
		var t := float(i) / count
		var freq := lerpf(freq_start, freq_end, t)
		phase += TAU * freq / MIX_RATE
		var sample := 0.0
		match wave:
			Wave.SINE:
				sample = sin(phase)
			Wave.SQUARE:
				sample = 1.0 if sin(phase) >= 0.0 else -1.0
			Wave.NOISE:
				sample = rng.randf_range(-1.0, 1.0) * 0.6 + sin(phase) * 0.4
		var envelope := minf(t * 20.0, 1.0) * (1.0 - t)
		data.encode_s16(i * 2, int(clampf(sample * envelope * volume, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
