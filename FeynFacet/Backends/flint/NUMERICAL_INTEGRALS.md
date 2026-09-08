# Compiled numerical evaluation

Build with `bash FeynFacet/Backends/flint/build_finite_integrals.sh`.
Requires a C++17 compiler, OpenMP, FLINT 3, GMP and MPFR. The executable lives
under the existing ignored `bin` directory. No runtime dependency is downloaded
or installed automatically.

`finite_integrals.cpp` evaluates the explicitly stored finite integrals,
using FLINT `acb` arbitrary-precision complex balls. It does not construct or
solve a differential equation. Arithmetic uncertainty is propagated inside
the native computation. Numerical quadrature error remains outside those
balls and is estimated by the reader's order, subdivision and precision
refinements. Final output assembly uses Wolfram arbitrary-precision arithmetic;
the overall result is not a rigorous enclosure.

The private text protocol `FFNI1` starts with working precision in bits,
thread count, quadrature order, panel count, instruction count, end of the
kernel instructions, integral count and kinematic-variable count.

Instructions represent constants (rational real and imaginary midpoints,
plus absolute uncertainty radii bounded by a power of two), coordinates,
the path parameter, earlier integrals, arithmetic, and elementary functions.
Their dependencies precede them. Each integral supplies the end of its
instruction range and the instruction containing its integrand. Program
validation rejects forward dependencies and unsupported operations.

Numerical inputs then supply the kinematic point, quadrature nodes, weights,
the interpolatory integration matrix and panel endpoints. The output `FFNO1`
contains each integral's final complex ball, with midpoint and radius encoded
as exact binary integers and exponents. No conversion through machine double
precision occurs. A separate value at every quadrature node is maintained for
each required earlier integral, including accumulation between panels.

The compiled arithmetic reuses registers after their last use. Independent
kernel evaluations at different quadrature nodes can use up to eight OpenMP
threads. Family/point batches instead use one thread per persistent Wolfram
worker to respect the total CPU allowance.

Principal elementary-function branches agree with the existing numerical
expressions in the tested ordinary domains. This is not a general analytic
continuation algorithm. Unsupported expressions select the Wolfram evaluator
under `"NumericalBackend"->Automatic`, or return a failure when `"FLINT"` is
explicitly requested.

The same build script also builds finite_taylor.cpp. Its private FFNT1
protocol supplies sparse entries of an ordinary-point coefficient DE as
rational functions, numerical center values, degree and precision. FLINT
expands each rational entry and computes
y[n+1] = Sum[B[a].y[n-a], {a,0,n}]/(n+1).
FFTO1 returns every computed coefficient as an exact binary complex ball.
The Wolfram interface determines epsilon-state closure before invoking it,
checks complex poles, and validates the requested master outputs against the
stored finite integrals. No assumption of a canonical epsilon form is made.

The Wolfram output reconstruction silences only N::meprec, which can otherwise
print very large exact-cancellation expressions. Finiteness, arithmetic
uncertainty and numerical-refinement checks still determine acceptance.
