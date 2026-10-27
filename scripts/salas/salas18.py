"""Gera as salas refeitas nas Sprints 18 e 19 (MUN-salas, regras 9 e 10; MUN-plataformas): todas menos a
arena do chefe (`sala_c04`, desenhada na Sprint 17). Tocha é `!` no layout desde a Sprint 19.

Uso (na raiz): py -3 scripts/salas/salas18.py game/content/rooms [sala ...]
Depois de gerar: rodar test_rooms_walk.gd, test_area_map.gd, as aceitações dos puzzles e dos segredos
e a Alpha inteira (MUN-085). Mexeu à mão numa sala gerada? Passe a mudança para cá, ou ela some na
próxima geração.
Cada sala é desenhada por operações num quadro de pedra; `exits`, `puzzle` e `atalho_entrada`
vêm da cena atual (não mudam), `targets` vem daqui.
"""
import json
import re
import sys
from pathlib import Path


class Grid:
    def __init__(self, width, height):
        self.w, self.h = width, height
        self.g = [["#"] * width for _ in range(height)]

    def fill(self, x0, y0, x1, y1, c):
        """Retângulo inclusivo."""
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.g[y][x] = c

    def hline(self, x0, x1, y, c):
        self.fill(x0, y, x1, y, c)

    def vline(self, x, y0, y1, c):
        self.fill(x, y0, x, y1, c)

    def put(self, x, y, c):
        self.g[y][x] = c

    def text(self):
        return "\n".join("".join(row) for row in self.g)


def hollow(width, height, floor_rows=2):
    """Pedra em volta, vazio dentro, chão com `floor_rows` linhas no fundo."""
    g = Grid(width, height)
    g.fill(1, 1, width - 2, height - 1 - floor_rows, ".")
    return g


# ---------------------------------------------------------------- sala_01 (60x23)
def sala_01():
    g = hollow(60, 23)
    g.vline(4, 1, 20, "%")
    g.vline(57, 1, 20, "|")
    for y in (18, 19, 20):
        g.put(0, y, "d")
        g.put(59, y, "b")
    g.hline(10, 12, 19, "=")
    g.hline(24, 26, 20, "^")
    # Escada de plataformas até o alto e a prateleira do segredo (vão de 6 na mesma altura).
    g.hline(30, 33, 19, "=")
    g.hline(34, 37, 17, "=")
    g.hline(30, 33, 15, "=")
    g.hline(34, 37, 13, "=")
    g.hline(30, 32, 11, "=")
    g.hline(18, 23, 11, "#")
    marks = {"C": (2, 20), "A": (6, 20), "4": (8, 20), "1": (11, 20), "2": (14, 20), "*": (20, 20),
             "3": (40, 20), "5": (50, 20), "B": (56, 20), "6": (17, 17), "7": (45, 17), "8": (20, 10)}
    targets = {"1": "fogo", "2": "planta", "3": "raio", "4": "serpente:ensino_sequencia", "5": "cristal",
               "6": "tocha", "7": "tocha", "8": "segredo"}
    return g, marks, targets


# ---------------------------------------------------------------- sala_02 (40x23)
def sala_02():
    g = hollow(40, 23)
    for y in (6, 7, 8):
        g.put(39, y, "c")
    for y in (18, 19, 20):
        g.put(0, y, "a")
    g.hline(24, 38, 9, "#")
    g.hline(8, 11, 11, "#")
    g.hline(18, 21, 11, "=")
    g.hline(23, 26, 13, "-")
    g.hline(18, 21, 15, "=")
    g.hline(13, 16, 17, "-")
    g.hline(8, 11, 19, "=")
    marks = {"A": (3, 20), "B": (36, 8), "1": (31, 8), "8": (9, 10), "6": (16, 20), "7": (26, 8)}
    targets = {"1": "inimigo:elemental:fogo", "8": "segredo", "6": "tocha", "7": "tocha"}
    return g, marks, targets


# ---------------------------------------------------------------- sala_03 (40x23)
def sala_03():
    g = hollow(40, 23)
    for y in (6, 7, 8):
        g.put(0, y, "a")
    for y in (19, 20):
        g.put(39, y, "b")
    g.hline(1, 10, 9, "#")
    g.hline(17, 20, 9, "#")
    g.hline(12, 15, 11, "=")
    g.hline(17, 20, 13, "=")
    g.hline(12, 15, 15, "=")
    g.hline(17, 20, 17, "=")
    g.hline(12, 15, 19, "=")
    # Poço de espinhos atravessado pela plataforma que se move; degrau do lado de lá para voltar.
    g.hline(24, 33, 20, "^")
    g.hline(22, 24, 18, ">")
    g.put(35, 18, "+")
    g.hline(37, 38, 19, "=")
    marks = {"A": (3, 8), "8": (19, 8), "*": (6, 20), "B": (36, 20), "1": (28, 13), "6": (8, 20), "7": (30, 8)}
    targets = {"8": "segredo", "1": "inimigo:enxame:2", "6": "tocha", "7": "tocha"}
    return g, marks, targets


