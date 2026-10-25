# MUN-movimento — Movimento do mago

- **Status:** Implementada
- **Sprint:** 0 (MUN-001 a 008), 3 (MUN-009 a 014)
- **Relacionadas:** `docs/roadmap-alpha.md`

## Contexto

O mago precisa andar e pular pela torre com controle responsivo, no estilo do gênero. Na Sprint 0 o objetivo é um protótipo que já nasce testável; o ajuste fino de sensação vem na Sprint 3.

## Fora do escopo

Aceleração gradual e animações (decidir jogando). Movimento causado por feitiços (`mover()`, `levitar()`), que vem na Sprint 6.

## Regras

1. O movimento é calculado por uma regra pura (`PlayerMotor`), separada do Node, a partir de uma **intenção** (direção horizontal, pulo apertado neste quadro, pulo segurado, esquiva apertada neste quadro).
2. A intenção vem do teclado por padrão, mas pode ser trocada por outra fonte (testes, feitiços no futuro).
3. Parâmetros são definidos em termos de jogo, não de física: velocidade de andar em px/s e **altura do pulo em pixels**. A velocidade do pulo é derivada: `v = sqrt(2 · gravidade · altura)`.
4. Valores: tile de 16 px; andar 120 px/s; gravidade 980 px/s²; altura do pulo 48 px (3 tiles); queda máxima 400 px/s; corte do pulo 0,5.
5. **Coyote time** 0,1 s: logo depois de sair de uma beirada, o pulo ainda vale.
6. **Jump buffer** 0,1 s: o pulo apertado pouco antes de tocar o chão acontece ao tocar.
7. **Esquiva** (tecla Shift): arrancada horizontal a 280 px/s por 0,16 s (cerca de 3 tiles) na direção para onde o mago olha, sem gravidade. Recarga de 0,35 s depois de terminar. No ar, uma esquiva por salto (recarrega ao tocar o chão). Durante a esquiva o mago fica **invulnerável a ataques** (não a espinhos; ver MUN-vida).
8. O mago olha para a última direção horizontal pedida (começa olhando para a direita).
9. **Voo controlado** (Sprint 6, usado por `levitar`): a intenção pode trazer uma velocidade vertical fixa (`fly_y`). Com ela, a gravidade não age e a velocidade vertical é exatamente `fly_y` (negativo sobe, 0 paira).

## Critérios de aceite

### MUN-001 — Andar

- **Dado** o mago no chão
- **Quando** a intenção é direção +1 (ou −1)
- **Então** a velocidade horizontal é +120 (ou −120) px/s

### MUN-002 — Parar ao soltar

- **Dado** o mago andando
- **Quando** a direção volta a 0
- **Então** a velocidade horizontal é 0

### MUN-003 — Gravidade com limite

- **Dado** o mago no ar
- **Quando** passa um quadro de `delta` segundos
- **Então** a velocidade vertical aumenta `gravidade · delta`, sem passar da queda máxima

### MUN-004 — Pular do chão

- **Dado** o mago no chão
- **Quando** o pulo é apertado
- **Então** a velocidade vertical vira `−sqrt(2 · gravidade · altura_pulo)`

### MUN-005 — Sem pulo no ar

- **Dado** o mago no ar
- **Quando** o pulo é apertado
- **Então** a velocidade vertical não recebe impulso

### MUN-006 — Pulo variável

- **Dado** o mago subindo
- **Quando** o pulo deixa de ser segurado
- **Então** a velocidade vertical é multiplicada pelo corte do pulo (0,5), uma única vez por pulo

### MUN-007 — Pousar no chão (cena)

- **Dado** o mago solto no ar acima do chão da sala de protótipo
- **Quando** passa cerca de 1 segundo
- **Então** ele está apoiado no chão, sem atravessá-lo

### MUN-008 — Altura do pulo (cena)

- **Dado** o mago parado no chão
- **Quando** pula segurando o botão
- **Então** a altura máxima atingida é `altura_pulo` com tolerância de 3 px

### MUN-009 — Coyote time

- **Dado** o mago saiu do chão há menos de 0,1 s sem pular
- **Quando** o pulo é apertado
- **Então** ele pula; depois de 0,1 s no ar, não pula mais

### MUN-010 — Jump buffer

- **Dado** o mago no ar
- **Quando** o pulo é apertado e ele toca o chão em até 0,1 s
- **Então** ele pula ao tocar o chão; se tocar depois de 0,1 s, não pula

### MUN-011 — Esquiva

- **Dado** o mago parado olhando para a esquerda
- **Quando** a esquiva é apertada
- **Então** a velocidade é (−280, 0) durante 0,16 s, sem gravidade, e depois volta ao movimento normal

### MUN-012 — Recarga e esquiva no ar

- **Dado** uma esquiva que acabou de terminar
- **Quando** a esquiva é apertada antes de 0,35 s
- **Então** nada acontece; no ar, só uma esquiva por salto, renovada ao tocar o chão

### MUN-013 — Invulnerável durante a esquiva

- **Dado** o mago esquivando
- **Então** `is_invulnerable()` é verdadeiro; antes e depois, falso

### MUN-014 — Distância da esquiva (cena)

- **Dado** o mago parado no chão
- **Quando** esquiva
- **Então** percorre 3 tiles (48 px) com tolerância de 5 px

### MUN-015 — Voo controlado

- **Dado** o mago no ar com `fly_y = -96`
- **Então** a velocidade vertical é −96, sem gravidade; com `fly_y = 0`, ele paira; sem `fly_y`, a gravidade volta

## Perguntas em aberto

- [ ] Aceleração e desaceleração graduais? Decidir jogando.
