Please revise the scientific structure of our boundary-integral report. Use
concrete terms only: positive-denominator set, inclusion of denominator sets,
maximal denominator class, derivative-closed DE system, scalar endpoint
coefficient, boundary integral, and new analytic period. Do not use the word
normally used for the set of active propagators.

The exact NLO facts are:

1. Kira returns 6 masters: one cut bubble and five top instances.
2. Momentum relabeling gives 3 positive-denominator-set classes, of which 2
   are maximal and nontrivial.
3. The exact evaluator makes only 2 SubTropica calls. They determine
   B(epsilon)=2 Pi/(1-2 epsilon) and one generic top function
   T(z)=-Pi Hypergeometric2F1[1,1,1-epsilon,z]/
        (epsilon Lambda1 Lambda2).
4. The generic top endpoint is
   lim_{z->0+}[(Lambda1 Lambda2/Pi)T(z)+1/epsilon]=0.
5. All five physical top masters follow by substituting five cross ratios and
   scale pairs into this one T.

Therefore NLO needs exactly 2 analytic inputs total, or exactly 1 nontrivial
boundary integration if the elementary bubble is preloaded. Explain why this
differs from the count 2 of maximal denominator geometries.

The exact NNLO bookkeeping is 342 masters -> 130 powered classes -> 82
positive-denominator-set classes -> 17 maximal nontrivial denominator
classes. State clearly that 17 is not yet the number of SubTropica boundary
jobs. Explain the required sequence: construct exact DEs and merge derivative
mixing; determine local modes/Jordan blocks; impose regularity and lower
integrals; identify explicit boundary integrals; quotient changes of variables
and shared normalized periods.

Use the solved examples to distinguish counts: the 8-master coupled example
has modes x^0,x^-epsilon,x^-2epsilon and one new hard period; the 4-master
doubled-cut example uses one regulated two-region integral to determine two
scalar coefficients; the 5-master factorized example reuses the first hard
period and adds no new one.

Return a concise but self-contained replacement narrative suitable for a
physics PDF. Include the NLO derivation and an agent-work-queue conclusion.
Do not invent references or internal implementation claims.