# ---------------------------------------------------------------- sala_p02 (40x23)
def sala_p02():
    g = hollow(40, 23)
    for y in (5, 6):
        g.put(0, y, "a")
    for y in (19, 20):
        g.put(39, y, "b")
    g.vline(31, 1, 20, "|")
    # Entrada no alto, escada para o chão do puzzle (duas que caem no meio).
    g.hline(1, 10, 7, "#")
    g.hline(12, 15, 9, "=")
    g.hline(8, 11, 11, "=")
    g.hline(12, 15, 13, "-")
    g.hline(8, 11, 15, "=")
    g.hline(12, 15, 17, "-")
    g.hline(8, 11, 19, "=")
    marks = {"A": (2, 6), "9": (5, 6), "6": (8, 6), "1": (5, 20), "2": (17, 20), "3": (23, 20), "7": (28, 20),
             "B": (36, 20), "5": (34, 20)}
    targets = {"9": "serpente:ensino_variaveis", "1": "runa:?", "2": "runa:?", "3": "runa:?", "7": "cadeado:soma",
               "6": "tocha", "5": "tocha"}
    return g, marks, targets


# ---------------------------------------------------------------- sala_p03 (40x23)
def sala_p03():
    g = hollow(40, 23)
    for y in (19, 20):
        g.put(0, y, "a")
        g.put(39, y, "b")
    g.vline(32, 1, 20, "|")
    # Bloco do elemental na chegada: o mago passa por cima, o elemental não desce.
    g.fill(5, 19, 11, 20, "#")
    # Segredo: plataforma que sobe até a altura da prateleira (vão de 6).
    g.hline(16, 17, 19, ">")
    g.put(16, 7, "+")
    g.hline(24, 30, 7, "#")
    marks = {"A": (2, 20), "1": (8, 18), "9": (14, 20), "6": (20, 20), "5": (29, 20), "8": (26, 6), "7": (29, 6),
             "B": (36, 20)}
    targets = {"9": "serpente:ensino_condicionais", "5": "cristal:mutavel", "1": "inimigo:elemental:gelo",
               "8": "segredo", "6": "tocha", "7": "tocha"}
    return g, marks, targets


# ---------------------------------------------------------------- sala_p04 (40x24)
def sala_p04():
    g = hollow(40, 24, floor_rows=3)
    for y in (5, 6):
        g.put(0, y, "a")
    for y in (19, 20):
        g.put(39, y, "b")
    g.vline(33, 1, 20, "|")
    # Vão de 12 sobre espinhos (a ponte).
    g.hline(14, 25, 21, "~")
    g.hline(14, 25, 22, "^")
    # Entrada no alto à esquerda e escada até o chão (uma que se move no meio).
    g.hline(1, 5, 7, "#")
    g.hline(7, 10, 9, "=")
    g.hline(2, 5, 11, "=")
    g.hline(2, 4, 13, ">")
    g.put(11, 13, "+")
    g.hline(2, 5, 15, "=")
    g.hline(7, 10, 17, "=")
    g.hline(2, 5, 19, "=")
    marks = {"A": (2, 6), "9": (11, 20), "*": (12, 20), "6": (8, 20), "7": (30, 20), "B": (36, 20)}
    targets = {"9": "serpente:ensino_loops", "6": "tocha", "7": "tocha"}
    return g, marks, targets


# ---------------------------------------------------------------- sala_p05 (40x24)
P05_OLD = """########################
#...............|......#
#...............|......#
#...............|......#
#...............|......#
#...............|......b
#.........3._...|...B..b
#..........#############
#..........#############
#..........#############
#..........#############
#.......2._#############
#........###############
#........###############
#........###############
#........###############
#........###############
#.....1._###############
#......#################
#......#################
a......#################
a.A.9..#################
########################
########################"""


