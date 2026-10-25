# Arquitetura

Estado em 2026-10-25, fim da Sprint 2. Atualizar ao fim de cada sprint que mudar a estrutura.

## Visão geral

```
┌──────────────────────────── Godot 4.7 (game/) ────────────────────────────┐
│                                                                           │
│  Nodes (src/nodes)            Regras puras (src/core)                     │
│  Player ───────────────────▶  PlayerMotor  ◀── PlayerIntent               │
│  (CharacterBody2D)            (sem Node, testável sem cena)               │
│                                                                           │
│  Cliente do executor (src/executor_client)                                │
│  SpellRequest ─▶ PythonSpellExecutor ─▶ SpellResult / SpellError          │
│                  (extends SpellExecutor; thread + worker)                 │
└──────────────────────────────┬────────────────────────────────────────────┘
                               │ 1 linha JSON por requisição (stdin/stdout)
                               ▼
┌────────────────── Worker Python 3.14 (executor/) ─────────────────────────┐
│  run_worker.py → worker.main → protocol.handle_line → runner.run_spell    │
│     (teto de memória)                    parse → sandbox → instrumentar   │
│                                            → exec com pieces.Contexto     │
└───────────────────────────────────────────────────────────────────────────┘
```

O jogo nunca roda o código do jogador no próprio processo. Ele manda o código e uma foto do mundo para um worker Python; o worker devolve a lista de ações (com a linha que gerou cada uma), as saídas de `print`, o estado final do mago e o erro, se houver. O jogo anima as ações depois.

## Pastas

| Pasta | O que tem |
| --- | --- |
| `docs/` | GDD, plano da Alpha, roadmap, sprints, specs, ADRs, arquitetura, diário |
| `docs/sprints/` | Um arquivo por sprint: plano (futuras) ou relatório (concluídas) |
| `docs/specs/<area>/` | Specs com critérios de aceite (IDs `AREA-NNN`) |
| `docs/adr/` | Decisões de arquitetura |
| `game/` | Projeto Godot (`res://` aponta para cá) |
| `game/src/core/` | Regras puras, sem Node |
| `game/src/nodes/` | Cenas e scripts de cena (`player/`, `world/`, `dev/`) |
| `game/src/executor_client/` | Cliente do executor Python |
| `game/content/` | Conteúdo de dados (hoje só `text/textos.csv`) |
| `game/tests/` | GdUnit4: `unit/`, `scene/`, `integration/`, `support/` |
| `game/addons/gdUnit4/` | GdUnit4 v6.2.2 (código de terceiros, não editar) |
| `executor/` | Pacote Python `arcane_executor` + `run_worker.py` + `tests/` (pytest) |
| `tests/contract/` | Fixtures JSON do protocolo, usadas pelas duas suítes |
| `scripts/` | `test.sh` (roda tudo), `fetch_python.sh` (baixa o Python embutido) |
| `runtime/` | Python standalone baixado (fora do git) |

## Godot

### Configuração (`game/project.godot`)

- Resolução base 640×360, janela 1280×720, stretch `viewport`, filtro de textura `nearest` (pixel art).
- Renderizador `gl_compatibility`.
- Ações de input: `move_left` (A, ←), `move_right` (D, →), `jump` (Espaço, W, ↑).
- Textos: `content/text/textos.csv` (coluna `pt_BR`) importado como tradução; nunca escrever texto visível direto no código, usar chaves (`PROTOTIPO_DICA`).
- Plugin GdUnit4 habilitado.
- Cena principal: `res://src/nodes/world/prototype_room.tscn`.

### Movimento (spec MUN-movimento)

- `PlayerIntent` (`src/core/player/player_intent.gd`): `move_x`, `jump_pressed`, `jump_held`. `PlayerIntent.from_input()` lê o teclado; `PlayerIntent.make(...)` cria uma à mão.
- `PlayerMotor` (`src/core/player/player_motor.gd`): `step(velocity, intent, on_floor, delta) -> Vector2`. Parâmetros: andar 120 px/s, gravidade 980, altura do pulo 48 px (velocidade derivada: `sqrt(2·g·h)`), queda máxima 400, corte do pulo 0,5 (uma vez por pulo).
- `Player` (`src/nodes/player/player.gd`, CharacterBody2D): origem nos pés; chama `intent_source` (Callable, padrão `PlayerIntent.from_input`) e `motor.step` no `_physics_process`. Testes e, no futuro, feitiços trocam `intent_source`.
- Sala de protótipo: chão em y=320, duas plataformas, paredes, câmera com limites 0–1280 × 0–360. Visual provisório com `ColorRect`.

