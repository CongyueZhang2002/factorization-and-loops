"""Hold a POSIX file lock until the owning Wolfram process releases stdin.

The OS releases the lock on normal exit, cancellation, or process death.
Different final-channel jobs can safely update one source-owned result file.
"""
import fcntl
import sys
from pathlib import Path

path = Path(sys.argv[1])
path.parent.mkdir(parents=True, exist_ok=True)
with path.open("a") as stream:
    fcntl.flock(stream, fcntl.LOCK_EX)
    print("LOCKED", flush=True)
    sys.stdin.readline()
