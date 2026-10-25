# PUZ-05-elevador — Puzzle 5: o elevador de levitação

- **Status:** Rascunho
- **Sprint:** 9
- **Relacionadas:** PUZ-validacao (regras 12 e 13), MAG-acoes (MAG-070: levitar seguido de mover voa), GDD "um elevador que precisa de uma função com parâmetro"
- **Conceito:** funções

## Desenho

Três plataformas sobem em escada, cada uma alta demais para o pulo (mais de 3 tiles). Ao lado de cada uma está gravada a altura certa: **4, 6 e 5**. Em cima de cada plataforma há uma placa, e a porta abre com as três placas pisadas. Subir é sempre "levitar a altura certa e andar 2 tiles", e é isso que pede uma função com parâmetro.

- Sala: `sala_p05`, ligada à `sala_p04`
- Puzzle: `{"id": "p05_elevador", "condicoes": [{"tipo": "placas_pisadas"}]}`
- Layout: cada plataforma fica a 2 tiles na horizontal da anterior. `levitar(h)` com a altura gravada põe os pés do mago acima da borda; com `h - 1`, ele bate na parede. **O número gravado é o parâmetro certo**, e o level design se ajusta a isso, não o contrário.
- Descer é cair; a sala deixa voltar à entrada (MUN-salas, regra 8).

## Soluções que devem passar

O teste começa com a mana cheia e o mago diante da primeira plataforma.

| # | Estilo | Código |
| --- | --- | --- |
| A | Função com parâmetro | `def subir(altura):` / `    meditar()` / `    levitar(altura)` / `    mover(2)` / `subir(4)` / `subir(6)` / `subir(5)` |
| B | Loop sobre uma lista | `for altura in [4, 6, 5]:` / `    meditar()` / `    levitar(altura)` / `    mover(2)` |
| C | Linhas soltas, em três feitiços | `levitar(4)` / `mover(2)`; depois `levitar(6)` / `mover(2)`; depois `levitar(5)` / `mover(2)` (o teste enche a mana entre eles) |

Nas soluções A e B, o `meditar()` dentro da função é o que paga as três subidas numa conjuração só: subir custa 3,4 ou mais, e a mana máxima é 10.

## Soluções que devem falhar

| # | Por quê | Código |
| --- | --- | --- |
| X | A mesma altura para todas: bate na parede da segunda | `levitar(4)` / `mover(2)`, conjurado 3 vezes |
| Y | Ordem trocada: anda antes de subir | `mover(2)` / `levitar(4)` |

## Critérios de aceite

### PUZ-060 — Soluções válidas pisam as três placas

- **Dado** a sala_p05
- **Quando** conjura cada solução A, B e C, cada uma num mundo novo
- **Então** as três placas ficam pisadas, o puzzle `p05_elevador` fica resolvido e a porta abre

### PUZ-061 — Soluções erradas não resolvem

- **Quando** conjura X ou Y
- **Então** no máximo a primeira placa fica pisada e a porta continua fechada

## Perguntas em aberto

- [ ] A regra MAG-070 (levitar seguido de mover voa na horizontal) muda o comportamento de feitiços antigos. Hoje o mago cai depois de levitar; com a regra, `levitar(2)` seguido de `mover(3)` atravessa um vão voando. Isso pode abrir atalhos em salas antigas. A sala_01 a sala_03 não têm vãos que importem; revisar na montagem do mapa (Sprint 14).
