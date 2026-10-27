# MUN-mapa — O mapa da Masmorra (Ato I)

- **Status:** Implementada
- **Sprint:** 14
- **Relacionadas:** MUN-salas, MUN-segredos, MUN-vida (fonte), NAR-serpente, PUZ-validacao, COM-chefe, SAV-progresso, UI-menus (fim da demo); rascunho em `docs/mapa-area.md`

## Contexto

O mapa é o currículo (GDD): cada passagem só exige conceitos que a serpente já ensinou. Esta spec descreve a área montada a partir do rascunho conferido pelo Victor (Sprint 13) e as regras que os testes verificam no grafo das salas, para o mapa não quebrar quando uma sala mudar.

## Fora do escopo

Mapa na tela (minimapa). Teletransporte entre pontos. Salas de outros atos.

## Regras

1. **Salas:** as cenas em `content/rooms/` formam a área. O jogo começa na `sala_01`, entrada `A`. São 13 salas: as 12 da Alpha e a `sala_fim` (fim da demonstração, UI-menus).
2. **Grafo** (caminho principal de cima para baixo):

   | De → para | Bloqueio | Conceito exigido |
   | --- | --- | --- |
   | sala_01 → sala_02 | porta de runas do P1 | sequência |
   | sala_02 → sala_03 → sala_p02 | nenhum | — |
   | sala_p02 → p03 → p04 → p05 → p06 | porta do puzzle de cada sala | variáveis, condicionais, loops, funções |
   | sala_p06 → sala_c01 | porta do P6 | revisão (os quatro) |
   | sala_c01 → c02 → c03 → c04 | nenhum (inimigos não bloqueiam) | — |
   | sala_c04 → sala_fim | porta do chefe | — |
   | sala_c01 ↔ sala_01 | **atalho de mão única** | — |

3. **Toda saída tem volta:** se a sala X tem uma saída para a sala Y, a sala Y tem uma saída para a sala X.
4. **Portas vão do chão ao teto.** Desde a Sprint 6 todas as peças estão liberadas; com `levitar`, o mago voaria por cima de uma porta baixa. Uma porta só bloqueia se fecha a passagem inteira.
5. **Porta de atalho** (`%` no layout, MUN-salas): sólida até o mago entrar na sala pela entrada do atalho (`atalho_entrada` na cena da sala). Aí abre e fica aberta para sempre (vai para o save, `atalhos`). Na Masmorra, a saída alta da `sala_c01` sobe até a entrada `C` da `sala_01`, atrás da porta de atalho: quem chega por baixo abre, quem está na `sala_01` vê uma porta fechada.
6. **Lições exigidas:** cada puzzle declara em `puzzle.licoes` as cenas da serpente que ensinam o que ele cobra. Todas precisam existir em `content/dialogos.json`.
7. **Ordem dos conceitos:** andando pelo mapa a partir do começo, cada porta de puzzle só é alcançada depois de todas as serpentes das lições que ela exige. A porta do chefe abre ao derrotá-lo; o chefe não exige lição.
8. **Como o teste anda pelo mapa:** cada célula que não é pedra nem porta fechada é passável nas quatro direções, ignorando a gravidade (é o máximo que o mago alcança voando). Assim, o teste pega qualquer jeito de passar por cima ou por fora de uma porta.

## Critérios de aceite

### MUN-080 — Toda saída tem volta

- **Dado** todas as salas de `content/rooms/`
- **Então** para cada saída de X para Y, Y tem uma saída para X

### MUN-081 — Portas fechadas seguram o mago, mesmo voando

- **Dado** todas as portas fechadas
- **Quando** o mago anda (ou voa) a partir da `sala_01`, entrada `A`
- **Então** só alcança a `sala_01`

### MUN-082 — Os conceitos vêm na ordem

- **Dado** o mapa, abrindo cada porta de puzzle só quando as serpentes das suas lições já foram alcançadas, a do chefe quando a sala dele é alcançada, e a de atalho quando a entrada do atalho é alcançada
- **Então** todas as salas são alcançadas, e os puzzles abrem na ordem P1, P2, P3, P4, P5, P6

### MUN-083 — Lições declaradas existem

- **Dado** os puzzles das salas
- **Então** todo puzzle declara ao menos uma lição em `licoes`, e toda lição existe em `content/dialogos.json`

### MUN-084 — Atalho de mão única (cena)

- **Dado** um mundo novo na `sala_01`
- **Então** a porta de atalho está fechada
- **Quando** o mago entra na `sala_01` pela entrada `C` (vindo da `sala_c01`)
- **Então** a porta de atalho abre, o save guarda o atalho, e ela já nasce aberta quando o mago volta à `sala_01` por outra entrada

### MUN-085 — A Alpha inteira, do menu ao fim (aceitação, Sprint 15)

- **Dado** a cena principal, um perfil vazio e o Python de verdade
- **Quando** o jogo começa por Novo jogo e o mago, sala por sala, ouve a lição de cada serpente, resolve cada puzzle com um feitiço, abre os dois baús, usa o atalho e a fonte, vence o chefe e fala com a serpente da `sala_fim`, **saindo de cada sala andando pela saída** (a porta precisa estar aberta)
- **Então** a tela de fim mostra 6 de 6 puzzles, 6 de 6 lições e 2 de 2 segredos, e Enter volta ao menu com Continuar
- Dentro de cada sala, o teste põe o mago direto no lugar de conjurar (como os outros testes de aceitação); o que ele confere é que o caminho inteiro fecha.

## Perguntas em aberto

- [ ] Um minimapa ajudaria iniciantes? (depois da Alpha)
