# Arte provisória

Gerada por `tools/gerar_provisorio.gd` (Sprint 16, spec ART-esteira). Para gerar de novo:

```
godot --headless --path game -s res://tools/gerar_provisorio.gd
godot --headless --path game --import
```

| Arquivo | O que é | Quem toma o lugar |
| --- | --- | --- |
| `tiles_bordas.png` (64×80) | 16 formas de pedra (linhas 0 a 3, pelo número da vizinhança), plataforma em (0, 4), espinhos em (1, 4) | `assets/cenario/tiles.png` |
| `fundo_1.png` a `fundo_3.png` (640×360) | Fundo em três camadas, da mais longe para a mais perto | `assets/cenario/fundo_N.png` |

O tileset (colisões) é montado por código em `Room.tileset_for`; não há `.tres` para editar. O contrato de toda a arte está em `docs/arte/identidade-visual.md` e `content/arte.json`.
