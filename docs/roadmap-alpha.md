# Roadmap da Alpha — Sprints

Base: `docs/plano-alpha.md` (fases 0 a 9) e `docs/gdd.md`.
Este documento reorganiza as fases em 15 sprints menores, cada uma com specs, testes e uma entrega que roda.

## 1. Como trabalhamos: spec → teste → código

Todo trabalho segue o mesmo ciclo:

1. **Spec.** Antes de codar, escrever (ou atualizar) a spec da funcionalidade em `docs/specs/`, usando `docs/specs/TEMPLATE.md`. A spec tem critérios de aceite no formato *Dado / Quando / Então*, cada um com um ID (`EXE-003`).
2. **Teste vermelho.** Cada critério vira pelo menos um teste automatizado com o ID no nome (`test_EXE_003_loop_infinito_esgota_mana`). O teste falha.
3. **Verde.** Implementar o mínimo para passar.
4. **Refatorar.** Com os testes verdes, limpar o código.
5. **Commit.** Só com a suíte inteira verde ("o jogo sempre roda").

### TDD onde compensa, não em tudo

| Camada | Abordagem | Por quê |
| --- | --- | --- |
| Executor Python, custo de mana, sandbox | **TDD estrito** | Lógica pura, maior risco técnico, regras bem definidas |
| Regras do jogo (dano, fraquezas, XP, níveis, validação de puzzle, save, grimório) | **TDD estrito** | Regras determinísticas, fáceis de testar sem cena |
| Contrato Godot ↔ executor (JSON) | **Testes de contrato** dos dois lados | Garante que as duas pontas falam a mesma língua |
| Puzzles | **Testes de aceitação** com soluções reais | Cada puzzle prova que aceita várias soluções e rejeita as erradas |
| Movimento, câmera, animação, VFX, "game feel" | **Teste depois** + checklist manual | Ajuste fino de sensação não se descobre escrevendo teste antes; testar só invariantes (altura do pulo, limites da câmera) |

### Arquitetura que facilita testar

- **Regras fora dos Nodes.** Lógica em classes puras (`RefCounted`/`Resource`) sem depender da árvore de cena. Os Nodes só ligam input, física e visual a essas classes. Assim 80% dos testes rodam sem abrir cena.
- **Executor atrás de uma interface.** O jogo fala com um `SpellExecutor`; nos testes de Godot usamos um `FakeSpellExecutor` que devolve respostas prontas, e só os testes de integração sobem o Python de verdade.
- **Fixtures de contrato compartilhadas.** Exemplos de requisição/resposta em `tests/contract/*.json`, lidos tanto pelo pytest quanto pelo GdUnit4.

### Ferramentas de teste

| Para quê | Ferramenta |
| --- | --- |
| Executor Python | `pytest` |
| Godot (unidade, cena, mocks) | GdUnit4 (tem *scene runner* e roda headless) |
| CI | GitHub Actions rodando as duas suítes a cada push |

### Definição de pronto (vale para toda sprint)

- [ ] Specs da sprint escritas e com status `Implementada`
- [ ] Todo critério de aceite coberto por teste com o ID no nome
- [ ] Suítes pytest e GdUnit4 verdes local e no CI
- [ ] O jogo abre e a entrega da sprint pode ser mostrada em uma demo curta
- [ ] Diário de desenvolvimento atualizado (2 linhas por sessão)
- [ ] Próxima tarefa escolhida antes de fechar a sessão

## 2. Visão geral

Os quatro marcos abaixo foram inferidos das fases, porque o diagrama de marcos do plano não veio no arquivo. Vale conferir com o original.

