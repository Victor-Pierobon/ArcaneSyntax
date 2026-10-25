# GRI-erros — Erros, teste e custo estimado no grimório

- **Status:** Implementada
- **Sprint:** 5
- **Relacionadas:** EXE-erros, EXE-custo, EXE-limites, EXE-sandbox, EXE-desbloqueio, GRI-slots

## Contexto

O GDD pede a mensagem real da linguagem, a linha marcada e uma tradução no mundo, para o jogador aprender a ler o erro de verdade. O custo estimado aparece antes de equipar, para planejar.

## Regras

**Frase no mundo**

1. Cada erro é mostrado em duas partes: uma frase no mundo e, abaixo, `Tipo: mensagem real (linha N)`.

   | Tipo | Frase (textos em `textos.csv`) |
   | --- | --- |
   | `SyntaxError`, `IndentationError` | A runa da linha N está malformada. |
   | `NameError` | A linha N invoca algo que não existe. |
   | `TypeError`, `ValueError`, `AttributeError` | A linha N usou uma peça do jeito errado. |
   | `ZeroDivisionError` | A linha N tentou dividir por zero. |
   | `ManaEsgotada` | A mana acabou na linha N. |
   | `TempoEsgotado` | O feitiço demorou demais e se desfez. |
   | `LimiteExcedido` | O feitiço tentou fazer coisas demais de uma vez. |
   | `FeiticoProibido` | A linha N usa uma magia proibida. |
   | `PecaBloqueada` | Você ainda não conhece essa magia (linha N). |
   | `ExecutorIndisponivel`, `RespostaInvalida` | O grimório não respondeu. Tente de novo. |
   | qualquer outro | Algo deu errado na linha N. |

   Sem linha, a frase omite o "linha N".

**Testar**

2. O botão **Testar** do grimório executa o feitiço selecionado com o estado real do mago e o alvo atual, **sem gastar mana nem mudar o mundo**, e mostra o resultado no painel de baixo: a frase de erro (se houver), as visões, as ações e o custo.
3. Com erro, a linha do erro fica **marcada** no editor. Editar o código tira a marca.
4. Um erro numa conjuração por slot também fica guardado: ao abrir o grimório nesse feitiço, a linha aparece marcada e o painel mostra o erro.

**Custo estimado**

5. Ao selecionar um feitiço e logo depois de editar (meio segundo sem digitar), o grimório executa o feitiço com **mana 1000 de 1000** e um alvo fictício (fogo, a 3 tiles), com as peças desbloqueadas, e mostra `Custo estimado: X`. Se der erro, mostra `Custo estimado: — (erro na linha N)`.
6. A estimativa depende do caminho que o código toma: com um alvo de outro elemento, o custo real pode mudar. O texto deixa isso claro ("com alvo de fogo").

## Critérios de aceite

### GRI-050 — Frase no mundo

- **Dado** cada tipo de erro da tabela
- **Então** a descrição tem a frase certa com o número da linha e a linha `Tipo: mensagem (linha N)`; sem linha, não aparece "linha"

### GRI-051 — Testar mostra o resultado sem gastar mana

- **Dado** mana 5 e o feitiço `print("oi")\nlancar(fogo, projetil)`
- **Quando** aperta Testar
- **Então** o painel mostra a visão "oi", a ação e o custo 3.2, e a mana do mago continua 5

### GRI-052 — Linha marcada e desmarcada

- **Quando** Testar dá erro na linha 2
- **Então** a linha 2 do editor fica marcada; ao editar, a marca some

### GRI-053 — Erro de conjuração aparece no grimório

- **Dado** uma conjuração do slot 1 que deu erro na linha 3
- **Quando** abre o grimório nesse feitiço
- **Então** a linha 3 está marcada e o painel mostra o erro

### GRI-060 — Custo estimado

- **Quando** seleciona `lancar(fogo, projetil, alvo)`
- **Então** aparece `Custo estimado: 3.1`; a requisição usou mana 1000 de 1000 e alvo de fogo

### GRI-061 — Estimativa com erro

- **Quando** o feitiço tem erro de sintaxe na linha 1
- **Então** aparece o traço e a linha do erro

### GRI-062 — Recalcula depois de editar

- **Quando** o código muda
- **Então** a estimativa é recalculada depois do intervalo (sem executar a cada tecla)
