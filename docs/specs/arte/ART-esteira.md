# ART-esteira — Esteira de arte

- **Status:** Implementada
- **Sprint:** 16
- **Relacionadas:** MUN-salas, MUN-movimento, MAG-efeitos, BLD-alpha; `docs/arte/identidade-visual.md` (o contrato para quem desenha)

## Contexto

A arte da Alpha 1.1 é feita pelo Victor, aos poucos e fora do Godot. O jogo procura cada arquivo pelo nome. Se o arquivo existe, usa; se não, mostra o provisório. Assim, cada PNG entregue aparece sem que ninguém mexa em cena, e um teste diz o que veio fora do combinado. O provisório também melhora, para o jogo deixar de parecer quadrados antes da arte chegar.

## Fora do escopo

- Luz, partículas novas, tremida de câmera e interface (Sprint 20).
- Arte e animações do chefe (Sprint 17, quando os ataques novos existirem).
- Animação de morte em jogo: hoje o mago renasce no mesmo quadro. O arquivo `morrer` entra no contrato, mas só é tocado quando houver tempo de morte.
- Arte da interface, das runas, do cadeado, da placa e da ponte: entram no contrato agora; o jogo passa a usá-los na Sprint 20. O cristal, a porta, o baú e a tocha entraram com a primeira leva de arte (regras 24 a 27).

## Regras

### Contrato

1. O contrato fica em `content/arte.json`: para cada **pasta** (`mago`, `serpente`, `elemental`, `enxame`, `guardiao`, `chefe`, `magia`, `objetos`, `cenario`, `ui`), o tamanho do quadro e as **animações**. Cada animação tem `fps`, `laco` e, se precisar, `reserva` (a animação usada quando o arquivo dela falta), `quadro` próprio (um número para quadros quadrados ou `[largura, altura]`) e `elementos` (variantes `<animação>_<elemento>`). Imagens paradas (fundo, tiles, interface) têm `imagem: true` e, se o tamanho for fixo, `tamanho: [largura, altura]`.
2. Arquivo: `game/assets/<pasta>/<animação>.png`. Animação é uma **tira horizontal**: a altura é a do quadro e a largura é um múltiplo da largura do quadro; o número de quadros é largura ÷ largura do quadro.
3. Os personagens são desenhados **olhando para a direita**; o jogo espelha para a esquerda. A base (os pés) fica no centro do quadro, 2 px acima da borda de baixo.
4. Todo pixel é **totalmente opaco ou totalmente transparente** (pixel semitransparente é suavização).
5. Se existir `game/assets/paleta.png` (1 px por cor), todo pixel opaco tem uma cor da paleta. Sem paleta, qualquer cor vale.
6. `game/assets/placeholder/` é do provisório e fica fora do contrato.

### Biblioteca

7. Para um personagem, o jogo monta as animações a partir dos arquivos que existem. Animação sem arquivo usa a `reserva`, seguindo a cadeia de reservas (`cair` → `pular` → `parado`). Sem nenhum arquivo da pasta, o personagem usa o provisório.
8. Os personagens que já usam a arte nesta sprint são o mago, a serpente (`parada`, e `falando` com o diálogo dela aberto), os inimigos (`andar_<elemento>` no elemental, `voar` no enxame, `andar` no guardião), o projétil e a faísca (`projetil_<elemento>`, `faisca_<elemento>`) e o escudo (`escudo_<elemento>`). Os colisores não mudam com a arte.

### Animações do mago

9. A cada quadro, a animação do mago sai de uma regra pura, nesta prioridade:
   1. **dano**, por 0,3 s depois de perder vida;
   2. **esquivar**, enquanto esquiva;
   3. a **ação** do feitiço ou do cajado, enquanto dura: `meditar` (meditar e absorver mana), `conjurar` (lançar e inscrever, por 0,25 s) ou `cajado` (por 0,2 s);
   4. no ar: **pular** subindo ou voando (levitar), **cair** descendo;
   5. **andar**, com velocidade horizontal acima de 10 px/s;
   6. **parado**.