| Sprint | Nome | Fase(s) | Horas | Marco |
| --- | --- | --- | --- | --- |
| 0 | Fundação e esteira de testes | 0 | 20–32 | M1 · Feitiço vira ação |
| 1 | Executor: protocolo e peças | 1 | 14–21 | M1 |
| 2 | Executor: custo, limites e sandbox | 1 | 15–23 | M1 |
| 3 | Personagem e mundo | 2 | 20–30 | M2 · Núcleo jogável |
| 4 | Grimório I: editor e feitiços salvos | 3 | 12–16 | M2 |
| 5 | Grimório II: slots, erros, custo e autocompletar | 3 | 15–21 | M2 |
| 6 | Magia no mundo I: ações, formas, elementos | 4 | 17–25 | M2 |
| 7 | Magia no mundo II: mana viva | 4 | 10–16 | M2 (playtest do núcleo) |
| 8 | Puzzles I: validação e execução passo a passo | 5 | 14–20 | M3 · Conteúdo |
| 9 | Puzzles II: os 5 puzzles restantes | 5 | 16–25 | M3 |
| 10 | Combate I: inimigos | 6 | 18–26 | M3 |
| 11 | Combate II: chefe e balanceamento | 6 | 12–19 | M3 |
| 12 | Progressão e sistemas da serpente | 7 | 12–18 | M3 |
| 13 | Conteúdo da serpente e save | 7, 8 | 14–21 | M4 · Alpha |
| 14 | Montagem da área | 8 | 14–21 | M4 |
| 15 | Testes com iniciantes e build | 9 | 15–25 | M4 |
| | **Total** | | **~238–359** | |

O total sobe um pouco em relação ao plano (226–344 h) pela esteira de testes e pelas specs. Parte disso volta na Fase 9, com menos bugs para caçar no fim.

## 3. Sprints

### Sprint 0 — Fundação e esteira de testes · 20–32 h

**Objetivo:** projeto criado, testes rodando no CI e um personagem andando.

- Tutorial oficial de jogo 2D do Godot (8–12 h)
- Repositório Git + GitHub, estrutura de pastas (abaixo), `.gitignore` do Godot (1–2 h)
- Instalar GdUnit4; criar `executor/` com `pytest`; um teste trivial em cada (2–3 h)
- GitHub Actions rodando pytest e GdUnit4 headless (2–4 h)
- Template de spec e convenção de IDs (já em `docs/specs/TEMPLATE.md`)
- Textos em arquivo de tradução desde o primeiro dia (`tr()` + CSV), mesmo só em português (1 h)
- Escolher pacote de assets provisórios (2–3 h)
- Protótipo: personagem andando e pulando numa tela (4–8 h)

**Specs:** nenhuma de jogo; só a convenção.
**Pronto quando:** um push no GitHub roda as duas suítes e fica verde; o personagem anda e pula.

### Sprint 1 — Executor: protocolo e peças · 14–21 h

**Objetivo:** o Godot manda código Python e recebe uma lista de ações em JSON. É o maior risco técnico do projeto, por isso vem primeiro.

- **Spike (2–3 h):** como embutir o Python (ex.: uma distribuição *standalone* empacotada com o jogo) e medir a latência de um processo por feitiço vs. um processo *worker* de longa duração falando por stdin/stdout. Resultado registrado num ADR.
- **ADR-001, modelo de execução.** Decidir como os sentidos funcionam: o jogo envia um *snapshot* do mundo, e ações que mudam o próprio mago (ex.: `absorver_mana()` aumenta `mana`) são simuladas dentro do executor, para `while mana < mana_max:` funcionar. A alternativa (executor pergunta ao jogo a cada passo) é mais fiel e bem mais complexa. Recomendo o snapshot para a Alpha.
- Protocolo v1: requisição `{codigo, estado_mundo, limites}` → resposta `{acoes[], custo_mana, saidas[], erro}`. Cada ação já sai com o **número da linha** que a gerou, o que deixa a execução passo a passo da Sprint 8 quase de graça.
- API de peças (`lancar`, `mover`, `levitar`, `meditar`, `absorver_mana`, sentidos `alvo.elemento`, `alvo.distancia`, `vida_atual`, `mana`, `mana_max`), registrando ações numa fila.
- `print` capturado como "visão" (`saidas[]`).
- Erros de sintaxe e de execução com linha e mensagem real do Python.
- Cliente Godot (`SpellExecutor`) que sobe o worker e troca mensagens.

**Specs:** `EXE-protocolo`, `EXE-pecas`, `EXE-erros`.
**Testes (TDD):** pytest para cada peça e erro; fixtures de contrato em `tests/contract/`; um teste de integração GdUnit4 que sobe o Python de verdade.
**Pronto quando:** de dentro do Godot, `lancar(fogo, projetil, alvo)` volta como ação com linha 1, e um erro de sintaxe volta com a linha certa.

### Sprint 2 — Executor: custo, limites e sandbox · 15–23 h

**Objetivo:** feitiço custa mana, loop infinito falha sem travar, e o código do jogador não mexe no computador.

