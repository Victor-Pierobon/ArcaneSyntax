# Handoff — ArcaneSyntax

> Contexto para começar uma conversa nova sem reler toda a documentação.
> **Atualizado em:** 2026-10-25, fim da Sprint 3.
> **Atualizar** ao fim de cada sprint (ou quando algo aqui deixar de ser verdade).

## 1. O projeto em 30 segundos

Metroidvania 2D em pixel art (Godot 4.7) em que cada feitiço é código Python real. O jogador, preso num livro, sobe uma torre; cada andar ensina conceitos de programação. Projeto solo do Victor Pierobon, em tempo livre, sem prazo fixo. Meta atual: **Alpha = Ato I (Fundações e Masmorra), só Python**, ~12 salas, 6 puzzles, 3 inimigos, 1 chefe, serpente como mentora. Critério de sucesso: um iniciante joga do início ao fim sem ajuda e quer continuar.

Pilares que guiam decisões: código real; o jogador cria os feitiços livremente; mana como custo de execução; o mapa é o currículo; puzzles validam o **estado do mundo**, nunca comparam código com gabarito.

## 2. Onde estamos

| | |
| --- | --- |
| Sprint atual | **Sprint 3 concluída** (mago com esquiva, vida, salas com transição, HUD); a próxima é a **Sprint 4** (grimório: editor e feitiços salvos) |
| Commits | Sprints 0 a 2 commitadas. **A Sprint 3 ainda não**; o Victor revisa e commita |
| Testes | 105 pytest + 65 GdUnit4, todos verdes localmente |
| CI | Configurado, **ainda não confirmado verde no GitHub** |
| Pendências do Victor | Tutorial 2D do Godot; escolher assets provisórios (hoje o jogo usa um tileset provisório de 3 tiles gerado por script); jogar e preencher o checklist de sensação da Sprint 3; conferir o CI; instalar templates de exportação para o build de fumaça; arte conceitual (guia em `docs/arte/guia-de-arte.md`) |

## 3. Regras de trabalho (combinadas com o Victor)

1. **Idioma:** português do Brasil em conversa, docs, specs, nomes de testes e textos do jogo. Código em inglês nos identificadores do Godot; o executor Python usa nomes em português porque são o vocabulário do jogador.
2. **Spec → teste vermelho → código → refatorar.** Toda funcionalidade começa por uma spec em `docs/specs/<area>/` (modelo em `docs/specs/TEMPLATE.md`), com critérios *Dado/Quando/Então* e IDs `AREA-NNN`. Cada critério vira teste com o ID no nome (`test_EXE_019_...`).
3. **TDD estrito** para regras e executor; **teste depois** + checklist manual para sensação (movimento, animação, VFX).
4. **Nunca fazer `git commit` nem `git push`.** Deixar as mudanças na árvore de trabalho, listar o que mudou e sugerir a mensagem de commit.
5. O jogo sempre roda: terminar com as duas suítes verdes.
6. Ao fim de cada sprint: atualizar o arquivo da sprint (vira relatório), `docs/diario.md`, `docs/roadmap-alpha.md` (status), `docs/arquitetura.md` se a estrutura mudou, e **este handoff**.
7. Ideias novas durante a Alpha vão para o GDD, não para o código.

## 4. Mapa da documentação (ler só o que a tarefa pedir)

| Precisa de… | Leia |
| --- | --- |
| Plano da sprint atual | `docs/sprints/sprint-NN-*.md` |
| Visão geral e status de todas as sprints | `docs/roadmap-alpha.md` |
| Como o código funciona hoje, pastas, armadilhas | `docs/arquitetura.md` |
| Regras exatas de uma funcionalidade | `docs/specs/<area>/*.md` |
| Por que uma decisão técnica foi tomada | `docs/adr/` |
| Visão do jogo completo | `docs/gdd.md` (longo) |
| Escopo e horas originais da Alpha | `docs/plano-alpha.md` |
| Histórico por sessão | `docs/diario.md` |
| Arte: especificações, lista de assets, prompts para IA | `docs/arte/guia-de-arte.md` |

