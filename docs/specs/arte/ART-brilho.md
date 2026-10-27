# ART-brilho — Luz, partículas, tremida, runas e moldura

- **Status:** Implementada
- **Sprint:** 20
- **Relacionadas:** ART-esteira, MAG-efeitos, COM-chefe, UI-menus, UI-hud, PUZ-passo-a-passo

## Contexto

A identidade visual (`docs/arte/identidade-visual.md`) lista o que o código faz para a arte brilhar, e diz que a luz "é o que mais muda a cara do jogo" com pouca arte. Esta spec junta esses efeitos. Nenhum muda regra de jogo: os puzzles, o dano e o executor ficam iguais.

## Fora do escopo

Sombras projetadas, mapas de normal, luz que muda puzzle (a tocha da porta condicional do GDD), fonte em pixel (entra quando o arquivo existir), ícones de vida e mana na HUD, sons novos.

## Regras

### Luz

1. **Sala escura:** o mundo fica sob uma luz ambiente escura e azulada (`Lighting.AMBIENT`); a HUD, os menus, o grimório e a caixa de diálogo não escurecem.
2. **Quem acende luz** (`PointLight2D` com a textura radial de `Lighting`): tocha (laranja, raio 80 px, cintila), cristal aceso (cor do elemento que o acendeu, 48 px; apagado não acende), projétil e faísca (cor do elemento, 32 px), escudo do mago (cor do elemento, 40 px), serpente (verde-água, 40 px), fonte (azul, 48 px), inimigos (cor do corpo, 32 px; o chefe, 64 px, troca de cor com a fase), orbe e pilar de pé do chefe (cor da fase, 24 px), e o **mago** (luz fraca e neutra, 56 px), para nunca sumir no escuro.
3. Luz que some com o dono (projétil que acerta, inimigo derrotado, pilar que desce).

### Partículas

4. **Cada elemento tem um jeito** (`ParticleStyle.for_element`, regra pura): **fogo**, brasas que sobem; **gelo**, flocos que caem devagar; **raio**, faíscas rápidas e curtas; **planta**, folhas que vão para o lado e caem. Outro elemento (ou nenhum) usa o estilo neutro de hoje.
5. Usam o estilo: o golpe num alvo (boneco, cristal ou inimigo; é onde o projétil e a faísca acertam), no elemento do golpe; o inimigo derrotado, no elemento dele; o cristal que acende, no elemento que o acendeu; e a troca de fase do chefe, no elemento novo.

### Tremida e congelamento

6. **Tremida de câmera** (`CameraShake`, regra pura): um "trauma" de 0 a 1 que soma e cai 1,5 por segundo; o deslocamento é `MAX_OFFSET` (6 px) × trauma², numa direção que muda com o tempo, sempre o mesmo para o mesmo tempo. Somam trauma: o mago machucado por um ataque (0,3), a troca de fase do chefe (0,5), um pilar que sobe a até 3 tiles do mago (0,2) e o chefe derrotado (0,8).
7. **Congelamento curto:** quando um golpe do chefe (orbe, pilar ou investida) acerta o mago, o jogo para por **0,06 s** e volta. Pausar ou trocar de sala no meio não deixa o jogo parado.
8. **Opção "Tremer a tela"** (UI-menus): ligada por padrão, gravada no `opcoes.json` (`tremer_tela`); desligada, não há tremida (o congelamento continua).

### Runas do código

9. Cada ação do feitiço que começa no mundo (`ActionPlayer.action_started`) solta uma **runa** acima do mago com o **número da linha** que a gerou: sobe 16 px e some em 0,8 s, na cor do elemento da ação (violeta sem elemento). Com a arte `magia/runa`, a runa usa o desenho; sem ela, um losango desenhado com o número.

### Interface

10. **Moldura:** com `ui/moldura` (9-slice de 48×48, margem de 16 px), o painel dos menus, da caixa de diálogo e do grimório usa a moldura; sem ela, o painel de hoje.
11. **Logo:** com `ui/logo`, o menu inicial mostra o logo no lugar do título em texto.

## Critérios de aceite

### ART-060 — Sala escura, HUD clara (cena)

- **Dado** o mundo montado
- **Então** existe um `CanvasModulate` com `Lighting.AMBIENT` no mundo, e a HUD, o grimório e a caixa de diálogo são `CanvasLayer` (fora dele)

### ART-061 — Quem acende luz (cena)

- **Dado** uma sala com tocha, cristal, serpente, fonte e um elemental de fogo
- **Então** a tocha, a serpente, a fonte, o elemental e o mago têm luz com a cor e o raio da regra 2; o cristal apagado não tem luz acesa
- **E** todo texto dentro da sala (nomes, números, avisos) tem `Lighting.READABLE`: não escurece (regressão da captura da Sprint 20)
- **Quando** o cristal acende com gelo e um projétil de raio é lançado
- **Então** o cristal tem luz da cor do gelo e o projétil, da cor do raio; o chefe na fase 2 tem luz da cor do gelo

### ART-062 — Estilo de partícula por elemento

- **Então** a gravidade do fogo aponta para cima; a do gelo, para baixo e fraca; o raio tem a maior velocidade e a menor duração; a planta tem gravidade para o lado; um elemento desconhecido usa o neutro

### ART-063 — Tremida de câmera

- **Dado** um `CameraShake` novo
- **Então** o deslocamento é zero
- **Quando** soma 0,5 de trauma
- **Então** o deslocamento tem tamanho até 6 × 0,25 px; somar mais não passa de 1; depois de 1/1,5 s sem somar, volta a zero; o mesmo tempo dá o mesmo deslocamento

### ART-064 — Tremida no jogo e a opção (cena)

- **Dado** o mago no mundo
- **Quando** um ataque o machuca
- **Então** a câmera ganha trauma (0,3) e se desloca; com a opção "Tremer a tela" desligada, não se desloca
- **E** a opção grava `tremer_tela` e volta igual ao abrir de novo

### ART-065 — Congelamento nos golpes do chefe (cena)

- **Quando** um orbe do chefe acerta o mago
- **Então** o jogo fica parado por 0,06 s (`Engine.time_scale` 0) e volta a 1
- **E** um ataque que não é do chefe não congela; e se o mundo sai da árvore durante o congelamento, a escala volta a 1

### ART-066 — Runas do código (cena)

- **Dado** o mago e um feitiço com `lancar` na linha 1 e `meditar` na linha 2
- **Quando** o feitiço toca no mundo
- **Então** saem duas runas acima do mago, com os números 1 e 2, a primeira na cor do elemento e a segunda violeta; 0,8 s depois, não há mais runas

### ART-067 — Moldura e logo (cena)

- **Dado** a pasta de arte de teste com `ui/moldura` e `ui/logo`
- **Então** o painel dos menus e o da caixa de diálogo usam uma `StyleBoxTexture` com a moldura, e o menu inicial mostra o logo (o título em texto some)
- **E** sem esses arquivos, o painel é o de hoje e o título aparece em texto
