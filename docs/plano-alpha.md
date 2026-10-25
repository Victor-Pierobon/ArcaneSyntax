# Jogo do Mago Programador — Plano da versão Alpha

Oct 24, 2026 · @Victor Pierobon

A Alpha é uma fatia jogável do Ato I, só com Python, estimada em 226 a 344 horas de trabalho. A ideia completa do jogo está em Doc.

## Escopo

A Alpha prova que o núcleo do jogo é divertido: escrever um feitiço em Python e vê-lo resolver um puzzle ou derrotar um inimigo. Tudo o que não ajuda a provar isso fica para depois.

| Entra na Alpha | Fica para depois |
| --- | --- |
| Uma área: Fundações e Masmorra, com cerca de 12 salas | Atos II, III e IV |
| Só Python | C, C++ e seus executores |
| A serpente, com diálogos e dicas | Kitsune e corvo |
| Grimório com editor, 5 slots, slot passivo e custo de mana | Modo Arquimago |
| 3 elementos (fogo, gelo, raio) e 2 formas (projétil, escudo) | Demais elementos e formas |
| 6 puzzles, um por conceito e um de revisão | Puzzles de reparo e de otimização avançada |
| 3 inimigos e 1 chefe | Bestiário completo |
| XP e níveis até o 5 | Progressão completa |
| Save de um perfil | Perfis múltiplos e modo professor |
| Arte provisória (assets prontos) | Arte final e trilha sonora |
| Português | Inglês e página na Steam |

**Conceitos da Alpha:** sequência, variáveis, condicionais, loops e funções.

**Critério de sucesso:** um iniciante em programação joga do início ao fim sem ajuda externa e quer continuar.

## Marcos

As dez fases se agrupam em quatro marcos, e cada um termina com algo que dá para testar.

&#91;embedded content: marcos da Alpha · 4 etapas\]

Só passe para o marco seguinte quando o critério do atual estiver cumprido.

## Horas por fase

As dez fases somam de 226 a 344 horas. As estimativas supõem alguém que já programa em Python e está começando no Godot; o limite alto cobre imprevistos e aprendizado.

| Fase | Entrega | Horas |
| --- | --- | --- |
| 0. Preparação | Godot aprendido, projeto criado, personagem andando | 15–25 |
| 1. Executor de feitiços | Código Python vira lista de ações, com custo de mana e limites | 25–40 |
| 2. Personagem e mundo | Movimento, salas, vida e HUD | 20–30 |
| 3. Grimório | Editor, feitiços salvos, 5 slots e erros | 25–35 |
| 4. Magia no mundo | Ações animadas, elementos, formas, cajado, meditação e feitiço passivo | 26–39 |
| 5. Puzzles | Validação, execução passo a passo e 6 puzzles | 30–45 |
| 6. Combate | 3 inimigos e o chefe | 30–45 |
| 7. Progressão e serpente | XP, níveis, diálogos e dicas | 20–30 |
| 8. Montagem da área | 12 salas, save e menus | 20–30 |
| 9. Testes e ajustes | Teste com iniciantes e build da Alpha | 15–25 |
| **Total** |  | **226–344** |

A Fase 1 vem antes de tudo de propósito: é o maior risco técnico, e se ela não funcionar o resto precisa mudar.

## Tarefas: fases 0 a 3

Cada tarefa cabe em uma a três sessões de tempo livre e tem sua estimativa em horas.

### Fase 0. Preparação

- [ ] Fazer o tutorial oficial de jogo 2D do Godot — 8 a 12 h
- [ ] Criar o repositório Git e a estrutura de pastas — 1 a 2 h
- [ ] Escolher um pacote de assets provisórios (masmorra, mago, inimigos) — 2 a 3 h
- [ ] Protótipo de uma tela com o personagem andando e pulando — 4 a 8 h

### Fase 1. Executor de feitiços

- [ ] Rodar Python num processo separado a partir do Godot, trocando mensagens em JSON — 6 a 10 h
- [ ] Criar a API de peças em Python (`lancar`, `mover`, sentidos), que só registra ações numa fila — 4 a 6 h
- [ ] Contar as operações executadas e converter em custo de mana — 4 a 6 h
- [ ] Limites de mana e de tempo, para um loop infinito falhar sem travar o jogo — 3 a 5 h
- [ ] Bloquear acesso a arquivos, rede e imports perigosos — 4 a 7 h
- [ ] Devolver erros com a linha e a mensagem real do Python — 2 a 3 h
- [ ] Testes automatizados do executor — 2 a 3 h

### Fase 2. Personagem e mundo

- [ ] Movimento: andar, pular, esquivar e gravidade ajustada — 6 a 9 h
- [ ] Câmera que segue o jogador, com limites por sala — 2 a 3 h
- [ ] Tilemap e colisões com o tileset provisório — 4 a 6 h
- [ ] Transição entre salas — 3 a 5 h
- [ ] Vida do jogador, dano e volta ao último ponto seguro — 3 a 4 h
- [ ] HUD com vida e mana — 2 a 3 h

### Fase 3. Grimório

