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
