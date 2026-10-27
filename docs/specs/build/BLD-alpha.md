# BLD-alpha — Build da Alpha para Windows

- **Status:** Implementada
- **Sprint:** 15
- **Relacionadas:** ADR-002 (worker persistente), EXE-protocolo, SAV-progresso, MUN-mapa; passos antigos em `docs/sprints/sprint-02-executor-custo-sandbox.md`

## Contexto

A Alpha precisa rodar no computador de quem vai testar, sem Godot nem Python instalados. O jogo exportado leva o Python embutido e o executor ao lado do `.exe`. Um teste de fumaça roda no próprio jogo exportado: ele confere se o executor responde e se o conteúdo carrega, coisas que só quebram fora do editor.

## Fora do escopo

Instalador, assinatura de código, ícone definitivo, outras plataformas, atualização automática.

## Regras

1. **Preset** `Windows Desktop` em `game/export_presets.cfg` (versionado): x86_64, `.pck` separado, com o `.console.exe` para ver a saída. Leva os `.json` de `content/` (o Godot só exporta recursos importados se não for avisado) e deixa de fora `tests/` e `addons/gdUnit4/`.
2. **Pasta do build** (`build/ArcaneSyntax/`, fora do git):
   - `ArcaneSyntax.exe`, `ArcaneSyntax.console.exe`, `ArcaneSyntax.pck`;
   - `executor/` só com `run_worker.py` e `arcane_executor/` (sem testes e sem `__pycache__`);
   - `runtime/python/` enxuto: sem `include`, `libs`, `Scripts`, `tcl`, `Lib/site-packages`, `Lib/ensurepip`, `Lib/idlelib`, `Lib/tkinter`, `Lib/turtledemo`, `Lib/venv`, `Lib/test` e as DLLs do Tk;
   - `LEIA-ME.txt` para quem joga (teclas, onde fica o save, como recomeçar).
   - Um `.zip` da pasta, `build/ArcaneSyntax-alpha.zip`, para enviar.
3. **Script:** `scripts/build_windows.ps1` faz tudo isso e termina rodando o teste de fumaça no jogo exportado; se a fumaça falha, o script falha e não gera o `.zip`.
4. **Teste de fumaça:** `ArcaneSyntax.console.exe --headless -- --fumaca` não abre o menu. Ele confere e sai com código 0 (tudo certo) ou 1 (lista os problemas):
   - o balanceamento, os diálogos, as dicas e a referência carregam sem erro;
   - os textos do `textos.csv` estão traduzidos (`MENU_TITULO` não aparece cru);
   - o mapa carrega todas as salas e o `AreaMap.walkthrough` chega a todas;
   - o executor responde: `meditar()` e `print("fumaça")` devolvem mana acima de 0 e a visão `fumaça`.
5. Os mesmos testes rodam no editor (GdUnit4), para a fumaça não quebrar sem ninguém ver.

## Critérios de aceite

### BLD-001 — Fumaça passa no editor

- **Dado** o projeto no editor, com o executor e o Python embutido
- **Quando** o teste de fumaça roda
- **Então** não há problemas

### BLD-002 — Fumaça aponta o problema

- **Dado** um executor que não sobe (Python que não existe)
- **Então** o teste de fumaça devolve um problema que fala do executor

### BLD-003 — Pedido pela linha de comando

- **Então** `--fumaca` nos argumentos do usuário liga a fumaça; sem ele, a cena principal abre no menu

### BLD-004 — O jogo exportado passa na fumaça (manual, pelo script)

- **Quando** `scripts/build_windows.ps1` roda
- **Então** a fumaça no `.exe` exportado sai com código 0 e o `.zip` é gerado

## Perguntas em aberto

- [ ] Ícone e nome da janela definitivos (depois da arte).
- [ ] Vale assinar o `.exe`? O Windows SmartScreen avisa em executáveis sem assinatura.
