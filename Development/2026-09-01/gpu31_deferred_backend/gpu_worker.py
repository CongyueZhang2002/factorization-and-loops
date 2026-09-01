#!/usr/bin/env python3
"""Persistent JSON-lines worker for repeated exact GPU31 images."""

from __future__ import annotations

import argparse
from collections import OrderedDict
import json
import os
from pathlib import Path
import sys
import time

from deferred_gpu import (
    GPUBackend, authenticate_roots, compile_preparation, parse_request, write_dago,
)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cache-entries", type=int, default=2)
    args = parser.parse_args()
    if not 1 <= args.cache_entries <= 8:
        raise SystemExit("--cache-entries must be in 1..8")
    cache = OrderedDict()
    with GPUBackend() as backend:
        print(json.dumps({
            "status": "Ready", "device": backend.cuda.name,
            "startup_s": backend.startup_s,
        }), flush=True)
        for line in sys.stdin:
            identity = None
            try:
                job = json.loads(line)
                identity = job.get("id")
                if job.get("command") == "quit":
                    print(json.dumps({"id": identity, "status": "Bye"}), flush=True)
                    return
                input_path = Path(job["input"]).resolve()
                request_path = Path(job["request"]).resolve()
                output_path = Path(job["output"]).resolve()
                max_threads = int(job.get("max_batch_threads", 1_000_000))
                started = time.perf_counter_ns()
                request = parse_request(request_path)
                authenticate_roots(request)
                stat = input_path.stat()
                key = (
                    input_path, stat.st_size, stat.st_mtime_ns,
                    request.symbols, request.roots,
                )
                cache_hit = key in cache
                if cache_hit:
                    programs = cache.pop(key)
                    cache[key] = programs
                else:
                    programs = compile_preparation(input_path, request)
                    cache[key] = programs
                    while len(cache) > args.cache_entries:
                        cache.popitem(last=False)
                parsed = time.perf_counter_ns()
                channels, timings = backend.evaluate(request, programs, max_threads)
                evaluated = time.perf_counter_ns()
                rows = [
                    list(channels[start:start + request.image_count])
                    for start in range(0, len(channels), request.image_count)
                ]
                output_path.parent.mkdir(parents=True, exist_ok=True)
                temporary = output_path.with_name(
                    f".{output_path.name}.tmp.{os.getpid()}"
                )
                try:
                    write_dago(
                        temporary, request, programs, rows,
                        parsed - started, evaluated - parsed,
                    )
                    temporary.replace(output_path)
                finally:
                    temporary.unlink(missing_ok=True)
                print(json.dumps({
                    "id": identity, "status": "OK", "cache_hit": cache_hit,
                    "records": len(programs.targets),
                    "terms": programs.term_count,
                    "unique_expressions": programs.unique_expression_count,
                    "instructions": len(programs.ops),
                    "images": request.image_count,
                    "prepare_s": (parsed - started) / 1e9,
                    "evaluate_s": (evaluated - parsed) / 1e9,
                    "kernel_s": timings["kernel_s"],
                }), flush=True)
            except Exception as error:
                print(json.dumps({
                    "id": identity, "status": "Error",
                    "error": f"{type(error).__name__}: {error}",
                }), flush=True)


if __name__ == "__main__":
    main()
