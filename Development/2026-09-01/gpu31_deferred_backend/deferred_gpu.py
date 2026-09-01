#!/usr/bin/env python3
"""Family-neutral DeferredASTRequestV1 evaluator on 31-bit CUDA Montgomery fields."""

from __future__ import annotations

import argparse
from array import array
from dataclasses import dataclass
from pathlib import Path
import struct
import time

from cuda_driver import Driver, U32, U64


CONST, INPUT, ADD, SUB, MUL, POW, INV, NEG = range(1, 9)
MAX_STACK = 32


def nprime32(p: int) -> int:
    return (-pow(p, -1, 1 << 32)) & 0xFFFFFFFF


def mont_mul(a: int, b: int, p: int, np: int) -> int:
    t = a * b
    m = (t * np) & 0xFFFFFFFF
    u = (t + m * p) >> 32
    return u - p if u >= p else u


def is_prime31(n: int) -> bool:
    if n < 2 or n >= 1 << 31:
        return False
    for small in (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37):
        if n == small:
            return True
        if n % small == 0:
            return False
    d, s = n - 1, 0
    while d & 1 == 0:
        d >>= 1
        s += 1
    for a in (2, 3, 5, 7, 11):
        x = pow(a, d, n)
        if x in (1, n - 1):
            continue
        for _ in range(s - 1):
            x = x * x % n
            if x == n - 1:
                break
        else:
            return False
    return True


@dataclass
class Request:
    prime: int
    symbols: tuple[str, str, str]
    roots: tuple[str, ...]
    base_count: int
    grade_count: int
    inputs: list[list[int]]
    deltas: list[list[int]]
    positive_roots: list[list[int]]

    @property
    def image_count(self) -> int:
        return self.base_count * self.grade_count


def parse_request(path: Path) -> Request:
    lines = path.read_text().splitlines()
    cursor = 0

    def take(prefix: str | None = None) -> str:
        nonlocal cursor
        if cursor >= len(lines):
            raise ValueError("truncated DeferredASTRequestV1")
        line = lines[cursor].strip()
        cursor += 1
        if prefix is not None:
            if not line.startswith(prefix):
                raise ValueError(f"expected {prefix!r}, got {line!r}")
            return line[len(prefix):]
        return line

    if take() != "DeferredASTRequestV1":
        raise ValueError("not a DeferredASTRequestV1")
    p = int(take("prime "))
    if not is_prime31(p):
        raise ValueError("GPU31 requires an odd prime below 2^31")
    symbols = tuple(take("variables ").split())
    if len(symbols) != 3 or len(set(symbols)) != 3:
        raise ValueError("exactly three distinct variables are required")
    rank = int(take("rank "))
    if not 0 <= rank <= 3:
        raise ValueError("rank must be in 0..3")
    roots = tuple(take("root ") for _ in range(rank))
    base_count = int(take("base_count "))
    if base_count <= 0:
        raise ValueError("base_count must be positive")
    grade_count = 1 << rank
    if base_count * grade_count > 4096:
        raise ValueError("request exceeds the 4096-image neutral ABI limit")
    base_rows: list[list[int]] = []
    for _ in range(base_count):
        fields = [int(value) for value in take("image ").split()]
        if len(fields) != 3 + 2 * rank or any(not 0 <= v < p for v in fields):
            raise ValueError("bad image row")
        for root_index in range(rank):
            delta, root = fields[3 + 2 * root_index:5 + 2 * root_index]
            if root == 0 or root * root % p != delta:
                raise ValueError("declared root value does not square to delta")
        base_rows.append(fields)
    if any(line.strip() for line in lines[cursor:]):
        raise ValueError("trailing request data")

    inputs = [[] for _ in range(3 + rank)]
    deltas = [[] for _ in range(rank)]
    positive_roots = [[] for _ in range(rank)]
    for fields in base_rows:
        for k in range(rank):
            positive_roots[k].append(fields[4 + 2 * k])
        for sheet in range(grade_count):
            for axis in range(3):
                inputs[axis].append(fields[axis])
            for k in range(rank):
                delta, root = fields[3 + 2 * k:5 + 2 * k]
                inputs[3 + k].append(p - root if sheet & (1 << k) else root)
                deltas[k].append(delta)
    return Request(p, symbols, roots, base_count, grade_count, inputs,
                   deltas, positive_roots)


