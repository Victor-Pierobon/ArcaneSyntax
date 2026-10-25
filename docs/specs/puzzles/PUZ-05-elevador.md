# PUZ-05-elevador — Puzzle 5: o elevador de levitação

- **Status:** Implementada
- **Sprint:** 9
- **Relacionadas:** PUZ-validacao (regras 12 e 13), MAG-acoes (MAG-070: levitar seguido de mover voa), GDD "um elevador que precisa de uma função com parâmetro"
- **Conceito:** funções

## Desenho

Três colunas de pedra sobem em escada, cada uma alta demais para o pulo. Ao lado de cada uma está gravada a altura certa: **5, 7 e 6**. Em cima de cada coluna há uma placa, e a porta abre com as três placas pisadas. Subir é sempre "levitar a altura certa e andar 2 tiles", e é isso que pede uma função com parâmetro.

- Sala: `sala_p05`, ligada à `sala_p04`
- Puzzle: `{"id": "p05_elevador", "condicoes": [{"tipo": "placas_pisadas"}]}`
- Layout: colunas de 2 tiles de largura, coladas umas nas outras, com 4, 10 e 15 tiles de altura. Ou seja, cada uma fica 4, 6 e 5 tiles acima da anterior. O número gravado é **um a mais** que o degrau: `levitar(h)` põe os pés do mago um tile acima da borda, o `mover(2)` o leva para cima da coluna e ele cai esse tile. O primeiro degrau tem 4 tiles porque o pulo alcança 3 (MUN-salas, regra 8).
- O mago começa encostado na primeira coluna, que é onde ele para naturalmente quando anda para a direita.
- Descer é cair; a sala deixa voltar à entrada (MUN-salas, regra 8).
- **Mudança na implementação:** o rascunho previa alturas 4, 6 e 5. Com essas alturas, o primeiro degrau teria 3 tiles e daria para subir só pulando.

## Soluções que devem passar

O teste começa com o mago encostado na primeira coluna.

| # | Estilo | Código |
| --- | --- | --- |
| A | Função com parâmetro, começando sem mana | `def subir(altura):` / `    meditar()` / `    levitar(altura)` / `    mover(2)` / `subir(5)` / `subir(7)` / `subir(6)` |
| B | Loop sobre uma lista, começando sem mana | `for altura in [5, 7, 6]:` / `    meditar()` / `    levitar(altura)` / `    mover(2)` |
| C | Linhas soltas, em três feitiços | `levitar(5)` / `mover(2)`; depois `levitar(7)` / `mover(2)`; depois `levitar(6)` / `mover(2)` (o teste enche a mana entre eles) |

Nas soluções A e B, o `meditar()` dentro do laço ou da função é o que paga as três subidas numa conjuração só: cada subida custa 3,4 ou mais, e a mana máxima é 10.

## Soluções que devem falhar

| # | Por quê | Código |
| --- | --- | --- |
| X | A mesma altura para todas: bate na parede da segunda coluna | `levitar(5)` / `mover(2)`, conjurado 3 vezes |
| Y | Ordem trocada: anda antes de subir | `mover(2)` / `levitar(5)` |

## Critérios de aceite

### PUZ-060 — Soluções válidas pisam as três placas

- **Dado** a sala_p05
- **Quando** conjura cada solução A, B e C, cada uma num mundo novo
- **Então** as três placas ficam pisadas, o puzzle `p05_elevador` fica resolvido e a porta abre

### PUZ-061 — Soluções erradas não resolvem

- **Quando** conjura X ou Y
- **Então** com X, só a primeira placa fica pisada; com Y, nenhuma; a porta continua fechada

## Perguntas em aberto

- [ ] A regra MAG-070 (levitar seguido de mover voa na horizontal) muda o comportamento de feitiços antigos. Hoje, `levitar(2)` seguido de `mover(3)` atravessa um vão voando. Isso pode abrir atalhos em salas antigas. As salas 01 a 03 não têm vãos que importem; revisar na montagem do mapa (Sprint 14).
