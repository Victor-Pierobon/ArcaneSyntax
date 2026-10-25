# Handoff — ArcaneSyntax

> Contexto para começar uma conversa nova sem reler toda a documentação.
> **Atualizado em:** 2026-10-25, fim da Sprint 9.
> **Atualizar** ao fim de cada sprint (ou quando algo aqui deixar de ser verdade).

## 1. O projeto em 30 segundos

Metroidvania 2D em pixel art (Godot 4.7) em que cada feitiço é código Python real. O jogador, preso num livro, sobe uma torre; cada andar ensina conceitos de programação. Projeto solo do Victor Pierobon, em tempo livre, sem prazo fixo. Meta atual: **Alpha = Ato I (Fundações e Masmorra), só Python**, ~12 salas, 6 puzzles, 3 inimigos, 1 chefe, serpente como mentora. Critério de sucesso: um iniciante joga do início ao fim sem ajuda e quer continuar.

Pilares que guiam decisões: código real; o jogador cria os feitiços livremente; mana como custo de execução; o mapa é o currículo; puzzles validam o **estado do mundo**, nunca comparam código com gabarito.

## 2. Onde estamos

| | |
| --- | --- |
| Sprint atual | **Sprint 9 concluída** (os 6 puzzles da Alpha jogáveis e com teste de aceitação; custo de inscrição; estrelas). A próxima é a **Sprint 10** (combate: inimigos). O marco M2 ainda espera o playtest do núcleo |
| Commits | Sprints 0 a 8 commitadas, mais as specs da Sprint 9 (`8e9e035`). **O código da Sprint 9 ainda não**; o Victor revisa e commita |
| Testes | 131 pytest + 265 GdUnit4 (inclui aceitação dos 6 puzzles com Python real), todos verdes localmente; pytest também verde no Python 3.14 |
| CI | Configurado, **ainda não confirmado verde no GitHub** |
| Pendências do Victor | **Playtest do núcleo** (roteiro em `docs/playtest/roteiro-nucleo.md`) e dos Puzzles 2 a 6 (`docs/feiticos-exemplo.md`, seção 4c; calibrar as estrelas do Puzzle 6); Tutorial 2D do Godot; escolher assets provisórios (hoje o jogo usa um tileset provisório de 3 tiles gerado por script); jogar e preencher o checklist de sensação da Sprint 3; conferir o CI; instalar templates de exportação para o build de fumaça; arte conceitual (guia em `docs/arte/guia-de-arte.md`) |

## 3. Regras de trabalho (combinadas com o Victor)

1. **Idioma:** português do Brasil em conversa, docs, specs, nomes de testes e textos do jogo. Código em inglês nos identificadores do Godot; o executor Python usa nomes em português porque são o vocabulário do jogador.
2. **Spec → teste vermelho → código → refatorar.** Toda funcionalidade começa por uma spec em `docs/specs/<area>/` (modelo em `docs/specs/TEMPLATE.md`), com critérios *Dado/Quando/Então* e IDs `AREA-NNN`. Cada critério vira teste com o ID no nome (`test_EXE_019_...`).
3. **TDD estrito** para regras e executor; **teste depois** + checklist manual para sensação (movimento, animação, VFX).
4. **Nunca fazer `git commit` nem `git push`.** Deixar as mudanças na árvore de trabalho, listar o que mudou e sugerir a mensagem de commit.
5. O jogo sempre roda: terminar com as duas suítes verdes.
5a. **Todo bug encontrado vira um teste de regressão** (pedido do Victor, 2026-10-25): primeiro o teste que reproduz o bug e falha, depois a correção. Vale para bugs achados por teste, por captura de tela, jogando ou lendo código. Registrar o bug e o teste no relatório da sprint.
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
| Feitiços prontos para testar (com resultado esperado; manter atualizado se as regras de custo/peças mudarem) | `docs/feiticos-exemplo.md` |
| Roteiro e registros de playtest | `docs/playtest/` |

## 5. Arquitetura em uma tela

