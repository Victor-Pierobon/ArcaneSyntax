# Gerador de sprites (PixelLab)

Gera os sprites do jogo pela API do PixelLab, um por vez, na ordem de importância, e entrega cada um no formato do contrato (`game/assets/<pasta>/<animação>.png`). Spec: `docs/specs/arte/ART-gerador.md`. O estilo segue `docs/arte/ArcaneSyntax_Guia_de_Estilo_Visual.md`: paleta de 27 cores, contorno escuro, cada escola de magia com a própria rampa de cores.

## Uma vez só

1. Instale o Pillow: `py -3 -m pip install --user pillow`
2. Guarde a chave do PixelLab (pegue em pixellab.ai/account) **fora do projeto**, numa variável de ambiente. No PowerShell:
   ```
   setx PIXELLAB_API_TOKEN "sua-chave"
   ```
   Feche e abra o terminal. Não cole a chave em arquivo do projeto nem no chat.
3. Confira: `py -3 scripts/sprites/gerar.py saldo`

## Todo mês (ou quando quiser)

Na raiz do repositório:

```
py -3 scripts/sprites/gerar.py status            # o que já foi, o que falta, o próximo
py -3 scripts/sprites/gerar.py rodar --simular   # o que vai rodar, sem gastar nada
py -3 scripts/sprites/gerar.py rodar             # gera até a cota acabar ou uma aprovação
```

- **Aprovação:** as bases do mago e da serpente param a fila. Olhe a prévia ampliada em `art/ia/previa/` e rode `aprovar mago_base` (gostou) ou `refazer mago_base` (gera de novo). Todas as animações saem dessa base, então vale caprichar aqui.
- **Não gostou de uma animação?** `refazer mago/andar`. O arquivo sai do jogo (o provisório volta) e o item volta para a fila.
- **Cota:** antes de cada item a ferramenta consulta o saldo. Se não der, ela para e você continua no mês seguinte. Ela só usa as gerações da assinatura, nunca crédito em dólar.
- **Arte sua:** se já existir um arquivo seu em `game/assets/`, a ferramenta não sobrescreve (o item fica como `pulado`).
- Depois de gerar, abra o Godot (ou rode `--import`) para a arte nova aparecer.

## Ordem (cerca de 38 gerações; a cota é de 40 por mês)

1. Mago: base e 9 animações (parado, andar, pular, cair, conjurar, esquivar, cajado, meditar, dano)
2. Projéteis: fogo, gelo e raio, cada um com forma própria (o guia pede que a magia não se distinga só pela cor)
3. Faísca e escudo do mago (gelo e raio saem do fogo por troca de rampa, sem custo)
4. Serpente: parada e falando
5. Inimigos: elemental (3 elementos), enxame, guardião e o escudo dele
6. Objetos: cristal apagado e aceso, tocha, porta, baú

Ficaram de fora desta leva (o jogo ainda não usa): morte do mago, retrato da serpente, placa, cadeado, runas, chefe (Sprint 17), cenário (pacote pronto) e interface.

**Segunda leva (segunda chave):** mortes, mergulho do enxame, impacto, aura de meditar e, depois delas, o **chefe**: base (para aprovar), `parado`, `golpe`, `orbe` e `mover` nas três fases (gelo e planta saem do fogo por troca de rampa), `troca`, `morrer`, o orbe voando, a marca de aviso e o pilar. O chefe custa ~19 gerações: as animações de 96 px saem por ~2 cada (`custo` no item). Os objetos que faltam (baú abrindo, placa, cadeado, fonte) vêm depois.

Campos especiais de um item: `gerar` [largura, altura] desenha maior e recorta o meio (o pilar tem 16×64, e a API só aceita lado menor que 32 em imagem quadrada); `inverter: true` põe a animação de trás para frente (o pilar é pedido afundando e vira um pilar subindo); `opaco: true` aceita imagem que preenche o quadro (tile); `alinhar` (`pes`, `centro` ou `nenhum`).

Para mudar a ordem ou um prompt, edite `fila.json`. O teste confere se a fila continua válida: `py -3 -m pytest scripts/sprites/tests`.

## Arquivos

| Onde | O quê |
| --- | --- |
| `scripts/sprites/fila.json` | fila, prompts, paleta e rampas das escolas |
| `art/ia/estado.json` | progresso (o que está pronto, gasto de cada item) |
| `art/ia/brutos/` | como veio da API |
| `art/ia/prontos/` | já limpo (paleta, alfa, alinhamento), também as bases |
| `art/ia/previa/` | ampliado 8×, para revisar |
| `game/assets/paleta.png` | a paleta do guia; o teste de arte do jogo acusa cor fora dela (`gerar.py paleta` grava de novo) |

## Antes de publicar

A Steam pede para declarar conteúdo gerado por IA (`docs/arte/guia-de-arte.md`, seção 8). Confira também nos termos do PixelLab se o uso comercial está liberado no seu plano.