- [ ] Abrir e fechar o grimório, pausando o jogo — 2 a 3 h
- [ ] Editor com realce de sintaxe Python (nó CodeEdit do Godot) — 4 a 6 h
- [ ] Lista de feitiços salvos: criar, renomear e apagar — 4 a 5 h
- [ ] Equipar feitiços nos 5 slots e conjurar por tecla — 4 a 6 h
- [ ] Painel de erros com a linha marcada no editor — 3 a 4 h
- [ ] Mostrar o custo de mana estimado de cada feitiço — 3 a 4 h
- [ ] Autocompletar das peças conhecidas — 5 a 7 h

## Tarefas: fases 4 a 6

### Fase 4. Magia no mundo

- [ ] Animar a fila de ações devolvida pelo executor (lançar, mover, levitar) — 5 a 8 h
- [ ] Formas: projétil e escudo — 5 a 7 h
- [ ] Elementos: fogo, gelo e raio, com efeitos e interações — 5 a 7 h
- [ ] Ataque básico de cajado, sem custo de mana — 2 a 3 h
- [ ] Meditar e absorver mana: as ações do primeiro feitiço — 3 a 4 h
- [ ] Slot passivo: feitiço executado continuamente pelo jogo, com custo por operação — 4 a 6 h
- [ ] Efeitos visuais e sons provisórios — 2 a 4 h

### Fase 5. Puzzles

- [ ] Sistema de validação pelo estado do mundo — 5 a 7 h
- [ ] Execução passo a passo, com linha destacada e velocidade ajustável — 6 a 9 h
- [ ] Puzzle 1, primeiro feitiço: meditar para reunir a primeira mana e usá-la para abrir o caminho — 3 a 4 h
- [ ] Puzzle 2, variáveis: guardar valores lidos na sala para abrir um cadeado de runas — 3 a 4 h
- [ ] Puzzle 3, condicionais: porta que muda de símbolo — 3 a 5 h
- [ ] Puzzle 4, loops: ponte de 12 blocos — 3 a 5 h
- [ ] Puzzle 5, funções: elevador com `levitar(altura)` usado em alturas diferentes — 4 a 6 h
- [ ] Puzzle 6, revisão: combina os conceitos, com estrelas por economia de mana — 3 a 5 h

### Fase 6. Combate

- [ ] Vida dos inimigos, dano e fraquezas elementais — 4 a 6 h
- [ ] Inimigo 1: elemental de fogo, fraco contra gelo — 4 a 6 h
- [ ] Inimigo 2: enxame pequeno, que pede um feitiço com repetição — 5 a 7 h
- [ ] Inimigo 3: guardião que alterna o elemento do escudo — 5 a 7 h
- [ ] Chefe da Masmorra: duas fases que trocam de fraqueza — 10 a 15 h
- [ ] Ajustar dificuldade e custos de mana — 2 a 4 h

## Tarefas: fases 7 a 9

### Fase 7. Progressão e serpente

- [ ] XP por monstros e puzzles, com bônus por solução econômica — 3 a 4 h
- [ ] Níveis até o 5, cada um aumentando a mana máxima — 2 a 3 h
- [ ] Sistema de diálogo — 4 a 6 h
- [ ] Falas da serpente: apresentação e um ensinamento por conceito — 4 a 6 h
- [ ] Dicas em três níveis para cada puzzle — 4 a 6 h
- [ ] Páginas de referência no grimório — 3 a 5 h

### Fase 8. Montagem da área

- [ ] Desenhar no papel o mapa da área, com cerca de 12 salas — 2 a 3 h
- [ ] Construir as salas no Godot — 8 a 12 h
- [ ] Posicionar puzzles, inimigos e segredos — 3 a 5 h
- [ ] Salvar e carregar o progresso — 4 a 6 h
- [ ] Menu inicial, pausa e opções básicas — 3 a 4 h

### Fase 9. Testes e ajustes

- [ ] Jogar do início ao fim e corrigir bugs — 5 a 8 h
- [ ] Testar com 3 a 5 iniciantes em programação, observando sem ajudar — 4 a 6 h
- [ ] Ajustar a partir do que os testes mostrarem — 5 a 8 h
- [ ] Gerar o build da Alpha — 1 a 3 h

## Como trabalhar no tempo livre

Sem prazo fixo, o risco é o projeto parar, não atrasar. Algumas regras para manter o ritmo:

1. **Uma tarefa por sessão.** Escolher a próxima tarefa antes de fechar o computador, para a sessão seguinte começar sem decidir nada.
2. **O jogo sempre roda.** Nunca encerrar uma sessão com o projeto quebrado; fazer commit do que funciona.
3. **Diário de desenvolvimento.** Duas linhas por sessão: o que foi feito e o que vem a seguir. Isso também vira material para divulgar o jogo depois.
4. **Arte por último.** Usar assets prontos até a Alpha estar jogável; arte bonita em sistema que vai mudar é retrabalho.
5. **Ideias novas vão para o GDD.** Durante a Alpha, ideias boas são anotadas, não implementadas.

**Ferramentas**

| Para quê | Ferramenta |
| --- | --- |
| Motor do jogo | Godot 4 |
| Feitiços | Python embutido, rodando em processo separado |
| Versões do código | Git e GitHub |
| Pixel art | Aseprite (pago) ou LibreSprite (gratuito) |
| Assets provisórios | Pacotes gratuitos ou baratos do itch.io |
| Tarefas | As listas deste documento |
