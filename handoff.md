# Handoff — ArcaneSyntax

> Contexto para começar uma conversa nova sem reler toda a documentação.
> **Atualizado em:** 2026-10-25, fim da Sprint 1.
> **Atualizar** ao fim de cada sprint (ou quando algo aqui deixar de ser verdade).

## 1. O projeto em 30 segundos

Metroidvania 2D em pixel art (Godot 4.7) em que cada feitiço é código Python real. O jogador, preso num livro, sobe uma torre; cada andar ensina conceitos de programação. Projeto solo do Victor Pierobon, em tempo livre, sem prazo fixo. Meta atual: **Alpha = Ato I (Fundações e Masmorra), só Python**, ~12 salas, 6 puzzles, 3 inimigos, 1 chefe, serpente como mentora. Critério de sucesso: um iniciante joga do início ao fim sem ajuda e quer continuar.

Pilares que guiam decisões: código real; o jogador cria os feitiços livremente; mana como custo de execução; o mapa é o currículo; puzzles validam o **estado do mundo**, nunca comparam código com gabarito.

## 2. Onde estamos

| | |
| --- | --- |
| Sprint atual | **Sprint 1 concluída**; a próxima é a **Sprint 2** (custo de mana, limites, sandbox) |
| Último commit | `8b798a0` (Sprint 0). **A Sprint 1 e esta documentação ainda não foram commitadas**; o Victor revisa e commita |
| Testes | 51 pytest + 23 GdUnit4, todos verdes localmente |
| CI | Configurado, **ainda não verificado no GitHub** |
| Pendências do Victor | Tutorial 2D do Godot; escolher assets provisórios; push e conferir o CI |

## 3. Regras de trabalho (combinadas com o Victor)

1. **Idioma:** português do Brasil em conversa, docs, specs, nomes de testes e textos do jogo. Código em inglês nos identificadores do Godot; o executor Python usa nomes em português porque são o vocabulário do jogador.
2. **Spec → teste vermelho → código → refatorar.** Toda funcionalidade começa por uma spec em `docs/specs/<area>/` (modelo em `docs/specs/TEMPLATE.md`), com critérios *Dado/Quando/Então* e IDs `AREA-NNN`. Cada critério vira teste com o ID no nome (`test_EXE_019_...`).
3. **TDD estrito** para regras e executor; **teste depois** + checklist manual para sensação (movimento, animação, VFX).
4. **Nunca fazer `git commit` nem `git push`.** Deixar as mudanças na árvore de trabalho, listar o que mudou e sugerir a mensagem de commit.
5. O jogo sempre roda: terminar com as duas suítes verdes.
6. Ao fim de cada sprint: atualizar o arquivo da sprint (vira relatório), `docs/diario.md`, `docs/roadmap-alpha.md` (status), `docs/arquitetura.md` se a estrutura mudou, e **este handoff**.
7. Ideias novas durante a Alpha vão para o GDD, não para o código.

## 4. Mapa da documentação (ler só o que a tarefa pedir)

| Precisa de… | Leia |
| --- | --- |
| Plano da sprint atual | `docs/sprints/sprint-NN-*.md` |
| Visão geral e status de todas as sprints | `docs/roadmap-alpha.md` |
| Como o código funciona hoje, pastas, armadilhas | `docs/arquitetura.md` |
| Regras exatas de uma funcionalidade | `docs/specs/<area>/*.md` |
| Por que uma decisão técnica foi tomada | `docs/adr/` |
| Visão do jogo completo | `docs/gdd.md` (longo) |
| Escopo e horas originais da Alpha | `docs/plano-alpha.md` |
| Histórico por sessão | `docs/diario.md` |

## 5. Arquitetura em uma tela

