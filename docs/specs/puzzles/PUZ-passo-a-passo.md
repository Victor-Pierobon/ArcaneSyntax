# PUZ-passo-a-passo — Ver o feitiço rodar linha a linha

- **Status:** Implementada (visual provisório)
- **Sprint:** 8
- **Relacionadas:** MAG-acoes, PUZ-validacao, GDD "Execução visível nos puzzles"

## Contexto

"Ver o loop girando ensina mais que qualquer explicação" (GDD). Cada ação já chega do executor com a linha que a gerou, então basta mostrar o código e destacar a linha enquanto a ação acontece.

## Regras

1. Em **salas com puzzle**, ao conjurar, aparece um painel com o código do feitiço, e a linha da ação que está acontecendo fica **destacada**. O painel some 1 s depois que as ações terminam.
2. Nessas salas, depois de cada ação há uma pausa de **0,3 s** dividida pela velocidade, para dar tempo de acompanhar.
3. **Velocidade ajustável** com a tecla **V**: 1× → 2× → 0,5× → 1×. O painel mostra a velocidade atual.
4. Fora de salas com puzzle, não há painel nem pausa (o combate continua rápido).
5. O passivo não aparece no painel (só as conjurações dos slots).

## Critérios de aceite

### PUZ-010 — A fila avisa cada ação

- **Quando** o `ActionPlayer` toca uma fila com o código do feitiço
- **Então** emite `sequence_started(codigo)` e `action_started(acao)` para cada ação, em ordem

### PUZ-011 — Pausa entre ações

- **Dado** `step_delay` de 0,3 s
- **Então** cada ação espera esse tempo antes da próxima; com 0, não espera

### PUZ-012 — Painel destaca a linha (cena)

- **Dado** uma sala com puzzle
- **Quando** conjura `meditar()\nmeditar()\nmover(1)`
- **Então** o painel mostra o código e a linha destacada passa por 1, 2 e 3

### PUZ-013 — Velocidade

- **Quando** aperta V três vezes
- **Então** a velocidade vai a 2×, 0,5× e volta a 1×, e a pausa entre ações acompanha (0,15 s; 0,6 s; 0,3 s)

### PUZ-014 — Fora de puzzle não aparece

- **Dado** uma sala sem puzzle
- **Quando** conjura
- **Então** o painel não aparece e não há pausa entre ações
