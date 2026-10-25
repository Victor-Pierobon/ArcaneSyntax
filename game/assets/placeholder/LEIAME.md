# Arte provisória

`tiles.png` (48×16) foi gerado por script na Sprint 3 só para o pipeline de tilemap funcionar:

| Coordenada no atlas | Tile | Colisão (em `tiles.tres`) |
| --- | --- | --- |
| (0, 0) | pedra | quadrado inteiro |
| (1, 0) | plataforma | faixa de 4 px no topo, atravessável por baixo |
| (2, 0) | espinhos | nenhuma (o dano vem de uma área criada pela `Room`) |

Para trocar pela arte definitiva, basta manter essas três coordenadas (ou ajustar `Room.ATLAS_*` em `src/nodes/world/room.gd`).
