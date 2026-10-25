# EXE-limites — Limites de execução

- **Status:** Implementada
- **Sprint:** 2
- **Relacionadas:** EXE-custo, EXE-sandbox, ADR-002

## Contexto

Nenhum feitiço pode travar o jogo ou o computador. A mana é o primeiro limite (o mundo ensina o erro); tempo, quantidade de ações e memória são as redes de segurança.

## Regras

1. **Tempo no worker:** cada instrução e cada volta de laço confere o relógio. Passou de `limite_tempo_ms` (padrão **1000**): erro `TempoEsgotado`.
2. **Watchdog no Godot:** se o worker não responde em `timeout_ms` (padrão **3000**), o Godot mata o processo, devolve `TempoEsgotado` e sobe um worker novo na próxima chamada. Cobre código preso dentro de funções em C (ex.: `10**10**8`), onde o relógio do worker não roda.
3. `ManaEsgotada` e `TempoEsgotado` **não podem ser capturados** pelo feitiço: não herdam de `Exception`, e o sandbox proíbe `except:` sem tipo e `BaseException` (EXE-sandbox).
4. **Ações:** no máximo **1000** por feitiço; passou disso, erro `LimiteExcedido`.
5. **Saídas:** no máximo **200** `print` por feitiço (erro `LimiteExcedido`); cada texto é cortado em **500** caracteres, terminando em `…`.
6. **Memória:** o worker limita a própria memória a **256 MB** ao iniciar (Windows: Job Object; Linux: `RLIMIT_AS`). Passou disso, o feitiço recebe `MemoryError` e o worker segue vivo.

## Critérios de aceite

### EXE-050 — Loop infinito esgota a mana

- **Dado** mana 5
- **Quando** o feitiço é `while True:\n    pass`
- **Então** `erro.tipo` é `"ManaEsgotada"` na linha 2, em menos de 1 s

### EXE-051 — Limite de tempo

- **Dado** mana 1000000 e `limite_tempo_ms` 200
- **Quando** o feitiço é `while True:\n    pass`
- **Então** `erro.tipo` é `"TempoEsgotado"`, em menos de 1 s

### EXE-052 — Laço sem instruções simples também para

- **Dado** `limite_tempo_ms` 200
- **Quando** o feitiço é `while True:\n    if False:\n        pass` (nenhuma instrução paga roda)
- **Então** `erro.tipo` é `"TempoEsgotado"`

### EXE-053 — Limites não podem ser capturados

- **Quando** o feitiço é `try:\n    while True:\n        pass\nexcept Exception:\n    meditar()`
- **Então** `erro.tipo` é `"ManaEsgotada"` e nenhuma ação `meditar` é registrada

### EXE-054 — Limite de ações

- **Dado** mana alta
- **Quando** o feitiço é `for i in range(2000):\n    meditar()`
- **Então** `erro.tipo` é `"LimiteExcedido"` e há exatamente 1000 ações

### EXE-055 — Limite de saídas

- **Quando** o feitiço é `for i in range(300):\n    print(i)`
- **Então** `erro.tipo` é `"LimiteExcedido"` e há exatamente 200 saídas

### EXE-056 — Texto longo é cortado

- **Quando** o feitiço é `print("a" * 600)`
- **Então** a saída tem 500 caracteres e termina em `…`

### EXE-057 — Memória limitada (worker real)

- **Quando** o feitiço é `x = "a" * (10 ** 9)`
- **Então** `erro.tipo` é `"MemoryError"` e o worker responde à requisição seguinte

### EXE-058 — Watchdog do Godot

- **Dado** o `PythonSpellExecutor` com `timeout_ms` curto
- **Quando** o feitiço fica preso em código C (`x = 10 ** 10 ** 8`)
- **Então** o resultado é `TempoEsgotado`, e o feitiço seguinte roda normalmente num worker novo