10. O mago olha para onde está virado (`motor.facing`).
11. O mago provisório é desenhado por código (túnica, chapéu, cajado), com uma pose simples por animação. O nó visual do mago é o mesmo com arte ou sem ela; o lampejo da mana pinta esse nó.

### Paredes

12. Cada tile de pedra escolhe sua forma pela vizinhança: um número de 4 bits, com 1 = pedra em cima, 2 = à direita, 4 = embaixo, 8 = à esquerda. Fora da sala conta como pedra.
13. O `tiles.png` tem **4 colunas × 5 linhas** de 16×16 (64×80). Nas linhas 0 a 3, a pedra de número *n* fica na coluna *n* % 4 e na linha *n* ÷ 4. Na linha 4 ficam a plataforma (coluna 0) e os espinhos (coluna 1).
14. O tileset é montado por código a partir da imagem. As 16 formas de pedra têm colisão inteira; a plataforma, uma faixa de 4 px no topo, atravessável por baixo; os espinhos, nenhuma (o dano continua vindo da área da sala).
15. Com `game/assets/cenario/tiles.png`, a sala usa a arte do Victor; sem ela, o provisório `assets/placeholder/tiles_bordas.png`, gerado por `game/tools/gerar_provisorio.gd`.

### Fundo

16. Atrás da sala há três camadas com paralaxe, da mais longe para a mais perto: `fundo_1`, `fundo_2` e `fundo_3`, cada uma com 640×360. Elas se repetem na horizontal e andam a 0,2, 0,45 e 0,7 da velocidade da câmera. Atrás de tudo há uma cor sólida escura.
17. Com `game/assets/cenario/fundo_N.png`, a camada usa a arte; sem ela, o provisório gerado pelo mesmo script.

### Efeitos e estados (primeira leva de arte, 2026-10-27)

21. **Impacto:** quando o projétil ou a faísca acerta um alvo ou uma parede, toca `magia/impacto_<elemento>` uma vez no ponto do acerto e some. Sem a arte, só as partículas de hoje.
22. **Aura de meditar:** com `magia/meditar`, a aura aparece sobre o mago enquanto a animação dele é `meditar` (com ou sem a arte do mago) e some depois; sem ela, o mago provisório desenha a própria aura.
23. **Morte dos inimigos:** com a arte de `morrer` (`morrer_<elemento>` no elemental, `morrer` no guardião), o inimigo derrotado toca essa animação no lugar de sumir na hora; ele sai da cena quando ela termina (no mínimo os 0,4 s de hoje). As regras de derrota não mudam: ele sai dos alvos na hora.
24. **Enxame:** o bicho toca `mergulhar` enquanto mergulha no mago e `voar` no resto do tempo.
25. **Escudo do guardião:** com `guardiao/escudo_<elemento>`, o escudo é esse sprite no centro do corpo, no lugar do círculo, e pisca do mesmo jeito no último segundo.
26. **Cristal:** apagado mostra `objetos/cristal_apagado`; aceso, `cristal_aceso_<elemento>` do feitiço que o acendeu. Sem a arte daquele estado, o retângulo de hoje.
27. **Porta e baú:** cada célula da porta (`|` e `%`) mostra `objetos/porta` (a de atalho, tingida de verde); abrir continua apagando a porta. O baú fechado mostra `objetos/bau_fechado`; aberto, o último quadro de `bau_abrindo` (tocado ao abrir) ou, sem ele, o fechado escurecido.
28. **Tocha:** `tocha` em `targets` é decoração (sem colisão, não é alvo): `objetos/tocha` em laço, ou uma chama provisória desenhada por código.

### Build

18. A fumaça (BLD-alpha) confere que o contrato carrega sem erros.

### Tela

19. Fora da sala é escuro: uma moldura da cor sólida cobre o fundo em volta da sala, para a sala menor que a tela não parecer flutuar.
20. Todo o desenho 2D fica preso à grade de pixels (`snap_2d_transforms_to_pixel` e `snap_2d_vertices_to_pixel`), para a câmera suave não deixar texto e sprites entre dois pixels.

## Critérios de aceite

### ART-001 — O contrato carrega

