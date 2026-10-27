# Diário de desenvolvimento

Duas linhas por sessão: o que foi feito e o que vem a seguir.

## 2026-10-25

- Sprint 0: repositório, estrutura de pastas, pytest + GdUnit4 + CI, spec MUN-movimento e protótipo do mago andando e pulando (10 testes verdes).
- Próximo: fazer o tutorial 2D do Godot, escolher os assets provisórios e rodar o CI no GitHub.

## 2026-10-25 (Sprint 1)

- Executor Python: worker persistente, protocolo v1, peças, erros com linha, cliente Godot e console de feitiços. Specs EXE-protocolo, EXE-pecas, EXE-erros; ADR-001 e ADR-002. 51 testes pytest e 23 GdUnit4 verdes.
- Próximo: Sprint 2, com custo de mana, limites de mana e tempo, e sandbox.

## 2026-10-25 (documentação)

- Documentação consolidada: `docs/arquitetura.md`, um arquivo por sprint em `docs/sprints/` (relatórios da 0 e da 1, planos da 2 à 15), roadmap virou índice com status, `handoff.md` + `CLAUDE.md` para novas conversas.
- Próximo: decidir a regra de custo de mana e começar a Sprint 2.

## 2026-10-25 (Sprint 2)

- Executor completo: custo de mana ("linhas baratas", por instrumentação da AST), limites de mana, tempo, ações, saídas e memória, watchdog no Godot, sandbox. Guia de arte com prompts. 105 pytest e 28 GdUnit4 verdes. Marco M1 fechado.
- Próximo: Sprint 3 (personagem e mundo); build de fumaça quando os templates de exportação estiverem instalados.

## 2026-10-25 (Sprint 3)

- Mago com coyote time, jump buffer e esquiva; vida, espinhos, pontos seguros e renascimento; 3 salas em layout de texto com transições e câmera; HUD. Tileset provisório gerado por script. O teste MUN-027 achou um bug real (área disparando com a posição antiga). 65 GdUnit4 e 105 pytest verdes.
- Próximo: Sprint 4 (grimório). Victor: jogar e avaliar a sensação do movimento; escolher assets.

## 2026-10-25 (Sprint 4)

- Grimório: Tab abre e pausa, lista de feitiços (novo, renomear, apagar), editor com realce de Python e das peças, gravação atômica em `user://grimorio.json` com backup se o arquivo estiver ilegível. A captura de tela pegou um bug no campo de nome. 96 GdUnit4 e 105 pytest verdes.
- Próximo: Sprint 5 (slots, conjurar, erros, custo, autocompletar).

## 2026-10-25 (Sprint 5)

- Slots e conjuração por tecla com o Python de verdade, registro de conjuração, Testar com linha do erro marcada, custo estimado, autocompletar, peças bloqueadas no executor, bonecos de treino como alvo. Captura de tela achou a linha do custo cortada (teste de regressão criado). 114 pytest e 132 GdUnit4 verdes. Nova regra: todo bug vira teste de regressão.
- Próximo: Sprint 6 (as ações acontecem no mundo).

## 2026-10-25 (Sprint 6)

- As ações acontecem no mundo: projétil que mira o alvo, escudo, mover, levitar (voo no motor), meditar, cajado, fraquezas elementais com efeito nos bonecos, visões sobre o mago; tudo congela com o grimório aberto. Ações parciais acontecem (decisão do Victor). Mutação achou dois testes fracos, reforçados. 157 GdUnit4 e 114 pytest verdes.
- Próximo: Sprint 7 (mana viva e slot passivo; fecha o M2 com playtest).

## 2026-10-25 (Sprint 7)

- Slot passivo (a cada 1 s, sem sobrepor, desliga com erro e religa ao editar), sons e partículas provisórios gerados por código, roteiro de playtest do núcleo. Captura de tela achou o status do passivo em cima do mago (teste de regressão criado). 179 GdUnit4 e 114 pytest verdes.
- Próximo: Victor faz o playtest do núcleo (fecha o M2); depois Sprint 8 (puzzles).

## 2026-10-25 (Sprint 8)

- Puzzles validados só pelo estado do mundo (cristais e porta de runas), passo a passo com a linha destacada e velocidade (V), Puzzle 1 na sala_01 com teste de aceitação no Python real (3 soluções que passam, 2 que falham). Bugs achados e com regressão: projétil de costas encostado na parede; painel do passo a passo cobrindo a ação. 202 GdUnit4 e 114 pytest verdes.
- Próximo: Sprint 9 (Puzzles 2 a 6). Playtest do núcleo ainda pendente.

