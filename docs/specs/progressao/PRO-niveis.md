# PRO-niveis — Níveis e mana máxima

- **Status:** Implementada
- **Sprint:** 12
- **Relacionadas:** PRO-xp, BAL-valores, MUN-vida, UI-hud, EXE-protocolo (`mana_max`)

## Contexto

"Cada nível aumenta a mana máxima, permitindo feitiços maiores e mais complexos" (GDD, Progressão). A regra de equilíbrio do GDD vale: nenhuma porta depende só de nível; código melhor compensa nível baixo.

## Fora do escopo

Níveis acima do 5 (Atos seguintes). Vida que sobe com nível. Escolhas de atributo. Gravar o nível em disco (Sprint 13).

## Regras

1. O mago começa no **nível 1**. O teto da Alpha é o **nível 5**.
2. O balanceamento, seção `niveis`, tem duas listas do mesmo tamanho (uma posição por nível):
   - `xp`: a XP acumulada para chegar a cada nível, **[0, 30, 70, 130, 210]**;
   - `mana_max`: a mana máxima de cada nível, **[10, 12, 14, 16, 18]**.
   A seção `mago.mana_max` deixa de existir: a mana máxima inicial é a do nível 1.
3. Ao ganhar XP, o nível é o maior cujo limiar a XP alcança. Um ganho grande pode subir mais de um nível de uma vez. No nível 5 a XP continua contando, mas o nível não sobe.
4. **Subir de nível**: a mana máxima passa à do nível novo e a **mana enche**. O registro mostra `Nível 3! Mana máxima 14`. Emite `leveled_up(nivel)`.
5. O feitiço vê a mana máxima nova (`mana_max` na foto do mundo).
6. O HUD mostra o nível e a XP: `Nível 2 · XP 45/70` (XP atual / limiar do próximo nível); no nível 5, `Nível 5 · XP 240`.

## Critérios de aceite

### PRO-020 — Curva de níveis

- **Então** `Progression.level_for(xp)` é 1 para 0 e 29, 2 para 30, 3 para 70 e 129, 4 para 130, 5 para 210 e para 9999
- **E** `Progression.mana_max_for(nivel)` é 10, 12, 14, 16, 18 do nível 1 ao 5

### PRO-021 — Subir de nível aumenta e enche a mana

- **Dado** um `MagoState` no nível 1 com mana 3
- **Quando** ganha 30 XP
- **Então** está no nível 2, com mana máxima 12 e mana 12, e emitiu `leveled_up(2)` uma vez

### PRO-022 — Vários níveis de uma vez e o teto

- **Dado** o nível 1
- **Quando** ganha 140 XP
- **Então** está no nível 4 (mana máxima 16), com `leveled_up` emitido para 2, 3 e 4
- **Quando** ganha mais 1000
- **Então** está no nível 5 (mana máxima 18) e a XP é 1140

### PRO-023 — HUD e registro (cena)

- **Dado** o mundo com o mago no nível 1
- **Então** o HUD mostra `Nível 1 · XP 0/30`
- **Quando** o mago ganha 45 XP
- **Então** o HUD mostra `Nível 2 · XP 45/70` e a mana `12.0/12.0`; o registro mostra `Nível 2! Mana máxima 12`

### PRO-024 — O feitiço vê a mana máxima nova (cena)

- **Dado** o mago no nível 2
- **Então** a foto do mundo tem `mana_max` 12

## Perguntas em aberto

- [ ] +2 de mana por nível é perceptível? (playtest)
