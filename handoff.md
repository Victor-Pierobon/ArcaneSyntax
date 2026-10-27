# Handoff — ArcaneSyntax

> Contexto para começar uma conversa nova sem reler toda a documentação.
> **Atualizado em:** 2026-10-27, Sprint 21 concluída (feixe, chefe mais rápido, magia mais cara).
> **Atualizar** ao fim de cada sprint (ou quando algo aqui deixar de ser verdade).

## 1. O projeto em 30 segundos

Metroidvania 2D em pixel art (Godot 4.7) em que cada feitiço é código Python real. O jogador, preso num livro, sobe uma torre; cada andar ensina conceitos de programação. Projeto solo do Victor Pierobon, em tempo livre, sem prazo fixo. Meta atual: **Alpha = Ato I (Fundações e Masmorra), só Python**, ~12 salas, 6 puzzles, 3 inimigos, 1 chefe, serpente como mentora. Critério de sucesso: um iniciante joga do início ao fim sem ajuda e quer continuar.

Pilares que guiam decisões: código real; o jogador cria os feitiços livremente; mana como custo de execução; o mapa é o currículo; puzzles validam o **estado do mundo**, nunca comparam código com gabarito.

## 2. Onde estamos

| | |
| --- | --- |
| Sprint atual | **Alpha 1.1** (`docs/plano-alpha-1-1.md`): **Sprint 21 concluída** (pedido do Victor: o `feixe`, aprendido na `sala_c03`; o chefe mais rápido e com mais pressão; `lancar` 4, faísca 1,5, meditar de 1 s; tiros atravessam plataformas). **Próxima: Sprint 22** (fechamento da 1.1: capturas, ajustes, build `ArcaneSyntax-alpha-1.1.zip`, roteiro de teste). O Victor faz a arte em paralelo; nenhuma arte nova desde a Sprint 16 |
| Commits | Sprints 0 a 20 e o plano da 1.1 commitados. **A Sprint 21 ainda não**; o Victor revisa e commita |
| Testes | 149 pytest + 626 GdUnit4 (+ 32 do gerador de sprites) (inclui aceitação dos 6 puzzles, dos 3 inimigos, do chefe 2.1, do feixe, dos 5 baús e **da Alpha inteira**, com Python real, e a fumaça do build), todos verdes localmente |
| CI | Configurado, **ainda não confirmado verde no GitHub** |
| Pendências do Victor | **Sprites por IA (PixelLab, 40 gerações/mês):** primeira leva pronta e ligada no jogo; `refazer objetos/porta` (veio com moldura e não se repete na vertical); o **chefe** está na fila (~19 gerações; `chefe_base` para aprovar; o jogo já lê `chefe/` desde a Sprint 17), esperando o PixelLab voltar a aceitar conta gratuita; depois: runas, cadeado, placa, ponte, fonte, `bau_abrindo`; **pacote de cenário** recolorido para a paleta do `docs/arte/ArcaneSyntax_Guia_de_Estilo_Visual.md`; revisar as decisões por recomendação do `plano-alpha-1-1.md`; revisar as decisões das Sprints 12 a 15 tomadas por recomendação (ver os relatórios); calibrar valores no `balanceamento.json` se quiser (estrelas do Puzzle 6 continuam na cena da sala); Tutorial 2D do Godot; preencher o checklist de sensação da Sprint 3; conferir o CI; arte conceitual (guia em `docs/arte/guia-de-arte.md`) |

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
- **Protocolo v1**: requisição `{versao:1, id, codigo, mundo:{mago:{vida,mana,mana_max}, alvo:{id,elemento,distancia,vida?,escudo?}|null, sala?:{runas:[int]}, inimigos?:[{id,elemento,distancia,vida?,escudo?}]}, pecas?, regras?}` → resposta `{versao:1, id, ok, acoes:[{tipo,linha,...}], saidas:[{linha,texto}], mago, custo_mana, erro:{tipo,mensagem,linha,coluna}|null}`.
- **Peças**: `lancar(elemento, forma, alvo=None)`, `mover(passos)`, `levitar(altura)`, `meditar()`, `absorver_mana()`, `inscrever(valor)`, `construir_bloco()`. Elementos `fogo/gelo/raio` e formas `projetil/escudo/faisca/feixe` são strings (o `feixe` começa bloqueado). Sentidos: `mana`, `mana_max`, `vida_atual`, `alvo` (`.elemento`, `.distancia`, `.vida`, `.escudo`, somente leitura; os dois últimos `None` fora dos inimigos), `inimigos` (lista de alvos, do mais perto para o mais longe, até 12 tiles), `ler_runa(n)` (a partir de 1; lê `mundo.sala.runas`).
- **Balanceamento (Sprint 11, BAL-valores)**: `game/content/balanceamento.json` (seções `mago`, `executor`, `dano`, `elemental`, `enxame`, `guardiao`, `chefe` e, desde a Sprint 12, `xp` e `niveis`) é o único lugar dos números de dificuldade e custo; `Balance.number/integer/list(seção, chave)`, `Balance.rules()` vai como `regras` em toda requisição (World e grimório). `REGRAS_PADRAO` do executor tem que ser igual à seção `executor` (pytest `test_balanceamento.py`). Sensação (pulo, esquiva, empurrão) fica fora.
- **Custo de mana (EXE-custo)**: instrução simples custa 0,1, cobrada **depois** de rodar (`return/break/continue/raise`: antes), **mais 0,1 de inscrição na primeira vez que cada linha roda** (Sprint 9: o loop sai mais barato que linhas repetidas); estruturas (`while/if/for/def`…) não custam; peças: `lancar` 4 (com `faisca`, 1,5; com `feixe`, 8; Sprint 21), `mover` 1, `levitar` 2, `inscrever` 1, `construir_bloco` 0,5, `meditar`/`absorver_mana` 0; teto `mana_max` aplicado depois de pagar. Mana interna em décimos inteiros. Feito por **instrumentação da AST** (ganchos `__instrucao__` e `__volta__`).
- **Limites (EXE-limites)**: `ManaEsgotada`, `TempoEsgotado` (1000 ms no worker; watchdog de 3000 ms no Godot), `LimiteExcedido` (1000 ações, 200 saídas); memória do worker limitada a 256 MB. Os limites não podem ser capturados pelo feitiço.
- **Sandbox (EXE-sandbox)**: só `import math`/`random`; nomes `__x` e atributos `_x` proibidos; `except:` e `BaseException` proibidos; builtins em lista branca (sem `open`, `exec`, `eval`…). Violação → `FeiticoProibido` e nada roda.
- **Movimento**: `Player` (CharacterBody2D) chama `PlayerMotor.step(velocity, intent, on_floor, delta)`; a intenção vem de `Player.intent_source` (teclado por padrão; testes injetam). Pulo de 3 tiles, coyote/buffer 0,1 s, esquiva (Shift) de 3 tiles com invulnerabilidade a ataques.
- **Mundo**: cena principal `World` carrega salas de `content/rooms/` (layout em texto: `#` pedra, `=` plataforma, `^` espinhos, `*` ponto seguro, `A–Z` entradas, `a–z` saídas; `exits = {"b": "sala_02:A"}`). `MagoState` (vida 5, mana 0/10) é a mana **real**; `to_spell_mago()` alimenta o executor. Espinho: −1 e volta ao ponto seguro; morte: vida cheia na entrada da sala. `Hud` mostra vida e mana.
- **Conjurar (Sprint 5)**: teclas 1–5 → `World.cast(n)` envia código + `MagoState.to_spell_mago()` + alvo (boneco mais perto em 12 tiles) + `unlocked_pieces`; aplica a **variação** de mana; resultado no `CastLog` (as ações ainda não acontecem no mundo). Grimório: botões 1–5 equipam, **Testar** roda sem gastar mana e marca a linha do erro, custo estimado com mana 1000 e alvo de fogo, autocompletar. Executor recusa peças fora de `pecas` (`PecaBloqueada`). Testes usam `FakeSpellExecutor`.
- **Ações no mundo (Sprint 6)**: `World.cast` → `ActionPlayer.play(result.actions)` (sempre, inclusive com erro) → `WorldActions.act_<tipo>`. Projétil (220 px/s, mira o alvo pelo id), escudo (2 s, bloqueia um ataque), `mover`/`levitar`/`meditar` controlam o mago e devolvem o controle, cajado (J, sem mana). `ElementTable`: fogo > planta, gelo > fogo, raio > gelo; cada um resiste a si mesmo. Bonecos mostram `Fraco!/Resistiu/Acertou`. Tudo congela com o grimório aberto.
- **Passivo (Sprint 7)**: botão **Passivo** no grimório; `World` roda o passivo a cada 1 s via `PassiveScheduler` (sem sobrepor, pausado não roda), aplica a variação de mana, toca as ações no `PassivePlayer`; erro desliga (menos `ManaEsgotada`/`ExecutorIndisponivel`), editar religa; HUD mostra o status. Sons (`Sfx`) e partículas (`Fx`) provisórios, gerados por código.
- **Puzzles (Sprints 8 e 9)**: na cena da sala, `puzzle = {"id", "condicoes", "estrelas"?}`; em `targets`: `cristal`, `cristal:fogo`, `cristal:mutavel[:cargas]`, `runa:4`/`runa:?`, `cadeado:soma`, `gravura:<texto>`; no layout: porta `|`, vão de ponte `~`, placa `_`. Condições: `cristais_acesos`, `cadeados_abertos`, `ponte_completa`, `placas_pisadas`. `PuzzleValidator` decide só pelo estado do mundo; resolvido abre a porta e fica em `World.solved_puzzles` (id → melhor quantidade de estrelas; memória). Estrelas pela mana gasta nos feitiços que agem (`World.room_mana_spent`). Levitar seguido de mover voa (elevador). Passo a passo com a linha destacada (V). **Salas:** Puzzle 1 na sala_01 (a saída só abre resolvido); Puzzles 2 a 6 em `sala_p02` a `sala_p06`, depois da saída de baixo à direita da sala_03 (provisório). Testes de aceitação em `tests/acceptance/` com o `PuzzleDriver` (sala do jogo + Python real).
- **Combate (Sprint 10)**: em `targets`, `inimigo:elemental[:fogo|gelo|planta]` (vida 12, patrulha e persegue no chão), `inimigo:enxame[:n]` (bichos de gelo, vida 2, voam, mergulham e recuam), `inimigo:guardiao` (vida 18, escudo fogo → planta → gelo de 4 s com 1 s de brecha; só passa o elemento que vence o escudo). Regras puras em `src/core/combat/` (`Damage`: projétil 3, faísca 1, cajado 1 × multiplicador, truncado; `ElementalBrain`, `SwarmBugBrain`, `GuardianShield`); nós em `src/nodes/combat/` (`Enemy` herda de `TrainingTarget`). Contato tira 1 de vida e empurra (`PlayerMotor.knock_back`); bloquear com escudo dá 1 s de invencibilidade. O projétil persegue o alvo e só acerta ele. Inimigos reaparecem (a sala é montada de novo). Salas `sala_c01..c03` depois da porta do Puzzle 6 (provisório). Aceitação em `tests/acceptance/test_combate_0N.gd`.
- **Chefe (Sprints 11 e 17, COM-chefe 2.0)**: `inimigo:chefe` (vida 90) com `chefe:ponto` (pontos no ar) e `chefe:investida` (dois no chão) em `targets`. `BossPhases`: fogo → gelo (≤ 60) → planta (≤ 30), nenhum golpe pula um limite, transição de 1,5 s invulnerável que cancela o ataque. `BossBrain` (regra pura): espera 2 s e repete mover → aviso → ataque → descanso; ataques por fase em `balanceamento.json` (`ataques`: leque; pilares, leque; investida, pilares, leque); devolve eventos que o `Boss` aplica (`BossBolt` em leque, `BossPillar` com marca e contorno na frente do mago, faixa da investida). O chefe é alvo a qualquer distância (`Enemy.any_distance`; o `Projectile` que o persegue não tem o limite de 12 tiles). Derrotado: abre a porta `|`, limpa marcas e orbes e não volta (`World.defeated_bosses`, `Room.boss_beaten`, `boss_defeated`); morrer traz o chefe inteiro. Arena `sala_c04` (40×22) depois da saída à direita da `sala_c03`.
- **Salas e plataformas (Sprint 18, MUN-salas, MUN-plataformas)**: no layout, `-` (plataforma que cai: treme 0,5 s, cai, volta em 3 s; avermelhada), `>` (que se move, 48 px/s, pausa de 0,5 s nas pontas) e `+` (o outro extremo, na linha ou na coluna). Regras puras `PlatformPath`, `FallingPlatformRule`, `WalkMap` (alcance a pé: vão de 4/3/2 para chão na mesma altura/1/2 acima); nós `MovingPlatform`, `FallingPlatform`. As 13 salas têm pelo menos 40×22; todas menos a arena (`sala_c04`) saem de `scripts/salas/salas18.py` (Sprints 18 e 19); `test_rooms_walk.gd` confere, nas 13, volta a pé, alcance do puzzle e da fonte e toda saída a pé (menos as do elevador da `p05` e da `p06`). Tocha: `!` no layout (desde a Sprint 19; `tocha` em `targets` ainda vale). Inimigos: grupos mistos parados (elemental com enxame) longe do lugar de cada luta de aceitação. 5 baús (`sala_01`, `02`, `03`, `p03`, `p06`). HUD: atalhos no bloco do topo, teclas na última faixa.
- **Brilho (Sprint 20, ART-brilho)**: `Lighting` (escuro do mundo por `CanvasModulate`, `PointLight2D` nos que brilham, `keep_readable` nos textos do mundo), `ParticleStyle` + `Fx.element_burst`, `CameraShake` + `World.shake`/`hit_stop` (golpes do chefe chegam pela `Room.boss_struck`), opção `Settings.screen_shake`, `CodeRune` (linha de cada ação), `UiSkin` (moldura e logo). Chefe calibrado: voo a 100 px/s, descansos 1,0/0,8/0,6 s.
- **Feixe e custos (Sprint 21, MAG-feixe)**: forma `feixe` (custo 8, dano 6; carrega 0,5 s parado; atravessa todos na linha até pedra ou porta); começa bloqueada (`MagoState.LOCKED_AT_START`) e a lição `ensino_feixe` (serpente da `sala_c03`) libera (`World.LESSON_UNLOCKS`). `lancar` custa 4, faísca 1,5; meditar leva 1 s. Plataformas na camada `Room.PLATFORM_LAYER`: tiros atravessam. Chefe: 140 px/s, descansos 0,7/0,5/0,4 s, leque mira 0,3 s adiante, orbes com os pilares na fase 3.
- **Progressão (Sprint 12, PRO-xp, PRO-niveis)**: `MagoState.xp`/`level`/`gain_xp` (sinais `xp_changed`, `leveled_up`); `Progression` (estática) com a curva e a XP do puzzle. Inimigo derrotado dá `Enemy.xp` (também os que reaparecem); puzzle dá 20 + 5 por estrela acima de uma, só na primeira vez. Subir de nível aumenta e enche a mana. `Enemy.setup(id, elemento, tipo, tamanho)`: o tipo é a seção do balanceamento. HUD: `Nível 2 · XP 45/70`.
- **Diálogo (Sprint 12, NAR-dialogo)**: `content/dialogos.json` (falas com `proxima` ou `opcoes`, textos como chaves do `textos.csv`); `DialogueBook` valida e aponta cena e fala; `DialogueRun` lê; `DialogueBox` no alto da tela pausa o jogo. `serpente:<cena>` em `targets`; `World.talk()` (E) com a serpente a até 2 tiles; o grimório não abre durante o diálogo (`GrimoireUI.blocked`). Cena de teste `serpente_ola` na `sala_01`.
- **Referência (Sprint 12, GRI-referencia)**: `content/referencia.json` (ordem e peças exigidas); textos `REF_<ID>_TITULO/_TEXTO` com BBCode e `\n`; `ReferenceBook`; aba Referência no `GrimoireUI` (`show_reference`, `select_page`).
- **Lições e dicas (Sprint 13, NAR-serpente, NAR-dicas)**: uma serpente `ensino_<conceito>` em cada sala de puzzle; a lição conta quando aparece a fala `licao`. Depois dela, com o puzzle aberto, `World.talk()` oferece a próxima dica (`HintBook.scene`, de `content/dicas.json`, 3 por puzzle, com a pergunta "Quer uma dica?"); resolvido, repete a lição. `World.seen_lessons`, `World.hints_used`.
- **Mapa (Sprint 14, MUN-mapa, MUN-segredos)**: 13 salas; caminho `sala_01` → `02` → `03` → `p02`…`p06` → `c01`…`c04` → `sala_fim`; atalho de mão única `sala_c01` → `sala_01` (porta `%`, abre quando o mago entra pela `atalho_entrada`; `World.opened_shortcuts`). Toda porta vai do chão ao teto (com `levitar`, o mago voa). Cada puzzle declara `licoes`. `AreaMap` (flood fill sem gravidade) testa volta, portas e ordem dos conceitos. `segredo` em `targets` = baú (`Chest`, +`xp.segredo` uma vez, `World.found_secrets`); `fonte` = `Fountain` (E enche vida e mana). Todo baú tem um caminho com feitiço e um só com movimento (pedido do Victor).
- **Menus (Sprint 14, UI-menus)**: `Main` abre no `TitleMenu` (Continuar só com save; Novo jogo pergunta e apaga só o `save.json`); `PauseMenu` (Esc com o jogo correndo); `OptionsMenu` + `Settings` (`<perfil>/opcoes.json`; texto +0/+2/+3 via `FontScale`, volume); `EndScreen` (sinal `World.demo_finished` da cena `fim_demo`, `World.summary()`). Com texto maior que Normal, a caixa de diálogo sobe e cobre o HUD.
- **Save (Sprint 13, SAV-progresso)**: cena principal `Main` (`main.tscn`) usa `user://perfis/padrao/` (`grimorio.json`, copiado do antigo, e `save.json` com `versao` 1). `World.save_path` vazio = sem save (os testes sobem o `World` direto e nunca tocam no progresso). `ProgressStore` grava de forma atômica; ilegível ou versão nova → `.bak` e jogo do zero. Grava ao entrar em sala, resolver puzzle, vencer chefe, subir de nível, terminar diálogo, abrir baú, beber na fonte, voltar ao menu e fechar; desde a Sprint 14 guarda `segredos` e `atalhos`. Para ir direto a uma sala no editor: **F6 no `world.tscn`** (sem save, sem menu e sem pausa; F5 abre o menu).
- **Arte (Sprint 16, ART-esteira)**: contrato em `content/arte.json` (`ArtCatalog` confere cada PNG: quadro, nome, pixel semitransparente, cor fora de `assets/paleta.png`); `ArtLibrary` lê `assets/<pasta>/<nome>.png` (null sem arquivo: o chamador usa o provisório; testes usam `use_root` + `reset`). Mago: `PlayerAnimation` (regra pura) + `PlayerVisual` (nó `Visual`; arte ou mago desenhado por código); `Player.play_action`/`hurt`. Paredes: `TileShape` (número de 4 bits da vizinhança → atlas 4×5) e `Room.tileset_for` (tileset por código). Fundo: `Backdrop` (3 `Parallax2D` + moldura escura em volta da sala). Inimigos, serpente, projétil e escudo têm `art_sprite`. Provisório gerado por `tools/gerar_provisorio.gd`. Desenho 2D preso aos pixels. **Primeira leva de arte (PixelLab) ligada:** mago, serpente, inimigos (andar, morrer, mergulhar, escudo do guardião), magias (projétil, faísca, impacto, escudo, aura de meditar), cristal, porta, baú e tocha (`tocha` em `targets` = `Torch`, decoração). `ArtLibrary.effect` (efeito de uma vez), `TrainingTarget.top_height()` (nome e barra acima do desenho).
- **Build (Sprint 15, BLD-alpha)**: `game/export_presets.cfg` (Windows Desktop, `.pck` separado, `.console.exe`, leva `content/*.json`, sem `tests/` e `addons/gdUnit4/`). `scripts/build_windows.ps1` exporta, copia `executor/` e `runtime/python/` enxuto, roda `ArcaneSyntax.console.exe --headless -- --fumaca` e gera o `.zip`. `SmokeCheck` (`src/nodes/main/smoke_check.gd`) confere conteúdo, textos, mapa e executor; a `Main` cria os menus só depois da fumaça. Aceitação da Alpha inteira: `tests/acceptance/test_alpha_completa.gd` (MUN-085).
- **Grimório**: Tab abre (pausa o mundo), Esc fecha. `Grimoire` (modelo; nomes até 24, únicos sem diferenciar maiúsculas; sinais de renomear/apagar para os slots), `GrimoireStore` (`user://grimorio.json`, gravação atômica, `.bak` se o arquivo estiver ilegível), `GrimoireUI` (lista + `CodeEdit` com realce de Python e das peças do jogo). Ainda não executa feitiços.
- **Contrato**: `tests/contract/*.json` é verificado pelas duas suítes.

