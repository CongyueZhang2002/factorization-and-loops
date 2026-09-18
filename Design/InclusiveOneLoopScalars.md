# Universal one-loop insertions in three-particle phase space

These are scalar integral inputs, independent of any measured hard function.
All particles are massless, labeled and future directed; q=sum(p_i), s=q^2>0,
D=4-2epsilon. The standard measure is product
d^(D-1)p_i/[(2pi)^(D-1)2E_i] times (2pi)^D delta^D(q-sum p_i).
No state factorial, flavor multiplicity, observable weight or amplitude is included.

## Bubble moments

Feynman parametrization of the normalized +i0 bubble gives

 B_ab(P2) = (-1)^(a+b) exp[(D/2-a-b)(log(P2)-i pi)]
   Gamma(a+b-D/2) Gamma(D/2-a) Gamma(D/2-b)
   /[Gamma(a) Gamma(b) Gamma(D-a-b)].

The measure here is d^D ell/(i pi^(D/2)); multiply by i pi^(D/2) for a raw
virtual loop. A massless one-propagator subloop with a polynomial numerator is
scaleless. Tensor moments use the full-D algebra, including all evanescent terms.

Let y=(s12,s13,s23)/s with sum(y)=1. The phase-space density is the unnormalized
Dirichlet density product y_i^(-epsilon), times

 N3=(4pi)^(2epsilon) s^(1-2epsilon)/(128pi^3 Gamma(2-2epsilon)).

Thus each monomial y^lambda integrates to

 N3 product Gamma(1-epsilon+lambda_i)
    /Gamma(3-3epsilon+sum lambda_i).

For a pair-invariant bubble, its timelike power adds an affine-epsilon exponent
to that pair's Dirichlet parameter. Remaining rational Laurent monomials give
a finite sum of Gamma products. Unsupported non-monomial denominators are not
assigned this value. The identity first holds on convergent exponent domains
and defines the continued scalar integral meromorphically.

`EvaluateOneLoopPhaseSpaceBubble` internally tensor-reduces the declared raw
subloop. FeynCalc supplies its i pi^2 PaVe normalization; the established scalar
function evaluator supplies pi^(-epsilon). Their product is precisely the raw
i pi^(D/2) conversion, applied once. The phase-space measure ratio is likewise
derived from the actual family's prefactor. Unit particle cuts are mandatory;
dotted virtual bubble powers can reduce to the same Gamma class.

## Inclusive one-mass scalar box

Define U8 as the standard three-particle phase space times 1/s12, with one
normalized virtual loop and four +i0 propagators at chords
(0,p1,p1+p3,q). The one-mass scalar box Euler representation gives

 U8 = (4pi)^(2e) s^(-2-3e)/(128pi^3 Gamma(2-2e))
      exp(i pi e) (2 rGamma/e^2) (2 I1-I3),
 rGamma=Gamma(1+e) Gamma(1-e)^2/Gamma(1-2e),
 I1=B(-2e,-2e) B(-e,-2e) 3F2(-e,-e,-e;1-e,-3e;1).

One independent Euler representation for the remaining term is

 I3=B(-2e,-2e) integral_0^1 dr r^(-1-e)(1-r)^(-1-2e)
       2F1(-2e,-2e;-4e;r) 2F1(-e,-e;1-e;r).

Introduce an auxiliary a^delta b^(-delta) in the original simplex. The three
Mellin-Barnes residue families at n and -e+-delta+n give a closed, convergent
3F2/4F3 identity and its delta derivative. That exact expression and the
independent numerical Euler check are retained in Pro record11 under
External/ChatGPT/Records/2026-09-18. Expanding its convergent Pochhammer sums gives

 I1=3/(2e^2)-17 Zeta(2)/2-32 Zeta(3)e-363 Zeta(4)e^2/8+O(e^3),
 I3=7/(4e^2)-29 Zeta(2)/4-22 Zeta(3)e-215 Zeta(4)e^2/16+O(e^3).

Together with Gamma(1-e) rGamma=1-2 Zeta(3)e^3-3 Zeta(4)e^4+O(e^5), this yields

 U8=(4pi)^(2e) s^(-2-3e) exp(i pi e)
     /[128pi^3 Gamma(1-e) Gamma(2-2e)]
     [5/(2e^4)-13pi^2/(4e^2)-89 Zeta(3)/e-1297pi^4/720+O(e)].

The provider uses this universal scalar expansion only after establishing an
exact prescribed momentum map to the reference integral. It converts the raw
family measure once and keeps the complex phase. The complete normalization's
Laurent valuation determines the required universal order; requests beyond
the available finite term fail. A coefficient needing positive scalar orders
must use the exact hypergeometric identity or a separately derived extension.
There is no fallback to a published measured coefficient.
