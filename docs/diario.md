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
