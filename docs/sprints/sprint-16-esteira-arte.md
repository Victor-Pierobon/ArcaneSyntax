# Sprint 16 — Esteira de arte e visual provisório

- **Status:** Concluída em 2026-10-27 · aguardando revisão e commit
- **Plano:** Alpha 1.1 (`docs/plano-alpha-1-1.md`) · **Estimativa:** 14–20 h
- **Depende de:** Sprint 15 (commitada, `8f037f4`)

## Objetivo

A arte do Victor entra no jogo só por estar na pasta certa, com o nome certo, e um teste diz o que veio fora do contrato. Enquanto a arte não chega, o jogo deixa de parecer quadrados: paredes com bordas, fundo com profundidade e um mago provisório que anima.

## Tarefas

- [x] Spec `ART-esteira` (contrato dos arquivos, animações do mago, bordas das paredes, fundo)
- [x] `content/arte.json`: o contrato da `docs/arte/identidade-visual.md` como dado, lido pelo jogo e pelo teste
- [x] Conferência de cada PNG entregue: tamanho do quadro, nome, pixels só opacos ou transparentes, cores da paleta (`game/assets/paleta.png`, se existir)
- [x] Biblioteca de arte: lê `game/assets/<pasta>/<animação>.png`, monta as animações, e o jogo usa o provisório quando falta
- [x] Animações do mago por regra pura, com um mago provisório desenhado por código
- [x] Paredes com bordas automáticas (16 formas, pela vizinhança) e tileset provisório novo, gerado por script
- [x] Fundo em três camadas com paralaxe (provisório gerado por script)
- [x] Serpente, inimigos, projéteis e escudo usam a arte quando ela existe
- [x] Teste de mutação, captura de tela, fechamento
- [x] **Primeira leva de arte (gerada pelo Victor no PixelLab):** conferir e ligar o que o jogo ainda não usava

## Decisões (por recomendação; o Victor revisa)

| Decisão | Por quê |
| --- | --- |
| O contrato é um arquivo de dados (`content/arte.json`), não uma tabela no código | O jogo, o teste e a fumaça leem o mesmo arquivo; mudar o tamanho de um quadro não pede código |
| Uma tira horizontal por animação, com o número de quadros pela largura | É a exportação mais simples do Aseprite e de imagem de IA recortada; não há JSON de animação para manter |
| **Bordas com 16 formas** (só os lados), não as 47 com cantos internos | Resolve o "parece quadrado" com um formato que se desenha à mão ou se monta de um pacote; os cantos internos ficam para quando a arte pedir |
| Tileset montado por código | Uma imagem nova de tiles não precisa de `.tres` nem de abrir o Godot; as colisões ficam em um lugar só |
| Conferência de paleta e de pixel semitransparente no teste | São os dois erros mais comuns de imagem gerada por IA (o Victor está decidindo se usa IA) |
| Morte, chefe, objetos de puzzle e interface entram no contrato, mas o jogo só passa a usá-los nas Sprints 17 e 20 | O chefe muda na Sprint 17; a arte desses itens depende do que o Victor entregar |

## O que foi entregue

**Specs:** ART-esteira (nova, regras 1 a 20, ART-001 a ART-050).

**Godot**
- `content/arte.json` (contrato); `ArtCatalog` (`src/core/art/`, regra pura); `ArtLibrary` (`src/nodes/art/`)
- `PlayerAnimation` (`src/core/player/`, regra pura); `PlayerVisual` (mago provisório desenhado por código ou a arte); `Player.play_action`, `Player.hurt`, `current_animation`
- `TileShape` (`src/core/world/`, regra pura); `Room.tileset_for` (tileset por código), `Room.tiles_source`
- `Backdrop` (`src/nodes/world/`): três camadas com paralaxe, cor sólida, moldura escura em volta da sala
- Arte opcional em `TrainingTarget` (e inimigos), `Serpent` (`parada`, `falando` no diálogo dela), `Projectile`, `Shield`; contorno escuro nos alvos provisórios
- `SmokeCheck` confere o contrato da arte; `tools/` fora do build
- Projeto: desenho 2D preso aos pixels
- Arte provisória: `tools/gerar_provisorio.gd` gera `assets/placeholder/tiles_bordas.png` e `fundo_1..3.png`; o tileset antigo de 3 tiles (`tiles.png`, `tiles.tres`) saiu

