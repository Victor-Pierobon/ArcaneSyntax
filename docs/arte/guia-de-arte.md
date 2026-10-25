# Guia de arte

Como produzir a arte do ArcaneSyntax sem retrabalho. Vale para arte feita à mão, assets comprados e conceitos gerados por IA.

## 1. Quando fazer o quê

| Agora (não se perde) | Depois que a Alpha estiver jogável (regra "arte por último") |
| --- | --- |
| Direção de arte: paleta, clima, referências | Sprites finais animados |
| Design de personagens (folhas de conceito) | Tilesets finais por andar |
| Escolher o pacote de assets provisórios (bloqueia a Sprint 3) | Efeitos visuais finais |
| Silhuetas e proporções do mago, serpente e inimigos | Interface final do grimório |

## 2. Especificações técnicas (já configuradas no Godot)

| Item | Valor |
| --- | --- |
| Resolução base | 640×360 (escala inteira para 1280×720 e 1920×1080) |
| Tile | 16×16 px |
| Mago | ~32 px de altura; colisor atual 12×30 px; origem nos pés |
| Filtro | `nearest` (sem suavização) |
| Formato | PNG com transparência; animações em sprite sheet (quadros do mesmo tamanho, lado a lado) |
| Paleta | Limitada: ~16–32 cores por andar; uma paleta por andar para sentir a subida da torre |
| Vista | Lateral (side-scroller) |
| Fonte-mãe | Arquivos `.aseprite` em `art/` (raiz do repo); PNG exportado em `game/assets/` |

Regras de pixel art que a IA costuma quebrar: pixels alinhados numa grade única; sem anti-aliasing automático nem degradê suave; contorno consistente; mesma luz (de cima, levemente à esquerda) em tudo.

## 3. Direção (do GDD)

- Atmosfera inspirada em Hollow Knight: sombrio e misterioso, mas acolhedor; silhuetas sempre legíveis.
- Magia Elemental (Python, Ato I): cores vivas, partículas naturais (chamas, gelo, folhas).
- Conjuração: as linhas de código brilham como runas.
- Andar da Alpha: **Fundações e Masmorra**: pedra antiga, umidade, tochas, cristais, runas apagadas.

## 4. Lista do que a Alpha precisa

**Mago (protagonista)**: parado, andar, pular, cair, esquivar, conjurar, meditar, ataque de cajado, levar dano, morrer.
**Serpente (mentora, Python)**: parada/falando, aparecer/sumir; retrato para diálogo.
**Inimigos**: elemental de fogo; enxame (inimigo pequeno, em grupo); guardião com escudo que troca de elemento (fogo/gelo/raio); chefe da Masmorra com duas fases.
**Tileset da Masmorra**: chão, paredes, cantos, plataformas, fundo em 2–3 camadas (paralaxe), espinhos.
**Objetos de puzzle**: cristais (apagado/aceso), porta com símbolos que mudam, cadeado de runas, blocos de ponte, elevador, tochas.
**Efeitos**: projétil e escudo em fogo, gelo e raio; meditação; absorver mana; runas de conjuração.
**Interface**: moldura de livro do grimório, vida e mana no HUD, 5 slots de feitiço, balão de diálogo, "visão" flutuante do `print`.

## 5. Fluxo com IA (ChatGPT ou outro gerador)

1. Gerar **conceito** com os prompts abaixo; pedir variações.
2. Escolher e anotar o que funciona (silhueta, cores, detalhes).
3. **Redesenhar no Aseprite** no tamanho real (32 px o mago, 16 px os tiles), usando a paleta definida.
4. Exportar PNG / sprite sheet para `game/assets/`.
5. Guardar os conceitos em `art/conceitos/` (fora do jogo) para referência.

Dicas de prompt: escrever em inglês costuma dar resultado mais fiel, mas português funciona. Sempre pedir "folha de referência" (várias vistas numa imagem). Trabalhar num mesmo chat para manter a consistência; quando gostar de um resultado, anexá-lo nos próximos pedidos como referência.

## 6. Prompts prontos

### 6.1 Guia de estilo em texto (comece por este)

