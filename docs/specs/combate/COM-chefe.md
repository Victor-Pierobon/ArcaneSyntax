# COM-chefe — Chefe da Masmorra

- **Status:** Implementada (2.0, Sprint 17; a versão 1 foi implementada na Sprint 11)
- **Sprint:** 11 (1.0), 17 (2.0)
- **Relacionadas:** COM-dano, COM-elemental, COM-guardiao, MAG-elementos, MUN-vida, MUN-movimento, BAL-valores, ART-esteira, ADR-001

## Contexto

O GDD pede que cada ato feche com um chefe que muda de fase e de fraqueza, "o que obriga o jogador a ter feitiços que se adaptam". Na Alpha 1.0 o chefe ficava parado e morria para quem só repetia a magia, sem reagir (playtest do Victor, 2026-10-26). Na 2.0 ele tem **três fases**, **se move** pela arena e tem **três ataques com aviso**. A luta cobra as duas coisas que o Ato I ensinou no combate: o feitiço que lê `alvo.elemento` e a proteção (andar, pular, esquivar, escudo). Quem fica parado conjurando perde; quem presta atenção nos avisos vence.

## Fora do escopo

Arte, animação e música definitivas (a arte entra pelo contrato quando chegar). Barra de vida do chefe no alto da tela (Sprint 20, interface). Fala da serpente antes da luta. Ataques aleatórios: o ciclo é fixo, para o jogador poder aprender. Montar a arena no mapa novo (Sprint 19; aqui a `sala_c04` é refeita no mesmo lugar do caminho).

## Regras

### Vida, fases e dano

1. Em `targets`: `inimigo:chefe`. Vida **90**, dano de contato **1** (COM-dano, regra 4). Todos os números desta spec vêm do balanceamento, seção `chefe` (BAL-valores).
2. **Fases** (`BossPhases`, regra pura): **fase 1** de **fogo** (fraca a gelo), **fase 2** de **gelo** (fraca a raio), **fase 3** de **planta** (fraca a fogo). O dano segue COM-dano, regra 1, com o elemento da fase.
3. **Gatilhos:** a fase 2 começa com vida **60** ou menos e a fase 3 com **30** ou menos. Nenhum golpe passa de um limite: o golpe que passaria para no limite, e o texto mostra o dano que contou. Assim nenhuma fase é pulada.
4. **Transição:** ao trocar, o chefe fica **1,5 s** invulnerável (golpe bloqueado, `Bloqueou`, dano 0), mostra `Fase N!`, pisca entre a cor da fase velha e a da nova, solta partículas e não ataca. O ataque em andamento é **cancelado**: marcas e pilares somem, o aviso some e o chefe fica onde está (a investida só existe na fase 3, que não tem troca). Orbes que já estão voando continuam.
5. **Sinal da fraqueza:** o corpo tem a cor do elemento da fase e o nome acima dele é o elemento. A troca acontece no início da transição; o feitiço já vê o elemento novo durante a transição (`escudo` é sempre `null`).
6. **Alvo a qualquer distância:** na sala do chefe, ele entra em `alvo` e em `inimigos` a qualquer distância (a arena tem 40 tiles de largura; o alcance de 12 tiles da COM-dano, regra 6, não vale para ele). O projétil e a faísca que o perseguem também não somem depois de 12 tiles (MAG-formas, regra 3); a parede ainda os para.

### Movimento e ciclo de ataques

