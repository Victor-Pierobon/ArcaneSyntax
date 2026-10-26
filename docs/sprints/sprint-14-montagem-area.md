# Sprint 14 — Montagem da área

- **Status:** Concluída em 2026-10-26 · aguardando revisão e commit do Victor
- **Fase do plano:** 8 · **Marco:** M4 · **Estimativa:** 14–21 h
- **Depende de:** Sprint 13 (mapa no papel)

## Objetivo

Dá para jogar do começo ao chefe.

## Tarefas

- [x] Specs `MUN-mapa`, `MUN-segredos` e `UI-menus`; MUN-vida ganhou a fonte, SAV-progresso os campos novos
- [x] Montar as salas na forma do mapa: atalho, portas de chão a teto, segredos, fonte e a sala do fim (13 salas)
- [x] Teste do mapa: toda saída tem volta, as portas seguram o mago mesmo voando, os conceitos vêm na ordem
- [x] Menu inicial, pausa e opções (tamanho do texto e volume); tela de fim da demo
- [x] Teste de mutação, captura de tela, fechamento

## Decisões

O Victor respondeu às quatro perguntas do mapa no começo da sprint. O resto são recomendações minhas.

| Decisão | De quem | Por quê |
| --- | --- | --- |
| **Segredos que aceitam vários caminhos:** "prefiro que o jogador seja recompensado por resolver os problemas de diversas formas, não apenas uma forma específica" | Victor | O baú só confere se o mago chegou (o pilar dos puzzles). Cada baú tem pelo menos um caminho com feitiço e um só com movimento, e os dois são testados |
| **Atalho de mão única** da `sala_c01` (depois do P6) para a `sala_01` | Victor | Padrão do gênero. Quem chega por trás abre a porta verde-escura ao lado da entrada, e ela fica aberta (vai para o save) |
| **Fonte antes do chefe** (`sala_c03`) | Victor | E enche vida e mana. Morrer continua devolvendo a vida cheia na entrada da sala |
| **Tela de fim da demo** atrás da porta do chefe | Victor | A serpente se despede na `sala_fim` e aparece o resumo (nível, XP, puzzles, estrelas, lições, segredos) |
| As 12 salas ficaram com a geometria das Sprints 9 a 11; a montagem mexeu só onde o mapa pedia | Recomendação | As salas de puzzle e combate têm aceitação com Python real; redesenhar a geometria pediria refazer essa calibragem sem ganho para a Alpha |
| Segredo dá **10 XP** (`xp.segredo` no balanceamento), uma vez por jogo | Recomendação | Recompensa visível sem desequilibrar a curva (a área toda dá ~257 XP) |
| Cada puzzle declara as lições que exige (`puzzle.licoes` na cena da sala) | Recomendação | O teste do mapa confere a ordem dos conceitos sem uma tabela à parte que possa ficar desatualizada |
| **Novo jogo apaga só o `save.json`**; o grimório fica | Recomendação | Os feitiços são do jogador |
| Opções: Normal / Grande / Muito grande (+0, +2, +3 pontos) e volume de 10 em 10, em `<perfil>/opcoes.json` | Recomendação | Acessibilidade do GDD; por perfil, porque em laboratório cada aluno tem o seu |
| Com texto maior que Normal, a caixa de diálogo **sobe e cobre o HUD** enquanto está aberta | Recomendação | Era o único jeito de manter as lições com código acima da metade da tela (veja os bugs); o jogo está pausado durante o diálogo |
| A pausa é da cena principal: o `world.tscn` aberto com F6 roda sem menu e sem pausa | Recomendação | O F6 é o modo de desenvolvimento (ir direto a uma sala) |

## O que foi entregue

**Specs:** MUN-mapa, MUN-segredos e UI-menus (novas). Atualizadas: MUN-salas (`%`), MUN-vida (regra 9, fonte, MUN-028), MUN-alvos, SAV-progresso (`segredos`, `atalhos`, quando grava e carrega), PRO-xp e BAL-valores (`xp.segredo`).

**Salas:** `sala_01` (porta do P1 de chão a teto, porta de atalho `%`, entrada `C`), `sala_02` e `sala_03` (nicho com baú), `sala_c01` (escada até a saída alta do atalho), `sala_c03` (fonte), `sala_c04` (saída para o fim), `sala_fim` (nova), `licoes` nos puzzles das seis salas.

