# PUZ-06-revisao — Puzzle 6: a câmara de revisão

- **Status:** Rascunho
- **Sprint:** 9
- **Relacionadas:** PUZ-02 a PUZ-05, PUZ-validacao (regras 8 a 15)
- **Conceito:** revisão (sequência, variáveis, condicionais, loops e funções), com estrelas por economia de mana

## Desenho

Uma sala só, com os quatro mecanismos em sequência, da esquerda para a direita:

1. **Cadeado de runas:** três runas sorteadas e um `cadeado:soma` perto da entrada.
2. **Ponte de 8 blocos** sobre espinhos.
3. **Cristal mutável com 2 cargas** depois da ponte.
4. **Duas plataformas** com placas, de alturas 4 e 5.

A porta, no fim, abre quando tudo está feito. As estrelas medem a mana gasta nos feitiços que agem (PUZ-validacao, regra 14).

- Sala: `sala_p06`, ligada à `sala_p05`
- Puzzle: `{"id": "p06_revisao", "condicoes": [{"tipo": "cadeados_abertos"}, {"tipo": "ponte_completa"}, {"tipo": "cristais_acesos"}, {"tipo": "placas_pisadas"}], "estrelas": [20.0, 24.0]}`
- Os limites das estrelas são **provisórios**: a referência econômica (A) dá 19.5 e a detalhada (B) dá 21.0. Calibrar no playtest.

## Soluções que devem passar

O teste fixa as runas em 4, 7 e 2 e a semente do cristal. Ele leva o mago a cada ponto, como um jogador andaria, e enche a mana antes de cada conjuração.

| # | Estilo | Feitiços, na ordem | Custo | Estrelas |
| --- | --- | --- | --- | --- |
| A | Econômica | `inscrever(ler_runa(1) + ler_runa(2) + ler_runa(3))` (1.2); `for i in range(8):` / `construir_bloco()` (4.9); a solução A do PUZ-03 duas vezes (3.2 cada); `def subir(h):` / `levitar(h)` / `mover(2)` / `subir(4)` / `subir(5)` (7.0) | 19.5 | 3 |
| B | Detalhada | a solução A do PUZ-02 (1.8); 8 linhas `construir_bloco()` (5.6); a solução B do PUZ-03 duas vezes (3.4 cada); `levitar(4)` / `mover(2)` / `levitar(5)` / `mover(2)` (6.8) | 21.0 | 2 |
| C | Passivo e funções | a solução A do PUZ-03 no passivo, ligado antes de atravessar a ponte; o resto como em A | — | pelo menos 1 |

## Soluções que devem falhar

| # | Por quê | Código |
| --- | --- | --- |
| X | Ponte incompleta | tudo como em A, mas com `range(7)` |
| Y | Cristal com elemento fixo | tudo como em A, mas com `lancar(fogo, projetil, alvo)` no cristal |

## Critérios de aceite

### PUZ-070 — Soluções válidas abrem a porta

- **Dado** a sala_p06
- **Quando** cada solução A, B e C é conjurada como descrito, cada uma num mundo novo
- **Então** o puzzle `p06_revisao` fica resolvido e a porta abre

### PUZ-071 — Estrelas pela economia

- **Então** a solução A ganha 3 estrelas e a B, 2; um erro a mais no cristal (3.2 gastos à toa) tira a A das 3 estrelas

### PUZ-072 — Soluções erradas não abrem

- **Quando** X ou Y
- **Então** a porta continua fechada, mesmo com as outras três condições cumpridas

## Perguntas em aberto

- [ ] Onde mostrar as estrelas? Proposta mínima para a Alpha: no registro de conjuração ("Puzzle resolvido! ★★☆") e no HUD por 3 s. Uma tela de resultado fica para depois.
- [ ] A distância entre A e B é pequena (1.5). Se o playtest mostrar que as estrelas não motivam, aumentar a ponte para 10 ou 12 blocos.
