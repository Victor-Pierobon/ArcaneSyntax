# EXE-protocolo — Protocolo Godot ↔ executor (v1)

- **Status:** Implementada
- **Sprint:** 1, 9, 10
- **Relacionadas:** ADR-001, ADR-002, EXE-pecas, EXE-erros

## Contexto

O jogo envia o código do feitiço e uma foto do mundo; o executor devolve o que o feitiço fez. Esse contrato é a fronteira entre as duas metades do projeto, então ele é testado dos dois lados com as mesmas fixtures (`tests/contract/`).

## Fora do escopo

As regras de custo, limites e sandbox estão em EXE-custo, EXE-limites e EXE-sandbox (Sprint 2); aqui só o formato.

## Regras

1. Transporte: uma requisição JSON por linha no stdin do worker; uma resposta JSON por linha no stdout, na mesma ordem.
2. Requisição:
   ```json
   {
     "versao": 1,
     "id": 7,
     "codigo": "lancar(fogo, projetil, alvo)",
     "mundo": {
       "mago": {"vida": 10, "mana": 5, "mana_max": 20},
       "alvo": {"id": "elemental_1", "elemento": "fogo", "distancia": 4.5}
     },
     "regras": {"ganho_meditar": 5, "ganho_absorver": 1}
   }
   ```
   `mundo.alvo` pode ser `null`. `pecas` é opcional: a lista de peças desbloqueadas (sem o campo, todas; EXE-desbloqueio). `regras` é opcional; cada valor ausente usa o padrão:

   | Regra | Padrão | Spec |
   | --- | --- | --- |
   | `ganho_meditar` | 5 | EXE-pecas |
   | `ganho_absorver` | 1 | EXE-pecas |
   | `custo_instrucao` | 0.1 | EXE-custo |
   | `custo_lancar` / `custo_mover` / `custo_levitar` | 3 / 1 / 2 | EXE-custo |
   | `custo_meditar` / `custo_absorver` | 0 / 0 | EXE-custo |
   | `custo_inscricao` (Sprint 9) | 0.1 | EXE-custo, regra 13 |
   | `custo_inscrever` / `custo_bloco` (Sprint 9) | 1 / 0.5 | EXE-custo |
   | `custo_faisca` (Sprint 10) | 1 | EXE-custo |
   | `limite_tempo_ms` | 1000 | EXE-limites |
3. Resposta:
   ```json
   {
     "versao": 1,
     "id": 7,
     "ok": true,
     "acoes": [{"tipo": "lancar", "linha": 1, "elemento": "fogo", "forma": "projetil", "alvo": "elemental_1"}],
     "saidas": [],
     "mago": {"vida": 10, "mana": 1.9, "mana_max": 20},
     "custo_mana": 3.1,
     "erro": null
   }
   ```
   `mago` é o estado do mago simulado no fim da execução (ADR-001). `custo_mana` é o total gasto (EXE-custo); 0 numa requisição inválida.
   Tipos de erro além das exceções do Python: `RequisicaoInvalida`, `ManaEsgotada`, `TempoEsgotado`, `LimiteExcedido`, `FeiticoProibido`, `PecaBloqueada`. Do lado do Godot: `ExecutorIndisponivel`, `RespostaInvalida` e `TempoEsgotado` (watchdog).
4. Toda ação e toda saída carregam a `linha` do código do jogador que a gerou.
5. Quando dá erro, `ok` é `false` e `erro` segue EXE-erros. As ações e saídas produzidas **antes** do erro continuam na resposta.
6. Uma requisição inválida nunca derruba o worker: ele responde com erro e segue lendo.
7. **Sala (Sprint 9, ainda v1).** `mundo.sala` é opcional: `{"runas": [4, 7, 2]}`, com números inteiros. Sem o campo, a sala não tem runas. Campos desconhecidos dentro de `sala` são ignorados, para o jogo poder mandar mais coisas no futuro sem quebrar o executor. As ações novas (`inscrever`, `construir_bloco`) seguem a regra 4. Uma requisição antiga, sem `sala`, continua válida e dá a mesma resposta.
8. **Inimigos (Sprint 10, ainda v1).** `mundo.inimigos` é opcional: uma lista de objetos `{"id", "elemento", "distancia", "vida"?, "escudo"?}`, do mais perto para o mais longe (COM-dano). `mundo.alvo` aceita os mesmos campos opcionais. `vida` é número ou null; `escudo` é texto ou null; sem o campo, vale `None` no feitiço. Um item malformado torna a requisição inválida. Requisições antigas continuam válidas e dão a mesma resposta.