7. **Pontos da arena:** em `targets`, `chefe:ponto` marca os pontos onde o chefe para no ar e `chefe:investida` marca os dois pontos no chão de onde a investida sai (um de cada lado). O chefe **voa**: vai em linha reta de um ponto ao outro a **140 px/s** (Sprint 21; 100 na Sprint 20, 60 na 17), atravessando paredes e plataformas, sem gravidade. Ele pode ser atingido enquanto se move.
8. **Início:** a luta começa quando a sala é montada: o chefe espera **2 s** parado no lugar do `1` e só então começa o ciclo.
9. **Ciclo** (`BossBrain`, regra pura): repete, sem sorteio, **mover → aviso → ataque → descanso**. Os ataques de cada fase seguem uma lista fixa, em ordem e em volta:
   - fase 1: leque;
   - fase 2: pilares, leque;
   - fase 3: investida, pilares, leque.
   A lista da fase nova começa do primeiro item, que é o ataque que a fase apresenta. Para o leque e os pilares, o chefe vai ao **próximo ponto** da lista de `chefe:ponto` (na ordem dos dígitos, em volta). Para a investida, vai ao ponto `chefe:investida` **mais longe do mago**. O descanso depois do ataque é de **0,7 s**, **0,5 s** e **0,4 s** nas fases 1, 2 e 3 (Sprint 21, a pedido do Victor: "ele é lento", "pouca pressão", "fácil de esquivar"; 1,0/0,8/0,6 na Sprint 20). Medido com os custos da Sprint 21 (COM-094/095): o mago parado morre aos ~22 s com o chefe em ~18 de 90; quem se protege vence aos ~26 s com 3 de vida. (Calibrados na Sprint 20: com 60 px/s e 1,5/1,2/1,0 s, o mago parado vencia ou perdia por pouco, com o chefe em 12 de 90; agora morre aos ~20 s com o chefe em ~48, e quem se protege vence com 3 de vida.)
10. **Todo ataque tem aviso** antes de machucar: quem presta atenção sempre tem tempo de sair. Nenhum ataque sai durante a transição ou o descanso.

### Ataques

11. **Leque de orbes.** Aviso de **0,45 s**: o chefe brilha na cor da fase (animação `orbe`). No fim do aviso, ele mira **adiante**: no centro do mago mais a velocidade dele vezes **0,3 s** (`leque_adiante_s`; parado, é o centro do mago), e lança **3 / 5 / 7** orbes (fases 1 / 2 / 3), um deles **exatamente na mira** e os outros a cada **15°** para os dois lados. Cada orbe tem a cor da fase, voa reto a **100 px/s** (90 até a Sprint 20), some numa parede ou no mago, e tira **1** de vida como ataque: o escudo do mago bloqueia, a esquiva evita, e vale a invencibilidade de 1 s (MUN-vida). Empurra o mago como o contato. Quem está parado leva o orbe do meio; andar, pular ou esquivar escapa.
12. **Pilares do chão** (fases 2 e 3). O chefe marca o chão **sob o mago** (o primeiro chão, `#` ou `=`, abaixo do centro dele, na coluna dele): **4** marcas na fase 2 e **5** na fase 3 (3 e 4 até a Sprint 20), uma a cada **0,6 s**, cada uma na coluna onde o mago está naquele momento, e **junto de cada marca, na fase 3, o chefe solta um orbe mirado no mago** (`pilar_orbes`). Cada marca pisca por **0,7 s** (animação `aviso`), com o contorno translúcido do pilar que vai subir, desenhada **na frente do mago** (quem está em cima dela tem que ver), e então um pilar de **1×4 tiles** sobe dali e fica **0,5 s**. O pilar tira **1** de vida como ataque a quem estiver nele (escudo bloqueia, invencibilidade de 1 s) e empurra para cima e para fora. Quem para em cima da marca é atingido; quem anda sai. A esquiva sozinha (0,16 s) não basta: o pilar dura mais.
13. **Investida** (fase 3). No ponto de investida, o chefe treme e brilha por **0,6 s** e uma faixa no chão marca o caminho até o outro ponto de investida. Então ele atravessa a arena no chão até o outro ponto a **300 px/s**. Encostar nele machuca como o contato (1, ataque: escudo bloqueia, esquiva evita). Escapa quem pula por cima, sobe numa plataforma, esquiva através dele ou usa o escudo.

### Arena

14. **`sala_c04` refeita como arena:** **40×22 tiles** (o tamanho da tela, câmera parada), com chão inteiro, plataformas `=` em dois níveis para fugir da investida e dos orbes, **4** pontos `chefe:ponto` no alto e **2** `chefe:investida` no chão, nos dois lados. A entrada `A` e a saída `a` ficam à esquerda (de onde vem a `sala_c03`); a porta `|` do chão ao teto e a saída `b` (para a `sala_fim`) à direita. O mapa da área (`AreaMap`, MUN-mapa) continua válido.

