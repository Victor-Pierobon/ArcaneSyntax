"""Worker persistente: uma requisição JSON por linha no stdin, uma resposta por linha no stdout."""

import sys

from .protocol import handle_line

LIMITE_MEMORIA_MB = 256


def _limitar_memoria_windows(limite_bytes):
    """Põe o próprio processo num Job Object com teto de memória."""
    import ctypes
    from ctypes import wintypes

    class IoCounters(ctypes.Structure):
        _fields_ = [
            (nome, ctypes.c_ulonglong)
            for nome in ("Read", "Write", "Other", "ReadBytes", "WriteBytes", "OtherBytes")
        ]

    class BasicLimit(ctypes.Structure):
        _fields_ = [
            ("PerProcessUserTimeLimit", ctypes.c_int64),
            ("PerJobUserTimeLimit", ctypes.c_int64),
            ("LimitFlags", wintypes.DWORD),
            ("MinimumWorkingSetSize", ctypes.c_size_t),
            ("MaximumWorkingSetSize", ctypes.c_size_t),
            ("ActiveProcessLimit", wintypes.DWORD),
            ("Affinity", ctypes.c_size_t),
            ("PriorityClass", wintypes.DWORD),
            ("SchedulingClass", wintypes.DWORD),
        ]

    class ExtendedLimit(ctypes.Structure):
        _fields_ = [
            ("BasicLimitInformation", BasicLimit),
            ("IoInfo", IoCounters),
            ("ProcessMemoryLimit", ctypes.c_size_t),
            ("JobMemoryLimit", ctypes.c_size_t),
            ("PeakProcessMemoryUsed", ctypes.c_size_t),
            ("PeakJobMemoryUsed", ctypes.c_size_t),
        ]

    job_object_limit_process_memory = 0x100
    job_object_extended_limit_information = 9

    kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
    kernel32.CreateJobObjectW.restype = wintypes.HANDLE
    kernel32.CreateJobObjectW.argtypes = (ctypes.c_void_p, wintypes.LPCWSTR)
    kernel32.SetInformationJobObject.argtypes = (wintypes.HANDLE, ctypes.c_int, ctypes.c_void_p, wintypes.DWORD)
    kernel32.GetCurrentProcess.restype = wintypes.HANDLE
    kernel32.AssignProcessToJobObject.argtypes = (wintypes.HANDLE, wintypes.HANDLE)

    job = kernel32.CreateJobObjectW(None, None)
    info = ExtendedLimit()
    info.BasicLimitInformation.LimitFlags = job_object_limit_process_memory
    info.ProcessMemoryLimit = limite_bytes
    ok = kernel32.SetInformationJobObject(
        job, job_object_extended_limit_information, ctypes.byref(info), ctypes.sizeof(info)
    )
    return bool(ok and kernel32.AssignProcessToJobObject(job, kernel32.GetCurrentProcess()))


def _limitar_memoria_unix(limite_bytes):
    import resource

    resource.setrlimit(resource.RLIMIT_AS, (limite_bytes, limite_bytes))
    return True


def limitar_memoria(megabytes=LIMITE_MEMORIA_MB):
    """Teto de memória do worker (EXE-057). Se não der, segue sem teto e avisa no stderr."""
    limite = megabytes * 1024 * 1024
    try:
        ok = _limitar_memoria_windows(limite) if sys.platform == "win32" else _limitar_memoria_unix(limite)
    except (OSError, ValueError, ImportError) as e:
        ok = False
        sys.stderr.write(f"aviso: não foi possível limitar a memória do executor: {e}\n")
    if not ok:
        sys.stderr.write("aviso: executor rodando sem teto de memória\n")
    return ok


def main():
    sys.stdin.reconfigure(encoding="utf-8")
    limitar_memoria()
    saida = sys.stdout
    for line in sys.stdin:
        if not line.strip():
            continue
        saida.write(handle_line(line) + "\n")
        saida.flush()


if __name__ == "__main__":
    main()
