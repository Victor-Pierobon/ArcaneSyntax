# COM-chefe — Chefe da Masmorra

- **Status:** Implementada
- **Sprint:** 11
- **Relacionadas:** COM-dano, COM-elemental, COM-guardiao, MAG-elementos, MUN-vida, BAL-valores, ADR-001

## Contexto

O GDD pede que cada ato feche com um chefe que muda de fase e de fraqueza, "o que obriga o jogador a ter feitiços que se adaptam". O chefe da Masmorra cobra o que o Ato I ensinou no combate: ler `alvo.elemento` antes de lançar (condicional ou dicionário) e se proteger com o escudo. Um feitiço fixo vence a primeira fase e emperra na segunda. O feitiço adaptável vence as duas sem mudar nada.

## Fora do escopo

Arte, animação e música definitivas. Barra de vida do chefe no HUD. Gravar em disco que o chefe foi derrotado (save, Sprint 13). Fala da serpente antes da luta (Sprint 13). Mais de duas fases e o chefe final.

## Regras

1. Em `targets`: `inimigo:chefe`. O chefe fica parado. Vida **30**, dano de contato **1** (COM-dano, regra 4). Os números vêm do arquivo de balanceamento (BAL-valores).
2. **Fases** (`BossPhases`, regra pura): na **fase 1** o corpo é de **fogo** (fraco a gelo); na **fase 2**, de **gelo** (fraco a raio). O dano segue COM-dano, regra 1, com o elemento da fase.
3. **Gatilho da troca:** a fase 2 começa quando a vida chega a **15** (metade) ou menos. Na fase 1 nenhum golpe leva a vida abaixo de 15: o golpe que passaria do limite para em 15, e o texto mostra o dano que contou. Assim a troca nunca é pulada.
4. **Transição:** ao trocar, o chefe passa **1,5 s** invulnerável: todo golpe nesse tempo é bloqueado (`Bloqueou`, dano 0). Ele mostra `Fase 2!`, pisca alternando a cor da fase velha e a da nova, solta partículas e não ataca.
5. **Sinal da fraqueza:** o corpo tem a cor do elemento da fase e o nome acima dele é o elemento. A troca de cor e de nome acontece no início da transição. O feitiço já vê o elemento novo durante a transição (na foto do mundo, `elemento` é o da fase nova; `escudo` é sempre `null`).
6. **Ataque à distância:** enquanto o mago está a até **12 tiles**, o chefe lança um **orbe** a cada **3 s** na fase 1 e a cada **2 s** na fase 2. O primeiro sai um intervalo depois de o mago chegar perto, e o relógio recomeça no fim da transição. O orbe tem a cor da fase, voa reto para onde estava o centro do mago a **90 px/s**, some numa parede ou depois de 16 tiles, e tira **1** de vida como ataque: o escudo do mago bloqueia, a esquiva evita e vale a invencibilidade de 1 s (MUN-vida). Empurra o mago como o contato.
7. **Derrota:** com vida 0 o chefe é derrotado como qualquer inimigo (COM-dano, regra 2). A porta `|` da sala abre, o registro mostra `Chefe derrotado!` e o chefe **não reaparece** enquanto o jogo estiver aberto: voltando à sala, ele não está lá e a porta já está aberta. A regra 5 de COM-dano (inimigos reaparecem) não vale para o chefe.
8. Morrer na luta monta a sala de novo com o chefe de vida cheia na fase 1 (MUN-vida).
9. O jogo pausado congela o chefe, os orbes, a transição e o relógio do ataque (COM-dano, regra 7).
10. Sala provisória: `sala_c04`, depois da saída da `sala_c03`; a porta guarda um nicho com um ponto seguro, até a montagem da área (Sprint 14).

## Critérios de aceite

### COM-080 — Fases e fraqueza

- **Dado** um `BossPhases` novo
- **Então** está na fase 1 com elemento `fogo`; o projétil de gelo dá 6, o de raio dá 3 e o de fogo dá 1
- **Quando** a vida chega a 15
- **Então** passa para a fase 2 com elemento `gelo`; o projétil de raio dá 6 e o de gelo dá 1

### COM-081 — A troca não é pulada

- **Dado** a fase 1 com vida 18
- **Quando** recebe um projétil de gelo (6)
- **Então** o dano é 3, a vida fica em 15 e começa a transição
- **E** com vida 30 e golpe de 6, o dano é 6 (o limite só corta o golpe que passaria)

### COM-082 — Transição invulnerável

- **Dado** a transição recém-começada
- **Então** qualquer golpe é bloqueado com dano 0 até passar 1,5 s; depois, o golpe volta a contar pela fase 2

### COM-083 — Relógio do ataque

- **Dado** o mago perto desde o início
- **Então** o primeiro orbe sai aos 3 s e o seguinte aos 6 s; com o mago longe, nenhum sai; na transição, nenhum sai; na fase 2, saem a cada 2 s contados do fim da transição

### COM-084 — Chefe na sala (cena)

- **Dado** uma sala com `inimigo:chefe`
- **Então** o alvo é `{"id", "elemento": "fogo", "distancia", "vida": 30, "escudo": null}`
- **Quando** a vida chega a 15
- **Então** o alvo passa a ter `"elemento": "gelo"`, o corpo e o nome trocam para gelo e o texto mostra `Fase 2!`

### COM-085 — O orbe machuca e o escudo bloqueia (cena)

- **Dado** o mago a 6 tiles do chefe
- **Quando** passa um intervalo de ataque
- **Então** um orbe acerta o mago, tira 1 de vida e o empurra; com o escudo ativo, o escudo some e a vida não muda

### COM-086 — Derrota, porta e memória (cena)

- **Dado** o chefe derrotado
- **Então** a porta abre, o registro mostra `Chefe derrotado!` e, ao sair e voltar, a sala não tem chefe e a porta está aberta
- **E** morrer antes de derrotá-lo traz o chefe de volta com vida 30 na fase 1

### COM-087 — Pausa congela (cena)

- **Dado** o chefe na transição e um orbe no ar
- **Quando** o jogo pausa
- **Então** o orbe não anda, a transição não termina e nenhum orbe novo sai

### COM-088 — Encontro com Python real (aceitação, `sala_c04`)

- **Dado** a sala do chefe
- **Quando** o mago conjura o feitiço adaptável de referência (com dicionário, ou com `if`), esperando o fim da transição quando ela acontece
- **Então** seis conjurações derrotam o chefe, gastando no máximo **21** de mana no total (orçamento de referência)
- **E** o feitiço fixo `lancar(gelo, projetil, alvo)` leva o chefe à fase 2 em três conjurações e depois causa só 1 por golpe

## Exemplos

```python
# Feitiço de referência: o mesmo do elemental (COM-dano) vence as duas fases
vence = {"fogo": gelo, "gelo": raio, "planta": fogo}
lancar(vence[alvo.elemento], projetil, alvo)
```

Custo: 3,4 de mana por conjuração (duas linhas, com inscrição, mais 3 do `lancar`); seis conjurações dão 20,4. Com mana máxima 10, o jogador precisa meditar no meio da luta (ou usar um passivo de `absorver_mana`), protegendo-se dos orbes.

Vida por conjuração: fase 1: 30 → 24 → 18 → 15 (o terceiro golpe para no limite); fase 2: 15 → 9 → 3 → 0.

## Perguntas em aberto

- [ ] Vida 30, orbe a cada 3 s/2 s e transição de 1,5 s estão justos? (playtest; os valores estão em `balanceamento.json`)
- [ ] O orbe precisa de aviso antes de sair (o chefe brilhar meio segundo antes)? (checklist de sensação)
