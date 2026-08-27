#!/usr/bin/env python3
"""Pre-dispatch no-write stage gate for the sole K146 V5b recovery."""

from __future__ import annotations
import hashlib
import os
from pathlib import Path

HERE = Path(__file__).resolve().parent
POOL = Path("/tmp/codex-triple-root-20260823c.vx654S/pool")
ANCHOR = POOL / "logs/inspect_k146_context_lifecycle_xh_v1.log"
OUTDIR = Path("/tmp/codex-triple-root-20260823c.vx654S/cf300_sector12_recapture_from_v4_xh_v5b_recovered_k146")

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main() -> None:
    checks = 0
    assert sha(ANCHOR) == "3d3e997de61b4e093d4605297c5e52f4d13b9e6d19c236a4b4a12d2330eda90c"
    checks += 1
    later_k146 = []
    anchor_time = ANCHOR.stat().st_mtime_ns
    for log in (POOL / "logs").iterdir():
        if not log.is_file() or log.stat().st_mtime_ns <= anchor_time:
            continue
        try:
            payload = log.read_text(errors="replace")
        except OSError:
            continue
        if "kernel 146 start" in payload:
            later_k146.append(log)
    allowed_reservation = (
        POOL / "logs/reserve_kernel146_for_k24_exact_qeps_xh_v1.log"
    )
    unexpected = [str(path) for path in later_k146
                  if path != allowed_reservation]
    assert unexpected == [], unexpected
    if allowed_reservation in later_k146:
        payload = allowed_reservation.read_text(errors="replace")
        status = POOL / "done/reserve_kernel146_for_k24_exact_qeps_xh_v1.status"
        assert status.is_file(), (
            "K146 exact-qeps no-mutation reservation is still active; "
            "wait for its natural release and do not stop it"
        )
        assert '"Status" -> "OK"' in status.read_text(errors="replace")
        assert "state_stable=" in payload and "source_stable=" in payload
        assert "status=released" in payload
    checks += 1
    assert not os.path.lexists(OUTDIR)
    checks += 1
    for name in (
        "run_cf300_sector12_recapture_from_v4_xh_v5b_recovered_k146.wls",
        "run_cf300_sector12_recapture_from_v4_xh_v5b_recovered_k146_body.wls",
        "preflight_cf300_sector12_recapture_v5b_recovered_k146_global_state.wls",
        "probe_cf300_sector12_recapture_v5b_recovered_k146_k146.wls",
        "inspect_cf300_sector12_recapture_v5b_recovered_k146_paths.py",
        "cf300_sector12_recapture_v5b_recovered_k146_path_seal.json",
    ):
        assert (HERE / name).is_file(), name
        checks += 1
    print(f"PASS {checks}/{checks}; no K146 mission after pinned lifecycle census; output absent")

if __name__ == "__main__":
    main()
