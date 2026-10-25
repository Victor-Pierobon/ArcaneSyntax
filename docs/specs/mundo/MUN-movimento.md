# MUN-movimento — Movimento do mago

- **Status:** Implementada (protótipo da Sprint 0)
- **Sprint:** 0 (protótipo), 3 (esquiva, coyote time, jump buffer)
- **Relacionadas:** `docs/roadmap-alpha.md`

## Contexto

O mago precisa andar e pular pela torre com controle responsivo, no estilo do gênero. Na Sprint 0 o objetivo é um protótipo que já nasce testável; o ajuste fino de sensação vem na Sprint 3.

## Fora do escopo

Esquiva, coyote time, jump buffer, aceleração gradual, animações (Sprint 3). Movimento causado por feitiços (`mover()`, `levitar()`), que vem na Sprint 6.

## Regras

1. O movimento é calculado por uma regra pura (`PlayerMotor`), separada do Node, a partir de uma **intenção** (direção horizontal, pulo apertado neste quadro, pulo segurado).
2. A intenção vem do teclado por padrão, mas pode ser trocada por outra fonte (testes, feitiços no futuro).
3. Parâmetros são definidos em termos de jogo, não de física: velocidade de andar em px/s e **altura do pulo em pixels**. A velocidade do pulo é derivada: `v = sqrt(2 · gravidade · altura)`.
4. Valores do protótipo: tile de 16 px; andar 120 px/s; gravidade 980 px/s²; altura do pulo 48 px (3 tiles); queda máxima 400 px/s; corte do pulo 0,5.

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

## Perguntas em aberto

- [ ] Aceleração e desaceleração graduais? Decidir jogando, na Sprint 3.