### Derrota, morte e pausa

15. **Derrota:** com vida 0 o chefe é derrotado como qualquer inimigo (COM-dano, regra 2): a porta `|` abre, o registro mostra `Chefe derrotado!`, ataques, marcas e orbes somem, e o chefe **não reaparece** (voltando à sala, ele não está lá e a porta está aberta). A regra 5 de COM-dano não vale para ele.
16. Morrer na luta monta a sala de novo com o chefe de vida cheia, na fase 1, no começo do ciclo.
17. O jogo pausado congela o chefe, o movimento, os avisos, as marcas, os pilares, a investida, os orbes, a transição e o descanso (COM-dano, regra 7).
18. **Arte:** com a arte da pasta `chefe/` (ART-esteira), o chefe usa `parado` (no ar), `mover`, `orbe` (aviso do leque), `golpe` (investida), `troca` (transição) e `morrer`, cada uma no elemento da fase; as marcas usam `aviso`, os pilares `pilar` e os orbes `orbe_voando_<elemento>`. Sem arte, retângulos e círculos provisórios na cor da fase.

## Critérios de aceite

### COM-080 — Três fases e fraqueza

- **Dado** um `BossPhases` novo
- **Então** está na fase 1 com elemento `fogo`: o projétil de gelo dá 6, o de raio 3, o de fogo 1
- **Quando** a vida chega a 60
- **Então** fase 2, `gelo`: raio dá 6, gelo dá 1
- **Quando** a vida chega a 30
- **Então** fase 3, `planta`: fogo dá 6, gelo dá 3

### COM-081 — Nenhuma troca é pulada

- **Dado** a fase 1 com vida 63
- **Quando** recebe um projétil de gelo (6)
- **Então** o dano é 3, a vida fica em 60 e começa a transição
- **E** o mesmo vale para a fase 2 com vida 33 e um projétil de raio: dano 3, vida 30, transição para a fase 3
- **E** com vida 90 e golpe de 6, o dano é 6 (o limite só corta o golpe que passaria)

### COM-082 — Transição invulnerável e cancela o ataque

- **Dado** a transição recém-começada
- **Então** todo golpe é bloqueado com dano 0 até passar 1,5 s; depois, conta pela fase nova
- **E** o `BossBrain` em aviso ou com marcas de pilar pendentes cancela tudo na troca e, no fim da transição, começa pelo primeiro ataque da fase nova

### COM-083 — Ciclo de ataques

- **Dado** um `BossBrain` novo, com 4 pontos e 2 de investida
- **Então** fica parado 2 s; depois vai ao ponto 1, avisa por 0,45 s, lança o leque, descansa 0,7 s, vai ao ponto 2 e repete
- **E** na fase 2 a ordem é pilares, leque, pilares…; na fase 3, investida, pilares, leque, investida…
- **E** o tempo de ida é a distância dividida por 140 px/s; os descansos são 0,7 / 0,5 / 0,4 s

### COM-089 — Direções do leque

- **Dado** a mira para a direita e a fase 2
- **Então** saem 5 orbes nos ângulos −30°, −15°, 0°, 15° e 30° em relação à mira; na fase 1, 3 orbes (−15°, 0°, 15°); na fase 3, 7 (−45° a 45°)
- **E** a mira é o centro do mago **no fim do aviso**, não no começo

### COM-090 — Pilares seguem o mago

- **Dado** a fase 2 e o mago na coluna 10
- **Quando** começa o ataque de pilares e o mago anda para a coluna 14 antes da segunda marca
- **Então** a primeira marca fica na coluna 10 e a segunda na 14; as marcas saem com 0,6 s entre elas, cada pilar sobe 0,7 s depois da sua marca e fica 0,5 s
- **E** na fase 2 saem 4 marcas e na fase 3, 5
- **E** a marca fica no primeiro chão abaixo do mago (`#` ou `=`), também quando ele está no ar

