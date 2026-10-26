# SAV-progresso — Salvar e carregar o progresso

- **Status:** Implementada
- **Sprint:** 13
- **Relacionadas:** GRI-grimorio (arquivo do grimório), PRO-xp, PRO-niveis, PUZ-validacao, COM-chefe, NAR-serpente, NAR-dicas, MUN-salas

## Contexto

Fechar e reabrir o jogo precisa manter todo o progresso. A Alpha tem um perfil só, mas o save já fica numa pasta por perfil, porque laboratórios de escola dividem computadores (GDD).

## Fora do escopo

Tela de perfis e de "novo jogo / continuar". Vários slots de save. Nuvem. Salvar a posição exata do mago dentro da sala (ele volta pela entrada).

## Regras

1. **Perfil:** a pasta é `user://perfis/<perfil>/`; na Alpha, o perfil é `padrao`. Nela ficam `grimorio.json` (formato de GRI-grimorio, com os slots e o passivo) e `save.json`.
2. **Migração do grimório:** se existe `user://grimorio.json` (de antes da Sprint 13) e o perfil não tem grimório, ele é **copiado** para o perfil. O arquivo antigo fica onde está.
3. **Conteúdo do `save.json`:**
   ```json
   {"versao": 1, "sala": "sala_p03", "entrada": "A",
    "mago": {"xp": 85, "mana": 4.0},
    "puzzles": {"p01_meditar": {"estrelas": 0}},
    "chefes": ["sala_c04"], "licoes": ["ensino_sequencia"], "dicas": {"p02_runas": 2}}
   ```
   O nível e a mana máxima não são guardados: vêm da XP (PRO-niveis). A vida volta cheia ao carregar.
4. **Quando grava:** ao entrar numa sala, ao resolver um puzzle, ao derrotar o chefe, ao subir de nível, ao terminar um diálogo e ao fechar o jogo. A gravação é atômica (escreve `.tmp` e renomeia), como o grimório.
5. **Quando carrega:** ao abrir o jogo pela cena principal (`main.tscn`), antes de montar a primeira sala. Com save, o mago começa na sala e na entrada salvas; sem save, no começo (`sala_01`, entrada `A`).
6. **Save com problema não quebra o jogo:**
   - arquivo ilegível ou que não é um objeto → copia para `save.json.bak`, começa do zero e avisa no registro;
   - `versao` maior que a do jogo → mesma coisa, com aviso de versão;
   - `versao` ausente ou menor → passa pelas migrações em ordem (hoje não há versão anterior à 1, então é tratado como ilegível);
   - campo ausente ou do tipo errado → usa o valor padrão daquele campo e mantém o resto;
   - sala que não existe → começa na `sala_01`; entrada que não existe na sala → a primeira entrada (MUN-salas).
7. **Testes não tocam no save do jogador:** o `World` só salva e carrega com `save_path` definido. Quem define é a cena principal; os testes que precisam do save usam `user://tests/…`.

## Critérios de aceite

### SAV-001 — Ida e volta preserva tudo

- **Dado** um mundo com XP 85, mana 4, P1 resolvido com 0 estrelas e P4 com 3, chefe da `sala_c04` derrotado, lições `ensino_sequencia` e `ensino_loops` vistas, 2 dicas usadas no P2, na `sala_p03` pela entrada `A`
- **Quando** salva e um mundo novo carrega o mesmo arquivo
- **Então** está na `sala_p03`, com XP 85, nível 3, mana 4, os mesmos puzzles e estrelas, o chefe derrotado, as lições e as dicas

### SAV-002 — Grava nos momentos certos (cena)

- **Quando** o mago entra numa sala, resolve um puzzle, sobe de nível ou termina um diálogo
- **Então** o `save.json` reflete a mudança logo depois

### SAV-003 — Save ilegível

- **Dado** um `save.json` com texto que não é JSON
- **Então** o mundo começa do zero, existe `save.json.bak` com o conteúdo antigo e o registro mostra o aviso

### SAV-004 — Versão nova demais

- **Dado** um save com `versao` 99
- **Então** o mundo começa do zero, guarda o `.bak` e avisa a versão

### SAV-005 — Campos ruins usam o padrão

- **Dado** um save versão 1 com `mago.xp` igual a `"muito"`, `chefes` igual a `5` e `sala` igual a `sala_que_nao_existe`
- **Então** o mundo carrega com XP 0, nenhum chefe derrotado, na `sala_01`, e as outras partes do save (ex.: puzzles) valem

### SAV-006 — Perfil e migração do grimório (cena)

- **Dado** a raiz de perfis de teste vazia e um `grimorio.json` antigo na raiz de teste
- **Quando** a cena principal abre
- **Então** o `World` usa `<raiz>/padrao/grimorio.json` e `<raiz>/padrao/save.json`, e o grimório antigo foi copiado para o perfil

### SAV-007 — Sem `save_path`, nada é salvo

- **Dado** um `World` sem `save_path` (como nos testes antigos)
- **Quando** troca de sala
- **Então** nenhum arquivo de save é criado

## Perguntas em aberto

- [ ] Vale um botão "Novo jogo" que apaga o save do perfil? (depois da Alpha, com a tela de perfis)