- **Godot (`game/`)**: regras puras em `src/core/` (sem Node, testáveis sem cena); Nodes em `src/nodes/`; cliente do executor em `src/executor_client/`.
- **Executor (`executor/`)**: worker Python persistente. O Godot sobe `runtime/python/python.exe -I -S -u executor/run_worker.py` com `OS.execute_with_pipe` e troca **uma linha JSON por requisição**. A ida e volta roda numa `Thread`; `execute()` é usado com `await`.
- **Modelo de execução (ADR-001)**: o jogo manda uma foto do mundo; o executor roda o feitiço inteiro, simulando só a mana do mago, e devolve todas as ações, cada uma com a `linha` que a gerou. O resto do mundo não muda durante a execução.
- **Protocolo v1**: requisição `{versao:1, id, codigo, mundo:{mago:{vida,mana,mana_max}, alvo:{id,elemento,distancia}|null, sala?:{runas:[int]}}, pecas?, regras?}` → resposta `{versao:1, id, ok, acoes:[{tipo,linha,...}], saidas:[{linha,texto}], mago, custo_mana, erro:{tipo,mensagem,linha,coluna}|null}`.
- **Peças**: `lancar(elemento, forma, alvo=None)`, `mover(passos)`, `levitar(altura)`, `meditar()`, `absorver_mana()`, `inscrever(valor)`, `construir_bloco()`. Elementos `fogo/gelo/raio` e formas `projetil/escudo` são strings. Sentidos: `mana`, `mana_max`, `vida_atual`, `alvo` (`.elemento`, `.distancia`, somente leitura), `ler_runa(n)` (a partir de 1; lê `mundo.sala.runas`).
- **Custo de mana (EXE-custo)**: instrução simples custa 0,1, cobrada **depois** de rodar (`return/break/continue/raise`: antes), **mais 0,1 de inscrição na primeira vez que cada linha roda** (Sprint 9: o loop sai mais barato que linhas repetidas); estruturas (`while/if/for/def`…) não custam; peças: `lancar` 3, `mover` 1, `levitar` 2, `inscrever` 1, `construir_bloco` 0,5, `meditar`/`absorver_mana` 0; teto `mana_max` aplicado depois de pagar. Mana interna em décimos inteiros. Feito por **instrumentação da AST** (ganchos `__instrucao__` e `__volta__`).
- **Limites (EXE-limites)**: `ManaEsgotada`, `TempoEsgotado` (1000 ms no worker; watchdog de 3000 ms no Godot), `LimiteExcedido` (1000 ações, 200 saídas); memória do worker limitada a 256 MB. Os limites não podem ser capturados pelo feitiço.
- **Sandbox (EXE-sandbox)**: só `import math`/`random`; nomes `__x` e atributos `_x` proibidos; `except:` e `BaseException` proibidos; builtins em lista branca (sem `open`, `exec`, `eval`…). Violação → `FeiticoProibido` e nada roda.
- **Movimento**: `Player` (CharacterBody2D) chama `PlayerMotor.step(velocity, intent, on_floor, delta)`; a intenção vem de `Player.intent_source` (teclado por padrão; testes injetam). Pulo de 3 tiles, coyote/buffer 0,1 s, esquiva (Shift) de 3 tiles com invulnerabilidade a ataques.
- **Mundo**: cena principal `World` carrega salas de `content/rooms/` (layout em texto: `#` pedra, `=` plataforma, `^` espinhos, `*` ponto seguro, `A–Z` entradas, `a–z` saídas; `exits = {"b": "sala_02:A"}`). `MagoState` (vida 5, mana 0/10) é a mana **real**; `to_spell_mago()` alimenta o executor. Espinho: −1 e volta ao ponto seguro; morte: vida cheia na entrada da sala. `Hud` mostra vida e mana.
- **Conjurar (Sprint 5)**: teclas 1–5 → `World.cast(n)` envia código + `MagoState.to_spell_mago()` + alvo (boneco mais perto em 12 tiles) + `unlocked_pieces`; aplica a **variação** de mana; resultado no `CastLog` (as ações ainda não acontecem no mundo). Grimório: botões 1–5 equipam, **Testar** roda sem gastar mana e marca a linha do erro, custo estimado com mana 1000 e alvo de fogo, autocompletar. Executor recusa peças fora de `pecas` (`PecaBloqueada`). Testes usam `FakeSpellExecutor`.
- **Ações no mundo (Sprint 6)**: `World.cast` → `ActionPlayer.play(result.actions)` (sempre, inclusive com erro) → `WorldActions.act_<tipo>`. Projétil (220 px/s, mira o alvo pelo id), escudo (2 s, bloqueia um ataque), `mover`/`levitar`/`meditar` controlam o mago e devolvem o controle, cajado (J, sem mana). `ElementTable`: fogo > planta, gelo > fogo, raio > gelo; cada um resiste a si mesmo. Bonecos mostram `Fraco!/Resistiu/Acertou`. Tudo congela com o grimório aberto.
- **Passivo (Sprint 7)**: botão **Passivo** no grimório; `World` roda o passivo a cada 1 s via `PassiveScheduler` (sem sobrepor, pausado não roda), aplica a variação de mana, toca as ações no `PassivePlayer`; erro desliga (menos `ManaEsgotada`/`ExecutorIndisponivel`), editar religa; HUD mostra o status. Sons (`Sfx`) e partículas (`Fx`) provisórios, gerados por código.
- **Puzzles (Sprints 8 e 9)**: na cena da sala, `puzzle = {"id", "condicoes", "estrelas"?}`; em `targets`: `cristal`, `cristal:fogo`, `cristal:mutavel[:cargas]`, `runa:4`/`runa:?`, `cadeado:soma`, `gravura:<texto>`; no layout: porta `|`, vão de ponte `~`, placa `_`. Condições: `cristais_acesos`, `cadeados_abertos`, `ponte_completa`, `placas_pisadas`. `PuzzleValidator` decide só pelo estado do mundo; resolvido abre a porta e fica em `World.solved_puzzles` (id → melhor quantidade de estrelas; memória). Estrelas pela mana gasta nos feitiços que agem (`World.room_mana_spent`). Levitar seguido de mover voa (elevador). Passo a passo com a linha destacada (V). **Salas:** Puzzle 1 na sala_01 (a saída só abre resolvido); Puzzles 2 a 6 em `sala_p02` a `sala_p06`, depois da saída de baixo à direita da sala_03 (provisório). Testes de aceitação em `tests/acceptance/` com o `PuzzleDriver` (sala do jogo + Python real).
- **Grimório**: Tab abre (pausa o mundo), Esc fecha. `Grimoire` (modelo; nomes até 24, únicos sem diferenciar maiúsculas; sinais de renomear/apagar para os slots), `GrimoireStore` (`user://grimorio.json`, gravação atômica, `.bak` se o arquivo estiver ilegível), `GrimoireUI` (lista + `CodeEdit` com realce de Python e das peças do jogo). Ainda não executa feitiços.
- **Contrato**: `tests/contract/*.json` é verificado pelas duas suítes.