- Contagem de operações → custo de mana. Recomendo contar **linhas executadas** (eventos de linha do `sys.settrace`) mais o custo base de cada peça: é estável entre versões do Python e fácil de explicar ao jogador. Fixar a versão do Python embutido para o custo ser determinístico.
- Limite de mana (feitiço para quando a mana acaba, com erro próprio "mana esgotada").
- Limite de tempo no worker + *watchdog* no Godot que mata e reinicia o processo se ele não responder.
- Sandbox: lista branca de imports (ex.: só `math` e `random`), builtins restritos (sem `open`, `exec`, `eval`, `__import__`), bloqueio de atributos *dunder* via análise da AST.
  - **Modelo de ameaça da Alpha:** o jogador roda o próprio código na própria máquina; o objetivo é impedir acidentes e manter a fantasia, não conter um atacante. Sandbox em processo Python não é segura contra ataque deliberado. Se um dia houver feitiços compartilhados ou modo escola, isolar no nível do sistema operacional.
- Estimativa de custo antes de equipar: execução de ensaio com estado fictício (reaproveita o executor) — usada na Sprint 5.

**Specs:** `EXE-custo`, `EXE-limites`, `EXE-sandbox`.
**Testes (TDD):** pytest com uma bateria de códigos maliciosos/acidentais que precisam ser bloqueados (`open`, `import os`, `__class__.__bases__`, `while True: pass`), e custos exatos de feitiços de exemplo.
**Pronto quando (fecha o M1):** loop infinito volta como "mana esgotada" em menos de X ms, `import os` é recusado com mensagem clara, e o custo de feitiços de referência bate com a spec.

### Sprint 3 — Personagem e mundo · 20–30 h

**Objetivo:** andar por duas ou três salas de teste com vida, dano e HUD.

- Movimento: andar, pular, esquivar, gravidade ajustada; *coyote time* e *jump buffer* (6–9 h)
- Câmera com limites por sala (2–3 h)
- Tilemap e colisões com o tileset provisório (4–6 h)
- Transição entre salas (3–5 h)
- Vida, dano, volta ao último ponto seguro (3–4 h)
- HUD com vida e mana (2–3 h)

**Specs:** `MUN-movimento`, `MUN-salas`, `MUN-vida`.
**Testes:** TDD para `Health` (dano, morte, respawn) e para a lógica de transição de salas; *scene runner* para invariantes do movimento (altura máxima do pulo, esquiva com invencibilidade); o resto por checklist manual de sensação.
**Pronto quando:** atravessar 3 salas, levar dano de espinhos e voltar ao ponto seguro.

### Sprint 4 — Grimório I: editor e feitiços salvos · 12–16 h

- Abrir/fechar o grimório pausando o jogo (2–3 h)
- `CodeEdit` com realce de Python (4–6 h)
- Lista de feitiços: criar, renomear, apagar, persistir em disco (6–7 h)

**Specs:** `GRI-grimorio`, `GRI-feiticos`.
**Testes:** TDD no modelo `Grimorio` (nomes únicos, apagar feitiço equipado, serialização); teste de cena para pausa.
**Pronto quando:** escrever um feitiço, fechar o jogo, abrir de novo e ele estar lá.

### Sprint 5 — Grimório II: slots, erros, custo e autocompletar · 15–21 h

- 5 slots + conjurar por tecla (4–6 h)
- Painel de erros com linha marcada no editor (3–4 h)
- Custo de mana estimado por feitiço (3–4 h)
- Autocompletar das peças conhecidas (5–7 h)

**Specs:** `GRI-slots`, `GRI-erros`, `GRI-autocompletar`.
**Testes:** TDD para `Slots` (equipar, trocar, slot vazio, mana insuficiente) e para o provedor de autocompletar (só sugere peças desbloqueadas); `FakeSpellExecutor` para o painel de erros.
**Pronto quando:** equipar um feitiço no slot 1, apertar a tecla e ver as ações no log; um erro marca a linha no editor.

### Sprint 6 — Magia no mundo I: ações, formas e elementos · 17–25 h

- `ActionPlayer`: interpreta a fila de ações e anima no mundo (5–8 h)
- Formas: projétil e escudo (5–7 h)
- Elementos: fogo, gelo, raio, com interações (5–7 h)
- Ataque de cajado sem custo (2–3 h)