### Cliente do executor (spec EXE-protocolo)

- `SpellExecutor` (Node): interface, `execute(request) -> SpellResult`, sempre chamado com `await`.
- `PythonSpellExecutor`: sobe o worker com `OS.execute_with_pipe(python, ["-I", "-S", "-u", run_worker.py])`; cada `execute` roda a ida e volta numa `Thread` (o pipe vai como argumento) e espera com `await process_frame` (não trava o jogo). Chamadas simultâneas esperam numa fila (`_busy`). **Watchdog:** passou de `timeout_ms` (padrão 3000), mata o worker e devolve `TempoEsgotado`. Se o processo morreu, sobe outro na próxima chamada. `_exit_tree` mata o worker.
- `PythonSpellExecutor.base_dir()`: pasta que contém `executor/` e `runtime/`. No editor (inclusive nos testes) é a raiz do repo; no jogo exportado, a pasta do `.exe`.
- Python usado, nesta ordem: `python_path` exportado → env `ARCANE_PYTHON` → `<base_dir>/runtime/python/python.exe` (Windows) ou `bin/python3` → `python`/`python3` do PATH.
- `SpellRequest.make(code, mago, target=null, rules={})` → `to_dict(id)`.
- `SpellResult.from_dict(data)`: `ok`, `actions: Array[Dictionary]`, `outputs`, `mago`, `cost` (float, `custo_mana`), `error: SpellError` (ou null). `SpellResult.failure(tipo, msg)` para falhas do lado Godot (`ExecutorIndisponivel`, `RespostaInvalida`).
- `SpellError`: `type`, `message`, `line`, `column`; `NO_POSITION = -1` representa null.
- Ainda **não existe** `FakeSpellExecutor`; criar em `game/tests/support/` quando o primeiro sistema que usa feitiços precisar (Sprint 4/5).

### Ferramenta de desenvolvimento

`src/nodes/dev/spell_console.tscn`: editor + botão Executar (Ctrl+Enter), mostra visões, ações, erro (linha pintada) e mana final. Não é parte do jogo.

## Executor Python (`executor/arcane_executor/`)

| Módulo | Papel |
| --- | --- |
| `worker.py` | Limita a própria memória (256 MB: Job Object no Windows, `RLIMIT_AS` no Linux); loop: lê linha do stdin (UTF-8), escreve resposta no stdout real, `flush` |
| `protocol.py` | `handle_line(str) -> str`, `handle_request(dict) -> dict`; valida requisição; JSON de saída com `ensure_ascii=True` |
| `runner.py` | `run_spell(codigo, mago, alvo, regras)`: `ast.parse` → `sandbox.verificar` → `instrumentar` (ganchos de custo e de volta) → `compile` como `<feitico>` → `exec`; captura erros com a linha do jogador |
| `sandbox.py` | Verificador da AST (imports, nomes `__`, atributos `_`, `except:`/`BaseException`), builtins em lista branca, `getattr` e companhia protegidos, importador com lista branca (`math`, `random`) |
| `pieces.py` | `Contexto` (fila de ações, saídas, mago simulado em gotas, custo, ganchos `instrucao`/`volta`, limites), peças, `Alvo` somente leitura, exceções de limite, `linha_do_jogador()` |
| `run_worker.py` | Entrada; põe `executor/` no `sys.path` (necessário porque `-I` não faz isso) |

Pontos importantes:

- O código do jogador é compilado com o nome de arquivo `<feitico>`. É assim que `linha_do_jogador()` e o traceback encontram a linha certa, ignorando os frames do executor.
- Sentidos (`mana`, `mana_max`, `vida_atual`) são variáveis globais do namespace, ressincronizadas depois de cada instrução paga. `alvo` é um objeto `Alvo` ou `None`.
- Elementos e formas são strings (`fogo = "fogo"`).
- Erro de execução não descarta o que rodou antes; o executor captura qualquer exceção (menos `KeyboardInterrupt`).
- **Custo (EXE-custo):** a instrumentação insere `__instrucao__(linha)` depois de cada instrução simples (antes de `return/break/continue/raise`) e `__volta__(linha)` no início de cada volta de laço. O gancho de instrução cobra `custo_instrucao`, aplica o teto `mana_max` e sincroniza os sentidos; os dois ganchos conferem o tempo. Peças cobram o custo base na chamada.
- **Mana em gotas:** 1 mana = 10 gotas (inteiros); `para_gotas`/`para_mana` convertem. Valores inteiros saem como `int` na resposta.
- **Limites (EXE-limites):** `ManaEsgotada`, `TempoEsgotado` e `LimiteExcedido` herdam de `BaseException`; depois do primeiro estouro, todo gancho relança o mesmo erro (`Contexto.estouro`).