## 5. Arquitetura em uma tela

- **Godot (`game/`)**: regras puras em `src/core/` (sem Node, testáveis sem cena); Nodes em `src/nodes/`; cliente do executor em `src/executor_client/`.
- **Executor (`executor/`)**: worker Python persistente. O Godot sobe `runtime/python/python.exe -I -S -u executor/run_worker.py` com `OS.execute_with_pipe` e troca **uma linha JSON por requisição**. A ida e volta roda numa `Thread`; `execute()` é usado com `await`.
- **Modelo de execução (ADR-001)**: o jogo manda uma foto do mundo; o executor roda o feitiço inteiro, simulando só a mana do mago, e devolve todas as ações, cada uma com a `linha` que a gerou. O resto do mundo não muda durante a execução.
- **Protocolo v1**: requisição `{versao:1, id, codigo, mundo:{mago:{vida,mana,mana_max}, alvo:{id,elemento,distancia}|null}, regras?}` → resposta `{versao:1, id, ok, acoes:[{tipo,linha,...}], saidas:[{linha,texto}], mago, custo_mana, erro:{tipo,mensagem,linha,coluna}|null}`.
- **Peças**: `lancar(elemento, forma, alvo=None)`, `mover(passos)`, `levitar(altura)`, `meditar()`, `absorver_mana()`. Elementos `fogo/gelo/raio` e formas `projetil/escudo` são strings. Sentidos: `mana`, `mana_max`, `vida_atual`, `alvo` (`.elemento`, `.distancia`, somente leitura).
- **Custo de mana (EXE-custo)**: instrução simples custa 0,1, cobrada **depois** de rodar (`return/break/continue/raise`: antes); estruturas (`while/if/for/def`…) não custam; peças: `lancar` 3, `mover` 1, `levitar` 2, `meditar`/`absorver_mana` 0; teto `mana_max` aplicado depois de pagar. Mana interna em décimos inteiros. Feito por **instrumentação da AST** (ganchos `__instrucao__` e `__volta__`).
- **Limites (EXE-limites)**: `ManaEsgotada`, `TempoEsgotado` (1000 ms no worker; watchdog de 3000 ms no Godot), `LimiteExcedido` (1000 ações, 200 saídas); memória do worker limitada a 256 MB. Os limites não podem ser capturados pelo feitiço.
- **Sandbox (EXE-sandbox)**: só `import math`/`random`; nomes `__x` e atributos `_x` proibidos; `except:` e `BaseException` proibidos; builtins em lista branca (sem `open`, `exec`, `eval`…). Violação → `FeiticoProibido` e nada roda.
- **Movimento**: `Player` (CharacterBody2D) chama `PlayerMotor.step(velocity, intent, on_floor, delta)`; a intenção vem de `Player.intent_source` (teclado por padrão; testes injetam). Pulo de 3 tiles, coyote/buffer 0,1 s, esquiva (Shift) de 3 tiles com invulnerabilidade a ataques.
- **Mundo**: cena principal `World` carrega salas de `content/rooms/` (layout em texto: `#` pedra, `=` plataforma, `^` espinhos, `*` ponto seguro, `A–Z` entradas, `a–z` saídas; `exits = {"b": "sala_02:A"}`). `MagoState` (vida 5, mana 0/10) é a mana **real**; `to_spell_mago()` alimenta o executor. Espinho: −1 e volta ao ponto seguro; morte: vida cheia na entrada da sala. `Hud` mostra vida e mana.
- **Contrato**: `tests/contract/*.json` é verificado pelas duas suítes.

Classes principais: `PlayerIntent`, `PlayerMotor`, `Player`, `Health`, `MagoState`, `RoomLayout`, `Room`, `World`, `Hud`, `SpellExecutor`, `PythonSpellExecutor`, `SpellRequest`, `SpellResult`, `SpellError`, `ContractFixtures` (testes). Python: `pieces.Contexto`, `runner.run_spell`, `protocol.handle_request` / `handle_line`, `worker.main`.