**Specs:** `MAG-acoes`, `MAG-formas`, `MAG-elementos`.
**Testes:** TDD para o `ActionPlayer` com um mundo falso (ordem das ações, ação inválida ignorada com aviso), para a tabela de interações elementais; *scene runner* para projétil acertando alvo.
**Pronto quando:** o feitiço adaptável do GDD (`feitico_adaptavel`) acerta alvos de elementos diferentes com o elemento certo.

### Sprint 7 — Magia no mundo II: mana viva · 10–16 h

- `meditar()` e `absorver_mana()` (3–4 h)
- Slot passivo executado periodicamente, com custo por operação (4–6 h)
- VFX e sons provisórios (2–4 h)
- **Playtest do núcleo** (1–2 h): alguém de fora escreve e usa um feitiço.

**Specs:** `MAG-mana`, `MAG-passivo`.
**Testes:** TDD para o agendador do passivo (intervalo, não sobrepõe execuções, para quando a mana não cobre o custo); teste comparando o rendimento de um passivo que checa a mana vs. um que absorve sempre (o GDD diz que o primeiro deve render mais).
**Pronto quando (fecha o M2):** o ciclo escrever → equipar → conjurar → ver acontecer funciona de ponta a ponta, e o passivo recarrega mana em combate.

### Sprint 8 — Puzzles I: validação e passo a passo · 14–20 h

- Validação pelo estado do mundo: condições declarativas (`todos_cristais_acesos`, `porta_aberta`) como `Resource`, avaliadas por um `PuzzleValidator` (5–7 h)
- Execução passo a passo com linha destacada e velocidade ajustável (6–9 h)
- Puzzle 1 — meditar para reunir a primeira mana e abrir o caminho (3–4 h)

**Specs:** `PUZ-validacao`, `PUZ-passo-a-passo`, `PUZ-01-meditar`.
**Testes:** TDD para o validador; **teste de aceitação por puzzle** que roda o executor real e o validador headless com uma lista de soluções que devem passar e outras que devem falhar.
**Pronto quando:** o Puzzle 1 resolve só pelo estado do mundo, com a linha atual destacada.

### Sprint 9 — Puzzles II · 16–25 h

- Puzzle 2, variáveis: cadeado de runas (3–4 h)
- Puzzle 3, condicionais: porta que muda de símbolo (3–5 h)
- Puzzle 4, loops: ponte de 12 blocos (3–5 h)
- Puzzle 5, funções: elevador com `levitar(altura)` (4–6 h)
- Puzzle 6, revisão: estrelas por economia de mana (3–5 h)

**Specs:** uma por puzzle (`PUZ-02` a `PUZ-06`), cada uma listando pelo menos três soluções válidas de estilos diferentes, duas inválidas e os limites de mana das estrelas.
**Testes:** aceitação com essas soluções. É aqui que o pilar "muitas soluções" vira teste: se alguém mudar o validador e uma solução legítima parar de passar, o CI acusa.
**Pronto quando:** os 6 puzzles passam nos testes de aceitação e são jogáveis numa sala de teste.

### Sprint 10 — Combate I: inimigos · 18–26 h

- Vida dos inimigos, dano, fraquezas elementais (4–6 h)
- Elemental de fogo, fraco contra gelo (4–6 h)
- Enxame, que pede feitiço com repetição sobre a lista de alvos (5–7 h)
- Guardião que alterna o elemento do escudo (5–7 h)

Pode exigir um sentido novo no executor (ex.: `inimigos_proximos()` devolvendo lista); se sim, atualizar `EXE-pecas` e o contrato primeiro.

**Specs:** `COM-dano`, `COM-elemental`, `COM-enxame`, `COM-guardiao`.
**Testes:** TDD para a tabela de dano/fraquezas e para as máquinas de estado dos inimigos (fora da cena); *scene runner* para um encontro de cada.
**Pronto quando:** cada inimigo pode ser vencido por um feitiço bem pensado e é sofrido de vencer só no cajado.

### Sprint 11 — Combate II: chefe e balanceamento · 12–19 h

- Chefe da Masmorra: duas fases que trocam de fraqueza (10–15 h)
- Ajuste de dificuldade e custos de mana (2–4 h), com os valores num único arquivo de balanceamento