def normalized(text: str) -> str:
    return "".join(text.replace("\\\r\n", "").replace("\\\n", "").split())


class ExpressionCompiler:
    def __init__(self, text: str, request: Request, allow_sqrt: bool = True):
        self.text, self.request, self.allow_sqrt = text, request, allow_sqrt
        self.i = 0
        self.code: list[tuple[int, int]] = []
        self.rmod = (1 << 32) % request.prime

    def skip(self) -> None:
        while self.i < len(self.text):
            if self.text[self.i].isspace():
                self.i += 1
            elif self.text[self.i] == "\\" and self.i + 1 < len(self.text) \
                    and self.text[self.i + 1] in "\r\n":
                self.i += 2
                if self.i < len(self.text) and self.text[self.i - 1] == "\r" \
                        and self.text[self.i] == "\n":
                    self.i += 1
            else:
                break

    def compile(self) -> list[tuple[int, int]]:
        self.sum()
        self.skip()
        if self.i != len(self.text):
            raise ValueError(f"unsupported expression at byte {self.i}: {self.text!r}")
        depth = peak = 0
        for op, _ in self.code:
            if op in (CONST, INPUT):
                depth += 1
                peak = max(peak, depth)
            elif op in (ADD, SUB, MUL):
                if depth < 2:
                    raise ValueError("invalid postfix stack")
                depth -= 1
            elif op in (POW, INV, NEG):
                if depth < 1:
                    raise ValueError("invalid postfix stack")
        if depth != 1 or peak > MAX_STACK:
            raise ValueError(f"expression stack depth {peak} exceeds {MAX_STACK}")
        return self.code

    def sum(self) -> None:
        self.term()
        while True:
            self.skip()
            if self.i >= len(self.text) or self.text[self.i] not in "+-":
                return
            op = ADD if self.text[self.i] == "+" else SUB
            self.i += 1
            self.term()
            self.code.append((op, 0))

    def term(self) -> None:
        self.primary()
        while True:
            self.skip()
            if self.i >= len(self.text) or self.text[self.i] not in "*/":
                return
            divide = self.text[self.i] == "/"
            self.i += 1
            self.primary()
            if divide:
                self.code.append((INV, 0))
            self.code.append((MUL, 0))

    def primary(self) -> None:
        self.skip()
        sign = 1
        while self.i < len(self.text) and self.text[self.i] in "+-":
            if self.text[self.i] == "-":
                sign = -sign
            self.i += 1
            self.skip()
        if self.i >= len(self.text):
            raise ValueError("missing primary")
        base_start, base_code_start = self.i, len(self.code)
        if self.text[self.i] == "(":
            self.i += 1
            self.sum()
            self.skip()
            if self.i >= len(self.text) or self.text[self.i] != ")":
                raise ValueError("missing closing parenthesis")
            self.i += 1
        elif self.text[self.i].isdigit():
            start = self.i
            while self.i < len(self.text) and self.text[self.i].isdigit():
                self.i += 1
            value = int(self.text[start:self.i]) % self.request.prime
            self.code.append((CONST, value * self.rmod % self.request.prime))
        else:
            start = self.i
            while self.i < len(self.text) and (
                    self.text[self.i].isalnum() or self.text[self.i] in "$`"):
                self.i += 1
            if start == self.i:
                raise ValueError(f"unsupported token at byte {self.i}")
            symbol = self.text[start:self.i]
            tail = symbol.rsplit("`", 1)[-1]
            self.skip()
            if tail == "Sqrt" and self.i < len(self.text) and self.text[self.i] == "[":
                if not self.allow_sqrt:
                    raise ValueError("radical not allowed in a declared root square")
                self.i += 1
                argument_start, code_start = self.i, len(self.code)
                self.sum()
                argument_end = self.i
                del self.code[code_start:]
                self.skip()
                if self.i >= len(self.text) or self.text[self.i] != "]":
                    raise ValueError("missing closing Sqrt bracket")
                self.i += 1
                wanted = normalized(self.text[argument_start:argument_end])
                try:
                    root_index = [normalized(root) for root in self.request.roots].index(wanted)
                except ValueError as error:
                    raise ValueError("undeclared radical") from error
                self.code.append((INPUT, 3 + root_index))
            else:
                tails = [name.rsplit("`", 1)[-1] for name in self.request.symbols]
                if tail not in tails:
                    raise ValueError(f"unsupported symbol {symbol!r}")
                self.code.append((INPUT, tails.index(tail)))
        base_end = self.i
        self.skip()
        if self.i < len(self.text) and self.text[self.i] == "^":
            self.i += 1
            self.skip()
            parenthesized = self.i < len(self.text) and self.text[self.i] == "("
            if parenthesized:
                self.i += 1
                self.skip()
            exponent_sign = 1
            if self.i < len(self.text) and self.text[self.i] in "+-":
                if self.text[self.i] == "-":
                    exponent_sign = -1
                self.i += 1
            start = self.i
            while self.i < len(self.text) and self.text[self.i].isdigit():
                self.i += 1
            if start == self.i:
                raise ValueError("integer exponent required")
            exponent = int(self.text[start:self.i])
            self.skip()
            denominator = 1
            if self.i < len(self.text) and self.text[self.i] == "/":
                self.i += 1
                self.skip()
                denominator_start = self.i
                while self.i < len(self.text) and self.text[self.i].isdigit():
                    self.i += 1
                if denominator_start == self.i:
                    raise ValueError("exponent denominator required")
                denominator = int(self.text[denominator_start:self.i])
                self.skip()
            if denominator == 2 and exponent & 1:
                if not self.allow_sqrt:
                    raise ValueError("half-integer exponent is not allowed here")
                wanted = normalized(self.text[base_start:base_end])
                if wanted.startswith("(") and wanted.endswith(")"):
                    wanted = wanted[1:-1]
                try:
                    root_index = [normalized(root) for root in self.request.roots].index(wanted)
                except ValueError as error:
                    raise ValueError(
                        "half-integer exponent requires a declared root square"
                    ) from error
                del self.code[base_code_start:]
                self.code.append((INPUT, 3 + root_index))
            elif denominator == 2:
                exponent //= 2
            elif denominator != 1:
                raise ValueError("only integer and declared half-integer powers are supported")
            if exponent > 0xFFFFFFFF:
                raise ValueError("GPU31 exponent exceeds 32 bits")
            if parenthesized:
                if self.i >= len(self.text) or self.text[self.i] != ")":
                    excerpt = self.text[max(0, self.i - 40):self.i + 80]
                    raise ValueError(
                        f"missing exponent parenthesis at byte {self.i}: {excerpt!r}"
                    )
                self.i += 1
            if exponent_sign < 0 and exponent:
                self.code.append((INV, 0))
            self.code.append((POW, exponent))
        if sign < 0:
            self.code.append((NEG, 0))