## 2026-10-25 (Sprint 9)

- Puzzles 2 a 6 jogáveis em `sala_p02` a `sala_p06` (runas e cadeado, cristal que muda de símbolo, ponte de 12 com estrelas, elevador com levitar + mover, câmara de revisão), cada um com teste de aceitação no Python real. Custo de inscrição (decisão do Victor) para o loop custar menos que linhas repetidas. Bugs com regressão: ordem das placas; alturas do elevador sem gravura (captura de tela). Mutação achou um teste fraco (placa no ar). 265 GdUnit4 e 131 pytest verdes.
- Próximo: Victor revisa e commita; playtest do núcleo e dos puzzles; depois Sprint 10 (combate).

## 2026-10-25 (Sprint 10)

- Combate: elemental (fogo, gelo, planta), enxame e guardião de escudo em `sala_c01` a `sala_c03`, cada um com teste de aceitação no Python real. Decisões do Victor: forma `faisca` (custo 1) para o loop sobre o enxame caber na mana, escudo do guardião que só deixa passar a fraqueza, inimigos que reaparecem. Sentidos novos: `inimigos`, `alvo.vida`, `alvo.escudo`. Bugs com regressão: o escudo não protegia de um inimigo encostado (bloquear agora dá invencibilidade); barra de vida em cima do nome (captura de tela). Mutação: 23 de 23 depois de um teste novo (ordem dos inimigos). 325 GdUnit4 e 144 pytest verdes.
- Próximo: Victor revisa e commita; playtest (núcleo, puzzles e combate); depois Sprint 11 (chefe e arquivo de balanceamento).

## 2026-10-26 (Sprint 11)

- O Victor jogou tudo até a Sprint 10 e está tudo funcionando: fecha o playtest do núcleo (M2), dos puzzles e do combate, sem ajuste de valores.
- Chefe da Masmorra na `sala_c04`: fogo na fase 1 e gelo na fase 2. A troca acontece com vida 15; o golpe que passaria para no limite e há 1,5 s de transição invulnerável com `Fase 2!`. Lança um orbe a cada 3 s/2 s, que o escudo bloqueia. Derrotado, não volta e abre a porta. O mesmo feitiço do elemental (`vence[alvo.elemento]`) vence em 6 conjurações e 20,4 de mana (aceitação com Python real e orçamento de 21).
- Arquivo de balanceamento `game/content/balanceamento.json`, lido por `Balance`: mago, custos do executor (vão como `regras` em toda requisição), dano, inimigos e chefe. Um pytest garante que o arquivo e o `REGRAS_PADRAO` concordam.
- Nenhum bug no jogo (dois testes com expectativa errada foram corrigidos). Mutação: 3 de 4; o sobrevivente era uma precisão menor que um quadro, e o código foi simplificado. 354 GdUnit4 e 145 pytest verdes.
- Próximo: Victor revisa e commita; depois Sprint 12 (progressão e sistemas da serpente).

## 2026-10-26 (Sprint 12)

- O Victor jogou o chefe e está funcionando. Sprint 11 commitada (`e3a7f22`).
- Progressão: XP por inimigos (elemental 10, bicho 2, guardião 15, chefe 50) e por puzzles (20 na primeira vez, +5 por estrela acima de uma); níveis 1 a 5 que aumentam e enchem a mana (10 → 18); nível e XP no HUD. Números no `balanceamento.json` (seções `xp` e `niveis`).
- Diálogo: cenas em `content/dialogos.json`, com escolhas e validação que aponta cena e fala (fala inexistente, texto fora do `textos.csv`, fala que nunca é alcançada ou não termina). A serpente na `sala_01` fala com **E**, e a caixa pausa o jogo.
- Aba Referência no grimório, com 13 páginas das peças na voz da serpente, filtradas pelo desbloqueio.
- Bugs com regressão (captura de tela): o mago cobria o `E: falar`; a caixa de diálogo embaixo cobria o mago e a serpente e foi para o alto. Mutação: 7 de 7. 387 GdUnit4 e 145 pytest verdes.
- Decisões tomadas por recomendação (o Victor pediu para seguir); registradas no relatório para revisão.
- Próximo: Victor revisa e commita; depois Sprint 13 (falas da serpente, dicas e save).

## 2026-10-26 (Sprint 13)