**Specs:** `COM-chefe`, `BAL-valores`.
**Testes:** TDD para a troca de fase e fraqueza; teste que garante que um feitiço adaptável de referência vence o chefe dentro de um orçamento de mana.
**Pronto quando (fecha o M3 de combate):** o chefe é vencível com feitiço adaptável e muda de fase de forma legível.

### Sprint 12 — Progressão e sistemas da serpente · 12–18 h

- XP por monstros e puzzles, bônus por solução econômica (3–4 h)
- Níveis até o 5, aumentando a mana máxima (2–3 h)
- Sistema de diálogo, com textos em arquivo (4–6 h)
- Páginas de referência no grimório (3–5 h)

**Specs:** `PRO-xp`, `PRO-niveis`, `NAR-dialogo`, `GRI-referencia`.
**Testes:** TDD para XP/níveis (curva, teto no 5, bônus) e para o leitor de diálogos (avança, ramifica, fala ausente gera erro claro).

### Sprint 13 — Conteúdo da serpente e save · 14–21 h

- Falas da serpente: apresentação e um ensinamento por conceito (4–6 h)
- Dicas em três níveis para cada puzzle (4–6 h)
- Salvar e carregar o progresso, com versão no formato do save (4–6 h)
- Desenhar o mapa da área no papel, ~12 salas (2–3 h)

**Specs:** `NAR-serpente`, `NAR-dicas`, `SAV-progresso`.
**Testes:** TDD para o save (ida e volta preserva tudo; save corrompido ou de versão antiga não quebra o jogo); teste que garante que todo puzzle tem as três dicas e toda fala referenciada existe.

### Sprint 14 — Montagem da área · 14–21 h

- Construir as 12 salas (8–12 h)
- Posicionar puzzles, inimigos e segredos (3–5 h)
- Menu inicial, pausa e opções básicas, incluindo tamanho da fonte (3–4 h)

**Specs:** `MUN-mapa` (grafo de salas e o que bloqueia cada passagem), `UI-menus`.
**Testes:** teste que carrega todas as salas e verifica conexões (toda porta leva a uma sala que existe e volta); teste de que a área é completável na ordem dos conceitos (cada bloqueio só exige conceitos já ensinados).
**Pronto quando:** dá para jogar do começo ao chefe.

### Sprint 15 — Testes com iniciantes e build · 15–25 h

- Jogar do início ao fim e corrigir bugs (5–8 h); cada bug vira um teste de regressão antes da correção
- Testar com 3 a 5 iniciantes, observando sem ajudar, com um roteiro de observação (4–6 h)
- Ajustes a partir dos testes (5–8 h)
- Build da Alpha para Windows (1–3 h)

**Pronto quando (fecha a Alpha):** um iniciante joga do início ao fim sem ajuda externa e quer continuar.

## 4. Estrutura de pastas proposta

```
ArcaneSyntax/
├─ docs/
│  ├─ gdd.md, plano-alpha.md      (os documentos atuais)
│  ├─ roadmap-alpha.md            (este arquivo)
│  ├─ adr/                        (decisões de arquitetura)
│  ├─ specs/                      (uma pasta por área: executor, grimorio, puzzles…)
│  └─ diario.md
├─ game/                          (projeto Godot)
│  ├─ src/
│  │  ├─ core/                    (regras puras, sem Node)
│  │  ├─ nodes/                   (cenas e scripts de cena)
│  │  └─ executor_client/
│  ├─ content/                    (salas, puzzles, falas, balanceamento)
│  └─ tests/                      (GdUnit4: unit/, scene/, integration/)
├─ executor/                      (Python)
│  ├─ arcane_executor/
│  └─ tests/                      (pytest)
├─ tests/contract/                (fixtures JSON compartilhadas)
└─ .github/workflows/ci.yml
```

## 5. Decisões a tomar cedo

| Quando | Decisão | Recomendação |
| --- | --- | --- |
| Sprint 1 | Modelo de execução (snapshot vs. interativo) | Snapshot com simulação local dos atributos do mago |
| Sprint 1 | Processo por feitiço vs. worker persistente | Worker persistente, medir no spike |
| Sprint 2 | O que conta como "operação" | Linhas executadas + custo base por peça |
| Sprint 0 | GDScript ou C# no Godot | GDScript (mais tutoriais, export mais simples, GdUnit4 cobre bem) |