def sala_p05():
    old = P05_OLD.split("\n")
    g = Grid(40, 24)
    for y, row in enumerate(old):
        for x, c in enumerate(row):
            g.put(x, y, c)
    # O corredor depois da porta vai até a parede da direita, com um vão de espinhos e uma que cai.
    g.fill(17, 1, 38, 6, ".")
    g.vline(16, 1, 6, "|")
    g.hline(25, 30, 7, ".")
    g.hline(25, 30, 8, "^")
    g.hline(27, 28, 7, "-")
    for y in (5, 6):
        g.put(39, y, "b")
    # As marcas do layout antigo (A, 9, 1, 2, 3) ficam no lugar; o B velho saiu com o corredor.
    targets = {"9": "serpente:ensino_funcoes", "1": "gravura:5", "2": "gravura:7", "3": "gravura:6",
               "6": "tocha", "7": "tocha"}
    return g, {"B": (36, 6), "6": (20, 6), "7": (33, 6)}, targets


# ---------------------------------------------------------------- sala_p06 (48x23)
P06_OLD = """################################################
#.........................................|....#
#.........................................|....#
#.........................................|....b
#...................................6._...|..B.b
#....................................###########
#....................................###########
#....................................###########
#....................................###########
#.................................4._###########
#..................................#############
#..................................#############
a..................................#############
a.A.91.2.3..7.*...........*....5...#############
################~~~~~~~~########################
################^^^^^^^^########################
################################################"""
P06_SHIFT = 6


def sala_p06():
    old = P06_OLD.split("\n")
    g = Grid(48, 17 + P06_SHIFT)
    g.fill(1, 1, 46, P06_SHIFT, ".")
    for y, row in enumerate(old[1:], start=1):
        for x, c in enumerate(row):
            g.put(x, y + P06_SHIFT, c)
    # A porta continua do chão ao teto.
    g.vline(42, 1, 4 + P06_SHIFT, "|")
    # Segredo no alto à esquerda: plataforma que sobe e um vão de 6 na mesma altura.
    g.hline(1, 3, 8, "#")
    g.hline(10, 11, 18, ">")
    g.put(10, 8, "+")
    # Tochas no layout (Sprint 19): os 9 dígitos já estão em uso.
    g.put(20, 19, "!")
    g.put(40, 10, "!")
    targets = {"9": "serpente:ensino_revisao", "1": "runa:?", "2": "runa:?", "3": "runa:?", "7": "cadeado:soma",
               "5": "cristal:mutavel:2", "4": "gravura:5", "6": "gravura:6", "8": "segredo"}
    return g, {"8": (2, 7)}, targets


# ---------------------------------------------------------------- sala_c01 (48x23, Sprint 19)
def sala_c01():
    g = hollow(48, 23)
    for y in (5, 6):
        g.put(0, y, "a")
    for y in (17, 18):
        g.put(47, y, "b")
    for y in (2, 3):
        g.put(47, y, "c")
    # Entrada no alto e escada até a borda sobre o fosso (duas que caem).
    g.hline(1, 9, 7, "#")
    g.hline(11, 14, 8, "=")
    g.hline(15, 18, 10, "-")
    g.hline(11, 14, 12, "=")
    g.hline(15, 18, 14, "-")
    g.hline(11, 14, 16, "=")
    g.fill(1, 18, 17, 20, "#")
    # Fosso dos elementais, 3 tiles abaixo da borda; um degrau para sair pela esquerda.
    g.hline(19, 20, 19, "=")
    # Do lado de lá: chão mais alto, grupo misto (elemental de planta e enxame) e a escada até o atalho.
    g.fill(35, 19, 46, 20, "#")
    for y, x0 in ((17, 36), (15, 41), (13, 36), (11, 41), (9, 36), (7, 40), (5, 36)):
        g.hline(x0, x0 + 3, y, "=")
    # A prateleira do atalho começa na coluna 42: com ela na 40, o último degrau ficava embaixo da quina
    # e o mago batia a cabeça (achado pelo MUN-111, Sprint 19).
    g.hline(42, 46, 4, "#")
    for x, y in ((8, 6), (26, 20), (43, 3)):
        g.put(x, y, "!")
    marks = {"A": (2, 6), "1": (23, 20), "2": (29, 20), "3": (40, 18), "4": (41, 9), "B": (44, 18), "C": (45, 3)}
    targets = {"1": "inimigo:elemental:fogo", "2": "inimigo:elemental:gelo", "3": "inimigo:elemental:planta",
               "4": "inimigo:enxame:2"}
    return g, marks, targets


