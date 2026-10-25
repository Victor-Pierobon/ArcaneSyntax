# Sprint 12 — Progressão e sistemas da serpente

- **Status:** Planejada
- **Fase do plano:** 7 · **Marco:** M3 · **Estimativa:** 12–18 h
- **Depende de:** Sprints 9 e 11 (XP vem de puzzles e monstros)

## Objetivo

O jogador ganha XP e níveis, e o jogo tem um sistema de diálogo e páginas de referência prontos para receber conteúdo.

## Tarefas

- [ ] XP por monstros e puzzles, bônus por solução econômica (3–4 h)
- [ ] Níveis até o 5, cada um aumentando a mana máxima (2–3 h)
- [ ] Sistema de diálogo, com textos em arquivo (4–6 h)
- [ ] Páginas de referência no grimório (3–5 h)

## Specs a escrever

`docs/specs/progressao/PRO-xp.md`, `PRO-niveis.md`, `docs/specs/narrativa/NAR-dialogo.md`, `docs/specs/grimorio/GRI-referencia.md`.

## Testes

- TDD: XP e níveis (curva, teto no 5, bônus por economia), leitor de diálogos (avança, ramifica, fala ausente gera erro claro).

## Notas

- Falas e páginas usam chaves de `textos.csv` (tradução para o inglês depois da Alpha).
- "Solução econômica" usa o `custo_mana` devolvido pelo executor (Sprint 2).

## Pronto quando

Derrotar um inimigo e resolver um puzzle dão XP, o nível sobe e aumenta a mana máxima, e um diálogo de teste roda.