## Critérios de aceite

### EXE-001 — Resposta de sucesso

- **Dado** uma requisição válida com código sem erros
- **Quando** o executor a processa
- **Então** a resposta tem `versao` 1, o mesmo `id`, `ok` true, `erro` null e as listas `acoes` e `saidas`

### EXE-002 — Estado final do mago

- **Dado** um feitiço que muda a mana do mago
- **Quando** termina
- **Então** `mago` traz a mana simulada final

### EXE-003 — Regras padrão

- **Dado** uma requisição sem `regras`
- **Quando** o feitiço chama `meditar()`
- **Então** a mana sobe 5

### EXE-004 — Requisição inválida

- **Dado** uma requisição sem `codigo`, sem `mundo`, com `versao` diferente de 1, ou uma linha que não é JSON
- **Quando** o executor a processa
- **Então** responde `ok` false com `erro.tipo` `"RequisicaoInvalida"`, `erro.linha` null e `mago` null, repetindo o `id` quando ele existir

### EXE-005 — Worker persistente

- **Dado** o worker rodando
- **Quando** recebe três requisições seguidas, uma delas inválida
- **Então** devolve três respostas, na ordem, e continua vivo

### EXE-006 — print não corrompe o protocolo

- **Dado** um feitiço que chama `print`
- **Quando** o worker o executa
- **Então** o stdout contém só a linha JSON da resposta, e o texto aparece em `saidas`

### EXE-007 — Cliente Godot

- **Dado** o `PythonSpellExecutor` no Godot
- **Quando** executa `lancar(fogo, projetil, alvo)` com um alvo no mundo
- **Então** recebe um `SpellResult` com uma ação `lancar` na linha 1, usando o mesmo worker em chamadas seguidas

### EXE-008 — Worker morto é substituído

- **Dado** o worker do Godot foi encerrado de fora
- **Quando** o jogo executa outro feitiço
- **Então** um worker novo é criado e o feitiço roda normalmente

### EXE-009 — Contrato compartilhado

- **Dado** as fixtures em `tests/contract/`
- **Quando** rodam as suítes
- **Então** o executor produz exatamente cada `resposta` a partir da `requisicao`, e o Godot lê cada `resposta` sem perder campos

### EXE-110 — Sala inválida

- **Dado** `mundo.sala` que não é objeto, ou `sala.runas` que não é uma lista de inteiros
- **Então** `RequisicaoInvalida`

### EXE-111 — Contrato das peças dos puzzles

- **Dado** uma fixture nova `10_pecas_de_puzzle.json`, com runas na sala, `ler_runa`, `inscrever` e `construir_bloco`
- **Quando** rodam as duas suítes
- **Então** o executor produz a resposta da fixture, e o Godot manda `mundo.sala` montado a partir da sala atual e lê as ações novas sem perder campos

### EXE-112 — Inimigos na requisição

- **Dado** `mundo.inimigos` com dois inimigos e `mundo.alvo` com `vida` e `escudo`
- **Então** a requisição é válida
- **E** `mundo.inimigos` que não é lista, item sem `id`, `vida` em texto ou `escudo` numérico dão `RequisicaoInvalida`

### EXE-113 — Contrato do combate

- **Dado** uma fixture nova `11_combate.json`, com inimigos, alvo com vida e escudo, e um loop de faíscas
- **Quando** rodam as duas suítes
- **Então** o executor produz a resposta da fixture, e o Godot manda `mundo.inimigos` montado a partir da sala atual