### COM-091 — Investida pelo lado de lá

- **Dado** a fase 3 com o mago perto do ponto de investida da esquerda
- **Então** o chefe vai ao ponto da direita, avisa por 0,6 s e atravessa até o da esquerda a 300 px/s

### COM-097 — Orbes junto dos pilares (Sprint 21)

- **Dado** a fase 3 e o ataque de pilares
- **Então** junto de cada marca sai um evento de orbe mirado no centro do mago; nas fases em que `pilar_orbes` é 0 (com pilares forçados na fase 1 no teste), não sai orbe

### COM-098 — O leque mira adiante (Sprint 21)

- **Dado** o mago andando a 120 px/s para a direita, embaixo do chefe
- **Então** o orbe do meio vai para o centro do mago mais 120 × 0,3 = 36 px à direita; com o mago parado, para o centro dele

### COM-092 — Chefe na sala (cena)

- **Dado** a arena com `inimigo:chefe` e o mago na entrada, a mais de 12 tiles do chefe
- **Então** o alvo é `{"id", "elemento": "fogo", "distancia", "vida": 90, "escudo": null}` e o chefe aparece em `inimigos`
- **Quando** a vida chega a 60 e depois a 30
- **Então** o alvo passa a `gelo` e depois a `planta`, o corpo e o nome trocam e o texto mostra `Fase 2!` e `Fase 3!`
- **E** o chefe voa entre os pontos (a posição dele chega ao ponto 1 e depois ao ponto 2)

### COM-085 — Os ataques machucam; escudo e esquiva protegem (cena)

- **Dado** o mago parado na arena
- **Quando** o leque sai
- **Então** o orbe do meio tira 1 de vida e empurra o mago; com o escudo ativo, o escudo some e a vida não muda; esquivando no momento do acerto, a vida não muda
- **Quando** um pilar sobe sob o mago parado
- **Então** tira 1 de vida; com o mago fora da marca, nada acontece
- **Quando** a investida passa pelo mago no chão
- **Então** tira 1 de vida; com o mago numa plataforma acima, nada acontece

### COM-086 — Derrota, porta e memória (cena)

- **Dado** o chefe derrotado
- **Então** a porta abre, o registro mostra `Chefe derrotado!`, não sobram marcas, pilares nem orbes, e ao sair e voltar a sala não tem chefe e a porta está aberta
- **E** morrer antes de derrotá-lo traz o chefe de volta com vida 90, na fase 1, parado no lugar do `1`

### COM-087 — Pausa congela (cena)

- **Dado** o chefe se movendo, uma marca de pilar piscando e um orbe no ar
- **Quando** o jogo pausa
- **Então** o chefe, o orbe e o relógio da marca não andam, e nenhum ataque novo sai

### COM-096 — O chefe usa a arte (cena)

- **Dado** a arte de teste `chefe/parado_fogo`, `chefe/orbe_fogo`, `chefe/parado_gelo`, `chefe/aviso`, `chefe/pilar` e `chefe/orbe_voando_fogo`
- **Então** o chefe aparece com a arte (sem o retângulo) tocando `parado_fogo`; no aviso do leque toca `orbe_fogo`; os orbes, as marcas e os pilares usam a arte deles
- **E** na fase 2, sem `troca` nem `orbe_gelo`, ele cai para `parado_gelo`

### COM-093 — A arena

- **Dado** a `sala_c04`
- **Então** tem 40×22 tiles, um `inimigo:chefe`, 4 `chefe:ponto`, 2 `chefe:investida` (um em cada metade, no chão), plataformas em dois níveis, a porta do chão ao teto e as saídas `a` (`sala_c03:B`) e `b` (`sala_fim:A`)
- **E** a câmera não se move com o mago andando de um lado ao outro da arena
- **E** o `AreaMap` continua passando (volta, portas, ordem dos conceitos)

### COM-088 — O feitiço adaptável vence as três fases (aceitação, Python real)

