# Sprint 19 — Salas II: combate e fim

- **Status:** Concluída em 2026-10-27 · aguardando revisão e commit
- **Plano:** Alpha 1.1 (`docs/plano-alpha-1-1.md`) · **Estimativa:** 14–20 h
- **Depende de:** Sprint 18 (commitada, `3e400bd`) e Sprint 17 (arena do chefe)

## Objetivo

As salas de combate (`sala_c01` a `c03`) e a `sala_fim` ficam do tamanho da tela, com travessia, mais inimigos e grupos mistos; a arena do chefe (`sala_c04`, Sprint 17) entra no mapa sem remendo. Com isso as 13 salas da Alpha 1.1 estão refeitas, e o mapa e a Alpha inteira (MUN-085) passam de novo.

## Tarefas

- [x] Tocha como caractere do layout (`!`), sem gastar dígito; as salas da Sprint 18 passam a usar (e a `sala_p06` ganha tochas)
- [x] `sala_c01` a `c03` e `sala_fim` refeitas no gerador (`scripts/salas/salas18.py`)
- [x] Aceitação de combate (COM-025, COM-044, COM-064) olhando só para os inimigos da cena que testam
- [x] `test_rooms_walk.gd` com as 13 salas (a fonte também precisa ser alcançável a pé); `AreaMap`; Alpha inteira
- [x] Teste de mutação, captura de tela de todas as salas novas, fechamento

## Decisões (por recomendação; o Victor revisa)

| Decisão | Por quê |
| --- | --- |
| `!` no layout é uma tocha; `tocha` em `targets` continua valendo | Só há 9 dígitos por sala e a `sala_p06` já usava todos; a Sprint 20 (luz) vai pôr tochas em todo lugar |
| "Ondas mistas" = grupos mistos parados na sala (elemental com enxame), não inimigos que aparecem em ondas | Sem mecânica nova de aparecer; o grupo misto já cobra ler `alvo.elemento` e o loop sobre `inimigos` ao mesmo tempo |
| Cada cena de aceitação de combate fica a mais de 12 tiles dos inimigos novos | O feitiço mira o mais perto em 12 tiles (MUN-alvos); assim a aceitação continua medindo o mesmo feitiço |
| A arena do chefe não muda | Já tem 40×22 e as saídas certas desde a Sprint 17; só passa a ser conferida pelo `WalkMap` |

## O que foi entregue

**Specs:** MUN-salas (legenda `!`, MUN-112; regra 10 e MUN-111: toda saída a pé, menos as do elevador, e a fonte); ART-esteira (regra 28: tocha no layout).

**Godot**
- `RoomLayout.torches` (`!`) e `Room._add_torch`; `tocha` em `targets` continua valendo
- Salas novas no gerador (`scripts/salas/salas18.py`), e as da Sprint 18 regeradas com as tochas em `!` (a `sala_p06` ganhou duas):
  - `sala_c01` (48×23): entrada no alto, escada com duas que caem até a borda sobre o fosso dos elementais de fogo e de gelo (3 tiles abaixo, com um degrau para sair), do lado de lá um elemental de planta e um enxame de 2, e a escada até o atalho para a `sala_01`;
  - `sala_c02` (40×23): elemental de gelo na chegada, poço de espinhos com uma plataforma que se move, o salão do enxame de 6;
  - `sala_c03` (40×23): fonte na chegada, o guardião no chão com um caminho alto por cima dele, e depois um elemental de planta e um enxame de 2;
  - `sala_fim` (40×22): um estrado com a serpente da despedida;
  - a arena (`sala_c04`) não mudou.

**Testes:** `test_room_layout.gd` e `test_art_leva1.gd` (MUN-112), `test_rooms_walk.gd` (as 13 salas, a fonte e toda saída a pé), `test_combate_01` a `03` (olham só para os inimigos da cena; o lugar do mago vem da posição dos inimigos).

**Totais:** 581 GdUnit4 (578 na Sprint 18), 145 pytest e 32 do gerador de sprites, verdes. A Alpha inteira (MUN-085) passa com as 13 salas novas.

## Bugs encontrados (cada um com teste de regressão)

| Bug | Como apareceu | Teste |
| --- | --- | --- |
| Na `sala_c01`, o último degrau da escada do atalho ficava embaixo da quina da prateleira: o mago batia a cabeça e não chegava à saída para a `sala_01` | O teste novo de "toda saída a pé" (MUN-111), antes de jogar | `test_MUN_111_toda_saida_se_alcanca_a_pe` (vermelho → verde: prateleira a partir da coluna 42, degrau nas colunas 40 a 43) |
| O enxame da `sala_c02` só tinha 4 dos 6 bichos nos sentidos e as faíscas batiam nas prateleiras que eu pus no salão | A aceitação COM-044 com a sala nova | `test_COM_044_*` (vermelho → verde: o enxame a ~9,8 tiles do mago, como antes, e o salão sem plataformas) |

O teste de "toda saída a pé" nasceu de uma lacuna achada ao montar a mutação: o MUN-111 conferia a volta, mas não a ida; tirar a escada do atalho não quebrava nada.

## Teste de mutação

5 mutantes, 5 mortos: `!` que não vira tocha; sala que ignora as tochas do layout; `sala_c01` sem o degrau do fosso; `sala_c01` sem o último degrau do atalho; prateleira entre o mago e o enxame da `sala_c02`.

## Captura de tela

`sala_c01`, `c02`, `c03`, `sala_fim` e `sala_p06` (com as tochas novas), inteiras e na altura do mago. A plataforma que cai aparece avermelhada; os grupos mistos ficam longe do lugar de cada luta.

## Como verificar

1. Jogue da `sala_p06` até o fim: o fosso da `c01` (conjure da borda), o grupo do lado de lá e a escada até o atalho; a plataforma que se move da `c02` e o enxame; a fonte, o guardião (ou o caminho por cima dele) e o grupo da `c03`; a arena; a despedida no estrado da `sala_fim`.
2. Para gerar as salas de novo: `py -3 scripts/salas/salas18.py game/content/rooms` (na raiz).

## Limitações conhecidas

- O `WalkMap` é uma aproximação: ele pegou a cabeça batendo na quina da `c01` porque a linha da cabeça passa pela pedra, mas não simula o arco do pulo. Vale jogar a escada do atalho.
- Os grupos mistos não aparecem em ondas: ficam parados na sala (decisão por recomendação).
- A `sala_c03` deixa passar por cima do guardião sem lutar (de propósito: dá para fugir dos inimigos, como no mapa da Sprint 14).
