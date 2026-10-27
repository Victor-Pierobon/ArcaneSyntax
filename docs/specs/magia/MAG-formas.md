# MAG-formas — Projétil, escudo e cajado

- **Status:** Implementada (visual provisório)
- **Sprint:** 6, 10
- **Relacionadas:** MAG-acoes, MAG-elementos, MUN-alvos, MUN-vida, COM-dano

## Regras

**Projétil**

1. Sai da mão do mago (8 px à frente, 16 px acima dos pés) a **220 px/s**, com a cor do elemento.
2. Com alvo (`alvo` do feitiço ou um item de `inimigos`, pelo id), voa em direção ao centro do alvo e **o persegue** enquanto ele existir (Sprint 10: os inimigos se mexem). Sem alvo, voa reto para onde o mago olha; se o alvo some no meio do caminho, continua reto na última direção.
3. Ao tocar um alvo, aplica o elemento e o dano (MAG-elementos, COM-dano) e some. **Com alvo, só acerta esse alvo** e atravessa os outros: num loop sobre o enxame, cada golpe vai para quem o feitiço escolheu. Sem alvo, ou depois que o alvo sumiu, acerta o primeiro que tocar. Ao tocar uma parede ou percorrer **12 tiles**, some (o projétil que persegue o chefe não tem esse limite: COM-chefe, regra 6).

**Escudo**

4. Um círculo da cor do elemento em volta do mago por **2 s**.
5. Enquanto ativo, **bloqueia o próximo ataque** (dano `ATTACK`; espinhos continuam machucando) e some ao bloquear. Um escudo novo substitui o anterior. Bloquear dá ao mago **1 s de invencibilidade**, como levar dano (Sprint 10: sem isso, um inimigo encostado mordia no quadro seguinte).
6. O elemento do escudo é guardado para as interações da Sprint 10 (guardião e chefe).

**Cajado**

7. Tecla **J**: golpe curto à frente do mago (área de 16 × 24 px por 0,15 s), **sem custo de mana**, com recarga de 0,35 s. O mago nunca fica indefeso (GDD).
8. O cajado acerta alvos com o "elemento" `cajado` (neutro).

**Faísca (Sprint 10)**

9. Igual ao projétil, mas menor e mais rápida (**300 px/s**), com dano base 1 (COM-dano) e custo 1 (EXE-custo). É a ferramenta para muitos inimigos pequenos (COM-enxame).

## Critérios de aceite

### MAG-010 — Projétil acerta o alvo

- **Dado** um boneco de fogo a 3 tiles
- **Quando** toca `lancar(gelo, projetil, <id do boneco>)`
- **Então** o boneco recebe gelo (efeito "fraco") e o projétil some

### MAG-011 — Projétil sem alvo

- **Quando** toca `lancar(fogo, projetil)` olhando para a direita, sem boneco no caminho
- **Então** o projétil voa para a direita e some ao bater na parede

### MAG-012 — Alvo que sumiu

- **Quando** o id do alvo não existe na sala
- **Então** o projétil voa reto para a frente, sem erro

### MAG-013 — Escudo

- **Quando** toca `lancar(raio, escudo)`
- **Então** o escudo aparece com o elemento raio; um ataque nesse tempo é bloqueado (a vida não muda) e o escudo some; outro ataque logo em seguida também não conta, só depois de 1 s; um espinho ainda machuca
- **E** sem bloquear nada, some depois de 2 s

### MAG-014 — Cajado

- **Dado** um boneco logo à frente
- **Quando** o mago golpeia com o cajado
- **Então** o boneco recebe `cajado`, a mana não muda, e um segundo golpe antes de 0,35 s não acontece

### MAG-015 — Faísca

- **Dado** um boneco de fogo a 3 tiles
- **Quando** toca `lancar(gelo, faisca, <id do boneco>)`
- **Então** o boneco recebe gelo pela forma `faisca`, e a faísca chega antes de um projétil lançado junto

### MAG-016 — O projétil persegue o alvo

- **Dado** um alvo que sobe 2 tiles logo depois do disparo
- **Então** o projétil o acerta mesmo assim

### MAG-017 — Só acerta o alvo escolhido

- **Dado** dois bonecos em linha, o mais perto no caminho
- **Quando** o projétil é lançado no mais longe
- **Então** só o mais longe é atingido; lançado sem alvo, quem é atingido é o mais perto
