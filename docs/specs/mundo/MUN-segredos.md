# MUN-segredos — Baús escondidos

- **Status:** Implementada
- **Sprint:** 14
- **Relacionadas:** MUN-mapa, MUN-salas, PRO-xp, SAV-progresso, BAL-valores

## Contexto

> Sprint 18: as salas 02 e 03 foram refeitas e ganharam baús novos no lugar dos velhos (mesmo id), e entraram baús na `sala_01`, `sala_p03` e `sala_p06`. Cada um está descrito no relatório da Sprint 18; a regra 5 abaixo vale para a geometria da Sprint 14.


Os corredores `sala_02` e `sala_03` ganharam um segredo cada. O Victor pediu (Sprint 14) que o jogador seja **recompensado por resolver o problema de várias formas, não de uma forma específica**. Por isso o baú não olha *como* o mago chegou, só *se* chegou: o mesmo pilar dos puzzles, que validam o estado do mundo e nunca o código.

## Fora do escopo

Itens e equipamentos (a Alpha não tem inventário). Segredos que exigem peças novas. Paredes falsas.

## Regras

1. **Baú:** `segredo` em `targets` põe um baú com os pés na célula. O mago encostar nele abre o baú, uma vez por jogo: dá a XP de `segredo.xp` (balanceamento, hoje 10) e avisa no registro.
2. O id do segredo é `<sala>_<dígito>`. Os segredos abertos vão para o save (`segredos`) e o baú já nasce aberto, sem dar XP de novo.
3. **Dois caminhos ao menos:** todo baú do jogo tem pelo menos um caminho **com feitiço** e um **só com movimento** (pulo e esquiva). Os dois são testados com a sala do jogo. Outros caminhos que o jogador inventar também valem.
4. Os segredos ficam fora do caminho principal: nenhum bloqueio do mapa depende deles (MUN-mapa).
5. **Na Masmorra:**
   - `sala_02`: nicho alto na parede da esquerda, acima da escada. Com feitiço: levitar e mover de lado. Sem feitiço: subir pelas plataformas e saltar com esquiva no ar.
   - `sala_03`: nicho alto à direita, acima dos espinhos. Com feitiço: levitar e mover. Sem feitiço: a escada de plataformas da esquerda leva a uma plataforma alta, e dela um salto com esquiva alcança o nicho.

## Critérios de aceite

### MUN-090 — Baú dá XP uma vez (cena)

- **Dado** uma sala com um baú
- **Quando** o mago encosta nele, se afasta e encosta de novo
- **Então** ganha a XP do segredo uma vez só, o baú fica aberto e `World.found_secrets` tem o id

### MUN-091 — Baú aberto vem do save (cena)

- **Dado** um save com o segredo já aberto
- **Quando** o mago encosta no baú
- **Então** o baú já está aberto e não dá XP

### MUN-092 — sala_02 com feitiço (aceitação)

- **Dado** a `sala_02` do jogo e o Python de verdade, o mago no chão embaixo do nicho
- **Quando** conjura um feitiço com `levitar` e `mover`
- **Então** abre o baú

### MUN-093 — sala_02 só com movimento (aceitação)

- **Dado** a `sala_02` do jogo
- **Quando** o mago sobe pelas plataformas e salta com esquiva, sem feitiço
- **Então** abre o baú

### MUN-094 — sala_03 com feitiço (aceitação)

- Como MUN-092, na `sala_03`

### MUN-095 — sala_03 só com movimento (aceitação)

- Como MUN-093, na `sala_03`

### MUN-096 a MUN-098 — Segredos da Alpha 1.1 (aceitação)

- **Dado** a `sala_01`, a `sala_p03` e a `sala_p06` refeitas (Sprint 18), cada uma com um baú
- **Então** cada baú abre com um feitiço (Python de verdade) e, em outro teste, só com movimento (pulo, esquiva, plataformas)
- **E** a área tem 5 segredos (MUN-090 de `test_area_map`)

## Perguntas em aberto

- [ ] Além de XP, o baú poderia guardar uma página extra da Referência (curiosidade de Python)? Ideia para o GDD.