- O Victor jogou a Sprint 12 e está funcionando. Sprint 12 commitada (`3e3e0a9`).
- A serpente ensina: uma lição por sala de puzzle (apresentação e sequência, variáveis, condicionais, loops, funções, revisão). A lição conta quando aparece a fala `licao`. Depois dela, falar de novo oferece dicas em três níveis (conceito → estrutura → exemplo parcial), sempre com a pergunta "Quer uma dica?". Resolvido o puzzle, ela repete a lição. Páginas de conceito na Referência.
- Save por perfil (`user://perfis/padrao/`): grimório (copiado do arquivo antigo) e `save.json` com versão. Grava ao entrar numa sala, resolver um puzzle, vencer o chefe, subir de nível, terminar um diálogo e fechar o jogo. Save ilegível ou de versão nova vira `.bak` e o jogo começa do zero; campo ruim usa o padrão. Cena principal nova `main.tscn`; o `World` sozinho não salva (testes seguros).
- Rascunho do mapa da área em `docs/mapa-area.md`, para o Victor conferir no papel.
- Bug com regressão: duas dicas com 5 linhas passavam da metade da tela (teste novo que abre todo o conteúdo). Mutação: 8 de 8. 417 GdUnit4 e 145 pytest verdes.
- Decisões tomadas por recomendação (o Victor pediu para seguir); registradas no relatório.
- Próximo: Victor revisa e commita, confere o mapa no papel; depois Sprint 14 (montagem da área, menus).

## 2026-10-26 (Sprint 14)

- O Victor jogou a Sprint 13 e está funcionando. Sprint 13 commitada (`99628d4`).
- O Victor respondeu às quatro perguntas do mapa: segredos que recompensam **resolver de várias formas, não de uma forma específica**; atalho de mão única depois do P6; fonte antes do chefe; tela de fim da demo.
- Área montada: 13 salas (a `sala_fim` é nova). Baús na `sala_02` e na `sala_03`, cada um com um caminho com feitiço e um só com pulo e esquiva, os dois com teste de aceitação. Fonte na `sala_c03`. Atalho da `sala_c01` para a `sala_01`, que abre por trás e fica no save. `AreaMap` confere o mapa: toda saída tem volta, as portas seguram o mago mesmo voando, e os puzzles abrem na ordem dos conceitos (cada puzzle declara as lições que exige).
- Menu inicial (Continuar, Novo jogo que pergunta antes e não apaga o grimório, Opções, Sair), pausa com Esc, opções de tamanho do texto e volume por perfil, tela de fim com resumo.
- Bugs com regressão: dava para voar com `levitar` por cima da porta do P1 (as portas agora vão do chão ao teto); com texto grande, as lições passavam da metade da tela (a caixa sobe e cobre o HUD enquanto está aberta). Mutação: 10 de 10. 458 GdUnit4 e 145 pytest verdes.
- Próximo: Victor revisa e commita, joga a seção 4h do começo ao fim; depois Sprint 15 (testes com iniciantes e build).

## 2026-10-26 (Sprint 15, parte do assistente)

- O Victor jogou a Sprint 14 e está funcionando. Sprint 14 commitada (`bec8f75`).
- O jogo inteiro virou um teste de aceitação (MUN-085): do menu ao fim, com Python real, ouvindo as seis lições, resolvendo os seis puzzles, abrindo os dois baús, usando atalho e fonte, vencendo o chefe e saindo de cada sala andando pela saída. Passou de primeira (cerca de 1 min).
- Build da Alpha para Windows: templates de exportação instalados (com o aval do Victor), preset versionado, `scripts/build_windows.ps1` com Python enxuto e `LEIA-ME.txt`, e um teste de fumaça que roda dentro do `.exe` exportado (`--fumaca`: conteúdo, textos, mapa e executor). `FUMACA OK`; `.zip` de 49 MB.
- Bug com regressão: no modo fumaça os menus vazavam (criados e nunca postos na árvore). Também: o `.gitignore` com `build/` escondia `docs/build/` e `docs/specs/build/` (virou `/build/`). Mutação: 4 de 4 (um mutante fraco refeito). 463 GdUnit4 e 145 pytest verdes.
- Roteiro dos testes com iniciantes em `docs/playtest/roteiro-alpha.md`.
- Próximo: Victor revisa e commita; testes com 3 a 5 iniciantes; ajustes com o que aparecer.

## 2026-10-26 (fim da Alpha 1.0, plano da 1.1)

