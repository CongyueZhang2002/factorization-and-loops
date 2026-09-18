# Rational closure and source-map composition

Actual ChatGPT6 Pro,6m32s, same EEC conversation:
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84.
Exact inspected revision:c7cd67493a87c7d7b9adf9350eed01624f9a3712.
Static inspection; no execution of our Wolfram tests or physics artifacts.

Confirmed: cancelling an identically zero rational coefficient of a typed GLI
does not use any integral relation or assume the integral vanishes. It is sound
before epsilon expansion and does not imply endpoint-distribution completeness.
Operator-aware predecessor discovery and exact bounded derivative acceptance
are also sound. One closing sample may trigger an exact attempt, never acceptance.

Found three orchestration gaps:

- Compose source maps instead of recursively unioning old and new rewrite rules.
  Example S=2A followed by A=S/2 is a valid representative change, but the union
  S->2A,A->S/2 cycles. Substitute the new closed basis images once into old
  closed source images, collect rational coefficients and remove identities.
- Carry the complete verified candidate-equivalence equations into derivative
  searches; source-target exports alone can omit cross-family identities for
  newly encountered auxiliary candidates.
- Propagate changed-input workspace selection at the bounded search root,
  before fixed Sample001/Exact001 subdirectories are created. Refusing changed
  input is safe, but unnecessarily blocks intentional enlargement.

For physical reuse, first batch FindMasterIntegralValues over the actual new
physical definitions and required orders, preserving PartialValues. For misses,
try verified covered-sector family maps to the DQ families and the accepted DQ
reduction. Such maps can expand a numerator into several donor GLIs. Cancel exact
donor coefficients before counting unknown values. Required donor upper order is
max_i(h_i - val_epsilon M_ij), with the usual omitted-tail audit. Transfer scalar
cuts, prescriptions, measures, domains and regulator coverage only; no amplitude
color/flavor factors. The two unsolved DQ coordinates cannot supply nonzero terms.

No published measured EEC coefficient was read or compared.