```
I'm making a 2D pixel art metroidvania called ArcaneSyntax. The player is an apprentice
mage trapped inside a book, climbing an abandoned wizard's tower; every spell is real Python
code. Mood: inspired by Hollow Knight, dark and mysterious but cozy, always readable
silhouettes. Base resolution 640x360, 16x16 tiles, main character about 32 px tall, side view.

Write me a visual style guide for the first area, "Foundations and Dungeon" (old stone,
damp, torches, glowing crystals, faded runes). Include:
1. A 24-color palette with hex codes, grouped (darks, stone, light sources, magic: fire,
   ice, lightning, nature).
2. Lighting rules, outline rules, contrast between foreground, gameplay layer and background.
3. Shape language for the mage, the snake mentor, and enemies.
4. Do's and don'ts for keeping everything readable at 32 px.
```

### 6.2 Painel de clima (moodboard)

```
Concept art moodboard for a pixel art metroidvania area called "Foundations and Dungeon":
the deepest level of an abandoned wizard's tower. Old mossy stone, damp walls, warm torches,
cold glowing blue crystals, faded runes carved in walls, a sense of quiet mystery but cozy.
Inspired by the mood of Hollow Knight. Side-scrolling view, 3 layers of depth (foreground,
gameplay platforms, misty background). Limited palette, no text.
```

### 6.3 Folha de conceito do mago

```
Character concept sheet for a pixel art side-scroller protagonist: an ordinary person who
became an apprentice mage after reading a strange book. Holds a simple wooden staff and
carries a glowing spellbook (grimoire) at the hip. Gender-neutral, readable silhouette at
32 pixels tall. Show: front, side and back views, plus 3 color variations. Clean pixel art,
limited palette (max 16 colors), no anti-aliasing, flat background, no text.
```

### 6.4 Serpente (mentora, magia Elemental / Python)

```
Character concept sheet for a friendly snake mentor in a pixel art game: curious, talkative,
patient, teaches elemental magic. Subtle nod to the Python language (blue and yellow accents)
without using any logo. Expressive face for dialogue. Show: idle coiled pose, talking pose,
and a larger portrait bust for dialogue boxes. Pixel art, limited palette, no anti-aliasing,
flat background, no text.
```

### 6.5 Inimigos da Alpha

```
Enemy concept sheet for a pixel art metroidvania dungeon, side view, each readable at
24 to 40 pixels tall:
1. Fire elemental: a small living flame, weak to ice.
2. Swarm: tiny mischievous ink-blot creatures that attack in groups of 6 to 10.
3. Shield guardian: a stone knight whose round shield glows in one element at a time
   (fire orange, ice cyan, lightning yellow); show the three shield states.
Same palette family as a dark mossy dungeon with blue crystals. Pixel art, no anti-aliasing,
flat background, no text.
```

### 6.6 Objetos de puzzle e tileset (referência)

```
Pixel art reference sheet, 16x16 tile grid, for a dark dungeon in a wizard's tower:
stone floor and wall tiles with corners, thin stone platform, spikes, a crystal in off and
lit states, a door engraved with a changing rune symbol, a rune lock with 3 dials,
floating bridge blocks, a small magic elevator platform, wall torch.
Limited palette (mossy greys, warm torch orange, cold crystal blue). No anti-aliasing,
no text.
```

### 6.7 Efeitos de magia

```
Pixel art spell effects sheet for a side-scroller, each effect shown in 4 animation frames
on a transparent-looking flat background: fire projectile, ice projectile, lightning
projectile, and a circular shield in each of the three elements. Also: a "meditation" aura
around a 32 px character and small glowing rune glyphs that float up when a spell is cast.
Vivid colors against a dark dungeon. No anti-aliasing, no text.
```

### 6.8 Pedir ajuda para redesenhar à mão

```
Here is the concept I chose [attach image]. I'll redraw it by hand in Aseprite as a sprite
32 pixels tall using this palette: [paste hex codes]. Describe a step-by-step plan:
silhouette first, then base colors, shading, and highlights. Then list the key poses for
these animations with a suggested frame count for each: idle, walk, jump, fall, dodge,
cast, meditate, staff attack, hurt, death.
```

## 7. Assets provisórios (tarefa da Sprint 0)

Procurar no itch.io pacotes gratuitos ou baratos com: tileset de masmorra 16×16, personagem mago ~32 px com animações, alguns inimigos. Conferir a **licença** (uso comercial permitido, exigência de crédito) e anotar o crédito em `art/CREDITOS.md`. Buscas úteis: "dungeon tileset 16x16", "wizard character pixel art", "pixel art spell effects".

## 8. Steam e IA

- A Steam exige declarar conteúdo gerado por IA (pré-gerado e em tempo real) no formulário de conteúdo do jogo.
- Arte totalmente gerada por IA pode não ter proteção de direito autoral em alguns países. Redesenhar à mão evita esse problema e deixa a arte consistente.