## Protocolo v1 (resumo; detalhes em `docs/specs/executor/EXE-protocolo.md`)

Requisição: `{versao: 1, id, codigo, mundo: {mago: {vida, mana, mana_max}, alvo: {id, elemento, distancia} | null}, regras?: {ganho_meditar, ganho_absorver, custo_instrucao, custo_lancar, custo_mover, custo_levitar, custo_meditar, custo_absorver, limite_tempo_ms}}`

Resposta: `{versao: 1, id, ok, acoes: [{tipo, linha, ...}], saidas: [{linha, texto}], mago: {...} | null, custo_mana, erro: {tipo, mensagem, linha, coluna} | null}`

Tipos de erro do executor além das exceções do Python: `RequisicaoInvalida`, `ManaEsgotada`, `TempoEsgotado`, `LimiteExcedido`, `FeiticoProibido`. Do Godot: `ExecutorIndisponivel`, `RespostaInvalida`, `TempoEsgotado` (watchdog).

Ações: `lancar {elemento, forma, alvo}`, `mover {passos}`, `levitar {altura}`, `meditar`, `absorver_mana`.

## Testes

| Suíte | Onde | Como rodar |
| --- | --- | --- |
| pytest | `executor/tests/` | `cd executor && python -m pytest` |
| GdUnit4 | `game/tests/` | `cd game && GODOT_BIN=... bash addons/gdUnit4/runtest.sh --headless -a res://tests --ignoreHeadlessMode` (Windows: `runtest.cmd`) |
| Tudo | — | `GODOT_BIN=... scripts/test.sh` |
| CI | `.github/workflows/ci.yml` | A cada push: job pytest (Python 3.14) e job GdUnit4 (Godot 4.7.2 Linux + Python 3.14) |

Convenções:

- Nome do teste carrega o ID da spec: `test_EXE_019_loop_sobre_a_mana`, `test_MUN_004_pular_do_chao`.
- Cabeçalho do arquivo de teste aponta a spec.
- Fixtures de contrato: `tests/contract/NN_nome.json` com `descricao`, `requisicao`, `resposta`. O pytest exige `handle_request(requisicao) == resposta`; o Godot exige que `SpellResult.from_dict(resposta).to_dict()` volte igual.

### Armadilhas já encontradas

| Situação | O que fazer |
| --- | --- |
| Em headless o Godot não entrega eventos de input | Testes de cena injetam `PlayerIntent` via `intent_source`, nunca simulam teclas |
| GdUnit4 recusa rodar headless | Passar `--ignoreHeadlessMode` |
| `ERROR: Remote Debugger ... 127.0.0.1:0` na saída | Esperado; o script do GdUnit4 provoca isso para evitar travar no depurador |
| Quando uma suíte falha, só o primeiro teste dela apareceu no relatório | Observado na Sprint 0; não confiar na contagem quando há falha |
| Script novo com `class_name` não é encontrado pelos testes | Rodar `godot --headless --path game --import` antes, para atualizar o cache de classes |
| `JSON.parse_string` do Godot lê todo número como float | Converter `linha` para int (`SpellResult`); comparar com fixtures via `ContractFixtures.normalize` |
| `res://` não alcança a raiz do repositório | `PythonSpellExecutor.base_dir()`: no editor usa `globalize_path("res://") + "/.."`; no jogo exportado, a pasta do `.exe` |
| Python com `-I` não põe a pasta do script no `sys.path` | `run_worker.py` insere manualmente |
| `python` do PATH no Windows é o alias da Microsoft Store | Usar `runtime/python` (`scripts/fetch_python.sh`) |
| Executável do Godot para linha de comando | `Godot_v4.7.2-stable_win64_console.exe` (o sem `_console` não mostra saída) |
| Teste com laço infinito trava o pytest quando o limite ainda não existe | Rodar a suíte com `timeout` no comando; no TDD de limites, o vermelho é um travamento |
| Feitiço em teste com muitos `print`/ações esgota a mana padrão (5) antes do limite testado | Dar mana alta no teste |
| `10 ** 10 ** 8` não é calculado na compilação (o otimizador do Python recusa resultados enormes) | Serve para testar o watchdog: trava em código C, sem passar pelos ganchos |
