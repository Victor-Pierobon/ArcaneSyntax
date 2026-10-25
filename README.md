# ArcaneSyntax

Metroidvania em pixel art em que cada feitiço é código Python real. Em desenvolvimento: versão Alpha (Ato I).

- Design: `docs/gdd.md`
- Plano da Alpha: `docs/plano-alpha.md`
- Sprints: `docs/roadmap-alpha.md`
- Specs: `docs/specs/` (modelo em `docs/specs/TEMPLATE.md`)

## Estrutura

| Pasta | Conteúdo |
| --- | --- |
| `game/` | Projeto Godot 4.7 (`src/core` regras puras, `src/nodes` cenas, `tests` GdUnit4) |
| `executor/` | Executor de feitiços em Python (`tests` com pytest) |
| `tests/contract/` | Fixtures JSON compartilhadas entre Godot e executor |
| `docs/` | GDD, plano, roadmap, specs, ADRs e diário |

## Rodando os testes

Requisitos: Python 3.12+ com `pytest`, Godot 4.7.

Uma vez só, baixe o Python que o jogo usa para rodar os feitiços (vai para `runtime/`, fora do git):

```bash
scripts/fetch_python.sh
```

Depois:

```bash
export GODOT_BIN="/c/Users/victo/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
scripts/test.sh
```

Só uma suíte:

```bash
cd executor && python -m pytest
cd game && bash addons/gdUnit4/runtest.sh --headless -a res://tests --ignoreHeadlessMode
```

Em modo headless o Godot não entrega eventos de input, por isso os testes de cena injetam a intenção do jogador (`Player.intent_source`) em vez de simular teclas.

## Console de feitiços (ferramenta de desenvolvimento)

Para testar o executor na mão: digite Python, aperte Ctrl+Enter e veja ações, visões (`print`), erros e a mana final.

```powershell
& "C:\Users\victo\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path game res://src/nodes/dev/spell_console.tscn
```

No editor: abra `src/nodes/dev/spell_console.tscn` e aperte F6.

Feitiços prontos para colar, com o resultado esperado de cada um: `docs/feiticos-exemplo.md`.

## Fluxo de trabalho

Spec → teste vermelho → código → refatorar → commit com tudo verde. Detalhes em `docs/roadmap-alpha.md`.
