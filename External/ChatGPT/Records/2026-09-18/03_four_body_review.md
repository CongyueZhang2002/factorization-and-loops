# Four-body coordinate and state review

Actual ChatGPT 6 Pro completed an 18 min 31 s review in the existing conversation:
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84

This is a summary, not a verbatim transcript. Pro inspected revision
`f126f8746890f09ea404e5bcd6d979412785771b` of the public repository. It did not
review subsequent polynomial-weight reduction or timelike-vertex changes.
No NLO EEC hard coefficient was supplied or compared.

## Conclusions

- The four-body invariant coordinates, absolute recursive phase-space factor,
  dimensional polar/azimuthal weights and transverse cross term are consistent.
- Reconstructing the rational source with the original unrestricted surviving
  propagators preserves the definition needed by later dotted-cut equations.
  Unit-cut numerator simplification is only a unit-cut identity and is used
  in a convergence domain followed by meromorphic continuation.
- The complete coherent final states have factors nf/2 for qqbgg, nf/4 for
  identical four-quark states, and nf(nf-1)/2 for distinct four-quark states.
  No further factor for the photon attachment is allowed. The inspected
  contraction sums attachments before squaring.
- One physical and one covariant final-gluon polarization sum is admissible
  for the complete gauge amplitude. The implemented physical projector
  contains the necessary term proportional to the reference momentum squared.
- No compensating normalization factor was recommended.

## Follow-up checks and scope

The exact Gram determinant and angular variances were added and pass. The
convergence metadata now states Re(epsilon)<1/2. Pro also recommended genuine
unit-cut cancellation, dotted-cut rejection and interior causal-pole rejection
tests, and a complete-amplitude Ward/relabeling check. Those additional tests
are not established merely by the current positive examples.

The coupling-order inventory should include the one-loop vector-current to
two-gluon amplitude squared, with its zero derived from generated amplitudes or
a general charge-conjugation/color identity. A component is now declared, but
its generated zero has not yet been recorded. This is not an omitted nonzero
contribution to the physical vector-current EEC.

The order-alpha_s UV source must be generated through epsilon^1 for the finite
order-alpha_s^2 result. Its existing final epsilon^0 records are insufficient;
source generation and the shared bare-coupling pole normalization must determine
this requirement before the counterterm is assembled.
