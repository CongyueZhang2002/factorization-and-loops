"""Shared POSIX execution of Wolfram drivers; no physics or project defaults."""
from pathlib import Path
import json
import os
import signal
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
ENTRY_MARKER = "FEYNFACET DRIVER ENTERED"
ERROR_MARKERS = ("::sntx", "Syntax::", "Get::noopen", "$Aborted")


def atomic_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f"{path.name}.partial-{os.getpid()}")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    temporary.replace(path)


def select_cpus(requested=None):
    available = sorted(os.sched_getaffinity(0))
    cpus = available[:8] if requested is None else list(requested)
    if (not cpus or any(type(cpu) is not int for cpu in cpus)
            or len(set(cpus)) != len(cpus) or len(cpus) > 8
            or not set(cpus).issubset(available)):
        raise ValueError("CpuSet must name one to eight distinct available CPUs.")
    return cpus


def completed(code, output, prefix):
    return (code == 0 and ENTRY_MARKER in output.splitlines()
            and any(line.startswith(prefix) for line in output.splitlines())
            and not any(marker in output for marker in ERROR_MARKERS))


def startup_failure(code, output):
    lines = [line.strip() for line in output.splitlines() if line.strip()]
    password = lines == ["No valid password found.", "Connection closed by WolframKernel."]
    activation = (len(lines) == 3 and lines[:2] == [
        "Your Wolfram product is not activated or is experiencing a license-related problem.",
        "Please activate the product at the following WolframKernel location:"]
        and lines[2].endswith("/WolframKernel"))
    return code == 255 and (password or activation)


def _group_exists(pid):
    try:
        os.killpg(pid, 0)
        return True
    except ProcessLookupError:
        return False


def stop_process_group(process, grace=5):
    """Reap the launcher and stop its owned group, even if the launcher exited."""
    if _group_exists(process.pid):
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        deadline = time.monotonic() + grace
        while _group_exists(process.pid) and time.monotonic() < deadline:
            process.poll()  # Reap an exited direct child.
            time.sleep(0.05)
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    process.wait()


def run_wolfram(script, arguments, *, logfile, completion, cpus=None,
                timeout=None, on_start=None, cancel=None):
    """Each attempt has fresh output; retry only recognized pre-entry license failures."""
    script = Path(script).resolve()
    if not script.is_file():
        raise FileNotFoundError(script)
    cpus = select_cpus(cpus)
    if timeout is not None and timeout <= 0:
        raise ValueError("TimeoutSeconds must be positive.")
    logfile = Path(logfile)
    logfile.parent.mkdir(parents=True, exist_ok=True)
    command = ["taskset", "-c", ",".join(map(str, cpus)), "wolframscript",
               "-file", str(script), *map(str, arguments)]
    started = time.monotonic()
    code, output, attempt = 130, "", 0
    with logfile.open("wb") as log:
        for attempt in range(5):
            if cancel is not None and cancel.is_set():
                break
            offset = log.tell()
            process = subprocess.Popen(command, cwd=ROOT, stdout=log,
                stderr=subprocess.STDOUT, start_new_session=True,
                env={**os.environ, "FACET_CPU_COUNT": str(len(cpus))})
            try:
                if on_start is not None:
                    on_start(process)
                while True:
                    if cancel is not None and cancel.is_set():
                        raise InterruptedError
                    remaining = None if timeout is None else timeout - (time.monotonic() - started)
                    if remaining is not None and remaining <= 0:
                        raise subprocess.TimeoutExpired(command, timeout)
                    try:
                        code = process.wait(timeout=min(0.2, remaining) if remaining else 0.2)
                        break
                    except subprocess.TimeoutExpired:
                        continue
            except (KeyboardInterrupt, InterruptedError):
                code = 130
            except subprocess.TimeoutExpired:
                code = 124
            finally:
                stop_process_group(process)
            log.flush()
            output = logfile.read_bytes()[offset:].decode(errors="replace")
            if code in (124, 130):
                log.write(f"\nWOLFRAM DRIVER STOPPED {code}\n".encode())
            if not startup_failure(code, output) or attempt == 4:
                break
            delay = 2 ** (attempt + 1)
            try:
                if cancel is None:
                    time.sleep(delay)
                elif cancel.wait(delay):
                    code = 130
                    break
            except KeyboardInterrupt:
                code = 130
                break
    return {"ReturnCode": code, "Passed": completed(code, output, completion),
            "Seconds": time.monotonic() - started, "StartupRetries": attempt,
            "Log": str(logfile)}
