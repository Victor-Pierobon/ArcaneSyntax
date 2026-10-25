# Sprint 15 — Testes com iniciantes e build

- **Status:** Planejada
- **Fase do plano:** 9 · **Marco:** fecha a Alpha · **Estimativa:** 15–25 h
- **Depende de:** Sprint 14

## Objetivo

Um iniciante em programação joga do início ao fim sem ajuda externa e quer continuar (critério de sucesso do plano).

## Tarefas

- [ ] Jogar do início ao fim e corrigir bugs; cada bug vira um teste de regressão antes da correção (5–8 h)
- [ ] Testar com 3 a 5 iniciantes, observando sem ajudar, com um roteiro de observação (4–6 h)
- [ ] Ajustes a partir dos testes (5–8 h)
- [ ] Build da Alpha para Windows (1–3 h)

## Notas para o build

- O build precisa levar o **Python standalone** (`runtime/python`, enxugado: sem `tkinter`, `idlelib`, `ensurepip`, cabeçalhos) e o **`executor/`** ao lado do `.exe`.
- `PythonSpellExecutor` hoje acha o executor via `ProjectSettings.globalize_path("res://") + "/.."`, o que **só funciona em desenvolvimento**. No build, usar a pasta do executável (`OS.get_executable_path().get_base_dir()`).
- Se a Sprint 2 fizer o build de fumaça recomendado, este passo já estará resolvido.

## Pronto quando (fecha a Alpha)

Um iniciante joga do início ao fim sem ajuda externa e quer continuar.
