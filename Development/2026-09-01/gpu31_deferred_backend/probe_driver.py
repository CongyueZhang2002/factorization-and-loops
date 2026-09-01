#!/usr/bin/env python3
"""Short libcuda + embedded-PTX Montgomery correctness probe."""

from array import array
import random
import time

from cuda_driver import Driver, U32, U64
from ff31_ptx import PTX


def inverse32_odd(p: int) -> int:
    return (-pow(p, -1, 1 << 32)) & 0xFFFFFFFF


def mont_mul(a: int, b: int, p: int, nprime: int) -> int:
    t = a * b
    m = (t * nprime) & 0xFFFFFFFF
    u = (t + m * p) >> 32
    return u - p if u >= p else u


def main() -> None:
    p = 2147483423
    nprime = inverse32_odd(p)
    rmod = (1 << 32) % p
    count, iterations = 4096, 31
    rng = random.Random(0x31C0DA)
    xs0 = [rng.randrange(1, p) for _ in range(count)]
    ys0 = [rng.randrange(1, p) for _ in range(count)]
    xs = array("I", ((x * rmod) % p for x in xs0))
    ys = array("I", ((y * rmod) % p for y in ys0))
    out = array("I", [0]) * count
    c1, c2 = 17 * rmod % p, 29 * rmod % p

    expected = []
    for x, y in zip(xs, ys):
        for _ in range(iterations):
            x = mont_mul(x, y, p, nprime)
            x = (x + c1) % p
            y = mont_mul(y, y, p, nprime)
            y = (y + c2) % p
        expected.append(x)

    started = time.perf_counter()
    with Driver(PTX) as cuda:
        loaded = time.perf_counter()
        dx, dy, dout = cuda.upload(xs), cuda.upload(ys), cuda.alloc(4 * count)
        kernel = cuda.function("ff31_bench")
        cuda.launch(kernel, count, [
            (U64, dx), (U64, dy), (U64, dout),
            (U32, count), (U32, iterations), (U32, p), (U32, nprime),
            (U32, c1), (U32, c2),
        ])
        cuda.synchronize()
        cuda.download(dout, out)
        finished = time.perf_counter()
        name = cuda.name
    if out.tolist() != expected:
        mismatch = next(i for i, (a, b) in enumerate(zip(out, expected)) if a != b)
        raise AssertionError(f"Montgomery mismatch at {mismatch}: {out[mismatch]} != {expected[mismatch]}")
    print(
        f"PASS device={name!r} values={count} iterations={iterations} "
        f"jit_ms={(loaded-started)*1000:.3f} run_ms={(finished-loaded)*1000:.3f}"
    )


if __name__ == "__main__":
    main()