# ---------------------------------------------------------------- sala_c02 (40x23, Sprint 19)
def sala_c02():
    g = hollow(40, 23)
    for y in (19, 20):
        g.put(0, y, "a")
        g.put(39, y, "b")
    # Elemental de gelo na chegada, poço de espinhos com a plataforma que se move, o enxame no salão.
    g.hline(13, 22, 20, "^")
    g.hline(10, 12, 19, ">")
    g.put(25, 19, "+")
    # O salão do enxame fica sem plataformas: elas param as faíscas (e o loop sobre `inimigos` errava).
    for x, y in ((3, 20), (28, 20), (37, 20)):
        g.put(x, y, "!")
    marks = {"A": (2, 20), "1": (6, 20), "4": (33, 16), "B": (36, 20)}
    targets = {"1": "inimigo:elemental:gelo", "4": "inimigo:enxame"}
    return g, marks, targets


# ---------------------------------------------------------------- sala_c03 (40x23, Sprint 19)
def sala_c03():
    g = hollow(40, 23)
    for y in (19, 20):
        g.put(0, y, "a")
        g.put(39, y, "b")
    # Caminho alto por cima do guardião (dá para evitar a luta e cair do outro lado).
    g.hline(8, 11, 19, "=")
    g.hline(12, 15, 17, "=")
    g.hline(16, 19, 15, "=")
    g.hline(20, 28, 14, "#")
    for x, y in ((10, 20), (22, 13), (37, 20)):
        g.put(x, y, "!")
    # A serpente que ensina o feixe, antes do chefe (MAG-feixe, regra 8; Sprint 21).
    marks = {"A": (2, 20), "2": (5, 20), "9": (8, 20), "1": (24, 20), "4": (34, 20), "3": (31, 11), "B": (36, 20)}
    targets = {"1": "inimigo:guardiao", "2": "fonte", "3": "inimigo:enxame:2", "4": "inimigo:elemental:planta",
               "9": "serpente:ensino_feixe"}
    return g, marks, targets


# ---------------------------------------------------------------- sala_fim (40x22, Sprint 19)
def sala_fim():
    g = hollow(40, 22)
    for y in (18, 19):
        g.put(0, y, "a")
    # Um estrado com a serpente no alto, à direita.
    g.fill(22, 18, 25, 19, "#")
    g.fill(26, 17, 38, 19, "#")
    for x, y in ((10, 19), (27, 16), (37, 16)):
        g.put(x, y, "!")
    marks = {"A": (2, 19), "9": (32, 16)}
    targets = {"9": "serpente:fim_demo"}
    return g, marks, targets


ROOMS = {"sala_01": sala_01, "sala_02": sala_02, "sala_03": sala_03, "sala_p02": sala_p02, "sala_p03": sala_p03,
         "sala_p04": sala_p04, "sala_p05": sala_p05, "sala_p06": sala_p06, "sala_c01": sala_c01,
         "sala_c02": sala_c02, "sala_c03": sala_c03, "sala_fim": sala_fim}


def gd_dict(values):
    return "{" + ", ".join(f"{json.dumps(k)}: {json.dumps(v, ensure_ascii=False)}" for k, v in values.items()) + "}"


def write(rooms_dir, room_id):
    g, marks, targets = ROOMS[room_id]()
    for mark, at in marks.items():
        if at is not None:
            g.put(at[0], at[1], mark)
    # Desde a Sprint 19 a tocha é `!` no layout e não gasta dígito.
    for digit in [d for d, spec in targets.items() if spec == "tocha"]:
        if digit in marks:
            x, y = marks[digit]
            g.put(x, y, "!")
        del targets[digit]
    layout = g.text()
    path = rooms_dir / f"{room_id}.tscn"
    old = path.read_bytes().decode("utf-8")
    keep = []
    for key in ("exits", "atalho_entrada", "puzzle"):
        found = re.search(rf"^{key} = .*$", old, re.M)
        if found:
            keep.append(found.group(0))
    lines = [
        "[gd_scene load_steps=2 format=3]",
        "",
        '[ext_resource type="Script" path="res://src/nodes/world/room.gd" id="1_room"]',
        "",
        f'[node name="{room_id}" type="Node2D"]',
        'script = ExtResource("1_room")',
        f'room_id = "{room_id}"',
        f'layout = "{layout}"',
    ]
    lines += [k for k in keep if k.startswith("exits")]
    lines += [k for k in keep if k.startswith("atalho_entrada")]
    lines.append(f"targets = {gd_dict(targets)}")
    lines += [k for k in keep if k.startswith("puzzle")]
    path.write_bytes(("\n".join(lines) + "\n").encode("utf-8"))
    print(f"== {room_id} ({g.w}x{g.h})")
    print(layout)


if __name__ == "__main__":
    rooms_dir = Path(sys.argv[1])
    for room_id in sys.argv[2:] or ROOMS:
        write(rooms_dir, room_id)
