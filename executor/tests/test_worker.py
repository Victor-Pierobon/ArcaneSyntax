"""Spec: docs/specs/executor/EXE-protocolo.md (EXE-005, EXE-006), com o worker como processo real."""
import json
import subprocess
import sys
from pathlib import Path

from helpers import requisicao

RUN_WORKER = Path(__file__).resolve().parents[1] / "run_worker.py"


def _worker():
    return subprocess.Popen(
        [sys.executable, "-I", "-S", "-u", str(RUN_WORKER)],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
    )


def _send(proc, line):
    proc.stdin.write(line + "\n")
    proc.stdin.flush()
    return proc.stdout.readline()


def test_EXE_005_worker_persistente():
    proc = _worker()
    try:
        r1 = json.loads(_send(proc, json.dumps(requisicao("meditar()", id=1))))
        r2 = json.loads(_send(proc, "lixo"))
        r3 = json.loads(_send(proc, json.dumps(requisicao("levitar(2)", id=3))))
        assert (r1["id"], r1["ok"]) == (1, True)
        assert r2["erro"]["tipo"] == "RequisicaoInvalida"
        assert (r3["id"], r3["ok"]) == (3, True)
        assert proc.poll() is None
    finally:
        proc.stdin.close()
        proc.wait(timeout=5)
    assert proc.returncode == 0


def test_EXE_006_print_nao_corrompe_o_protocolo():
    proc = _worker()
    try:
        codigo = "print('oi')\nprint('ação ✨')"
        r = json.loads(_send(proc, json.dumps(requisicao(codigo))))
        assert [s["texto"] for s in r["saidas"]] == ["oi", "ação ✨"]
        second = json.loads(_send(proc, json.dumps(requisicao("meditar()", id=2))))
        assert second["id"] == 2
    finally:
        proc.stdin.close()
        proc.wait(timeout=5)


def test_EXE_057_memoria_limitada():
    proc = _worker()
    try:
        r = json.loads(_send(proc, json.dumps(requisicao('x = "a" * (10 ** 9)'))))
        assert r["erro"]["tipo"] == "MemoryError"
        seguinte = json.loads(_send(proc, json.dumps(requisicao("meditar()", id=2))))
        assert seguinte["ok"] is True
    finally:
        proc.stdin.close()
        proc.wait(timeout=5)