def skip_space(text: str, i: int) -> int:
    while i < len(text) and text[i].isspace():
        i += 1
    return i


def scan_string(text: str, i: int) -> int:
    if text[i] != '"':
        raise ValueError("association key must be a string")
    i += 1
    while i < len(text):
        if text[i] == "\\":
            i += 2
        elif text[i] == '"':
            return i + 1
        else:
            i += 1
    raise ValueError("unterminated string")


def scan_value(text: str, i: int, closing: str) -> tuple[int, int]:
    i = skip_space(text, i)
    start, stack = i, []
    pairs = {"(": ")", "[": "]", "{": "}", "<|": "|>"}
    while i < len(text):
        if text[i] == '"':
            i = scan_string(text, i)
            continue
        if not stack and (text[i] == "," or text.startswith(closing, i)):
            end = i
            while end > start and text[end - 1].isspace():
                end -= 1
            return start, end
        if text.startswith("<|", i):
            stack.append("|>")
            i += 2
            continue
        if text.startswith("|>", i):
            if not stack or stack[-1] != "|>":
                raise ValueError("unmatched |>")
            stack.pop()
            i += 2
            continue
        char = text[i]
        if char in "([{":
            stack.append(pairs[char])
        elif char in ")]}":
            if not stack or stack.pop() != char:
                raise ValueError(f"unmatched {char}")
        i += 1
    raise ValueError("unterminated value")


