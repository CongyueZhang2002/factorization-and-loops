#!/usr/bin/env python3
"""Export cached CF259 postfix programs plus the exact CUDA reference output."""

from __future__ import annotations

import argparse
from array import array
import json
from pathlib import Path
import pickle
import struct
import sys
import time

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from deferred_gpu import GPUBackend, nprime32  # noqa: E402
from family_dlog_gpu import make_request, sidecar_metadata  # noqa: E402

MAGIC = b"CFCPU1V1"
HEADER = struct.Struct("<8s14Q")
PRIME = 2_147_483_647


def write_u32(handle, values) -> None:
    data = values if isinstance(values, array) else array("I", values)
    if sys.byteorder != "little":
        data = array("I", data)
        data.byteswap()
    data.tofile(handle)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("programs", type=Path)
    ap.add_argument("sidecar", type=Path)
    ap.add_argument("output", type=Path)
    ap.add_argument("--base-count", type=int, default=11)
    ap.add_argument("--seed", type=int, default=259091)
    args = ap.parse_args()

    total_at = time.perf_counter()
    at = time.perf_counter()
    with args.programs.open("rb") as handle:
        programs = pickle.load(handle)["connection"]
    pickle_s = time.perf_counter() - at
    symbols, roots, _, _, _, dimension = sidecar_metadata(args.sidecar)
    at = time.perf_counter()
    request = make_request(PRIME, symbols, roots, args.base_count, args.seed)
    request_s = time.perf_counter() - at
    if programs.unique_expression_count != 946 or request.image_count != 88:
        raise ValueError("not the expected 946-program x 88-image CF259 fixture")
    if programs.dimensions != (2, dimension, dimension):
        raise ValueError("connection dimensions disagree with sidecar")
    if any(op > 15 or arg >= (1 << 28)
           for op, arg in zip(programs.ops, programs.args, strict=True)):
        raise ValueError("instruction cannot be packed into the benchmark ABI")

    at = time.perf_counter()
    packed = array("I", ((op << 28) | arg
                         for op, arg in zip(programs.ops, programs.args,
                                            strict=True)))
    rmod = (1 << 32) % PRIME
    constants = array("I", (value % PRIME * rmod % PRIME
                             for value in programs.constants))
    inputs = array("I", (value * rmod % PRIME
                          for channel in request.inputs for value in channel))
    pack_s = time.perf_counter() - at

    gpu_wall_at = time.perf_counter()
    with GPUBackend() as gpu:
        startup_s = gpu.startup_s
        reference, gpu_timing = gpu.evaluate(request, programs)
    gpu_wall_s = time.perf_counter() - gpu_wall_at

    counts = (1, PRIME, programs.unique_expression_count, len(programs.ops),
              len(programs.constants), len(request.inputs), request.image_count,
              request.base_count, len(roots), request.grade_count,
              len(programs.targets), programs.term_count, len(programs.factors),
              len(reference))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    at = time.perf_counter()
    with args.output.open("wb") as handle:
        handle.write(HEADER.pack(MAGIC, *counts))
        for section in (programs.offsets, packed, constants, inputs,
                        programs.record_offsets, programs.term_offsets,
                        programs.factors, reference):
            write_u32(handle, section)
    write_s = time.perf_counter() - at

    print(json.dumps({
        "phase": "exported_cf259_cpu_benchmark",
        "programs": programs.unique_expression_count,
        "instructions": len(programs.ops),
        "records": len(programs.targets), "terms": programs.term_count,
        "factors": len(programs.factors), "constants": len(programs.constants),
        "input_channels": len(request.inputs), "images": request.image_count,
        "output_values": len(reference), "output_bytes": len(reference) * 4,
        "payload_bytes": args.output.stat().st_size,
        "cold_pickle_read_s": round(pickle_s, 6),
        "request_setup_s": round(request_s, 6),
        "cpu_pack_s": round(pack_s, 6),
        "gpu_context_s": round(startup_s, 6),
        "gpu_upload_s": round(gpu_timing["upload_s"], 6),
        "gpu_kernel_s": round(gpu_timing["kernel_s"], 6),
        "gpu_download_s": round(gpu_timing["download_s"], 6),
        "gpu_evaluate_wall_s": round(gpu_wall_s - startup_s, 6),
        "gpu_context_plus_evaluate_wall_s": round(gpu_wall_s, 6),
        "payload_write_s": round(write_s, 6),
        "export_total_s": round(time.perf_counter() - total_at, 6),
        "gpu_device": gpu_timing["device"], "nprime": nprime32(PRIME),
    }), flush=True)


if __name__ == "__main__":
    main()
