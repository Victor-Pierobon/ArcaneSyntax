# Sprint 2 — Executor: custo, limites e sandbox

- **Status:** Planejada (próxima)
- **Fase do plano:** 1 · **Marco:** fecha o M1 · **Estimativa:** 15–23 h
- **Depende de:** Sprint 1

## Objetivo

O feitiço custa mana, um loop infinito falha sem travar nada, e o código do jogador não mexe no computador.

## Decisão a tomar ANTES de escrever a spec EXE-custo

**Como cobrar mana sem quebrar o primeiro feitiço.** O GDD diz que cada operação gasta mana e que o jogador começa com mana 0, aprendendo `meditar()`, que "não custa nada". Se cada linha custar mana cobrada antes de executar, `meditar()` com mana 0 já falha. E se cada linha custar 1 e `absorver_mana()` der 1, o loop `while mana < mana_max: absorver_mana()` (2 linhas por volta) perde mana em vez de ganhar.

Proposta, a validar com o Victor:

1. Mana interna em unidades inteiras pequenas (ex.: 1 mana = 10 "gotas"), para evitar float e permitir linha barata.
2. Custo por linha executada pequeno (ex.: 1 gota = 0,1 mana); custo base por peça (`lancar` caro, `mover`/`levitar` médio, `meditar`/`absorver_mana` zero).
3. A cobrança acontece **depois** da linha executar (a linha de `meditar()` já recebeu a mana quando é cobrada).
4. Se a mana ficaria negativa: o feitiço para com o erro `ManaEsgotada` (mensagem: "a mana acabou na linha N"), preservando o que rodou antes.
5. Com esses números, o loop de absorver rende +0,8 por volta, e o passivo que checa antes rende mais que um que absorve sempre, como o GDD quer.

Os valores ficam em `regras` (vindos do jogo), não fixos no executor, para o balanceamento morar num lugar só (Sprint 11).

## Tarefas

- [ ] Decidir a regra de custo acima e escrever `EXE-custo` (1 h)
- [ ] Contar linhas executadas só nos frames `<feitico>` com `sys.settrace` (eventos `line`) (3–4 h)
- [ ] Custo base por peça + campo `custo_mana` na resposta + mana debitada do mago simulado (2–3 h)
- [ ] Limite de mana: erro `ManaEsgotada` (1–2 h)
- [ ] Limite de tempo no worker: checar o relógio no tracer a cada linha; erro `TempoEsgotado` (1–2 h)
- [ ] Watchdog no Godot: se o worker não responder em X s, matar o processo, devolver `TempoEsgotado` e subir outro na próxima chamada (cobre laços em código C como `10**10**8`) (2–3 h)
- [ ] Sandbox (4–7 h):
  - análise da AST antes de executar: só `import` da lista branca (proposta: `math`, `random`); proibir nomes e atributos que começam com `_`
  - builtins restritos: sem `open`, `exec`, `eval`, `compile`, `input`, `breakpoint`, `globals`, `vars`, `memoryview`, `__import__` livre; `getattr`/`setattr`/`hasattr` recusando nomes com `_`
  - erro `FeiticoProibido` com mensagem que diz o que não é permitido e por quê
- [ ] Estimativa de custo: execução de ensaio com estado fictício, devolvida para o grimório usar na Sprint 5 (1–2 h)
- [ ] Atualizar fixtures de contrato e protocolo (`custo_mana`), cliente Godot e console de feitiços (1–2 h)
- [ ] **Recomendado:** build de fumaça — exportar para Windows com `runtime/python` e `executor/` ao lado do `.exe` e conjurar um feitiço no build. Hoje o cliente acha o executor por um caminho que só existe em desenvolvimento (ver Sprint 15); descobrir isso agora custa pouco (2–3 h)

## Specs a escrever

- `docs/specs/executor/EXE-custo.md` — critérios candidatos: custo exato de feitiços de referência; peças gratuitas; `meditar()` com mana 0 funciona; loop de absorver termina cheio; passivo que checa custa menos que o que não checa; custo é determinístico (mesmo código, mesmo custo).
- `docs/specs/executor/EXE-limites.md` — `while True: pass` volta `ManaEsgotada` rápido; com mana alta, volta `TempoEsgotado` em menos de X ms; `10**10**8` é morto pelo watchdog e o próximo feitiço roda; o worker continua vivo nos casos cobertos pelo tracer.
- `docs/specs/executor/EXE-sandbox.md` — bateria de códigos que precisam ser bloqueados: `open('x')`, `import os`, `__import__('os')`, `().__class__.__bases__`, `getattr(alvo, '__class__')`, `exec('...')`, `eval`, `globals()`; `import math` e `import random` funcionam; mensagens claras.
- Atualizar `EXE-protocolo` (campo `custo_mana`, novos tipos de erro).

## Testes

- pytest em TDD estrito, um teste por critério.
- `test_EXE_006` (Sprint 1) usa `import sys`; reescrever para provar a mesma coisa sem import proibido (por exemplo, só com `print`).
- GdUnit4: integração do watchdog (feitiço que trava → `TempoEsgotado` → próximo feitiço funciona, com PID novo).

## Notas e riscos

- **Modelo de ameaça:** o jogador roda o próprio código na própria máquina. O objetivo é evitar acidentes e manter a fantasia; sandbox dentro do processo Python não segura um ataque deliberado. Se um dia houver feitiços compartilhados ou modo escola, isolar no nível do sistema operacional.
- `sys.settrace` deixa o código mais lento (estimativa: 2 a 5 vezes). Medir; feitiços são curtos.
- Memória: `"a" * 10**10` pode estourar a RAM antes do watchdog agir. Avaliar um teto (no Linux, `resource`; no Windows, Job Object via `ctypes`) ou checar tamanhos na AST. Se ficar caro, registrar como risco conhecido para a Alpha.
- Determinismo: o custo depende de eventos `line`, estáveis dentro da mesma versão do Python. Por isso a versão é fixa (ADR-002).

## Pronto quando (fecha o M1)

Loop infinito volta `ManaEsgotada` ou `TempoEsgotado` sem travar o jogo, `import os` é recusado com mensagem clara, e o custo dos feitiços de referência bate com a spec.
