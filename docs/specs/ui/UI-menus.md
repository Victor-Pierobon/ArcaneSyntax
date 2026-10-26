# UI-menus — Menu inicial, pausa, opções e fim da demo

- **Status:** Implementada (visual provisório)
- **Sprint:** 14
- **Relacionadas:** SAV-progresso, MUN-mapa (`sala_fim`), NAR-dialogo, GRI-grimorio, UI-hud

## Contexto

Para um iniciante jogar do começo ao fim sem ajuda, o jogo precisa abrir num menu, deixar pausar a qualquer momento e terminar a demonstração com clareza. A acessibilidade do GDD pede fonte ajustável no grimório e nos diálogos, e pausa sempre disponível.

## Fora do escopo

Tela de perfis e vários slots (a Alpha tem o perfil `padrao`). Remapear teclas. Opções de vídeo. Créditos.

## Regras

1. **Menu inicial:** a cena principal (`Main`) abre no menu: título, **Continuar** (só se o perfil tem `save.json`), **Novo jogo**, **Opções** e **Sair**. O primeiro botão já vem com o foco: dá para jogar só com o teclado (setas e Enter).
2. **Novo jogo:** sem save, começa direto na `sala_01`. Com save, pergunta antes ("O progresso salvo será apagado. O grimório fica."). Sim apaga o `save.json` do perfil e começa; Não volta ao menu. **O grimório nunca é apagado**: os feitiços são do jogador.
3. **Pausa:** Esc, durante o jogo, abre o menu de pausa (**Continuar**, **Opções**, **Voltar ao menu**) e pausa o mundo. Com o grimório ou um diálogo aberto, Esc continua sendo deles (fechar o grimório; o diálogo ignora). Com a pausa aberta, o grimório não abre e Esc fecha a pausa.
4. **Voltar ao menu** salva o progresso, fecha o mundo e mostra o menu inicial.
5. **Opções**, iguais no menu inicial e na pausa:
   - **Tamanho do texto:** Normal, Grande, Muito grande, que somam 0, 2 ou 3 pontos à fonte do grimório (lista, editor, referência, resultado) e da caixa de diálogo. Vale na hora.
   - **Volume:** de 0% a 100%, de 10 em 10, no som do jogo todo.
   - Guardadas em `<perfil>/opcoes.json`; arquivo ilegível ou valor fora da faixa usa o padrão (Normal, 80%).
6. **A caixa de diálogo cabe em qualquer tamanho de texto:** com Muito grande, toda fala e dica do jogo continua acima da metade da tela (NAR-005). Para isso, com texto maior que Normal a caixa sobe para o alto da tela e cobre o HUD enquanto está aberta (o jogo está pausado). Com texto Normal, ela continua abaixo do HUD.
7. **Fim da demo:** atrás da porta do chefe, a `sala_fim` tem a serpente com a cena `fim_demo`. Quando a fala `fim` aparece e o diálogo termina, o jogo salva e mostra a tela de fim com o resumo: nível e XP, puzzles resolvidos (de 6), estrelas, lições vistas e segredos encontrados (do total da área). Enter volta ao menu inicial; Continuar leva de volta à `sala_fim`.
8. Textos de todos os menus vêm do `textos.csv`.

## Critérios de aceite

### UI-010 — Menu sem save (cena)

- **Dado** um perfil sem `save.json`
- **Então** o menu não mostra Continuar e o foco está em Novo jogo
- **Quando** escolhe Novo jogo
- **Então** o mundo sobe na `sala_01`, entrada `A`, com o save e o grimório do perfil

### UI-011 — Continuar (cena)

- **Dado** um perfil com save na `sala_p03`
- **Então** o menu mostra Continuar com o foco
- **Quando** escolhe Continuar
- **Então** o mundo sobe na `sala_p03`

### UI-012 — Novo jogo com save pede confirmação (cena)

- **Dado** um perfil com save e um grimório com o feitiço "Meu"
- **Quando** escolhe Novo jogo e responde Não
- **Então** continua no menu, com o save intacto
- **Quando** escolhe Novo jogo e responde Sim
- **Então** o mundo sobe na `sala_01` com XP 0, e o grimório ainda tem "Meu"

### UI-013 — Pausa (cena)

- **Dado** o jogo rodando
- **Quando** aperta Esc
- **Então** a pausa abre e a árvore fica pausada; Tab não abre o grimório
- **Quando** aperta Esc de novo (ou escolhe Continuar)
- **Então** a pausa fecha e o jogo continua
- **E** com o grimório aberto, Esc fecha o grimório e não abre a pausa

### UI-014 — Voltar ao menu salva (cena)

- **Dado** o mago na `sala_02`
- **Quando** escolhe Voltar ao menu na pausa
- **Então** o `save.json` está na `sala_02`, o mundo foi fechado e o menu inicial aparece, sem pausa

### UI-015 — Opções guardadas (regra pura)

- **Dado** um `Settings` novo
- **Então** texto Normal (0 pontos) e volume 80%
- **Quando** passa para Muito grande e volume 30%, grava e lê de novo
- **Então** volta Muito grande (3 pontos) e 30%
- **E** volume 130 vira 100; arquivo ilegível ou tamanho desconhecido usa o padrão

### UI-016 — Tamanho do texto vale no grimório e no diálogo (cena)

- **Quando** o tamanho do texto vira Grande
- **Então** o editor do grimório e o texto da caixa de diálogo ficam 2 pontos maiores; voltando a Normal, voltam ao tamanho original

### UI-017 — Fim da demo (cena)

- **Dado** o mundo na `sala_fim` com 2 puzzles resolvidos (4 estrelas) e 1 segredo
- **Quando** a conversa `fim_demo` termina
- **Então** a tela de fim mostra o resumo e Enter volta ao menu inicial

## Perguntas em aberto

- [ ] Vale um botão para remapear teclas? (GDD, acessibilidade, depois da Alpha)
- [ ] A tela de fim deveria convidar a responder o questionário do playtest?