def association(text: str, span: tuple[int, int]) -> dict[str, tuple[int, int]]:
    start, end = span
    start = skip_space(text, start)
    while end > start and text[end - 1].isspace():
        end -= 1
    if not text.startswith("<|", start) or not text.startswith("|>", end - 2):
        raise ValueError("association expected")
    result, i = {}, start + 2
    while True:
        i = skip_space(text, i)
        if text.startswith("|>", i):
            return result
        key_end = scan_string(text, i)
        key = text[i + 1:key_end - 1]
        i = skip_space(text, key_end)
        if not text.startswith("->", i):
            raise ValueError("rule expected")
        result[key] = scan_value(text, i + 2, "|>")
        i = skip_space(text, result[key][1])
        if text.startswith("|>", i):
            return result
        if i >= end or text[i] != ",":
            raise ValueError("association comma expected")
        i += 1


def list_spans(text: str, span: tuple[int, int]) -> list[tuple[int, int]]:
    start, end = span
    start = skip_space(text, start)
    while end > start and text[end - 1].isspace():
        end -= 1
    if text[start] != "{" or text[end - 1] != "}":
        raise ValueError("list expected")
    result, i = [], start + 1
    while True:
        i = skip_space(text, i)
        if text[i] == "}":
            return result
        item = scan_value(text, i, "}")
        result.append(item)
        i = skip_space(text, item[1])
        if text[i] == "}":
            return result
        if text[i] != ",":
            raise ValueError("list comma expected")
        i += 1


def slice_value(text: str, span: tuple[int, int]) -> str:
    return text[span[0]:span[1]].strip()


@dataclass
class Programs:
    offsets: array
    ops: array
    args: array
    targets: list[tuple[int, int, int]]
    dimensions: tuple[int, int, int]
    term_count: int
    unique_expression_count: int


def compile_preparation(path: Path, request: Request) -> Programs:
    text = path.read_text()
    whole = (0, len(text))
    top = association(text, whole)
    deferred = association(text, top["DeferredPreparation"])
    prep = association(text, deferred["Preparation"])
    if slice_value(text, prep["Status"]) != '"Prepared"' or \
            slice_value(text, prep["ABIVersion"]) != '"BlockEquationDeferredV1"':
        raise ValueError("unsupported DeferredPreparation schema")
    record_spans = list_spans(text, prep["Records"])
    if not record_spans:
        raise ValueError("empty Records")
    offsets, ops, args = array("I", [0]), array("I"), array("I")
    targets, term_count, unique = [], 0, set()
    for record_span in record_spans:
        record = association(text, record_span)
        target = tuple(int(slice_value(text, item))
                       for item in list_spans(text, record["Target"]))
        if len(target) != 3 or any(value <= 0 for value in target):
            raise ValueError("Target must have three positive indices")
        targets.append(target)
        terms = list_spans(text, record["Terms"])
        first = True
        for term_span in terms:
            term = association(text, term_span)
            expressions = [slice_value(text, term["Coefficient"])]
            expressions += [slice_value(text, item)
                            for item in list_spans(text, term["Operands"])]
            for expression_index, expression in enumerate(expressions):
                unique.add(normalized(expression))
                code = ExpressionCompiler(expression, request).compile()
                for op, arg in code:
                    ops.append(op)
                    args.append(arg)
                if expression_index:
                    ops.append(MUL)
                    args.append(0)
            if not first:
                ops.append(ADD)
                args.append(0)
            first = False
            term_count += 1
        if first:
            ops.append(CONST)
            args.append(0)
        depth = peak = 0
        for op in ops[offsets[-1]:]:
            if op in (CONST, INPUT):
                depth += 1
                peak = max(peak, depth)
            elif op in (ADD, SUB, MUL):
                depth -= 1
            if depth < 1:
                raise ValueError("invalid assembled record stack")
        if depth != 1 or peak > MAX_STACK:
            raise ValueError(f"assembled record stack depth {peak} exceeds {MAX_STACK}")
        offsets.append(len(ops))
    dimensions = tuple(max(target[axis] for target in targets) for axis in range(3))
    if len(targets) != dimensions[0] * dimensions[1] * dimensions[2]:
        raise ValueError("Targets do not form a complete rectangle")
    expected = []
    for a in range(1, dimensions[0] + 1):
        for b in range(1, dimensions[1] + 1):
            for c in range(1, dimensions[2] + 1):
                expected.append((a, b, c))
    if targets != expected:
        raise ValueError("Targets are not in lexicographic ABI order")
    return Programs(offsets, ops, args, targets, dimensions, term_count, len(unique))


