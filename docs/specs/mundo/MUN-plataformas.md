# MUN-plataformas — Plataforma que se move e plataforma que cai

- **Status:** Rascunho
- **Sprint:** 18
- **Relacionadas:** MUN-salas, MUN-movimento, MUN-vida, MUN-mapa, MAG-acoes (levitar e mover)

## Contexto

As salas refeitas da Alpha 1.1 são maiores e mais altas (plano da 1.1). Para a travessia não ser só "pular de plataforma fixa em plataforma fixa", entram os dois elementos de mundo que o plano permite, aprovados pelo Victor (Sprint 18): a **plataforma que se move** e a **plataforma que cai**. Nenhuma delas é puzzle: são caminho, e toda sala continua deixando voltar.

## Fora do escopo

Plataformas que giram, que seguem trilhos com curvas, que o feitiço liga e desliga, ou que esmagam. Arte definitiva (entra pelo contrato quando chegar). Números no balanceamento: tempos e velocidades são sensação (BAL-valores, fora do escopo) e ficam nas classes.

## Regras

### Layout

1. **Legenda nova** (MUN-salas, regra 1):
   - `-`: plataforma que cai. Uma sequência de `-` na mesma linha é **uma** plataforma.
   - `>`: plataforma que se move. Uma sequência de `>` na mesma linha é **uma** plataforma, desenhada no lugar de partida.
   - `+`: o outro extremo do caminho da plataforma que se move: na **mesma linha** (caminho horizontal: a plataforma anda até a ponta dela encostar no `+`, incluindo-o) ou na **mesma coluna** da primeira célula `>` (caminho vertical: a plataforma anda até a linha do `+`). Cada plataforma `>` tem exatamente um `+`; o `+` mais perto, na linha ou na coluna, é o dela.
2. Erros de autoria (`>` sem `+`, `+` sem plataforma) aparecem como os outros erros de sala (`push_error`, a sala abre mesmo assim; a plataforma sem caminho fica parada).
3. As duas plataformas são **atravessáveis por baixo** como `=` (o mago pula através e pousa em cima).

### Plataforma que se move (`MovingPlatform`)

4. Vai e volta entre a partida e o extremo, a **48 px/s** (3 tiles/s), com **0,5 s** parada em cada ponta. Começa parada na partida e sai depois da primeira pausa.
5. Quem está em pé nela **anda junto** (o mago não escorrega para fora quando ela anda nem quando ela sobe ou desce).
6. A posição é uma regra pura (`PlatformPath.position_at(t)`): o mesmo tempo dá sempre a mesma posição.

### Plataforma que cai (`FallingPlatform`)

7. Quando o mago **pisa nela** (em pé, em cima), ela treme por **0,5 s** e então **cai**: some e deixa de segurar. Depois de **3 s** fora, volta para o lugar, inteira.
8. Pisar e sair antes dos 0,5 s não cancela: depois de começar a tremer, ela cai.
9. O estado é uma regra pura (`FallingPlatformRule`: parada → tremendo → caída → parada). **Dá para ver que ela cai:** madeira avermelhada e mais escura, com rachaduras, diferente da plataforma fixa (regressão da captura de tela da Sprint 18: igual à fixa, o mago caía sem ter como prever).

### Comum

10. O jogo pausado congela as duas (o tempo não corre).
11. Morrer ou voltar à sala monta as plataformas de novo, nos lugares de partida.
12. Para o mapa (`AreaMap`, MUN-mapa) as duas são espaço livre (não bloqueiam). Para a verificação de alcance a pé (MUN-salas, regra 9), `-` é chão e o caminho inteiro de uma `>` horizontal é chão; numa `>` vertical, as duas pontas são chão e ligadas entre si.

## Critérios de aceite

### MUN-100 — Leitura do layout

- **Dado** o layout com `>>>....+` numa linha, uma coluna com `+` acima de um `>>` e `---` em outra linha
- **Então** o `RoomLayout` tem duas plataformas que se movem (largura 3, caminho horizontal até a ponta encostar no `+`; largura 2, caminho vertical) e uma que cai (largura 3)
- **E** um `>` sem `+` gera um erro e um `+` sozinho também

### MUN-101 — Caminho da plataforma que se move

- **Dado** um caminho de 64 px na horizontal
- **Então** em t = 0 e t = 0,5 está na partida; em t = 0,5 + 64/48 está no extremo; fica lá até 0,5 s depois; volta pelo mesmo caminho e o ciclo se repete
- **E** no meio do caminho a posição é a proporção do tempo andado

### MUN-102 — Plataforma que cai

- **Dado** uma `FallingPlatformRule` parada
- **Quando** o mago pisa
- **Então** treme por 0,5 s (segura), cai (não segura) e, 3 s depois, volta parada (segura)
- **E** pisar de novo enquanto treme não muda o tempo; sem pisar, continua parada

### MUN-103 — O mago anda junto (cena)

- **Dado** o mago parado em cima de uma plataforma que se move na horizontal
- **Quando** ela anda 2 s
- **Então** os pés do mago acompanham a plataforma (a distância entre eles não muda mais de 2 px) e ele continua em pé nela
- **E** numa plataforma vertical, subindo, ele continua em pé nela

### MUN-104 — Pisar derruba (cena)

- **Dado** uma plataforma que cai sobre um vão
- **Quando** o mago pousa nela e fica parado
- **Então** 0,5 s depois ele cai junto; 3 s depois de cair, ela está de volta e segura o mago de novo

### MUN-105 — Pausa e sala montada de novo (cena)

- **Dado** uma plataforma andando e outra tremendo
- **Quando** o jogo pausa
- **Então** nenhuma muda de estado nem de posição até despausar
- **E** morrer na sala traz as duas de volta à partida

## Exemplos

```
#...............+......#    caminho horizontal: >>> anda até a ponta encostar no +
#....>>>...............#
#......................#
#..+...................#    caminho vertical: o + na coluna da primeira célula da plataforma
#......................#
#..>>..........---.....#    --- cai quando o mago pisa
```

## Perguntas em aberto

- [ ] Velocidade de 3 tiles/s e as pausas de 0,5 s estão boas? (checklist de sensação)
- [ ] A plataforma que cai deveria avisar mais (piscar ou rachar) antes de cair? (com a arte)
