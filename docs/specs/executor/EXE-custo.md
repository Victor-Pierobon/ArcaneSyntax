# EXE-custo — Custo de mana dos feitiços

- **Status:** Implementada (Sprint 2); **regra 13 (custo de inscrição) em rascunho, Sprint 9**
- **Sprint:** 2, 9
- **Relacionadas:** EXE-protocolo, EXE-pecas, EXE-limites, PUZ-04-ponte, GDD "Mana como custo de execução"
- **Decisão do Victor (2026-10-25):** "linhas baratas": cada instrução custa pouco, peças têm custo base, recuperar mana é grátis.
- **Decisão do Victor (2026-10-25, Sprint 9):** custo de inscrição, para que um loop custe menos que as mesmas linhas repetidas (a ponte de 12 blocos do GDD).

## Contexto

O GDD quer que código eficiente custe menos, que um loop infinito acabe com a mana em vez de travar o jogo, e que o primeiro feitiço (`meditar()`, com mana 0) funcione.

## Regras

1. **Resolução de 0,1.** Internamente a mana é guardada em décimos inteiros; valores recebidos são arredondados para 0,1. Na resposta, valores inteiros saem como inteiros (`5`) e os demais com uma casa (`4.9`).
2. **Instrução simples** executada custa `custo_instrucao` (padrão **0,1**), cobrada **logo depois de ela terminar**. Assim `meditar()` com mana 0 recebe a mana antes de pagar, e também funciona dentro de uma função do jogador.
3. `return`, `break`, `continue` e `raise` são cobradas **antes** (não existe "depois" para elas).
4. **Estruturas não custam por si:** `while`, `for`, `if`, `try`, `with`, `match`, `def`, `class`. O que custa é o que roda dentro delas. Uma instrução que termina com erro não é cobrada.
5. **Peças** têm custo base, cobrado na chamada, depois de validar os argumentos e antes do efeito:

   | Peça | Regra | Padrão |
   | --- | --- | --- |
   | `lancar` | `custo_lancar` | 3 |
   | `mover` | `custo_mover` | 1 |
   | `levitar` | `custo_levitar` | 2 |
   | `meditar` | `custo_meditar` | 0 |
   | `absorver_mana` | `custo_absorver` | 0 |
   | `inscrever` (Sprint 9) | `custo_inscrever` | 1 |
   | `construir_bloco` (Sprint 9) | `custo_bloco` | 0,5 |
   | `ler_runa` (sentido, Sprint 9) | — | 0 |

6. **Teto depois do pagamento.** Ganhos de mana podem passar de `mana_max` durante a instrução; depois de pagar a instrução, a mana é limitada a `mana_max`.
7. **Sentidos atualizados a cada instrução.** `mana`, `mana_max` e `vida_atual` voltam ao valor real depois de cada instrução paga (substitui a regra 3 de EXE-pecas, que sincronizava só a cada peça).
8. **Sem mana para pagar:** erro `ManaEsgotada` na linha da instrução ou da peça; o que rodou antes fica (EXE-protocolo, regra 5). A ação de uma peça que não pôde ser paga não é registrada. A mana final fica no que sobrou.
9. A resposta traz `custo_mana`: total gasto em instruções e peças.
10. O custo é determinístico: mesmo código e mesma foto, mesmo custo.
11. **Estimativa para o grimório (Sprint 5):** o jogo executa o feitiço com mana alta e uma foto fictícia e lê `custo_mana`. Não existe modo especial no executor.
12. **Limitação conhecida:** compreensões (`[x for x in ...]`) não pagam por volta; o limite de tempo (EXE-limites) cobre os casos extremos.
13. **Custo de inscrição (Sprint 9).** A **primeira vez** que uma linha paga uma instrução numa execução, paga também `custo_inscricao` (padrão **0,1**). Nas vezes seguintes, essa linha paga só `custo_instrucao`. A conta é feita por linha do código do jogador: `a = 1; b = 2` na mesma linha paga a inscrição uma vez só. Linhas que nunca rodam não pagam inscrição, e cada execução começa do zero (o passivo paga de novo a cada rodada). Na prática, a primeira passagem por uma linha custa 0,2 e as seguintes, 0,1. Doze linhas `construir_bloco()` pagam doze inscrições; um loop paga uma.

   Com a regra 13, os números dos critérios abaixo foram recalculados. Os valores da Sprint 2 estão no histórico do git.