**Testes:** `tests/unit/art/` (contrato, arte entregue, biblioteca), `tests/unit/player/test_player_animation.gd`, `tests/unit/world/test_tile_shape.gd`, `tests/scene/art/test_art_scene.gd` (sala de teste `sala_bordas`), `test_smoke.gd` (ART-050), apoio `tests/support/art_fixtures.gd`.

**Primeira leva de arte (ART-esteira, regras 21 a 28, ART-041 a ART-048):** a arte de 47 arquivos do Victor passa na conferência. O que já estava ligado (mago, serpente, inimigos andando, projétil, faísca, escudo do mago) apareceu sem mexer em código; o resto foi ligado agora:
- impacto do projétil e da faísca (`ArtLibrary.effect`, toca uma vez e some); aura de meditar (`PlayerVisual.aura`);
- morte do elemental e do guardião (o inimigo fica na cena até a animação acabar); `mergulhar` do enxame; escudo do guardião desenhado (`Guardian.shield_sprite`, 80% opaco);
- cristal apagado e aceso pelo elemento que o acendeu (`Crystal.lit_element`); porta (`RuneDoor.art_sprites`, a de atalho tingida); baú fechado e aberto (escurecido, sem `bau_abrindo`);
- tocha: `tocha` em `targets` vira `Torch` (decoração); duas na `sala_01` para ver a arte. As outras salas ganham tochas na Sprint 18;
- `TrainingTarget._art()` aceita várias animações (`[pasta, principal, outras...]`); `top_height()` põe nome e barra acima do desenho.

**Totais:** 508 GdUnit4, 145 pytest e 32 do gerador de sprites, verdes. A Alpha inteira (MUN-085) continua passando com o tileset novo.

## Bugs encontrados (cada um com teste de regressão)

| Bug | Como apareceu | Teste |
| --- | --- | --- |
| Nas salas menores que a tela, o fundo aparecia em volta da sala e ela parecia flutuar | Captura de tela (`sala_c01`, `sala_c02`, `sala_c04`) | `test_ART_031_fora_da_sala_e_escuro` (vermelho → verde com a moldura escura) |
| O nome do elemento sobre o inimigo ("fogo") saía embaralhado: com a câmera suave, o texto de 7 px caía entre pixels. Já existia antes; o zoom da captura mostrou | Captura ampliada do elemental | `test_ART_032_desenho_preso_aos_pixels` (vermelho → verde ligando o encaixe na grade de pixels) |
| O contrato pedia o escudo do guardião em fogo, gelo e **raio**, mas o escudo do jogo troca entre fogo, **planta** e gelo (COM-guardiao): o gerador fez um `escudo_raio` que nunca apareceria | Revisão da primeira leva de arte | `test_ART_001_variantes_iguais_as_do_jogo` (vermelho → verde corrigindo `arte.json` e `fila.json`; o `escudo_planta` saiu do de fogo por troca de cor, sem gastar geração; o `escudo_raio` saiu de `game/assets/`) |
| Com arte, o nome do inimigo e a barra de vida ficavam na altura do colisor, em cima do desenho (o "fogo" sobre a cabeça do guardião) | Captura ampliada com a primeira leva | `test_ART_048_nome_e_barra_acima_da_arte` (vermelho → verde com `top_height`, o pixel mais alto do desenho) |
| Os testes do provisório (`ART-011` mago provisório, `ART-022` tiles provisórios, `ART-040` sem arte) liam `game/assets/` e quebraram quando chegou a primeira arte de verdade (gerada pelo PixelLab, 2026-10-27) | Suíte de arte depois do gerador de sprites | Os três passam a usar a pasta de teste (`_use_art()`); `test_ART_011_mago_provisorio_segue_a_regra` falhava com a arte do mago e passa |