Classes principais: `PlayerIntent`, `PlayerMotor`, `Player`, `Health`, `MagoState`, `RoomLayout`, `Room`, `World`, `Hud`, `CastLog`, `TrainingTarget`, `ActionPlayer`, `WorldActions`, `Projectile`, `Shield`, `ElementTable`, `PassiveScheduler`, `Sfx`, `Fx`, `PuzzleValidator`, `MutableCrystalRule`, `Crystal`, `Rune`, `RuneLock`, `Bridge`, `PressurePlate`, `RuneDoor`, `StepView`, `Grimoire`, `GrimoireStore`, `GrimoireUI`, `PythonHighlighter`, `SpellReport`, `CompletionProvider`, `SpellExecutor`, `PythonSpellExecutor`, `SpellRequest`, `SpellResult`, `SpellError`, `ContractFixtures` e `PuzzleDriver` (testes). Python: `pieces.Contexto`, `runner.run_spell`, `protocol.handle_request` / `handle_line`, `worker.main`.

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
- **Testes e jogo compartilham `user://`**: todo teste que cria `World` ou mexe no grimório usa `user://tests/…` (`world.grimoire_path`) e apaga no `after_test`. Teste que pausa a árvore despausa no `after_test`.
- Captura de tela por script (`godot --path game -s script.gd`) já pegou bugs visuais que os testes não pegam (Sprints 4 e 5); vale repetir ao mexer em interface.
- `PackedStringArray([...])` não é constante em GDScript; corrotina não pode ser guardada para esperar depois (espere um sinal).
- `physics_frame` da árvore chega mesmo pausado: para esperar em tempo de jogo use `create_timer(t, false, true)`.
- O teste de mutação já pegou testes fracos em duas sprints seguidas (5 e 6); manter o hábito ao fim de cada sprint.
- O grimório aberto pede estimativa de custo (mana 1000) mesmo pausado; testes que contam requisições filtram essas.
- O `python` do PATH no Windows é o alias da Microsoft Store; usar `runtime/python`.
- Python local do Victor é 3.15; o runtime e o CI usam 3.14. Rodar o pytest também com o 3.14 quando mexer em mensagens de erro ou custo.
- **Para o assistente:** comandos Bash com heredoc contendo Python com barras invertidas ou caminhos do Windows já falharam **quatro** vezes (duas na Sprint 9); prefira as ferramentas Write/Edit, ou um script `.py` escrito com Write. Script Python que grava com `write_text` no Windows gera CRLF: use `write_bytes`.
- `ActionPlayer.play` com só ações desconhecidas emite `finished` antes de devolver; um `await finished` depois disso trava o teste.
- O Python 3.14 embutido não tem pytest: rode-o com o pytest do Python local no `sys.path` (comando em `docs/arquitetura.md`, armadilhas).
- As salas `sala_p0N` foram geradas por script (geometria do elevador exata: colunas de 2 tiles coladas, alturas = degrau + 1). Mexer à mão exige rodar a aceitação de novo.

