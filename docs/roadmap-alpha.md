# Roadmap da Alpha — Sprints

Base: `docs/plano-alpha.md` (fases 0 a 9) e `docs/gdd.md`.
Este documento reorganiza as fases em 16 sprints menores (0 a 15), cada uma com specs, testes e uma entrega que roda.

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

| Sprint | Nome | Fase(s) | Horas | Marco | Status |
| --- | --- | --- | --- | --- | --- |
| 0 | [Fundação e esteira de testes](sprints/sprint-00-fundacao.md) | 0 | 20–32 | M1 · Feitiço vira ação | Concluída (tutorial e assets pendentes) |
| 1 | [Executor: protocolo e peças](sprints/sprint-01-executor-protocolo.md) | 1 | 14–21 | M1 | Concluída |
| 2 | [Executor: custo, limites e sandbox](sprints/sprint-02-executor-custo-sandbox.md) | 1 | 15–23 | M1 | Concluída (build de fumaça pendente) |
| 3 | [Personagem e mundo](sprints/sprint-03-personagem-mundo.md) | 2 | 20–30 | M2 · Núcleo jogável | Concluída (arte provisória) |
| 4 | [Grimório I: editor e feitiços salvos](sprints/sprint-04-grimorio-editor.md) | 3 | 12–16 | M2 | Concluída |
| 5 | [Grimório II: slots, erros, custo e autocompletar](sprints/sprint-05-grimorio-slots.md) | 3 | 15–21 | M2 | Concluída |
| 6 | [Magia no mundo I: ações, formas, elementos](sprints/sprint-06-magia-acoes.md) | 4 | 17–25 | M2 | Concluída |
| 7 | [Magia no mundo II: mana viva](sprints/sprint-07-magia-mana.md) | 4 | 10–16 | M2 (playtest do núcleo) | Concluída (playtest feito em 2026-10-26) |
| 8 | [Puzzles I: validação e execução passo a passo](sprints/sprint-08-puzzles-validacao.md) | 5 | 14–20 | M3 · Conteúdo | Concluída |
| 9 | [Puzzles II: os 5 puzzles restantes](sprints/sprint-09-puzzles-conteudo.md) | 5 | 16–25 | M3 | Concluída |
| 10 | [Combate I: inimigos](sprints/sprint-10-combate-inimigos.md) | 6 | 18–26 | M3 | Concluída |
| 11 | [Combate II: chefe e balanceamento](sprints/sprint-11-combate-chefe.md) | 6 | 12–19 | M3 | Concluída |
| 12 | [Progressão e sistemas da serpente](sprints/sprint-12-progressao.md) | 7 | 12–18 | M3 | Concluída |
| 13 | [Conteúdo da serpente e save](sprints/sprint-13-serpente-save.md) | 7, 8 | 14–21 | M4 · Alpha | Concluída |
| 14 | [Montagem da área](sprints/sprint-14-montagem-area.md) | 8 | 14–21 | M4 | Concluída |
| 15 | [Testes com iniciantes e build](sprints/sprint-15-testes-build.md) | 9 | 15–25 | M4 | Concluída (build e teste do jogo inteiro; o Victor jogou tudo, no editor e no `.exe`; os testes com outras pessoas passaram para o fim da 1.1) |
| | **Total** | | **~238–359** | | |

### Alpha 1.1 (visual, salas e chefe)

Plano completo, decisões e verificação em [`plano-alpha-1-1.md`](plano-alpha-1-1.md). A arte é do Victor, em paralelo ([`arte/identidade-visual.md`](arte/identidade-visual.md)).

| Sprint | Nome | Horas | Status |
| --- | --- | --- | --- |
| 16 | Esteira de arte e visual provisório | 14–20 | **Próxima** |
| 17 | Chefe 2.0 (3 fases, movimento, pilares, mais vida) | 16–24 | Planejada |
| 18 | Salas I: começo e puzzles | 18–26 | Planejada |
| 19 | Salas II: combate e fim | 14–20 | Planejada |
| 20 | Integração da arte e brilho | 12–20 | Planejada (depende da arte) |
| 21 | Fechamento da 1.1 e testes com outras pessoas | 8–12 | Planejada |
| | **Total** | **~82–122** | |

O total sobe um pouco em relação ao plano (226–344 h) pela esteira de testes e pelas specs. Parte disso volta na Fase 9, com menos bugs para caçar no fim.

## 3. Sprints

Cada sprint tem um arquivo em `docs/sprints/` com tarefas, specs, testes, notas e critério de pronto. Sprints concluídas viram relatório (o que foi entregue, decisões, desvios, como verificar).

## 4. Estrutura de pastas

```
ArcaneSyntax/
├─ docs/
│  ├─ gdd.md, plano-alpha.md      (os documentos atuais)
│  ├─ roadmap-alpha.md            (este arquivo)
│  ├─ arquitetura.md              (como o sistema funciona hoje)
│  ├─ sprints/                    (um arquivo por sprint)
│  ├─ adr/                        (decisões de arquitetura)
│  ├─ specs/                      (uma pasta por área: executor, grimorio, puzzles…)
│  └─ diario.md
├─ game/                          (projeto Godot)
│  ├─ src/
│  │  ├─ core/                    (regras puras, sem Node)
│  │  ├─ nodes/                   (cenas e scripts de cena)
│  │  ├─ executor_client/
│  │  └─ nodes/dev/               (console de feitiços)
│  ├─ content/                    (salas, puzzles, falas, balanceamento)
│  └─ tests/                      (GdUnit4: unit/, scene/, integration/)
├─ executor/                      (Python)
│  ├─ arcane_executor/
│  └─ tests/                      (pytest)
├─ tests/contract/                (fixtures JSON compartilhadas)
├─ scripts/                       (test.sh, fetch_python.sh)
├─ runtime/                       (Python embutido baixado; fora do git)
├─ handoff.md                     (contexto para novas conversas)
└─ .github/workflows/ci.yml
```

## 5. Decisões

| Quando | Decisão | Situação |
| --- | --- | --- |
| Sprint 0 | GDScript ou C# no Godot | **GDScript** |
| Sprint 1 | Modelo de execução (snapshot vs. interativo) | **Snapshot + simulação do mago** (ADR-001) |
| Sprint 1 | Processo por feitiço vs. worker persistente | **Worker persistente**, Python 3.14 standalone (ADR-002) |
| Sprint 2 | Regra de custo de mana | **Linhas baratas**: instrução 0,1 cobrada depois, estruturas grátis, peças com custo base (EXE-custo) |
| Sprint 2 | Contagem de instruções | **Instrumentação da AST** (não `sys.settrace`) |
| Sprint 3 | Como descrever as salas | **Layout em texto** + tileset provisório (MUN-salas); rever quando a arte chegar |
| Sprint 5 | Peças bloqueadas | **O executor recusa** (`pecas` na requisição; EXE-desbloqueio) |
| Sprint 5 | Como aplicar a mana devolvida | **Pela variação** (`final − enviada`) |
| Sprint 6 | Ações anteriores a um erro acontecem no mundo? | **Sim** (Victor, 2026-10-25) |
| Sprint 8 | Como autorar puzzles | **Dicionário `puzzle` na cena da sala** + cristais em `targets` + porta `\|` no layout (não `Resource`) |