def cpu_program(code: list[tuple[int, int]], inputs: list[list[int]], image: int,
                p: int, np: int, one: int) -> int:
    stack: list[int] = []
    for op, arg in code:
        if op == CONST:
            stack.append(arg)
        elif op == INPUT:
            stack.append(inputs[arg][image])
        elif op == ADD:
            b, a = stack.pop(), stack.pop()
            stack.append((a + b) % p)
        elif op == SUB:
            b, a = stack.pop(), stack.pop()
            stack.append((a - b) % p)
        elif op == MUL:
            b, a = stack.pop(), stack.pop()
            stack.append(mont_mul(a, b, p, np))
        elif op == POW:
            base, result, exponent = stack.pop(), one, arg
            while exponent:
                if exponent & 1:
                    result = mont_mul(result, base, p, np)
                base = mont_mul(base, base, p, np)
                exponent >>= 1
            stack.append(result)
        elif op == INV:
            base, result, exponent = stack.pop(), one, p - 2
            if base == 0:
                raise ZeroDivisionError("singular image")
            while exponent:
                if exponent & 1:
                    result = mont_mul(result, base, p, np)
                base = mont_mul(base, base, p, np)
                exponent >>= 1
            stack.append(result)
        elif op == NEG:
            value = stack.pop()
            stack.append(p - value if value else 0)
    if len(stack) != 1:
        raise ValueError("bad CPU postfix stack")
    return stack[0]


def authenticate_roots(request: Request) -> None:
    p, np = request.prime, nprime32(request.prime)
    rmod = (1 << 32) % p
    mont_inputs = [[value * rmod % p for value in channel]
                   for channel in request.inputs]
    for root_index, expression in enumerate(request.roots):
        code = ExpressionCompiler(expression, request, allow_sqrt=False).compile()
        for image in range(request.image_count):
            value = cpu_program(code, mont_inputs, image, p, np, rmod)
            standard = mont_mul(value, 1, p, np)
            if standard != request.deltas[root_index][image]:
                raise ValueError(f"root square {root_index + 1} mismatches image {image + 1}")


