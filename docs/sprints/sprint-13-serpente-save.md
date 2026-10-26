# Sprint 13 — Conteúdo da serpente e save

- **Status:** Concluída em 2026-10-26 · aguardando revisão e commit do Victor
- **Fases do plano:** 7 e 8 · **Marco:** M4 · **Estimativa:** 14–21 h
- **Depende de:** Sprint 12

## Objetivo

A serpente ensina cada conceito e dá dicas; o progresso é salvo.

## Tarefas

- [x] Specs `NAR-serpente`, `NAR-dicas`, `SAV-progresso`; `GRI-referencia` ganhou as páginas de conceito
- [x] Falas da serpente: apresentação e um ensinamento por conceito (sequência, variáveis, condicionais, loops, funções) e a revisão
- [x] Dicas em três níveis para cada puzzle: conceito → estrutura → exemplo parcial
- [x] Salvar e carregar o progresso, com versão no formato do save, por perfil
- [x] Mapa da área: rascunho em `docs/mapa-area.md` (**falta o Victor conferir no papel**)
- [x] Teste de mutação, captura de tela, fechamento

## Decisões

Recomendações minhas, seguidas depois do "pode seguir" do Victor. Os textos estão no `textos.csv`, as cenas em `content/dialogos.json` e as dicas em `content/dicas.json`.

| Decisão | Por quê |
| --- | --- |
| **Uma serpente por sala de puzzle**, perto da entrada, com a lição do conceito da sala | O mapa é o currículo: a lição vem logo antes do desafio que a cobra |
| A lição conta como vista quando aparece a fala `licao`; recusar antes dela não conta | Quem diz "Agora não" na apresentação ainda vai ouvir a lição depois |
| Depois da lição, **falar de novo oferece a próxima dica**, sempre com a pergunta "Quer uma dica?" | Ninguém gasta uma dica sem querer; a dica conta só quando aparece |
| Com o puzzle resolvido, a serpente repete a lição | Revisar continua possível; as páginas de conceito também estão na Referência |
| A cena da dica é **montada pelo jogo** a partir de `dicas.json` (3 chaves por puzzle) | A pergunta e as respostas são iguais em todos os puzzles; só o texto da dica muda |
| A lição de condicionais explica que o feitiço vê o mundo da hora da conjuração | Fecha a decisão em aberto do cristal mutável (ADR-001, PUZ-03) |
| **Save em `user://perfis/padrao/`** (`save.json` e `grimorio.json`); o grimório antigo é copiado para lá | Perfis desde já (laboratórios de escola, GDD); o arquivo antigo fica intacto |
| Uma **cena principal nova** (`main.tscn`) liga o save; o `World` sozinho não salva | Os testes que sobem o `World` direto nunca tocam no progresso do jogador |
| O save grava ao entrar numa sala, resolver um puzzle, derrotar o chefe, subir de nível, terminar um diálogo e fechar o jogo; o mago volta pela entrada da sala, com a vida cheia | Simples e previsível; a posição exata dentro da sala não importa numa sala pequena |
| Save ilegível ou de versão mais nova: `.bak` e jogo do zero, com aviso. Campo ruim: valor padrão só daquele campo | Um save quebrado nunca impede de jogar |

## O que foi entregue

**Specs:** NAR-serpente, NAR-dicas e SAV-progresso (novas). Atualizadas: GRI-referencia (regra 7, páginas de conceito) e NAR-dialogo (regra 7).

**Godot**
- `HintBook` (`src/core/narrative/hint_book.gd`, novo): `load_file`, `validate`, `hints`, `has_hints`, `scene(puzzle, nível)`
- `DialogueRun.has_seen(fala)`: lembra as falas que apareceram
- `ProgressStore` (`src/core/save/progress_store.gd`, novo): gravação atômica, `load_data` com versão, `.bak` e `last_problem`
- `MagoState.restore_progress(xp, mana)`: volta ao save sem avisar subida de nível
- `World`: `save_path`, `seen_lessons`, `hints_used`, `hints`, `LESSON_LINE`; `talk()` escolhe entre lição e dica; `_on_dialogue_finished` conta lição e dica e salva; `progress_snapshot`, `save_progress`, `apply_progress` (tolerante a campo ruim), gravação nos momentos da regra 4 e ao fechar a janela
- `Main` (`src/nodes/main/main.gd` + `main.tscn`, novos): perfil, migração do grimório, `World` com save. **A cena principal do projeto agora é `main.tscn`**
- Conteúdo: seis lições em `content/dialogos.json` (a `serpente_ola` virou o começo de `ensino_sequencia`), `content/dicas.json` (18 dicas), cinco páginas de conceito em `content/referencia.json`, serpentes nas salas `sala_p02` a `sala_p06`, textos novos no `textos.csv`

**Testes:** `tests/unit/narrative/test_hint_book.gd`, `test_serpent_content.gd`, `tests/unit/save/test_progress_store.gd`, `tests/scene/narrative/test_serpent_lessons.gd` (sala de teste `sala_licao`), `tests/scene/world/test_save.gd`, `test_main.gd`, `test_NAR_005_toda_fala_cabe_na_caixa`. Os testes de diálogo e de referência foram ajustados ao conteúdo novo (`ensino_sequencia`, 18 páginas).

**Totais:** 417 GdUnit4 e 145 pytest, verdes.

## Bugs encontrados (cada um com teste de regressão)

| Bug | Como apareceu | Teste |
| --- | --- | --- |
| As dicas 3 do P2 e do P5 tinham 5 linhas e a caixa de diálogo passava da metade da tela | Captura de tela (a dica do P6, com 4 linhas, já enchia a caixa), que levou a um teste sobre **todo** o conteúdo | `test_NAR_005_toda_fala_cabe_na_caixa` (vermelho nas duas dicas → verde depois de encurtá-las) |

Melhoria de texto achada na mesma captura: as lições mostravam código no meio da frase ("for i in range(3): e, na linha de baixo…"). Agora o código vem em linhas próprias, recuado.

## Teste de mutação

8 mutantes, 8 mortos: dica oferecida sem a lição vista; dica contada sem aparecer; chefes não carregados do save; sala não salva ao entrar; versão nova demais aceita; grimório do perfil sobrescrito pela migração; falas vistas não lembradas; mana máxima não recalculada ao carregar.

## Captura de tela

Serpente na sala da ponte, lição de loops, pergunta da dica, dica 3 da ponte e do P6, e a página Funções na Referência.

## Como verificar

Siga a seção "4g. Lições, dicas e save" de `docs/feiticos-exemplo.md`.

## Limitações conhecidas

- A serpente só fala quando você aperta E; puxar conversa sozinha ficou de fora (NAR-dialogo, pergunta em aberto).
- Sem tela de "novo jogo": para recomeçar, apague `%APPDATA%\Godot\app_userdata\ArcaneSyntax\perfis\padrao\save.json`.
- O mapa é um rascunho; a montagem das salas é da Sprint 14.
- As páginas da Referência e as dicas citam custos como texto; se o `balanceamento.json` mudar, revise-as à mão.
