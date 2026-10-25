# MAG-formas — Projétil, escudo e cajado

- **Status:** Implementada (visual provisório)
- **Sprint:** 6
- **Relacionadas:** MAG-acoes, MAG-elementos, MUN-alvos, MUN-vida; Sprint 10 (inimigos)

## Regras

**Projétil**

1. Sai da mão do mago (8 px à frente, 16 px acima dos pés) a **220 px/s**, com a cor do elemento.
2. Com alvo (`alvo` do feitiço, pelo id), voa em direção ao centro do alvo naquele momento. Sem alvo, ou se o alvo não existe mais, voa reto para onde o mago olha.
3. Ao tocar um alvo, aplica o elemento nele (MAG-elementos) e some. Ao tocar uma parede ou percorrer **12 tiles**, some.

**Escudo**

4. Um círculo da cor do elemento em volta do mago por **2 s**.
5. Enquanto ativo, **bloqueia o próximo ataque** (dano `ATTACK`; espinhos continuam machucando) e some ao bloquear. Um escudo novo substitui o anterior.
6. O elemento do escudo é guardado para as interações da Sprint 10 (guardião e chefe).

**Cajado**

7. Tecla **J**: golpe curto à frente do mago (área de 16 × 24 px por 0,15 s), **sem custo de mana**, com recarga de 0,35 s. O mago nunca fica indefeso (GDD).
8. O cajado acerta alvos com o "elemento" `cajado` (neutro).

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
- **Então** o escudo aparece com o elemento raio; um ataque nesse tempo é bloqueado (a vida não muda) e o escudo some; um espinho ainda machuca
- **E** sem bloquear nada, some depois de 2 s

### MAG-014 — Cajado

- **Dado** um boneco logo à frente
- **Quando** o mago golpeia com o cajado
- **Então** o boneco recebe `cajado`, a mana não muda, e um segundo golpe antes de 0,35 s não acontece
