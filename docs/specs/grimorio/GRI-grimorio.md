# GRI-grimorio — O grimório na tela

- **Status:** Implementada (visual provisório)
- **Sprint:** 4
- **Relacionadas:** GRI-feiticos; Sprint 5 (slots, erros, custo, autocompletar)

## Contexto

O grimório é um editor de código disfarçado de livro (GDD). Abrir pausa o jogo, para ninguém aprender sob pressão.

## Fora do escopo

Slots, conjurar, painel de erros, custo estimado, autocompletar (Sprint 5). Modo Arquimago (depois da Alpha). Arte do livro.

## Regras

1. **Tab** abre o grimório quando ele está fechado. **Esc** ou o botão Fechar fecham. (Tab não fecha, porque dentro do editor ele indenta o código.)
2. Aberto, o grimório **pausa o mundo** (`get_tree().paused`) e continua respondendo (`process_mode = ALWAYS`). Fechado, o mundo volta.
3. À esquerda, a lista de feitiços e os botões **Novo**, **Renomear** e **Apagar**, com um campo de nome. À direita, o editor do feitiço selecionado.
4. **Novo** cria `Feitiço N` (GRI-feiticos regra 5) e já o seleciona. **Renomear** usa o campo de nome. **Apagar** remove o selecionado e seleciona o vizinho. Erros de nome aparecem numa linha de aviso, em texto de `textos.csv`.
5. Trocar de feitiço, fechar o grimório ou fechar o jogo **guarda a edição** no modelo; criar, renomear, apagar e fechar **salvam no disco**.
6. Ao abrir, o feitiço selecionado continua o mesmo da última vez (ou o primeiro, se não houver).
7. **Editor:** realce de Python (palavras-chave, textos, comentários, números), com cor própria para as peças do jogo (`lancar`, `meditar`, `fogo`, `mana`…), números de linha, indentação automática com 4 espaços.
8. Se o arquivo do grimório estava ilegível (GRI-feiticos regra 9), o aviso aparece na linha de aviso na primeira vez que o grimório abre.

## Critérios de aceite

### GRI-001 — Abrir pausa, fechar despausa

- **Quando** o grimório abre
- **Então** fica visível e a árvore está pausada; ao fechar, some e a árvore volta

### GRI-002 — Funciona com o jogo pausado

- **Dado** o grimório aberto
- **Então** ele pode processar e o mago não

### GRI-003 — Novo, renomear e apagar pela tela

- **Quando** aperta Novo duas vezes, renomeia o segundo para "Raio" e apaga o primeiro
- **Então** a lista mostra só "Raio", selecionado, e o disco tem o mesmo conteúdo; renomear para um nome inválido mostra o aviso e não muda nada

### GRI-004 — Edição guardada ao trocar de feitiço

- **Dado** dois feitiços
- **Quando** edita o código do primeiro e seleciona o segundo
- **Então** o modelo tem o código editado do primeiro e o editor mostra o do segundo

### GRI-005 — Fechar salva no disco

- **Quando** edita o código e fecha
- **Então** um grimório carregado do mesmo arquivo tem o código editado

### GRI-006 — Realce de Python

- **Então** o realce dá cor a `while` e `def` (palavra-chave), a `print` (builtin) e a `lancar`, `fogo` e `mana` (peças do jogo), cada grupo com sua cor, e tem regiões de cor para textos e comentários

### GRI-007 — Lembra o selecionado

- **Dado** o segundo feitiço selecionado
- **Quando** fecha e abre de novo
- **Então** o segundo continua selecionado

### GRI-008 — Aviso de arquivo ilegível

- **Dado** o grimório foi carregado de um arquivo corrompido
- **Quando** abre pela primeira vez
- **Então** a linha de aviso explica que o arquivo foi guardado como `.bak`
