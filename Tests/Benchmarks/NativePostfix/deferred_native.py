#!/usr/bin/env python3
"""Family-neutral ctypes wrapper for the native 31-bit postfix evaluator."""

from __future__ import annotations

from array import array
import ctypes
from pathlib import Path
import time

from deferred_gpu import Programs, Request

U32P = ctypes.POINTER(ctypes.c_uint32)
F64P = ctypes.POINTER(ctypes.c_double)
CHARP = ctypes.POINTER(ctypes.c_char)


def u32_pointer(values: array) -> U32P:
    if not values:
        return U32P()
    return ctypes.cast((ctypes.c_uint32 * len(values)).from_buffer(values), U32P)


class NativeBackend:
    """Evaluate neutral ``Programs`` objects without family-specific policy."""

    def __init__(self, library: Path, threads: int = 8) -> None:
        if not 1 <= threads <= 64:
            raise ValueError("threads must be in 1..64")
        at = time.perf_counter()
        self.library = ctypes.CDLL(str(library))
        self.threads = threads
        self._plans: dict[int, tuple[Programs, ctypes.c_void_p, float]] = {}
        create = self.library.ffnative_plan_create
        create.argtypes = [U32P, ctypes.c_uint32, U32P, U32P, ctypes.c_uint64,
                           ctypes.c_uint32, U32P, ctypes.c_uint32, U32P,
                           ctypes.c_uint32, U32P, ctypes.c_uint32,
                           CHARP, ctypes.c_uint64]
        create.restype = ctypes.c_void_p
        self.library.ffnative_plan_destroy.argtypes = [ctypes.c_void_p]
        evaluate = self.library.ffnative_evaluate
        evaluate.argtypes = [ctypes.c_void_p, ctypes.c_uint32, U32P, U32P,
                             ctypes.c_uint32, ctypes.c_uint32, ctypes.c_uint32,
                             ctypes.c_uint32, ctypes.c_uint32, ctypes.c_uint32,
                             U32P, F64P, CHARP, ctypes.c_uint64]
        evaluate.restype = ctypes.c_int
        self.startup_s = time.perf_counter() - at

    def __enter__(self) -> "NativeBackend":
        return self

    def __exit__(self, *_args) -> None:
        self.close()

    def close(self) -> None:
        for _, pointer, _ in self._plans.values():
            self.library.ffnative_plan_destroy(pointer)
        self._plans.clear()

    def _plan(self, programs: Programs) -> tuple[ctypes.c_void_p, float]:
        key = id(programs)
        known = self._plans.get(key)
        if known is not None and known[0] is programs:
            return known[1], 0.0
        error = ctypes.create_string_buffer(512)
        at = time.perf_counter()
        pointer = self.library.ffnative_plan_create(
            u32_pointer(programs.offsets), programs.unique_expression_count,
            u32_pointer(programs.ops), u32_pointer(programs.args), len(programs.ops),
            len(programs.constants), u32_pointer(programs.record_offsets),
            len(programs.targets), u32_pointer(programs.term_offsets),
            programs.term_count, u32_pointer(programs.factors), len(programs.factors),
            error, len(error),
        )
        seconds = time.perf_counter() - at
        if not pointer:
            raise RuntimeError(error.value.decode() or "native plan creation failed")
        self._plans[key] = (programs, pointer, seconds)
        return pointer, seconds

    def evaluate(self, request: Request, programs: Programs):
        plan, plan_setup_s = self._plan(programs)
        prime = request.prime
        rmod = (1 << 32) % prime
        at = time.perf_counter()
        constants = array("I", (value % prime * rmod % prime
                                 for value in programs.constants))
        inputs = array("I", (value * rmod % prime
                              for channel in request.inputs for value in channel))
        preparation_s = time.perf_counter() - at
        result = array("I", [0]) * (len(programs.targets) * request.image_count)
        timing = (ctypes.c_double * 4)()
        error = ctypes.create_string_buffer(512)
        at = time.perf_counter()
        status = self.library.ffnative_evaluate(
            plan, prime, u32_pointer(constants), u32_pointer(inputs),
            len(request.inputs), request.image_count, request.base_count,
            len(request.roots), request.grade_count, self.threads,
            u32_pointer(result), timing, error, len(error),
        )
        call_s = time.perf_counter() - at
        if status:
            raise RuntimeError(error.value.decode() or "native postfix evaluation failed")
        return result, {
            "backend": "NativeCPU31Postfix",
            "threads": self.threads,
            "plan_setup_s": plan_setup_s,
            "preparation_s": preparation_s,
            "expression_s": timing[0], "assembly_s": timing[1],
            "channels_s": timing[2], "native_total_s": timing[3],
            "call_s": call_s,
        }