Classes principais: `PlayerIntent`, `PlayerMotor`, `Player`, `Health`, `MagoState`, `RoomLayout`, `Room`, `World`, `Hud`, `CastLog`, `TrainingTarget`, `ActionPlayer`, `WorldActions`, `Projectile`, `Shield`, `ElementTable`, `PassiveScheduler`, `Sfx`, `Fx`, `PuzzleValidator`, `MutableCrystalRule`, `Damage`, `ElementalBrain`, `SwarmBugBrain`, `GuardianShield`, `BossPhases`, `BossBrain`, `BossPillar`, `Balance`, `Progression`, `Enemy`, `Elemental`, `SwarmBug`, `Guardian`, `Boss`, `BossBolt`, `DialogueBook`, `DialogueRun`, `DialogueBox`, `Serpent`, `ReferenceBook`, `HintBook`, `ProgressStore`, `Main`, `AreaMap`, `ArtCatalog`, `ArtLibrary`, `PlayerAnimation`, `PlayerVisual`, `TileShape`, `Backdrop`, `Chest`, `Fountain`, `Settings`, `FontScale`, `MenuPanel`, `TitleMenu`, `PauseMenu`, `OptionsMenu`, `EndScreen`, `Crystal`, `Rune`, `RuneLock`, `Bridge`, `PressurePlate`, `RuneDoor`, `StepView`, `Grimoire`, `GrimoireStore`, `GrimoireUI`, `PythonHighlighter`, `SpellReport`, `CompletionProvider`, `SpellExecutor`, `PythonSpellExecutor`, `SpellRequest`, `SpellResult`, `SpellError`, `ContractFixtures` e `PuzzleDriver` (testes). Python: `pieces.Contexto`, `runner.run_spell`, `protocol.handle_request` / `handle_line`, `worker.main`.

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