- **Godot (`game/`)**: regras puras em `src/core/` (sem Node, testáveis sem cena); Nodes em `src/nodes/`; cliente do executor em `src/executor_client/`.
- **Executor (`executor/`)**: worker Python persistente. O Godot sobe `runtime/python/python.exe -I -S -u executor/run_worker.py` com `OS.execute_with_pipe` e troca **uma linha JSON por requisição**. A ida e volta roda numa `Thread`; `execute()` é usado com `await`.
- **Modelo de execução (ADR-001)**: o jogo manda uma foto do mundo; o executor roda o feitiço inteiro, simulando só a mana do mago, e devolve todas as ações, cada uma com a `linha` que a gerou. O resto do mundo não muda durante a execução.
- **Protocolo v1**: requisição `{versao:1, id, codigo, mundo:{mago:{vida,mana,mana_max}, alvo:{id,elemento,distancia}|null}, regras?}` → resposta `{versao:1, id, ok, acoes:[{tipo,linha,...}], saidas:[{linha,texto}], mago, erro:{tipo,mensagem,linha,coluna}|null}`.
- **Peças**: `lancar(elemento, forma, alvo=None)`, `mover(passos)`, `levitar(altura)`, `meditar()`, `absorver_mana()`. Elementos `fogo/gelo/raio` e formas `projetil/escudo` são strings. Sentidos: `mana`, `mana_max`, `vida_atual`, `alvo` (`.elemento`, `.distancia`, somente leitura).
- **Movimento**: `Player` (CharacterBody2D) chama `PlayerMotor.step(velocity, intent, on_floor, delta)`; a intenção vem de `Player.intent_source` (teclado por padrão; testes injetam).
- **Contrato**: `tests/contract/*.json` é verificado pelas duas suítes.

Classes principais: `PlayerIntent`, `PlayerMotor`, `Player`, `SpellExecutor`, `PythonSpellExecutor`, `SpellRequest`, `SpellResult`, `SpellError`, `ContractFixtures` (testes). Python: `pieces.Contexto`, `runner.run_spell`, `protocol.handle_request` / `handle_line`, `worker.main`.

## 6. Comandos

```bash
# Godot (linha de comando: usar o _console.exe)
export GODOT_BIN="/c/Users/victo/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"

# Python embutido (uma vez por máquina; vai para runtime/, fora do git)
scripts/fetch_python.sh

# Testes
cd executor && python -m pytest                       # executor
cd game && "$GODOT_BIN" --headless --path . --import  # após criar scripts com class_name
cd game && bash addons/gdUnit4/runtest.sh --headless -a res://tests --ignoreHeadlessMode
scripts/test.sh                                        # tudo

# Jogo e console de feitiços
"$GODOT_BIN" --path game
"$GODOT_BIN" --path game res://src/nodes/dev/spell_console.tscn
```

No PowerShell, o executor de testes do Godot é `.\addons\gdUnit4\runtest.cmd` com `$env:GODOT_BIN`.

## 7. Armadilhas conhecidas

- Headless não entrega eventos de input → testes de cena injetam `PlayerIntent`.
- GdUnit4 precisa de `--ignoreHeadlessMode`; o `ERROR: Remote Debugger ... 127.0.0.1:0` na saída é esperado.
- Script novo com `class_name` → rodar `--import` antes dos testes.
- `JSON.parse_string` do Godot devolve números como float → `SpellResult` converte `linha`; comparar com fixtures via `ContractFixtures.normalize`.
- `res://` não alcança a raiz do repo; o cliente usa `globalize_path("res://") + "/.."`, **que só funciona em desenvolvimento** (resolver no build).
- O `python` do PATH no Windows é o alias da Microsoft Store; usar `runtime/python`.
- Python local do Victor é 3.15; o runtime e o CI usam 3.14. Rodar o pytest também com o 3.14 quando mexer em mensagens de erro ou custo.
- **Para o assistente:** comandos Bash com heredoc contendo Python com barras invertidas ou caminhos do Windows já falharam duas vezes; prefira as ferramentas Write/Edit para criar e alterar arquivos.

## 8. Decisões em aberto

| Decisão | Onde está a proposta |
| --- | --- |
| **Regra de custo de mana** (o primeiro feitiço é `meditar()` com mana 0; cobrança por linha não pode impedir isso nem tornar o loop de absorver negativo) | `docs/sprints/sprint-02-executor-custo-sandbox.md` — decidir com o Victor antes de escrever `EXE-custo` |
| Ações anteriores a um erro acontecem no mundo? | Sprint 6 |
| Lista de peças desbloqueadas entra no protocolo? | Sprint 5 |
| Peças novas para puzzles (runas, símbolo da porta, blocos) e combate (`inimigos`, `alvo.escudo`) | Sprints 9 e 10 |
| Questões do GDD: título, protagonista, motivo do mago, público, C++ | `docs/gdd.md`, fim |

## 9. Próximo passo

Começar a **Sprint 2** pelo item "Decisão a tomar antes" do arquivo da sprint: apresentar ao Victor a proposta da regra de custo de mana e, com a resposta, escrever `docs/specs/executor/EXE-custo.md`, `EXE-limites.md` e `EXE-sandbox.md`, e então os testes.
