# Frobenius initialization and Taylor continuation

`frobenius_taylor` evaluates one truncated series at arbitrary precision.
`Frobenius.wl` controls matching points, Taylor steps, precision and convergence.
It uses one native thread per family when run by the dynamic validation pool.

The header is:

```
FFFR1 bits threads order epsilon_width dimension entries nilpotency_index mode
```

`mode=0` initializes the logarithmic Frobenius series at a singular point;
`mode=1` takes an ordinary Taylor step. The connection supplied in either case
is z A(z,epsilon), regular jointly at z=epsilon=0. Center, displacement,
polynomial entries and the first seed use rational real/imaginary midpoints
with exact or power-of-two uncertainty fields. The output starts with
`FFFO1 dimension epsilon_width order`. Each coefficient has sixteen integer
fields: real and imaginary value balls, then real and imaginary tail balls.
Each real ball consists of midpoint mantissa, midpoint binary exponent,
radius mantissa, radius binary exponent.

`FFFR2` changes only the seed representation: each complex seed consists of
the eight integer value-ball fields from the preceding output. This retains
the actual dyadic midpoints and their nonnegative radii. Native reconstruction
rounds radii upwards if needed and includes them in every subsequent operation.
Malformed/truncated balls and negative radii fail. `FFFR1` also remains usable
for numerical seeds supplied by Wolfram and for existing running workers.

The Wolfram caller keeps the accepted native state separately from its
display/diagnostic numerical values. Rejected trial steps restart from the last
accepted state. A precision retry restarts from the original boundary data.
The conservative conversion to Wolfram accuracy is used for diagnostics and
final output, but is not repeatedly fed back into the native computation.

Native balls enclose arithmetic uncertainty for the truncated recurrence.
They do not include a proven infinite-series remainder: last-eight-order tails,
matching-point comparisons and independent reference comparisons provide
separate convergence evidence. Results explicitly retain
`ErrorEstimateIsRigorousBound -> False`.

Verification:

```
python3 Tests/Transport/t_frobenius_ball_transport.py
wolframscript -file Tests/Transport/t_numerical_frobenius.wls
```

`PhaseTimings` records input preparation, native process time and output
conversion. Successful Frobenius evaluations also report initialization and
continuation times; complete physical evaluations retain boundary precision
attempts, boundary continuation summaries and ordinary transport time.

Taylor-step proposals retain the successful radius fraction instead of retrying
the configured maximum after every accepted step. A local predictor uses the
first retained tail power (Taylor order minus seven), targets a tail ratio
of 10^-5, and limits growth to 5/4. Failed proposals halve the fraction; the next proposal cannot immediately grow after a rejected trial.
Every trial still satisfies the original geometric radius cap and the
unchanged tail-ratio acceptance threshold of 10^-3 and arithmetic check.
The predictor is a performance heuristic, not an error bound.