- **Dado** o `content/arte.json` do jogo
- **Então** carrega sem erros e tem as dez pastas
- **E** cada pasta e cada animação do contrato da `identidade-visual.md` estão nele: as 10 do mago, `andar` e `morrer` nas três variantes do elemental, os fundos 1 a 3, o `tiles.png` de 64×80

### ART-002 — Arquivo dentro do contrato passa

- **Dado** uma tira de 48×48 × 6 quadros em `mago/andar.png`, só com pixels opacos ou transparentes
- **Então** a conferência não acusa nada e conta 6 quadros
- **E** `elemental/andar_gelo.png` (variante) e `chefe/pilar.png` (quadro de 16×64) também passam com o tamanho certo

### ART-003 — Arquivo fora do contrato é acusado

- **Então** acusa, dizendo o arquivo e o motivo:
  - altura diferente do quadro;
  - largura que não é múltipla do quadro;
  - pasta ou nome que o contrato não tem;
  - pixel semitransparente, com a posição do primeiro;
  - com paleta, cor fora dela, com a posição e a cor do primeiro pixel;
  - imagem parada de tamanho fixo com outro tamanho.
- **E** sem paleta, qualquer cor passa

### ART-004 — Toda arte entregue segue o contrato

- **Dado** os PNG em `game/assets/` (menos `placeholder/` e a `paleta.png`)
- **Então** nenhum é acusado (a lista de problemas sai na mensagem do teste)

### ART-005 — A biblioteca monta as animações

- **Dado** uma pasta de teste com `parado` (4 quadros) e `pular` (2 quadros) do mago
- **Então** as animações do mago têm `parado` com 4 quadros, a 6 fps, em laço, e `pular` com 2
- **E** `cair` existe com os quadros do `pular` (reserva), e `andar` com os do `parado`
- **E** sem nenhum arquivo do mago, a biblioteca não devolve animações (o jogo usa o provisório)

### ART-010 — Regra da animação do mago

- **Então** a regra escolhe, pela prioridade da regra 9:
  - parado no chão → `parado`; andando → `andar`;
  - subindo ou voando → `pular`; descendo → `cair`;
  - meditando → `meditar`, mesmo no ar;
  - esquivando enquanto conjura → `esquivar`;
  - com dano → `dano`, acima de tudo.

### ART-011 — O mago na cena

- **Dado** o jogo sem arte do mago
- **Então** o mago mostra o provisório, que segue a animação da regra
- **Dado** a arte do mago numa pasta de teste
- **Então** o mago tem um sprite animado que toca `andar` andando e `parado` parado, espelhado olhando para a esquerda

### ART-012 — Feitiço, cajado e dano tocam no mago

- **Dado** o mundo com o executor de teste
- **Quando** conjura um `lancar`, medita, bate com o cajado ou leva dano
- **Então** a animação passa a `conjurar`, `meditar`, `cajado` ou `dano`, e volta depois do tempo da ação

### ART-020 — Bordas pela vizinhança

- **Então** uma pedra isolada no meio da sala tem número 0; uma pedra cercada, 15; uma pedra no chão com ar em cima, 14 (direita, embaixo e esquerda); a pedra no canto da sala conta a borda de fora como pedra

### ART-021 — A sala monta as formas e as colisões

- **Dado** uma sala com chão, uma coluna, uma plataforma e espinhos
- **Então** cada pedra está na coordenada do seu número no atlas; a plataforma em (0, 4); os espinhos em (1, 4)
- **E** o mago fica de pé sobre qualquer forma de pedra, atravessa a plataforma por baixo e para em cima dela

### ART-022 — Tiles do Victor no lugar do provisório

- **Dado** um `cenario/tiles.png` na pasta de arte de teste
- **Então** a sala usa essa imagem; sem ele, usa a provisória

### ART-030 — Fundo em três camadas

- **Dado** o mundo
- **Então** há três camadas de paralaxe atrás da sala, com fatores 0,2, 0,45 e 0,7, repetindo a cada 640 px na horizontal, com as imagens provisórias
- **E** com um `cenario/fundo_2.png` na pasta de teste, a camada do meio usa a arte e as outras continuam provisórias

### ART-031 — Fora da sala é escuro (regressão)