## Critérios de aceite

### EXE-040 — Instrução custa 0,1

- **Dado** mana 5
- **Quando** o feitiço é `x = 1\ny = 2`
- **Então** `custo_mana` é 0.4 (duas linhas, cada uma 0,1 + 0,1 de inscrição) e a mana final é 4.6

### EXE-041 — Estruturas não custam

- **Quando** o feitiço é `if True:\n    x = 1`
- **Então** `custo_mana` é 0.2

### EXE-042 — Laço paga cada volta

- **Quando** o feitiço é `for i in range(3):\n    x = i`
- **Então** `custo_mana` é 0.4 (três voltas de 0,1 e uma inscrição)

### EXE-043 — Custo base das peças

- **Dado** mana 20
- **Quando** o feitiço é `lancar(fogo, projetil)\nmover(1)\nlevitar(2)`
- **Então** `custo_mana` é 6.6 (3 + 1 + 2 + 3 × 0,2); com `regras` `{"custo_lancar": 1}` o custo é 4.6

### EXE-044 — Meditar com mana 0 funciona

- **Dado** mana 0
- **Quando** o feitiço é `meditar()`, ou uma função do jogador que chama `meditar()`
- **Então** o feitiço termina sem erro e com mana positiva (4.8 no caso direto)

### EXE-045 — O loop de absorver termina cheio

- **Dado** mana 0 de 5, `ganho_absorver` 1
- **Quando** o feitiço é `while mana < mana_max:\n    absorver_mana()`
- **Então** termina sem erro, com 6 ações `absorver_mana` e mana 5 (a primeira volta rende +0,8; as outras, +0,9; a última passa do teto e é cortada)

### EXE-046 — Mana esgotada

- **Dado** mana 0.6
- **Quando** o feitiço é `x = 1\nx = 2\nx = 3\nx = 4`
- **Então** `erro.tipo` é `"ManaEsgotada"` na linha 4, `custo_mana` é 0.6 e a mana final é 0

### EXE-047 — Peça sem mana não age

- **Dado** mana 2
- **Quando** o feitiço é `mover(1)\nlancar(fogo, projetil)`
- **Então** só a ação `mover` é registrada e o erro é `ManaEsgotada` na linha 2

### EXE-048 — Sentidos acompanham o gasto

- **Dado** mana 5
- **Quando** o feitiço é `x = 1\nprint(mana)`
- **Então** a saída é `4.8`

### EXE-049 — Checar antes de agir economiza

- **Dado** mana cheia (10 de 10)
- **Quando** o feitiço é `if mana < mana_max:\n    absorver_mana()`
- **Então** `custo_mana` é 0, enquanto `absorver_mana()` sozinho custa 0.2

### EXE-090 — Inscrição: a primeira passagem por uma linha custa mais

- **Dado** mana 5
- **Quando** o feitiço é `x = 1\nx = 2\nx = 3`
- **Então** `custo_mana` é 0.6; e `for i in range(3):\n    x = i` custa 0.4

### EXE-091 — O loop sai mais barato que as linhas repetidas

- **Dado** mana 20 e `regras` `{"custo_bloco": 0.5}`
- **Quando** o feitiço é doze linhas `construir_bloco()`
- **Então** `custo_mana` é 8.4; e `for i in range(12):\n    construir_bloco()` custa 7.3

### EXE-092 — Inscrição por linha, não por instrução

- **Quando** o feitiço é `a = 1; b = 2`
- **Então** `custo_mana` é 0.3 (duas instruções e uma inscrição)

### EXE-093 — Linha que não roda não paga inscrição

- **Dado** mana cheia (10 de 10)
- **Quando** o feitiço é `if mana < mana_max:\n    absorver_mana()`
- **Então** `custo_mana` é 0 (o passivo econômico continua grátis com a mana cheia)

### EXE-094 — Inscrição configurável

- **Dado** `regras` `{"custo_inscricao": 0}`
- **Quando** o feitiço é `x = 1\ny = 2`
- **Então** `custo_mana` é 0.2 (o comportamento da Sprint 2)