**Godot**
- `AreaMap` (`src/core/world/area_map.gd`, novo): a área como grafo de células; `reach` (onde o mago chega, voando, com as portas abertas que você disser) e `walkthrough` (abre cada porta quando ela pode abrir e devolve a ordem dos puzzles); totais para o resumo
- `RoomLayout.shortcut_doors` (`%`); `Room.atalho_entrada`, `shortcut_open`, `open_shortcut`, `chests`, `fountains`, sinal `secret_found`; `RuneDoor.make(células, cor)`
- `Chest` e `Fountain` (`src/nodes/world/`, novos)
- `World`: `found_secrets`, `opened_shortcuts`, `drink()`, `fountain_in_reach()`, `summary()`, sinal `demo_finished`; `talk()` cai na fonte quando não há serpente perto; save com `segredos` e `atalhos`
- `Settings` (`src/core/settings/settings.gd`, novo) e `FontScale` (`src/nodes/ui/font_scale.gd`, novo); `GrimoireUI.set_text_delta`, `DialogueBox.set_text_delta`
- Menus (`src/nodes/ui/`, novos): `MenuPanel` (base), `TitleMenu`, `PauseMenu`, `OptionsMenu`, `EndScreen`
- `Main`: abre no menu inicial; `continue_game`, `new_game`, `return_to_menu`; liga pausa, opções e fim
- Conteúdo: cena `fim_demo` em `dialogos.json`, `xp.segredo` no balanceamento, textos novos (menus, fonte, segredo, fim) e `Esc pausa` na dica de controles

**Testes:** `tests/unit/world/test_area_map.gd`, `tests/unit/settings/test_settings.gd`, `tests/scene/world/test_secrets.gd` (sala de teste `sala_segredo`), `tests/scene/world/test_shortcut.gd`, `tests/scene/ui/test_menus.gd`, `tests/acceptance/test_segredos.gd` (dois caminhos por baú, mais um que prova que sem esquiva não alcança). Ajustados: `test_main.gd` (o menu vem antes do mundo), `test_save.gd` (segredos e atalhos), `test_room_layout.gd` (`%`), `test_dialogue_box.gd` (texto grande).

**Totais:** 458 GdUnit4 e 145 pytest, verdes.

## Bugs encontrados (cada um com teste de regressão)

| Bug | Como apareceu | Teste |
| --- | --- | --- |
| A porta do P1 tinha 3 tiles de altura e o resto da `sala_01` era ar até o teto: com `levitar` (liberado desde a Sprint 6), o mago passava voando por cima sem resolver o puzzle | Lendo o código ao planejar o teste do mapa | `test_MUN_081_portas_fechadas_seguram_o_mago` (vermelho com a porta antiga, no teste de mutação) e `test_MUN_081_porta_baixa_deixa_passar_voando` |
| Com texto Grande ou Muito grande, as lições com código passavam da metade da tela (a pior terminava em y 216 com limite de 180) | Teste novo que abre todas as falas no maior tamanho | `test_UI_016_toda_fala_cabe_com_texto_muito_grande` (vermelho → verde com a caixa no alto) |

## Teste de mutação

10 mutantes, 10 mortos: porta do P1 de 3 tiles; puzzle que abre sem as lições; baú que dá XP toda vez; entrar pelo atalho sem abrir; segredos que não voltam do save; pausa que não bloqueia o grimório; Novo jogo que não apaga o save; volume sem teto; caixa que não sobe com texto grande; fonte que não enche a mana. Como os testes e o código foram escritos juntos, o teste de mutação também serviu para ver cada teste novo ficar vermelho.

## Captura de tela

Menu inicial, pausa, opções, lição de loops com texto Muito grande, os dois nichos com baú, a fonte, a escada do atalho na `sala_c01`, a `sala_01` vista do atalho, a despedida da serpente e o resumo. Nada se sobrepõe. A porta de atalho e a porta do P1 agora são colunas do chão ao teto (verde-escura e roxa).

## Como verificar

Siga a seção "4h. A área inteira, menus e fim da demo" de `docs/feiticos-exemplo.md`.

## Limitações conhecidas

- O `world.tscn` aberto com F6 não tem pausa nem menu (só pelo F5).
- Os segredos estão à vista; o desafio é chegar, não achar. Paredes falsas ficaram de fora.
- A geometria das salas continua a das Sprints 9 a 11 (provisória, sem arte). O tileset definitivo pode pedir outro passe.
- A porta de atalho aberta some com a animação de 0,4 s toda vez que se entra na sala (como a porta do chefe).