- **Dado** uma sala menor que a tela
- **Então** os pontos fora da sala, dos quatro lados, ficam cobertos pela moldura escura, e o centro da sala não
- **E** trocando de sala, a moldura acompanha a sala nova

### ART-032 — Desenho preso aos pixels (regressão)

- **Então** as duas opções de encaixe na grade de pixels estão ligadas no projeto

### ART-040 — Os outros personagens usam a arte

- **Dado** a pasta de teste com `serpente/parada`, `elemental/andar_fogo`, `magia/projetil_gelo` e `magia/escudo_raio`
- **Então** a serpente, o elemental de fogo, o projétil de gelo e o escudo de raio mostram um sprite animado com essas animações, e o retângulo provisório do elemental some
- **E** sem a arte, o elemental mostra o retângulo da cor do elemento e a serpente o desenho de hoje

### ART-041 — Impacto do projétil

- **Dado** a pasta de teste com `magia/impacto_fogo`
- **Quando** um projétil de fogo acerta um boneco
- **Então** um sprite `impacto_fogo` aparece na sala, sem laço, e sai da cena quando termina
- **E** sem a arte, nenhum sprite de impacto aparece

### ART-042 — Aura de meditar

- **Dado** a pasta de teste com `magia/meditar`
- **Então** a aura do mago fica escondida parado, aparece com a animação `meditar` e some depois

### ART-043 — Inimigo morre com a animação

- **Dado** a pasta de teste com `elemental/andar_fogo` e `morrer_fogo`
- **Quando** o elemental de fogo é derrotado
- **Então** ele sai dos alvos na hora, o sprite toca `morrer_fogo` e continua visível, e ele sai da cena depois que a animação termina
- **E** sem `morrer_fogo`, o sprite some na hora, como hoje

### ART-044 — Enxame mergulha

- **Dado** a pasta de teste com `enxame/voar` e `mergulhar`
- **Então** o bicho toca `voar` rodando a casa e `mergulhar` enquanto mergulha

### ART-045 — Escudo do guardião

- **Dado** a pasta de teste com `guardiao/escudo_fogo`
- **Então** com o escudo de fogo o guardião mostra o sprite `escudo_fogo` e não desenha o círculo; na brecha, o sprite fica escondido

### ART-046 — Cristal apagado e aceso

- **Dado** a pasta de teste com `objetos/cristal_apagado` e `cristal_aceso_gelo`
- **Então** o cristal apagado mostra `cristal_apagado` e esconde o retângulo
- **Quando** um feitiço de gelo o acende
- **Então** ele mostra `cristal_aceso_gelo`

### ART-047 — Porta, baú e tocha

- **Dado** a pasta de teste com `objetos/porta`, `bau_fechado` e `tocha`
- **Então** cada célula da porta mostra a arte, o baú fechado mostra `bau_fechado`, aberto fica escurecido (sem `bau_abrindo`), e a tocha toca `tocha` em laço, sem ser alvo
- **E** sem a arte, a porta é o retângulo de hoje e a tocha, a chama provisória

### ART-050 — A fumaça confere o contrato

- **Dado** o contrato com erro
- **Então** a fumaça acusa "arte: ..."

## Exemplos

```json
"mago": {
  "quadro": 48,
  "animacoes": {
    "parado": {"fps": 6, "laco": true},
    "cair": {"fps": 8, "laco": true, "reserva": "pular"}
  }
},
"chefe": {
  "quadro": 96,
  "animacoes": {
    "pilar": {"quadro": [16, 64], "fps": 12, "laco": false}
  }
}
```

Números de pedra (regra 12), vistos de uma parede de 3×3 cercada de ar:

```
 6 14 12
 7 15 13
 3 11  9
```

## Perguntas em aberto

- [ ] Fundo nas salas mais altas que a tela (Sprint 18): hoje a camada não se repete na vertical; embaixo aparece a cor sólida.
- [ ] Bordas com cantos internos (o conjunto de 47 tiles) se o pacote ou a IA entregarem: só se a arte pedir.
- [ ] Velocidade de cada animação (fps): ajustar quando a arte chegar; está no `arte.json`.
