# ADR-002 — Processo do executor e Python embutido

- **Status:** Aceita
- **Data:** 2026-10-25

## Contexto

O jogo nunca executa o código do jogador no próprio processo. Precisamos decidir como subir o Python e qual Python distribuir com o jogo.

## Spike (2026-10-25, Windows 11, Python standalone 3.14.9)

| Modelo | Latência por feitiço |
| --- | --- |
| Um processo novo por feitiço | ~26 ms (mediana) |
| Worker persistente, JSON por linha via stdin/stdout | ~0,04 ms (mediana), 0,06 ms (p95); subir o worker custa ~30 ms uma vez |

## Decisão

- **Worker persistente.** Um processo Python de longa duração, uma requisição JSON por linha no stdin, uma resposta por linha no stdout. Se morrer ou travar, o jogo mata e sobe outro.
- **Python standalone 3.14** (projeto `python-build-standalone`, build `install_only_stripped`, ~23 MB compactado, ~65 MB extraído), empacotado com o jogo. Versão fixa para que mensagens de erro e custo de mana sejam iguais em toda máquina.
- Rodado com `-I -S -u` (isolado do ambiente do usuário, sem `site`, sem buffer).
- Em desenvolvimento, `scripts/fetch_python.sh` baixa o mesmo Python para `runtime/python/` (fora do git). Sem ele, cai no `python` do PATH ou em `ARCANE_PYTHON`.

## Consequências

- O `print` do jogador não pode ir para o stdout, que é o canal do protocolo: ele é capturado e devolvido como `saidas`.
- O CI usa Python 3.14 para bater com o runtime.
- Enxugar o runtime (tirar `tkinter`, `idlelib`, `ensurepip`, cabeçalhos) fica para o build da Alpha.
