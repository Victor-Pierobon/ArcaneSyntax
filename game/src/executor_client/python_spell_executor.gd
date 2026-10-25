class_name PythonSpellExecutor
extends SpellExecutor
## Executa feitiços num worker Python persistente (ADR-002), trocando uma linha JSON
## por requisição. A ida e volta roda numa thread para não travar o jogo.

## Caminho do Python; se vazio, usa ARCANE_PYTHON, depois runtime/python, depois o PATH.
@export var python_path: String = ""
## Watchdog (spec EXE-limites): sem resposta nesse tempo, o worker é morto e o feitiço
## volta como TempoEsgotado. Fica acima do limite_tempo_ms do próprio worker.
@export var timeout_ms: int = 3000

var _stdio: FileAccess
var _pid := -1
var _next_id := 1
var _busy := false


func execute(request: SpellRequest) -> SpellResult:
	while _busy:
		await get_tree().process_frame
	_busy = true
	var result := await _execute_now(request)
	_busy = false
	return result


func worker_pid() -> int:
	return _pid


func _execute_now(request: SpellRequest) -> SpellResult:
	if not _ensure_worker():
		return SpellResult.failure("ExecutorIndisponivel", "não foi possível iniciar o Python")

	var id := _next_id
	_next_id += 1
	var thread := Thread.new()
	# O pipe vai como argumento para a thread manter a própria referência mesmo se o
	# watchdog descartar o worker no meio da espera.
	thread.start(_roundtrip.bind(_stdio, JSON.stringify(request.to_dict(id))))
	var started := Time.get_ticks_msec()
	var timed_out := false
	while thread.is_alive():
		if not timed_out and Time.get_ticks_msec() - started > timeout_ms:
			timed_out = true
			_stop_worker()  # fechar o processo destrava o get_line da thread
		await get_tree().process_frame
	var reply: String = thread.wait_to_finish()

	if timed_out:
		return SpellResult.failure("TempoEsgotado", "o feitiço demorou demais e foi interrompido")
	if reply.is_empty():
		_stop_worker()
		return SpellResult.failure("ExecutorIndisponivel", "o executor parou de responder")
	var data: Variant = JSON.parse_string(reply)
	if not data is Dictionary:
		return SpellResult.failure("RespostaInvalida", "resposta ilegível do executor")
	return SpellResult.from_dict(data)


func _roundtrip(stdio: FileAccess, line: String) -> String:
	stdio.store_line(line)
	stdio.flush()
	return stdio.get_line()


func _ensure_worker() -> bool:
	if _pid != -1 and OS.is_process_running(_pid):
		return true
	_stop_worker()
	var info := OS.execute_with_pipe(_resolve_python(), ["-I", "-S", "-u", _worker_script()])
	if info.is_empty():
		return false
	_stdio = info["stdio"]
	_pid = info["pid"]
	return true


func _stop_worker() -> void:
	if _pid != -1 and OS.is_process_running(_pid):
		OS.kill(_pid)
	_pid = -1
	_stdio = null


func _exit_tree() -> void:
	_stop_worker()


## Pasta que contém executor/ e runtime/. Em desenvolvimento é a raiz do repositório;
## no jogo exportado, a pasta do executável (o build copia as duas pastas para lá).
static func base_dir(running_in_editor: bool, project_dir: String, executable_path: String) -> String:
	if running_in_editor:
		return project_dir.path_join("..").simplify_path()
	return executable_path.get_base_dir()


func _base_dir() -> String:
	return base_dir(OS.has_feature("editor"), ProjectSettings.globalize_path("res://"), OS.get_executable_path())


func _worker_script() -> String:
	return _base_dir().path_join("executor/run_worker.py")


func _resolve_python() -> String:
	if not python_path.is_empty():
		return python_path
	var from_env := OS.get_environment("ARCANE_PYTHON")
	if not from_env.is_empty():
		return from_env
	var bundled := _base_dir().path_join("runtime/python")
	bundled = bundled.path_join("python.exe" if OS.get_name() == "Windows" else "bin/python3")
	if FileAccess.file_exists(bundled):
		return bundled
	return "python" if OS.get_name() == "Windows" else "python3"