# Sprites por IA (PixelLab; chave em PIXELLAB_API_TOKEN; spec ART-gerador)
py -3 scripts/sprites/gerar.py status | rodar [--simular] | aprovar <id> | refazer <id> | saldo
py -3 -m pytest scripts/sprites/tests                 # testes da ferramenta (precisa do Pillow)

# Build da Alpha (PowerShell, na raiz; precisa dos templates de exportação do 4.7.2)
#   $env:GODOT_BIN = "C:\...\Godot_v4.7.2-stable_win64_console.exe"; .\scripts\build_windows.ps1
#   → build/ArcaneSyntax/ e build/ArcaneSyntax-alpha.zip; a fumaça roda no .exe exportado

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
- As salas `sala_p0N` e `sala_c0N` foram geradas por script (geometria do elevador exata: colunas de 2 tiles coladas, alturas = degrau + 1). Mexer à mão exige rodar a aceitação de novo.
- Inimigo derrotado some 0,4 s depois: em teste, guarde o que precisa pelos sinais (`was_hit`, `defeated`), não lendo o nó depois.
- Captura de tela por script: espere `physics_frame` (a janela desenha muito mais rápido que a física; com `process_frame` o mundo quase não anda).
- `Balance` é estático e guarda o arquivo: teste que usa `Balance.use_file` chama `Balance.reset()` no `after_test`, senão os números trocados vazam para as suítes seguintes. Mudar um custo do executor exige mudar o `balanceamento.json` **e** o `REGRAS_PADRAO` (o pytest avisa).
- Teste de aceitação longo com inimigo que ataca à distância: dê vida de sobra ao mago (`health.maximum = 99; restore_full()`) e reponha a posição antes de cada conjuração (o empurrão tira o alvo do alcance).
- **Para o assistente:** não deixe `python -` (ou outro comando que lê a entrada) solto num comando Bash: ele espera para sempre e o comando estoura o tempo (Sprint 11).
- **Para o assistente (Sprint 12):** o Bash da ferramenta às vezes sobe com caminhos `/cygdrive/c/...` e **não enxerga a pasta Downloads** (onde está o Godot). Nesse caso, rode o Godot e o GdUnit4 pelo PowerShell (`$env:GODOT_BIN = "C:\...\Godot_v4.7.2-stable_win64_console.exe"; .\addons\gdUnit4\runtest.cmd ...` dentro de `game/`) e use caminhos relativos no Bash. Nesse Bash (cygwin), `grep -c $'\r'` acusa CR em arquivos que são LF: confira fins de linha com `git ls-files --eol <arquivo>`.
- Os `ERROR: Parse JSON failed` na saída dos testes vêm dos testes de arquivo ilegível (balanceamento, diálogos, referência) e são esperados.
- Teste novo de cena com texto na tela: compare com `tr("CHAVE")` (o `textos.csv` é carregado nos testes). Chave nova no CSV pede `--import` antes de rodar.
- **Conteúdo novo de fala ou dica:** `test_NAR_005_toda_fala_cabe_na_caixa` abre todas e confere que a caixa não passa da metade da tela; no máximo ~4 linhas por fala. As páginas e dicas citam custos como texto: revise-as se o balanceamento mudar.
- Teste que precisa do save cria o `World` com `save_path = "user://tests/…"` e apaga o arquivo (e o `.bak`) no `after_test`; nunca use o caminho do perfil.
- **Level design (Sprint 14):** porta baixa numa sala alta não bloqueia, porque `levitar` está liberado desde o começo. Toda porta vai do chão ao teto; `test_area_map.gd` pega o erro. Sala nova ou saída nova: rode `test_area_map.gd` (volta, portas e ordem dos conceitos; o total de salas está no teste).
- Menus em teste: aperte os botões com `pressed.emit()` e use `PauseMenu.handle_cancel()` no lugar do Esc. A `Main` abre no menu: chame `continue_game()` ou `new_game()` para ter `main.world`.
- **Para o assistente (Sprint 14):** no Bash (cygwin), o `python` é o do Windows e não enxerga `/tmp/arquivo`, a não ser que o caminho vá como argumento do script (`python /tmp/e.py` funciona; `pathlib.Path("/tmp/x")` dentro do script não). Use `cygpath -w` ou o scratchpad.
- **Build:** arquivo novo em `content/` que não é `.json` nem recurso importado não vai para o `.exe` sozinho: ajuste o `include_filter` do preset e rode o script (a fumaça pega os JSON). O teste da Alpha inteira (`test_alpha_completa.gd`) roda ~1 min; mexeu numa sala, num puzzle ou numa saída, ele precisa continuar verde.
- **PowerShell 5.1:** `.ps1` com acento precisa de UTF-8 **com BOM** (o `build_windows.ps1` tem); programa nativo que escreve no stderr vira erro com `ErrorActionPreference = Stop`, então o script decide pela saída (`$LASTEXITCODE`). **Para o assistente:** rodar com `-ExecutionPolicy Bypass` foi negado pelo modo automático; chame `& .\scripts\build_windows.ps1` direto.
- **Para o assistente (Sprint 15):** o Bash da ferramenta voltou a ser o Git Bash (`/c/...`); caminho do Windows para o `python` vai como argumento entre aspas simples.
- **Arte (Sprint 16):** arte provisória nova ou mudada: `godot --headless --path game -s res://tools/gerar_provisorio.gd` e depois `--import`. Teste que troca a pasta de arte chama `ArtLibrary.reset()` e `ArtFixtures.clear()` no `after_test`. Captura de tela ampliada (recorte em volta de um nó) achou dois bugs nesta sprint; vale repetir ao mexer em visual. O PowerShell da ferramenta pode voltar para a raiz do repo entre chamadas: use `--path` absoluto. As variantes do contrato têm que ser as do jogo (`test_ART_001_variantes_iguais_as_do_jogo`); mudou um elemento no jogo, mude `arte.json` e `scripts/sprites/fila.json`. Variante de cor nova sai de graça com `troca_cor` na fila.
- **Chefe (Sprint 17):** os testes de cena do chefe trocam o balanceamento por um com tempos curtos (`_use_balance`, `Balance.reset()` no `after_test`); a fase 1 tem `pilar_marcas` 0, então teste que força pilares na fase 1 diz quantas marcas quer. O `BossBrain` compara tempos com uma folga (`EPSILON`): somar passos de 1/60 s não fecha exato e cada etapa ganhava um quadro. As plataformas `=` param projéteis e orbes: na arena, conjure de onde não há plataforma acima (os testes usam a plataforma alta, célula (12, 16)). A HUD de baixo cobre o chão das salas do tamanho da tela.
- **Salas (Sprint 18):** as salas refeitas saem de `scripts/salas/salas18.py`; mexer à mão numa delas sem passar para o script faz a mudança sumir na próxima geração. Sala nova ou mudada: `test_rooms_walk.gd`, `test_area_map.gd`, a aceitação do puzzle e dos segredos dela e a Alpha inteira. `targets` só aceita os dígitos `1` a `9`: para decoração, use `!` (tocha) no layout. Na arena do chefe, a plataforma para o projétil que desce: teste que conjura de cima dela usa `driver.wait_boss_above(boss)`. Inimigo perto de um puzzle vira o `alvo` dos feitiços do puzzle (o mais perto em 12 tiles): deixe os inimigos a mais de 12 tiles do lugar onde se conjura. **Para o assistente:** heredoc com Python com barras invertidas falhou de novo (quinta vez); para scripts com `
- **Brilho (Sprint 20):** texto novo dentro da sala (`Label` filho de algo do mundo) precisa de `Lighting.keep_readable`, senão escurece; `test_ART_060_textos_do_mundo_nao_escurecem` pega. O congelamento muda `Engine.time_scale`: teste que pode parar no meio de um congelamento volta a escala a 1 no `after_test`. A luta COM-094/095 é sensível a pequenas mudanças de tempo: se ela virar, meça as duas lutas (tempo, vida do mago e do chefe) antes de mexer no balanceamento. No Godot 4, um objeto liberado não passa em `!= null`: use `is_instance_valid`.
- **Custos (Sprint 21):** mudar um custo do executor mexe em muita coisa: `REGRAS_PADRAO` e `balanceamento.json` (o pytest avisa), os contratos `tests/contract/*.json` (regenere só os campos de custo, como na Sprint 21), as aceitações que conferem custo (puzzles 4 e 6 e as estrelas, enxame, chefe), os textos da Referência e `docs/feiticos-exemplo.md`. O Puzzle 1 precisa de `meditar()` (+5) e um `lancar` com as linhas: `lancar` acima de 4,6 quebra o primeiro puzzle. A luta COM-094/095 é medida por robôs: se ela virar, registre de onde vêm os golpes (estado do chefe a cada dano) antes de mexer no balanceamento.
` ou aspas escapadas, use a ferramenta Write.

## 8. Decisões em aberto

| Decisão | Onde está a proposta |
| --- | --- |
| ~~Ações anteriores a um erro acontecem no mundo?~~ | **Decidido pelo Victor (2026-10-25): sim**, as ações parciais acontecem |
| ~~Build de fumaça completo~~ | **Feito na Sprint 15** (BLD-alpha; templates instalados com o aval do Victor) |
| Ícone e assinatura do `.exe` (SmartScreen avisa) | `BLD-alpha.md`, perguntas em aberto |
| ~~Lista de peças desbloqueadas entra no protocolo?~~ | **Decidido (2026-10-25):** sim, o executor recusa peças bloqueadas (opção recomendada; o Victor não se opôs) |
| ~~Peças novas para puzzles~~ | **Feito na Sprint 9** (`ler_runa`, `inscrever`, `construir_bloco`) |
| ~~Peças de combate~~ | **Feito na Sprint 10** (`inimigos`, `alvo.vida`, `alvo.escudo`, `faisca`) |
| ~~Chefe e arquivo de balanceamento~~ | **Feito na Sprint 11** (regra própria `BossPhases`, orbe à distância; `content/balanceamento.json`), recomendações aprovadas pelo Victor |
| Duração da luta do chefe (meta de 2 a 4 min; medida com uma ação por segundo: ~32 s) e margem do "parado perde" (chefe com 12 de 90); pilares nas plataformas ou só no chão | `COM-chefe.md`, perguntas em aberto; calibrar jogando (`balanceamento.json`, seção `chefe`) |
| Decisões da Sprint 17 tomadas por recomendação (plataformas param projéteis e orbes; quem se protege esquiva em vez de escudo; mana 14 na medição) | `docs/sprints/sprint-17-chefe.md`, Decisões; o Victor revisa |
| Decisões da Sprint 18 tomadas por recomendação (`>` e `+` no layout; tempos das plataformas nas classes; inimigos só nos corredores e na chegada da `p03`; baús novos na `sala_01`, `p03` e `p06`) e velocidade das plataformas | `docs/sprints/sprint-18-salas-1.md`, Decisões; `MUN-plataformas.md`, perguntas em aberto |
| Decisões da Sprint 12 tomadas por recomendação (valores de XP e níveis; inimigos que reaparecem dão XP; diálogo só com E; caixa no alto) | `docs/sprints/sprint-12-progressao.md`, Decisões; o Victor revisa |
| A serpente puxa conversa sozinha em momentos-chave? | `NAR-dialogo.md`, perguntas em aberto; na Sprint 13 ficou só com E |
| Decisões da Sprint 13 tomadas por recomendação (serpente por sala, dicas com pergunta, save por perfil e momentos de gravação) | `docs/sprints/sprint-13-serpente-save.md`, Decisões; o Victor revisa |
| ~~Mapa da área~~ | **Decidido pelo Victor (Sprint 14):** segredos com vários caminhos, atalho de mão única, fonte antes do chefe, tela de fim; `docs/mapa-area.md` |
| Decisões da Sprint 14 tomadas por recomendação (salas com a geometria antiga, 10 XP por baú, Novo jogo mantém o grimório, tamanhos de texto, caixa que sobe com texto grande, sem pausa no F6) | `docs/sprints/sprint-14-montagem-area.md`, Decisões; o Victor revisa |
| ~~Loop no cristal mutável falha por causa do ADR-001~~ | **Feito na Sprint 13:** a lição de condicionais explica que é um acerto por conjuração |
| Limites das estrelas do Puzzle 6 (20/24) | `PUZ-06-revisao.md`; calibrar no playtest |
| Questões do GDD: título, protagonista, motivo do mago, público, C++ | `docs/gdd.md`, fim |

## 9. Próximo passo

1. **Sprint 22** (`docs/plano-alpha-1-1.md`): fechamento da 1.1. Captura de todas as salas, ajuste de valores (o Victor joga a luta do chefe e o feixe), build `ArcaneSyntax-alpha-1.1.zip` (`scripts/build_windows.ps1`, fumaça), roteiro de teste (`docs/playtest/`). Perguntar de novo pela arte antes do build. Criar `docs/sprints/sprint-22-*.md` no começo.
2. Depois, Sprints 18 a 21, na ordem do plano. Perguntar ao Victor que arte já chegou em `game/assets/` antes da Sprint 20.
