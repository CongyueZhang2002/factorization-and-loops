"""Minimal CUDA Driver API binding; no CUDA toolkit or Python packages needed."""

from __future__ import annotations

import ctypes as C


class CUDAError(RuntimeError):
    pass


class Driver:
    def __init__(self, ptx: str):
        self.lib = C.CDLL("libcuda.so.1")
        self._bind()
        self._check(self.lib.cuInit(0), "cuInit")
        device = C.c_int()
        self._check(self.lib.cuDeviceGet(C.byref(device), 0), "cuDeviceGet")
        self.device = device.value
        name = C.create_string_buffer(128)
        self._check(self.lib.cuDeviceGetName(name, len(name), device), "cuDeviceGetName")
        self.name = name.value.decode(errors="replace")
        self.context = C.c_void_p()
        self._check(self.lib.cuCtxCreate_v2(C.byref(self.context), 0, device), "cuCtxCreate")
        self.module = C.c_void_p()
        image = C.create_string_buffer(ptx.encode() + b"\0")
        try:
            self._check(
                self.lib.cuModuleLoadDataEx(C.byref(self.module), image, 0, None, None),
                "cuModuleLoadDataEx",
            )
        except Exception:
            self.close()
            raise
        self._allocations: set[int] = set()

    def _bind(self) -> None:
        L = self.lib
        L.cuGetErrorName.argtypes = [C.c_int, C.POINTER(C.c_char_p)]
        L.cuGetErrorString.argtypes = [C.c_int, C.POINTER(C.c_char_p)]
        L.cuDeviceGet.argtypes = [C.POINTER(C.c_int), C.c_int]
        L.cuDeviceGetName.argtypes = [C.c_char_p, C.c_int, C.c_int]
        L.cuCtxCreate_v2.argtypes = [C.POINTER(C.c_void_p), C.c_uint, C.c_int]
        L.cuCtxDestroy_v2.argtypes = [C.c_void_p]
        L.cuModuleLoadDataEx.argtypes = [
            C.POINTER(C.c_void_p), C.c_void_p, C.c_uint, C.c_void_p, C.c_void_p
        ]
        L.cuModuleUnload.argtypes = [C.c_void_p]
        L.cuModuleGetFunction.argtypes = [C.POINTER(C.c_void_p), C.c_void_p, C.c_char_p]
        L.cuMemAlloc_v2.argtypes = [C.POINTER(C.c_uint64), C.c_size_t]
        L.cuMemFree_v2.argtypes = [C.c_uint64]
        L.cuMemcpyHtoD_v2.argtypes = [C.c_uint64, C.c_void_p, C.c_size_t]
        L.cuMemcpyDtoH_v2.argtypes = [C.c_void_p, C.c_uint64, C.c_size_t]
        L.cuLaunchKernel.argtypes = [
            C.c_void_p,
            C.c_uint, C.c_uint, C.c_uint,
            C.c_uint, C.c_uint, C.c_uint,
            C.c_uint, C.c_void_p, C.POINTER(C.c_void_p), C.c_void_p,
        ]
        L.cuCtxSynchronize.argtypes = []

    def _check(self, code: int, operation: str) -> None:
        if code == 0:
            return
        name, detail = C.c_char_p(), C.c_char_p()
        self.lib.cuGetErrorName(code, C.byref(name))
        self.lib.cuGetErrorString(code, C.byref(detail))
        raise CUDAError(
            f"{operation}: {name.value.decode() if name.value else code}: "
            f"{detail.value.decode() if detail.value else 'unknown CUDA error'}"
        )

    def function(self, name: str) -> C.c_void_p:
        result = C.c_void_p()
        self._check(
            self.lib.cuModuleGetFunction(C.byref(result), self.module, name.encode()),
            f"cuModuleGetFunction({name})",
        )
        return result

    def alloc(self, nbytes: int) -> int:
        pointer = C.c_uint64()
        self._check(self.lib.cuMemAlloc_v2(C.byref(pointer), nbytes), "cuMemAlloc")
        self._allocations.add(pointer.value)
        return pointer.value

    def free(self, pointer: int) -> None:
        if pointer:
            self._check(self.lib.cuMemFree_v2(pointer), "cuMemFree")
            self._allocations.discard(pointer)

    def allocation_mark(self) -> frozenset[int]:
        return frozenset(self._allocations)

    def release_since(self, mark: frozenset[int]) -> None:
        for pointer in list(self._allocations.difference(mark)):
            self.free(pointer)

    @staticmethod
    def _host_address(buffer) -> int:
        return C.addressof(C.c_char.from_buffer(buffer))

    def upload(self, buffer) -> int:
        pointer = self.alloc(len(buffer) * buffer.itemsize)
        self._check(
            self.lib.cuMemcpyHtoD_v2(
                pointer, self._host_address(buffer), len(buffer) * buffer.itemsize
            ),
            "cuMemcpyHtoD",
        )
        return pointer

    def download(self, pointer: int, buffer) -> None:
        self._check(
            self.lib.cuMemcpyDtoH_v2(
                self._host_address(buffer), pointer, len(buffer) * buffer.itemsize
            ),
            "cuMemcpyDtoH",
        )

    def launch(self, function, count: int, args, block: int = 128) -> None:
        holders = []
        pointers = []
        for ctype, value in args:
            holder = ctype(value)
            holders.append(holder)
            pointers.append(C.cast(C.byref(holder), C.c_void_p))
        parameters = (C.c_void_p * len(pointers))(*pointers)
        grid = (count + block - 1) // block
        self._check(
            self.lib.cuLaunchKernel(
                function, grid, 1, 1, block, 1, 1, 0, None, parameters, None
            ),
            "cuLaunchKernel",
        )

    def synchronize(self) -> None:
        self._check(self.lib.cuCtxSynchronize(), "cuCtxSynchronize")

    def close(self) -> None:
        if not hasattr(self, "lib"):
            return
        for pointer in list(getattr(self, "_allocations", ())):
            self.lib.cuMemFree_v2(pointer)
        if getattr(self, "module", None) and self.module.value:
            self.lib.cuModuleUnload(self.module)
            self.module = C.c_void_p()
        if getattr(self, "context", None) and self.context.value:
            self.lib.cuCtxDestroy_v2(self.context)
            self.context = C.c_void_p()

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.close()


U32 = C.c_uint32
U64 = C.c_uint64