## Teste de mutação

14 mutantes, 14 mortos (um depois de reforçar o teste): borda de fora que não conta como pedra; sala com uma pedra só; plataforma que não deixa atravessar; ação acima da esquiva; pixel semitransparente que passa; paleta ignorada; biblioteca sem reserva; moldura que não acompanha a sala; dano que não aparece no mago; cajado que não anima; **retângulo que continua aparecendo com a arte** (sobreviveu: o teste conferia o sprite, mas não que o retângulo some; reforçado); arte do mago que não espelha; fundo que ignora a arte do Victor; fumaça que não confere a arte.

Primeira leva de arte: 14 mutantes, 14 mortos (dois depois de reforçar os testes): impacto que não aparece ou fica em laço; aura sempre visível; morte que não espera a animação ou esconde a arte; enxame que não mergulha; **escudo na brecha** (sobreviveu: na brecha o guardião desenhava um círculo branco e o teste não conferia; reforçado); cristal que não troca; **cristal com o elemento errado** (sobreviveu: com uma arte de cristal aceso só, a reserva escondia o erro; o teste passou a ter duas); porta sem arte; baú aberto igual ao fechado; tocha que vira alvo; sala que ignora a tocha; nome na altura do corpo.

## Captura de tela

`sala_01` (com e sem paralaxe), `sala_02`, `sala_p05`, `sala_p06`, `sala_c01`, `sala_c02`, `sala_c04`; o mago ampliado em parado, conjurar, meditar, cajado e dano; o elemental ampliado. As paredes ganharam topo claro com musgo e lados escuros; o fundo tem arcos, colunas e correntes em três profundidades; o mago provisório tem chapéu, túnica, grimório no quadril e cajado com uma pedra que brilha ao conjurar.

Primeira leva de arte: `sala_01` (mago, serpente, tochas, porta de atalho), meditar com a aura, projétil e escudo, `sala_02` (baú), `sala_p02` (porta), `sala_c01` a `c04` (elemental, enxame, guardião com escudo). O estilo combina entre si; os pontos fracos estão em Limitações.

## Como verificar

1. Abra o jogo (F5) e jogue um pouco: paredes, fundo andando mais devagar que a sala, o mago andando, pulando, conjurando (o cajado sobe) e meditando (aura).
2. Para ver a esteira funcionando, ponha qualquer PNG de 48×48 (ou uma tira de quadros de 48×48) em `game/assets/mago/parado.png` e abra o jogo de novo: o mago vira a imagem. Rode `test_arte_entregue.gd` para ver a conferência (com uma `game/assets/paleta.png`, ela acusa cor fora da paleta). Apague o arquivo depois, se era só um teste.
3. Para gerar o provisório de novo: `godot --headless --path game -s res://tools/gerar_provisorio.gd` e `--import`.

## Limitações conhecidas

- **Porta:** a arte gerada veio com moldura (topo e base); empilhada na porta de 16 tiles de altura, vira uma coluna de quadrinhos. O prompt já pede um tile que se repete: vale `refazer objetos/porta` (1 geração).
- Treino (bonecos `fogo`/`planta`/`raio`) e chefe continuam retângulos: o boneco não está no contrato e o chefe muda na Sprint 17.
- O mago não toca `morrer` (a arte existe; falta o tempo de morte).

- As salas continuam com a geometria antiga (Sprints 18 e 19); várias são menores que a tela e ficam com a moldura escura em volta.
- Nas salas mais altas que a tela, o fundo não se repete na vertical (embaixo aparece a cor sólida).
- Bordas sem cantos internos (16 formas); um canto de dentro de parede em L não tem desenho próprio.
- O mago não toca `morrer` (renasce no mesmo quadro).
- Os inimigos com arte viram para o lado em que andam; o guardião e o chefe ainda não têm arte ligada além do `andar`.