- O Victor jogou o jogo inteiro no editor e o `.exe` do build: tudo funcionando. A Sprint 15 fecha; os testes com outras pessoas ficam para o fim da 1.1.
- Jogando, ele achou o visual (só quadrados), as salas e o chefe simples demais. O chefe morre para quem só repete magia, sem reagir.
- Plano da Alpha 1.1 (`docs/plano-alpha-1-1.md`, Sprints 16 a 21): esteira de arte e provisório melhor, chefe 2.0 (três fases, movimento, pilares do chão, ~90 de vida, "parado perde"), as 13 salas refeitas, luz e partículas, build 1.1.
- Arte mista (decisão do Victor): cenário de pacote recolorido; mago, serpente, inimigos, chefe, efeitos e interface próprios. Roteiro e contrato dos arquivos em `docs/arte/identidade-visual.md`.
- Próximo: Victor revisa e commita; começa a paleta e a ficha de estilo. Assistente: Sprint 16.

## 2026-10-27 (Sprint 16)

- A Sprint 15 e o plano da 1.1 foram commitados (`8f037f4`). O Victor está pensando em fazer toda a arte com IA; a esteira serve para os dois caminhos.
- Esteira de arte (ART-esteira): o jogo procura `game/assets/<pasta>/<animação>.png` pelo contrato de `content/arte.json` e usa o provisório quando falta. Um teste confere cada PNG entregue: tamanho do quadro, nome, pixel semitransparente e cor fora da paleta (os erros típicos de IA).
- Provisório novo: paredes com bordas (16 formas pela vizinhança, tileset montado por código), fundo em três camadas com paralaxe e um mago desenhado por código que anima (parado, andar, pular, cair, esquivar, conjurar, meditar, cajado, dano), por uma regra pura.
- Bugs com regressão, achados por captura de tela: o fundo aparecia em volta das salas menores que a tela (moldura escura); o nome "fogo" sobre o inimigo saía embaralhado (desenho preso aos pixels). Mutação: 14 de 14 (um teste reforçado). 494 GdUnit4 e 145 pytest verdes.
- Primeira leva de arte do Victor (PixelLab, `scripts/sprites/gerar.py`): 47 arquivos, todos dentro do contrato. Ligado o que faltava: impacto, aura de meditar, morte e mergulho dos inimigos, escudo do guardião, cristal, porta, baú e tocha (regras 21 a 28).
- Bugs com regressão: o contrato pedia o escudo do guardião em raio, mas o jogo usa planta (o `escudo_planta` saiu por troca de cor, sem gastar geração); nome e barra de vida caíam em cima da arte (altura pelo desenho). Mutação da leva: 14 de 14 (dois testes reforçados). 508 GdUnit4, 145 pytest e 32 do gerador verdes.
- A porta gerada veio com moldura e não se repete bem na vertical: sugerido `refazer objetos/porta`.
- Próximo: Victor revisa e commita; Sprint 17 (chefe 2.0).

## 2026-10-27 (Sprint 17)

- A Sprint 16 foi commitada (`3606ff1`). O Victor aprovou as recomendações do chefe 2.0.
- Spec `COM-chefe` 2.0: três fases (fogo, gelo, planta), vida 90 com trocas em 60 e 30 que nenhum golpe pula, ciclo fixo mover → aviso → ataque → descanso, um ataque novo por fase (leque de orbes, pilares do chão, investida), todos com aviso. Números novos no `balanceamento.json`.
- `BossBrain` (regra pura) decide tudo e devolve eventos; o nó `Boss` só desenha e aplica. `BossPillar` novo. A `sala_c04` virou a arena de 40×22, com plataformas em dois níveis.
- Aceitação com Python real, uma ação por segundo, vida 5 e mana 14: o mago parado morre aos 33 s (o chefe com 12 de 90); o que sai das marcas e esquiva vence aos 32 s com 3 de vida. O feitiço do dicionário vence as três fases em 15 conjurações (51 de mana).
- Bugs com regressão: o projétil sumia depois de 12 tiles e não alcançava o chefe longe na arena (lendo o código); a marca do pilar ficava atrás do mago parado em cima dela (captura ampliada; agora o contorno do pilar pisca na frente). Mutação: 16 de 16.
- Próximo: Victor revisa e commita, joga a luta (os 2 a 4 minutos e a margem do "parado perde" são para o playtest); depois Sprint 18 (salas I).

## 2026-10-27 (Sprint 18)

