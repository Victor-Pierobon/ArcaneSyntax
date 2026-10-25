# MAG-efeitos — Efeitos visuais e sons provisórios

- **Status:** Implementada (provisória)
- **Sprint:** 7
- **Relacionadas:** MAG-acoes, MAG-formas, MAG-elementos; Sprint de arte (depois da Alpha jogável)

## Contexto

Os feitiços precisam de resposta visual e sonora para o playtest do núcleo ser legível. Tudo aqui é provisório e gerado por código: nenhum arquivo de áudio ou imagem novo, para não virar retrabalho quando a arte e a trilha definitivas chegarem.

## Regras

1. **Sons** são gerados por código (`Sfx`), um por evento: `conjurar`, `acerto`, `fraco`, `escudo`, `cajado`, `mana`. Cada elemento muda o timbre do `conjurar` (fogo grave, gelo agudo, raio áspero).
2. **Efeitos:** partículas na meditação (aura subindo), brilho ao absorver mana, explosão de partículas na cor do elemento quando um projétil acerta.
3. Um evento de som desconhecido é ignorado com aviso.
4. O volume dos efeitos fica no barramento `SFX`, para ajustar depois (menu de opções, Sprint 14).

## Critérios de aceite

### MAG-060 — Sons existem para cada evento

- **Então** `Sfx` tem um som para cada evento da regra 1, e um evento desconhecido devolve `false` sem travar

### MAG-061 — Os eventos tocam

- **Quando** o mago conjura um projétil que acerta um boneco fraco ao elemento
- **Então** tocam `conjurar` e `fraco`

### MAG-062 — Checklist manual

- [ ] A aura da meditação aparece e some
- [ ] O brilho do absorver aparece
- [ ] A explosão do acerto tem a cor do elemento
- [ ] Os sons não incomodam em repetição (o passivo absorve a cada segundo)