## 8. Decisões em aberto

| Decisão | Onde está a proposta |
| --- | --- |
| ~~Ações anteriores a um erro acontecem no mundo?~~ | **Decidido pelo Victor (2026-10-25): sim**, as ações parciais acontecem |
| Build de fumaça completo (exportar e conjurar no `.exe`) | Passos em `docs/sprints/sprint-02-executor-custo-sandbox.md`; depende dos templates de exportação |
| ~~Lista de peças desbloqueadas entra no protocolo?~~ | **Decidido (2026-10-25):** sim, o executor recusa peças bloqueadas (opção recomendada; o Victor não se opôs) |
| ~~Peças novas para puzzles~~ | **Feito na Sprint 9** (`ler_runa`, `inscrever`, `construir_bloco`) |
| Peças de combate (`inimigos`, `alvo.escudo`) | Sprint 10 |
| Loop que lança várias vezes no cristal mutável falha por causa do ADR-001 (o feitiço vê o mundo da hora da conjuração) | `PUZ-03-simbolo.md`; proposta: a serpente explica na Sprint 13 |
| Limites das estrelas do Puzzle 6 (20/24) | `PUZ-06-revisao.md`; calibrar no playtest |
| Questões do GDD: título, protagonista, motivo do mago, público, C++ | `docs/gdd.md`, fim |

## 9. Próximo passo

1. Perguntar ao Victor sobre o **playtest do núcleo** e dos **Puzzles 2 a 6** (ainda pendente; fecha o M2 e calibra as estrelas).
2. Começar a **Sprint 10** (`docs/sprints/sprint-10-combate-inimigos.md`): inimigos. **Primeiro** listar as peças e sentidos novos (`inimigos`, `alvo.escudo`, vida dos inimigos) e atualizar `EXE-pecas`, o protocolo (campos opcionais, sem quebrar a v1) e as specs de combate; o balanceamento já deve usar o custo com inscrição.