- **Dado** a arena, o mago com vida de sobra (o que se testa aqui é o feitiço)
- **Quando** conjura o feitiço de referência (com dicionário, ou com `if/elif/else`), esperando o fim de cada transição
- **Então** **15** conjurações derrotam o chefe (6 de dano cada, nenhuma cortada pelo limite), gastando no máximo **67** de mana (52 até a Sprint 20, com o `lancar` a 3)
- **E** o feitiço fixo `lancar(gelo, projetil, alvo)` leva o chefe à fase 2 em cinco conjurações e depois causa só 1 por golpe

### COM-094 — Parado perde (aceitação, Python real)

- **Dado** a arena, o mago com a vida de jogo (**5**) e a mana máxima do nível esperado na chegada (**16**, nível 4; era 14 até a Sprint 20), parado no chão no meio da arena
- **Quando** ele só conjura o feitiço de referência e medita quando a mana não basta, **uma ação por segundo**, sem nunca andar, pular, esquivar nem usar o escudo
- **Então** o mago morre antes de o chefe ser derrotado (em no máximo 120 s de jogo)

### COM-095 — Quem se protege vence (aceitação, Python real)

- **Dado** o mesmo mago, no mesmo ritmo de uma ação por segundo
- **Quando** ele sai de cada marca de pilar assim que ela aparece, esquiva atravessando o orbe que chega perto e o chefe que vem na investida, medita só nas brechas (sem aviso, sem marca perto, sem orbe a menos de 120 px) e deixa um passivo de `absorver_mana()` ligado (Sprint 21: com a magia mais cara, é o que o jogo ensina); no resto do tempo conjura o feitiço de referência
- **Então** o chefe é derrotado e o mago termina com **2** de vida ou mais

## Exemplos

```python
# Feitiço de referência: o mesmo do elemental (COM-dano) vence as três fases
vence = {"fogo": gelo, "gelo": raio, "planta": fogo}
lancar(vence[alvo.elemento], projetil, alvo)
```

Custo: 4,4 de mana por conjuração (3,4 até a Sprint 20); 15 conjurações dão **66**. Com mana máxima perto de 14, o jogador medita várias vezes no meio da luta (ou usa um passivo de `absorver_mana`), e é aí que os ataques cobram atenção.

Vida por conjuração: 90 → 84 → 78 → 72 → 66 → **60** (fase 2) → 54 → … → **30** (fase 3) → … → 0.

Feitiço fixo: `lancar(gelo, projetil, alvo)` faz 6 na fase 1, 1 na fase 2 (gelo resiste a gelo) e 3 na fase 3. Quem fixou à mão os dois elementos da Alpha 1.0 (`gelo` e `raio`) precisa adaptar para a fase 3.

Balanceamento (`chefe`), valores iniciais:

```json
"chefe": {
  "vida": 90,
  "elementos": ["fogo", "gelo", "planta"],
  "troca_vida": [60, 30],
  "transicao_s": 1.5,
  "inicio_s": 2.0,
  "velocidade": 100,
  "descanso_s": [1.0, 0.8, 0.6],
  "ataques": [["leque"], ["pilares", "leque"], ["investida", "pilares", "leque"]],
  "leque_aviso_s": 0.6,
  "leque_orbes": [3, 5, 7],
  "leque_abertura_graus": 15,
  "orbe_velocidade": 90,
  "orbe_alcance_tiles": 48,
  "orbe_dano": 1,
  "pilar_marcas": [0, 3, 4],
  "pilar_intervalo_s": 0.6,
  "pilar_aviso_s": 0.8,
  "pilar_ativo_s": 0.5,
  "pilar_altura_tiles": 4,
  "pilar_dano": 1,
  "investida_aviso_s": 0.8,
  "investida_velocidade": 240
}
```

## Perguntas em aberto

- [ ] Vida 90 e os tempos acima dão a luta de 2 a 4 minutos que o plano pede? (playtest; os testes só garantem "parado perde, quem se protege vence")
- [ ] Os pilares devem sair só do chão da arena (e as plataformas altas virarem refúgio) em vez de seguir o mago também nas plataformas?
- [ ] Barra de vida do chefe no alto da tela (Sprint 20)?