- O Victor jogou a luta do chefe 2.0 e commitou a Sprint 17 (`d8d36e6`). Escolheu as duas plataformas novas (a que se move e a que cai).
- Plataformas no layout (`>` e `+`, `-`), com regras puras (`PlatformPath`, `FallingPlatformRule`) e nós que levam o mago. `WalkMap`: alcance a pé com os limites do pulo, para pegar degrau alto e sala sem volta.
- As oito primeiras salas refeitas por script (`scripts/salas/salas18.py`): todas com pelo menos 40×22, altura, plataformas novas, espinhos, inimigos no caminho (elemental de fogo na `sala_02`, enxame na `sala_03`, elemental de gelo na chegada da `sala_p03`) e três baús novos (5 no total), cada um com caminho com feitiço e só com movimento. Os puzzles e as aceitações continuam os mesmos.
- A HUD saiu do chão (atalhos no topo). Bugs com regressão: a HUD em cima dos pés do mago; a plataforma que cai igual à fixa (captura de tela); e um teste intermitente da Sprint 17 (na investida o chefe vai ao chão e o golpe de quem está na plataforma batia nela; os testes esperam a linha livre). Mutação: 15 de 17 (2 equivalentes). 578 GdUnit4, 145 pytest e 32 do gerador verdes.
- Próximo: Victor revisa e commita, joga as salas novas; depois Sprint 19 (combate e fim).

## 2026-10-27 (Sprint 19)

- O Victor testou a Sprint 18 (tudo funcionando) e commitou (`3e400bd`).
- Tocha virou `!` no layout (sem gastar dígito); a `sala_p06` ganhou tochas.
- `sala_c01` a `c03` e `sala_fim` refeitas no gerador: fosso dos elementais com borda e escada até o atalho, grupos mistos (elemental com enxame) longe do lugar de cada luta, poço com plataforma que se move, caminho alto por cima do guardião, estrado da despedida. As 13 salas da Alpha 1.1 estão refeitas.
- O teste de alcance a pé passou a conferir também a ida (toda saída a pé, menos as do elevador) e achou a escada do atalho da `c01` com a cabeça batendo na quina. Mutação: 5 de 5. 581 GdUnit4, 145 pytest e 32 do gerador verdes.
- Próximo: Victor revisa e commita, joga do fim da `p06` até a `sala_fim`; Sprint 20 (arte e brilho) depende do que chegou de arte.

## 2026-10-27 (Sprint 20)

- O Victor testou e commitou a Sprint 19 (`bcd2792`). Nenhuma arte nova chegou (~28 gerações pendentes no gerador); não gastei gerações sem ele pedir.
- Sala escura com luz nas tochas, cristais, feitiços, serpente, fonte, inimigos e no mago; partículas por elemento; tremida de câmera e um congelamento de 0,06 s nos golpes do chefe, com a opção "Tremer a tela"; a linha de cada ação vira uma runa acima do mago; moldura e logo prontos para quando os arquivos chegarem.
- Bugs com regressão: os textos do mundo escureciam com a sala (captura); o projétil que perseguia o chefe dava erro quando o chefe sumia no meio do voo (desde a Sprint 17); e o congelamento fez o mago parado vencer o chefe, porque a margem da luta era fina demais. O chefe foi calibrado (voo a 100 px/s, descansos de 1,0/0,8/0,6 s): o parado morre com o chefe em ~48 de 90, quem se protege vence com 3 de vida.
- Mutação: 15 de 15 (um teste reforçado). 612 GdUnit4, 145 pytest e 32 do gerador verdes.
- Próximo: Victor revisa e commita, joga (a luta do chefe mudou de ritmo); Sprint 21 (fechamento da 1.1).

## 2026-10-27 (Sprint 21)

- O Victor commitou a Sprint 20 e pediu: o feixe ("tipo kamehameha ou o Zoltraak de Frieren"), o chefe menos lento e mais difícil, e magia mais cara ("dá para castar várias em sequência sem pensar").
- Feixe: carrega 0,5 s parado e dispara um raio reto que atravessa todos na linha até a parede; dano 6 (o dobro do projétil), custo 8; aprendido com uma serpente na `sala_c03` (a primeira peça que começa bloqueada).
- Custos: `lancar` 3 → 4, faísca 1 → 1,5; meditar leva 1 s. O Puzzle 1 continua funcionando (meditar uma vez e lançar); as estrelas do Puzzle 6 subiram 2.
- Chefe: voa a 140 px/s, descansa menos, avisos mais curtos, o leque mira adiante, investida mais rápida, mais marcas, orbes junto dos pilares na fase 3. A calibração medida mostrou que a magia cara pesava mais que o chefe, e que as plataformas paravam os tiros de quem fugia para baixo delas: agora tiros atravessam plataformas.
- Mutação: 12 de 12. 626 GdUnit4, 149 pytest (também no 3.14) e 32 do gerador verdes.
- Próximo: Victor revisa e commita, joga a luta e o feixe; Sprint 22 (fechamento da 1.1).