def gpu_evaluate(request: Request, programs: Programs,
                 max_batch_threads: int = 1_000_000):
    if not 1 <= max_batch_threads <= 2_000_000:
        raise ValueError("max_batch_threads must be in 1..2,000,000")
    p, np = request.prime, nprime32(request.prime)
    rmod = (1 << 32) % p
    flat_inputs = array("I", (
        value * rmod % p for channel in request.inputs for value in channel
    ))
    result = array("I")
    timings = {"jit_s": 0.0, "upload_s": 0.0, "kernel_s": 0.0, "download_s": 0.0}
    started = time.perf_counter()
    kernel_path = Path(__file__).with_name("postfix_kernels.ptx")
    if not kernel_path.exists():
        raise FileNotFoundError("postfix_kernels.ptx is absent; run make -j1")
    with Driver(kernel_path.read_text()) as cuda:
        timings["jit_s"] = time.perf_counter() - started
        upload_at = time.perf_counter()
        d_offsets = cuda.upload(programs.offsets)
        d_ops = cuda.upload(programs.ops)
        d_args = cuda.upload(programs.args)
        d_inputs = cuda.upload(flat_inputs)
        status = array("I", [0])
        d_status = cuda.upload(status)
        timings["upload_s"] = time.perf_counter() - upload_at
        kernel = cuda.function("ff31_eval")
        channel_kernel = cuda.function("ff31_channels")
        per_batch = max(1, max_batch_threads // request.image_count)
        for start in range(0, len(programs.targets), per_batch):
            batch = min(per_batch, len(programs.targets) - start)
            count = batch * request.image_count
            host_out = array("I", [0]) * count
            d_out = cuda.alloc(4 * count)
            d_channels = cuda.alloc(4 * count)
            at = time.perf_counter()
            cuda.launch(kernel, count, [
                (U64, d_offsets), (U64, d_ops), (U64, d_args),
                (U64, d_inputs), (U64, d_out), (U64, d_status),
                (U32, start), (U32, batch), (U32, request.image_count),
                (U32, p), (U32, np), (U32, rmod),
            ])
            cuda.launch(channel_kernel, count, [
                (U64, d_out), (U64, d_inputs), (U64, d_channels),
                (U32, batch), (U32, request.base_count),
                (U32, len(request.roots)), (U32, request.grade_count),
                (U32, p), (U32, np), (U32, rmod),
                (U32, request.grade_count * rmod % p),
            ])
            cuda.synchronize()
            timings["kernel_s"] += time.perf_counter() - at
            at = time.perf_counter()
            cuda.download(d_channels, host_out)
            timings["download_s"] += time.perf_counter() - at
            cuda.free(d_out)
            cuda.free(d_channels)
            result.extend(host_out)
        cuda.download(d_status, status)
        device_name = cuda.name
    if status[0]:
        raise ZeroDivisionError(f"GPU evaluator status bits {status[0]}")
    timings["device"] = device_name
    timings["gpu_bytes_max"] = (
        4 * (len(programs.offsets) + len(programs.ops) + len(programs.args)
             + len(flat_inputs) + 1 + 2 * min(max_batch_threads,
                                              len(programs.targets) * request.image_count))
        + 128 * min(max_batch_threads,
                    len(programs.targets) * request.image_count)
    )
    return result, timings


def canonical_channels(raw: array, request: Request) -> list[list[int]]:
    p, np = request.prime, nprime32(request.prime)
    standard = [mont_mul(value, 1, p, np) for value in raw]
    rows = []
    for record in range(len(raw) // request.image_count):
        channels = []
        offset = record * request.image_count
        for base in range(request.base_count):
            for grade in range(request.grade_count):
                total = 0
                for sheet in range(request.grade_count):
                    value = standard[offset + base * request.grade_count + sheet]
                    total = (total - value if (sheet & grade).bit_count() & 1
                             else total + value) % p
                denominator = request.grade_count
                for k, roots in enumerate(request.positive_roots):
                    if grade & (1 << k):
                        denominator = denominator * roots[base] % p
                channels.append(total * pow(denominator, p - 2, p) % p)
        rows.append(channels)
    return rows


def write_dago(path: Path, request: Request, programs: Programs,
               rows: list[list[int]], parse_ns: int, evaluation_ns: int) -> None:
    with path.open("wb") as stream:
        stream.write(b"DAGO1V1\0")
        stream.write(struct.pack(
            "<13Q", 0, request.prime, len(request.roots), request.base_count,
            request.grade_count, len(programs.targets), programs.term_count,
            programs.unique_expression_count, *programs.dimensions,
            parse_ns, evaluation_ns,
        ))
        for target, values in zip(programs.targets, rows, strict=True):
            stream.write(struct.pack("<3Q", *target))
            stream.write(struct.pack(f"<{len(values)}Q", *values))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("request", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--max-batch-threads", type=int, default=1_000_000)
    args = parser.parse_args()
    started = time.perf_counter_ns()
    request = parse_request(args.request)
    authenticate_roots(request)
    programs = compile_preparation(args.input, request)
    parsed = time.perf_counter_ns()
    channels, timings = gpu_evaluate(request, programs, args.max_batch_threads)
    rows = [list(channels[start:start + request.image_count])
            for start in range(0, len(channels), request.image_count)]
    evaluated = time.perf_counter_ns()
    write_dago(args.output, request, programs, rows, parsed - started,
               evaluated - parsed)
    print(
        "Status=OK",
        f"Device={timings['device']!r}",
        f"Records={len(programs.targets)}",
        f"Terms={programs.term_count}",
        f"Instructions={len(programs.ops)}",
        f"Images={request.image_count}",
        f"JITms={timings['jit_s'] * 1e3:.3f}",
        f"Kernelms={timings['kernel_s'] * 1e3:.3f}",
        f"GPUmaxMiB={timings['gpu_bytes_max'] / 2**20:.2f}",
    )


if __name__ == "__main__":
    main()
