# Sprint 15 — Testes com iniciantes e build

- **Status:** Concluída em 2026-10-26 · o Victor jogou o jogo inteiro no editor e no `.exe`, com tudo funcionando; os testes com outras pessoas passaram para o fim da Alpha 1.1 (`docs/plano-alpha-1-1.md`). Aguardando revisão e commit
- **Fase do plano:** 9 · **Marco:** fecha a Alpha · **Estimativa:** 15–25 h
- **Depende de:** Sprint 14

## Objetivo

Um iniciante em programação joga do início ao fim sem ajuda externa e quer continuar (critério de sucesso do plano).

## Tarefas

- [x] Jogar do início ao fim e corrigir bugs: teste de aceitação da Alpha inteira (MUN-085), do menu ao fim, com Python real; o Victor jogou a Sprint 14 inteira e está funcionando
- [x] Build da Alpha para Windows: preset, `scripts/build_windows.ps1`, Python enxuto, `LEIA-ME.txt`, teste de fumaça no `.exe` exportado (BLD-alpha)
- [x] Roteiro de observação: `docs/playtest/roteiro-alpha.md`
- [x] Teste do jogo inteiro pelo Victor (editor e `.exe`): tudo funcionando
- [ ] ~~Testar com 3 a 5 iniciantes~~: **adiado** para o fim da Alpha 1.1 (Sprint 21), por decisão do Victor. Jogando, ele achou o visual, as salas e o chefe simples demais, e isso virou o plano da 1.1

## Decisões

| Decisão | De quem | Por quê |
| --- | --- | --- |
| Baixar e instalar os templates de exportação do Godot 4.7.2 | Victor | Sem eles não há build. Instalei só os de Windows em `%APPDATA%\Godot\export_templates\4.7.2.stable` |
| O jogo inteiro vira **um** teste de aceitação, que sai de cada sala andando pela saída | Recomendação | Pega o que os testes por sala não pegam: uma porta que não abre, uma saída que leva ao lugar errado, um passo do caminho que ficou impossível. Dentro de cada sala ele vai direto ao lugar de conjurar, como os outros testes de aceitação |
| Teste de fumaça **dentro do jogo** (`--fumaca`), rodado pelo script no `.exe` exportado | Recomendação | O que quebra no build (JSON não exportado, salas `.remap`, Python fora do lugar) só aparece fora do editor |
| `.pck` separado e `.console.exe` junto | Recomendação | O `.console.exe` mostra a saída (é por ele que a fumaça roda); o `.pck` separado deixa o build menor de reconstruir |
| Python enxuto (sem tkinter, idlelib, ensurepip, site-packages, cabeçalhos, tcl) | Recomendação | O worker roda com `-I -S` e não usa nada disso. O `.zip` ficou com 49 MB |
| Testes com iniciantes **sem ficha de desafios** | Recomendação | Quem ensina é o jogo; precisar de ajuda é o dado que o teste mede |

## O que foi entregue

**Specs:** BLD-alpha (nova); MUN-mapa ganhou o MUN-085.

**Godot**
- `SmokeCheck` (`src/nodes/main/smoke_check.gd`, novo): `requested(args)`, `run()` (balanceamento, diálogos, dicas, referência, textos, mapa e executor) e `report(problemas)`
- `Main`: `--fumaca` roda a fumaça e fecha com código 0 ou 1, sem abrir o menu; `user_args`, `quit_after_smoke`, sinal `smoke_finished`; os menus são criados no `_ready`, depois da fumaça
- `game/export_presets.cfg` (novo, versionado): Windows Desktop, x86_64, leva `content/*.json`, deixa de fora `tests/` e `addons/gdUnit4/`

**Build:** `scripts/build_windows.ps1` (exporta, copia `executor/` e `runtime/python/` enxuto, `LEIA-ME.txt`, roda a fumaça no `.exe`, gera `build/ArcaneSyntax-alpha.zip`); `docs/build/LEIA-ME.txt`; `build/` no `.gitignore`.

**Testes:** `tests/acceptance/test_alpha_completa.gd` (MUN-085, cerca de 1 min), `tests/integration/test_smoke.gd` (BLD-001 a BLD-003).

**Totais:** 463 GdUnit4 e 145 pytest, verdes. A fumaça passou no `.exe` exportado (`FUMACA OK`), e o jogo exportado abre no menu com janela.

## Bugs encontrados (cada um com teste de regressão)

| Bug | Como apareceu | Teste |
| --- | --- | --- |
| No modo fumaça, a `Main` criava os quatro menus como membros e saía antes de pô-los na árvore: 127 objetos vazavam ao fechar o jogo exportado | Saída da fumaça no `.exe` exportado | `test_BLD_003_fumaca_nao_cria_os_menus` (o GdUnit4 acusa nós órfãos; vermelho no teste de mutação com os menus de volta como membros) |
| O `.gitignore` com `build/` também escondia `docs/build/` (o `LEIA-ME.txt`) e `docs/specs/build/` (a spec), que não iriam para o commit | `git status` no fechamento | Sem teste automático (configuração do repositório): virou `/build/`, conferido no `git status` e registrado nas armadilhas da arquitetura |

O teste da Alpha inteira passou de primeira: o caminho do começo ao fim fecha.

## Teste de mutação

5 mutantes, 4 mortos e 1 refeito: menus criados antes da fumaça; puzzle resolvido sem abrir a porta (só o teste da Alpha inteira pega numa sala do jogo); fim da demo que não avisa; fumaça que não registra o executor. O sobrevivente era um mutante fraco: a condição mutada ainda acusava o problema pela checagem de mana. Foi trocado por um mutante que tira o aviso, e o teste pegou.

## Como verificar

1. `$env:GODOT_BIN = "C:\...\Godot_v4.7.2-stable_win64_console.exe"` e `.\scripts\build_windows.ps1` na raiz (PowerShell). O fim mostra `FUMACA OK` e o caminho do `.zip`.
2. Abra `build\ArcaneSyntax\ArcaneSyntax.exe` e jogue um pouco: ele usa o mesmo perfil do editor. O Victor jogou o `.exe` em 2026-10-26, e está tudo funcionando.
3. Para os testes com iniciantes, siga `docs/playtest/roteiro-alpha.md`.

## Limitações conhecidas

- Sem ícone, sem assinatura de código: o Windows SmartScreen avisa na primeira vez (o `LEIA-ME.txt` explica).
- O build roda só em Windows x86_64.
- O `.exe` exportado e o editor usam a mesma pasta de perfis; para testar com outra pessoa no seu computador, siga a preparação do roteiro.

## Pronto quando (fecha a Alpha)

Um iniciante joga do início ao fim sem ajuda externa e quer continuar.