## 6. Comandos

```bash
# Godot (linha de comando: usar o _console.exe)
export GODOT_BIN="/c/Users/victo/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"

# Python embutido (uma vez por máquina; vai para runtime/, fora do git)
scripts/fetch_python.sh

# Testes
cd executor && python -m pytest                       # executor
cd game && "$GODOT_BIN" --headless --path . --import  # após criar scripts com class_name
cd game && bash addons/gdUnit4/runtest.sh --headless -a res://tests --ignoreHeadlessMode
scripts/test.sh                                        # tudo

# Jogo e console de feitiços
"$GODOT_BIN" --path game
"$GODOT_BIN" --path game res://src/nodes/dev/spell_console.tscn
```

No PowerShell, o executor de testes do Godot é `.\addons\gdUnit4\runtest.cmd` com `$env:GODOT_BIN`.

## 7. Armadilhas conhecidas

- Headless não entrega eventos de input → testes de cena injetam `PlayerIntent`.
- GdUnit4 precisa de `--ignoreHeadlessMode`; o `ERROR: Remote Debugger ... 127.0.0.1:0` na saída é esperado.
- Script novo com `class_name` → rodar `--import` antes dos testes.
- `JSON.parse_string` do Godot devolve números como float → `SpellResult` converte `linha`; comparar com fixtures via `ContractFixtures.normalize`.
- `res://` não alcança a raiz do repo; `PythonSpellExecutor.base_dir()` usa a raiz do repo no editor e a pasta do `.exe` no jogo exportado (o build precisa copiar `executor/` e `runtime/python/` para lá).
- Teste de limite com laço infinito **trava** o pytest enquanto o limite não existe: rodar com `timeout` no comando.
- Feitiços de teste com muitos `print`/ações esgotam a mana padrão (5): dar mana alta.
- GdUnit4 para a suíte no primeiro teste que falha: a contagem total cai; não confiar nela quando há falha.
- `Area2D` recém-criada vê a posição antiga do corpo no primeiro quadro → `Room` liga as áreas só depois do primeiro quadro. Trocar de sala/teleportar dentro de `body_entered`: sempre `call_deferred`.
- Level design: o pulo alcança 3 tiles no limite; degraus de no máximo 2 tiles, e toda sala precisa deixar voltar.
- O `python` do PATH no Windows é o alias da Microsoft Store; usar `runtime/python`.
- Python local do Victor é 3.15; o runtime e o CI usam 3.14. Rodar o pytest também com o 3.14 quando mexer em mensagens de erro ou custo.
- **Para o assistente:** comandos Bash com heredoc contendo Python com barras invertidas ou caminhos do Windows já falharam duas vezes; prefira as ferramentas Write/Edit para criar e alterar arquivos.

## 8. Decisões em aberto

| Decisão | Onde está a proposta |
| --- | --- |
| Ações anteriores a um erro acontecem no mundo? | Sprint 6 |
| Build de fumaça completo (exportar e conjurar no `.exe`) | Passos em `docs/sprints/sprint-02-executor-custo-sandbox.md`; depende dos templates de exportação |
| Lista de peças desbloqueadas entra no protocolo? | Sprint 5 |
| Peças novas para puzzles (runas, símbolo da porta, blocos) e combate (`inimigos`, `alvo.escudo`) | Sprints 9 e 10 |
| Questões do GDD: título, protagonista, motivo do mago, público, C++ | `docs/gdd.md`, fim |

## 9. Próximo passo

Começar a **Sprint 4** (`docs/sprints/sprint-04-grimorio-editor.md`): grimório que abre pausando o jogo, editor com realce de Python e lista de feitiços salva em disco. O console de feitiços (`src/nodes/dev/spell_console.gd`) é o ponto de partida do editor. Perguntar ao Victor se ele jogou a Sprint 3 e o que achou do checklist de sensação.
