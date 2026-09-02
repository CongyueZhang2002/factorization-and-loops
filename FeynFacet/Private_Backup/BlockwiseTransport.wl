(* ==== moved whole from Private/Transport/BlockwiseTransport.wl on 2026-09-02 (user decision U1) ====
   Evidence: reachable only through the Libra path-ordered transport engines
   (TransportFamily / TransportPathArtifactRun), which the lazy-operator
   observable transport (Transport/ObservableTransport.wl) replaced as the
   production route; route_split.py: no helper of this module is used by
   ObservableTransport*, EpsForm or Geometry.
   This file is never loaded by FeynFacet.m. *)

(* Stage 2, block-wise engine: the family solution constructed
   RECURSIVELY ON THE BLOCK DAG instead of as one monolithic
   path-ordered exponential.

   Reached as TransportFamily[..., "Engine" -> "Blockwise"] (and hence
   also TransportFamilyInChart[..., "Engine" -> "Blockwise"], which
   forwards its options).  Everything before the transport -- assembly,
   the five-part conjugation certificate, the path restriction, the
   monic gate, the depth-budget arithmetic -- and everything after it --
   valuation constraints, the master series, the per-order check against
   the ORIGINAL family differential equation -- is MasterTransport's and
   is not duplicated here.  This file owns exactly the middle: how the
   canonical-frame solution F is built, and the exact certificate of the
   construction itself.

   WHY.  Measured (2026-08-16 night, README "Transport depth-vs-cost"):
   the monolithic Pexp of the 13x13 (CF230) and 24x24 (CF258) chart
   systems at weight 5-7 exceeded the engine's 1800 s budget three
   times.  The diagnosis in both reviews is word combinatorics over the
   UNION alphabet, not algebra swell: a monolithic Pexp at weight w over
   L letters carries L^w words in every entry, whether or not the block
   DAG can reach that entry.  Block-wise the count factorizes over the
   DAG, each block using only its own alphabet and only the orders it is
   actually asked for.

   THE RECURSION.  With the assembly's block-lower-triangular conjugated
   connection on the path, Ahat = sum_r eps^r Ahat^[r], and F the
   canonical-frame solution graded in eps,

     dF_{i,n}/dtau = sum_{j<=i} sum_r Ahat_ij^[r] F_{j,n-r},   (R)

   with the diagonal term j = i contributing only r >= 1 (the assembly
   certificate makes every diagonal block an epsilon-form, and
   masterTransportEpsShift refuses anything else as non-terminating).
   Integrating from the base point tau = 0,

     F_{i,n} = C_{i,n} + Int_0^tau sum_{j<=i} sum_r Ahat_ij^[r] F_{j,n-r}.

   Two facts make this the whole engine:

     (a) j = i needs r >= 1, so F_{i,n} reads only STRICTLY LOWER orders
         of its own block -- the recursion in n is well founded;
     (b) j < i is a strictly lower block in the DAG, so computing each
         block completely (over its own order window) in topological
         order satisfies every dependence, INCLUDING the ones that read
         a HIGHER order of a lower block, which is what a coupling of
         negative epsilon order does.  That is precisely what the
         module's per-block "Need" recursion budgets.

   WHY THERE IS NO Phi^-1 AND NO SHUFFLE PRODUCT.  The textbook form of
   the same statement is variation of constants,

     F_i = Phi_i [ C_i + Int Phi_i^-1 sum_j Ahat_ij F_j ],

   and it is what both reviews write down.  Implemented literally it
   costs two products of WORD-VALUED objects per block -- Phi_i^-1
   against the source, then Phi_i against the integral -- and a product
   of two iterated integrals is a SHUFFLE: G(u;tau) G(v;tau) = sum over
   Binomial[|u|+|v|,|u|] interleavings.  At weights 4 and 4 that is 70
   words for one product, and the count multiplies down the DAG.  Form
   (R) is the same solution with the Phi products already cancelled: its
   only operations are

     constant-rational matrix x word map      (linear, no new words)
     dlog x word map, integrated              (ONE word append per word)

   so the word count grows exactly like the Chen weight and never
   through a shuffle.  Phi_i is therefore not needed to BUILD the
   solution.  It is still computed -- once per distinct diagonal block
   connection, cached, by Libra -- and used as an INDEPENDENT check that
   the homogeneous part of (R) equals Phi_i . C_i word for word (option
   "PhiCrossCheck").  That is the mature-package cross-validation the
   house rules ask for, in the place where it is cheap: the diagonal
   blocks, which are small.

   REPRESENTATION.  A "word map" is an Association

     <| {a1,...,an} -> coefficient, ... |>,   {} the empty word,

   with the letters a_k and the coefficients exact rational functions of
   the kinematic variables, free of tau and (at a fixed epsilon order)
   free of eps.  It is converted to the module's inert
   TransportWord[{a1,...,an}, tau] only at the boundary, so a stored
   solution is exactly what the monolithic engine stores and every
   downstream consumer (valuation, master series, the original-DE check)
   works unchanged.  Nothing is ever expanded into a GPL basis, no
   global shuffle reduction is performed, and Together is applied per
   COEFFICIENT, never to a word-carrying expression (the measured reason
   is in MasterTransport.wl's header).

   THE INTEGRATION STEP, and the structural fact it needs -- MEASURED,
   not assumed.  Each epsilon-Laurent coefficient Ahat_ij^[r] is
   partial-fractioned in tau.  When it is pure dlog, sum_a R_a/(tau - a)
   with tau-free residues,

     Int_0^tau dlog(s - a) G(w; s) = G(a, w; tau),

   is one word APPEND per word and nothing else is needed.  Both reviews
   assume that this is always the case.  It is not.  S1 of the
   2026-08-16 campaign (Scripts/Diagnostics/blockwise_structure.wls) measured it on
   the actual target: for CF230 in the chart, 13 of the 18 nonzero block
   pairs are pure dlog, and the five couplings FROM block 6 (class 49,
   rows {8,9,10,11}) into the blocks below it carry poles in tau of
   order up to 3 together with a polynomial part.  The higher poles are
   not an artifact of expanding the regulator first: measured exactly in
   eps, the tau-carrying denominator factors of coupling (6,3) already
   have multiplicities {1,2,3}.  The decomposition is therefore VERIFIED per entry
   (entry - sum_a R_a/(tau - a) === 0, exactly) and, where it fails, the
   coupling goes through masterTransportBWIntegrateGeneral -- an exact
   integration by parts that stays inside the same word algebra and only
   promotes the coefficients from constants to rational functions of the
   path parameter.  Which (block pair, epsilon order) needed it is
   reported under "GeneralIntegrator", because that is a measurement
   about the family.

   THE CERTIFICATE.  The construction is checked, per block and per
   epsilon order, as the recursion (R) itself:

     d/dtau F_{i,n} - sum_{j<=i} sum_r Ahat_ij^[r] F_{j,n-r} == 0,

   with the derivative of each word taken by the module's OWN derivative
   rule, the derivative of each coefficient taken exactly, sparse
   collection by word, and an exact zero test per rational coefficient.
   Coefficient-wise vanishing is SUFFICIENT here, and that is a
   statement about the representation rather than a hope: every term of
   a word map is a SINGLE Chen word (products of words never arise, see
   above), and single iterated integrals over distinct dlog forms with
   tau-free letters are linearly independent over the field of rational
   functions.  So no Lyndon/fibration reduction is needed before the
   test -- but the hypothesis it rests on is checked, not assumed:
   masterTransportBWLetterCheck verifies that the canonicalized letters
   are pairwise distinct and that none of them sits at the base point
   (a letter at tau = 0 would make the iterated integrals divergent and
   the whole word representation shuffle-regularized rather than
   convergent).  If that check ever fails the engine refuses by name
   instead of reporting a zero it cannot justify.

   Together with the assembly's five-part certificate (which contains
   the exact gauge identity A = dT T^-1 + T Ahat T^-1 in the form
   "DiagonalEqualsDeclaredForm" plus flatness), the recursion
   certificate proves the original-basis solution.  The per-order check
   against the ORIGINAL family differential equation still runs
   afterwards, unchanged, as the independent statement it always was. *)

ClearAll[
  $masterTransportBlockwisePhiCache,
  $masterTransportBlockwiseApartCache,
  $masterTransportBlockwiseLinearizeCache,
  $masterTransportBlockwiseFailure,
  masterTransportBlockwiseCacheReset,
  masterTransportBWIntegrateTerm,
  masterTransportBWApartTerms,
  masterTransportBWIntegrateTermList,
  masterTransportBWIntegrateGeneral,
  masterTransportBWApplyGeneral,
  masterTransportBWCouplingRep,
  masterTransportBWCanon,
  masterTransportBWZeroQ,
  masterTransportBWLinearize,
  masterTransportBWPolePart,
  masterTransportBWPartialFractions,
  masterTransportBWLetterCheck,
  masterTransportBWDlogEntry,
  masterTransportBWDlogMatrix,
  masterTransportBWAddMap,
  masterTransportBWTogetherMap,
  masterTransportBWCombine,
  masterTransportBWIntegrate,
  masterTransportBWApply,
  masterTransportBWDerivative,
  masterTransportBWToExpression,
  masterTransportBWWordCount,
  masterTransportBWMaxWeight,
  masterTransportBWProductionZeroQ,
  masterTransportBWSchedule,
  masterTransportBWPhi,
  masterTransportBWPhiCrossCheck,
  masterTransportBlockwiseSolve
];

$masterTransportBlockwisePhiCache = <||>;
$masterTransportBlockwiseApartCache = <||>;
$masterTransportBlockwiseLinearizeCache = <||>;

(* Anomalies inside the integrator are thrown, never returned: a status
   Association returned where a word map is expected would be consumed as
   if it were a solution. *)
$masterTransportBlockwiseFailure = "masterTransportBlockwiseFailure";

masterTransportBlockwiseCacheReset[] := (
  $masterTransportBlockwisePhiCache = <||>;
  $masterTransportBlockwiseApartCache = <||>;
  $masterTransportBlockwiseLinearizeCache = <||>);

(* ------------------------------------------------------------------ *)
(*  word maps                                                          *)
(* ------------------------------------------------------------------ *)

(* Letters are canonicalized ONCE, when the connection is decomposed.
   The same pole reaches the connection in more than one syntactic form
   (1/(1-4v) from one leg, -1/(4v-1) from another); collecting on the
   raw form puts equal words in different buckets and manufactures a
   nonzero residual out of bookkeeping.  Same discipline as
   masterTransportNormalizeWords. *)
masterTransportBWCanon[a_] := masterTransportRadicalNormalize[Together[a]];

(* zero test for a tau-free or tau-dependent COEFFICIENT (word-free):
   Together decides over the rational functions; over an extension by
   radicals of the frozen variable the exact reduction in
   MasterTransport.wl decides. *)
masterTransportBWZeroQ[c_] :=
  TrueQ[Together[c] === 0] ||
  (masterTransportRadicalQ[c] && TrueQ[masterTransportRadicalZeroQ[c]]);

(* ---- algebraic letters --------------------------------------------

   The tau-dependent factors of a denominator, LINEARIZED over the
   extension: a factor linear in tau contributes its root; an
   irreducible quadratic a tau^2 + b tau + c contributes the two roots
   (-b +- k Sqrt[D0])/(2 a) with b^2 - 4 a c = k^2 D0, D0 square-free
   (masterTransportRadicalCanon in MasterTransport.wl).  A quadratic
   whose discriminant depends on the regulator is an eps-dependent locus
   -- an apparent singularity, never a letter -- and is refused by name;
   so is any factor of degree >= 3 (none has been measured; it would
   need a different representation).

   Returns <|"Poles" -> {<|"Letter", "Multiplicity", "Factor"|>, ...},
             "LeadingCoefficient" -> lc, "TauFree" -> the tau-free part|>
   such that   den == lc * TauFree * Product (tau - letter)^multiplicity
   EXACTLY over the extension (checked by the callers' reconstruction
   tests, not assumed here). *)
masterTransportBWLinearize[den_, tau_, eps_: None] := Module[
  {key, cached, factors, poles, lc, tauFree, result},
  key = {den, tau, eps};
  cached = Lookup[$masterTransportBlockwiseLinearizeCache, Key[key], None];
  If[AssociationQ[cached], Return[cached]];
  factors = FactorList[den];
  poles = {}; lc = 1; tauFree = 1;
  Do[
    Module[{f = factor[[1]], mult = factor[[2]], degree, a, b, c, disc, radical},
      If[FreeQ[f, tau],
        tauFree = tauFree f^mult,
        degree = Exponent[f, tau];
        Which[
          degree === 1,
            lc = lc Coefficient[f, tau, 1]^mult;
            AppendTo[poles, <|
              "Letter" -> masterTransportBWCanon[
                -Coefficient[f, tau, 0]/Coefficient[f, tau, 1]],
              "Multiplicity" -> mult, "Factor" -> f|>],
          degree === 2,
            a = Coefficient[f, tau, 2]; b = Coefficient[f, tau, 1];
            c = Coefficient[f, tau, 0];
            disc = Together[b^2 - 4 a c];
            If[eps =!= None && ! FreeQ[disc, eps],
              Throw[<|"Status" -> "EpsDependentQuadraticLetter", "Factor" -> f,
                "Discriminant" -> disc|>, $masterTransportBlockwiseFailure]];
            radical = masterTransportRadicalCanon[disc];
            lc = lc a^mult;
            AppendTo[poles, <|
              "Letter" -> masterTransportBWCanon[(-b + radical)/(2 a)],
              "Multiplicity" -> mult, "Factor" -> f, "Radical" -> radical|>];
            AppendTo[poles, <|
              "Letter" -> masterTransportBWCanon[(-b - radical)/(2 a)],
              "Multiplicity" -> mult, "Factor" -> f, "Radical" -> radical|>],
          True,
            Throw[<|"Status" -> "DenominatorDegreeAboveTwoInTau", "Factor" -> f,
              "Degree" -> degree|>, $masterTransportBlockwiseFailure]]]],
    {factor, factors}];
  result = <|"Poles" -> poles, "LeadingCoefficient" -> lc,
    "TauFree" -> tauFree|>;
  $masterTransportBlockwiseLinearizeCache[key] = result;
  result];

(* The pole part of e at tau = a, where a is a root of multiplicity m of
   the denominator of e:  sum_{j=1}^m c_j/(tau - a)^j.

   The (tau - a) factors are REMOVED BY CONSTRUCTION, never by cancelling
   against a denominator the kernel has not factored over the extension:
   with e = N/(lc * TauFree * (tau-a)^m * Product_{other}(tau - a_i)^{m_i}),
   g = e (tau - a)^m is written explicitly from the linearization, and
   c_j = g^{(m-j)}(a)/(m-j)!.  Substituting tau -> a into g is then a
   plain evaluation of a rational function that is regular there. *)
masterTransportBWPolePart[e_, tau_, linearized_Association, a_, m_Integer] :=
  Module[{t, num, g, others},
    t = Together[e];
    num = Numerator[t];
    others = Times @@ Table[
      If[TrueQ[masterTransportBWZeroQ[p["Letter"] - a]], 1,
        (tau - p["Letter"])^p["Multiplicity"]],
      {p, linearized["Poles"]}];
    g = num/(linearized["LeadingCoefficient"] linearized["TauFree"] others);
    Table[
      masterTransportBWCanon[
        (D[g, {tau, m - j}]/(m - j)!) /. tau -> a],
      {j, 1, m}]];

masterTransportBWAddMap[m1_Association, m2_Association] := Module[{out},
  out = m1;
  (* Lookup THREADS over a list-valued key: Lookup[a, {k1,k2}, 0] is a
     LIST of two lookups, not the value at the key {k1,k2}.  A word IS a
     list, so every accumulation here must wrap it in Key[].  (Reading
     with a[key] and writing with a[key] = v are exact-key operations and
     do not thread -- only Lookup does.)  Measured 2026-08-16: without
     Key[] every coefficient silently became a List and the recursion
     certificate failed on the NLO anchor. *)
  KeyValueMap[Function[{w, c}, out[w] = Lookup[out, Key[w], 0] + c], m2];
  out];

masterTransportBWTogetherMap[m_Association] := Module[{t},
  (* Production keeps the exact arithmetic DAG.  Canonicalizing every
     word coefficient independently made a 12,834-word CF303 order spend
     210 s in Together before any new mathematics happened.  Equal word
     keys have already been accumulated by the Association; the final
     pointwise certificate decides the unsimplified rational sums. *)
  If[masterTransportCheckLevel[] === "Production",
    Return[DeleteCases[m, 0]]];
  t = DeleteCases[Map[Together, m], 0];
  (* over an extension a vanishing coefficient need not Together to 0 *)
  If[masterTransportRadicalQ[t],
    t = Select[t, ! masterTransportBWZeroQ[#] &]];
  t];

(* out_i = sum_k mat[[i,k]] vec[[k]], with mat rational and tau-free *)
masterTransportBWCombine[mat_, vec_List] := Table[
  Module[{accumulate},
    accumulate = <||>;
    Do[
      If[! TrueQ[mat[[i, k]] === 0] && Length[vec[[k]]] > 0,
        KeyValueMap[
          Function[{w, c},
            accumulate[w] = Lookup[accumulate, Key[w], 0] + mat[[i, k]] c],
          vec[[k]]]],
      {k, Length[vec]}];
    accumulate],
  {i, Length[mat]}];

(* Int_0^tau (sum_a R_a dlog(s - a)) . vec(s) ds.

   One append per word -- BUT ONLY for a word whose coefficient is free
   of the path parameter.  Codex review 2026-08-16 item 1, and it is a
   soundness bug, not a refinement: the append rule states

     Int_0^tau c(s) dlog(s-a) G(w;s) ds  =  c(tau) G(a,w;tau),

   which is false as soon as c' =/= 0.  Codex's example, now test X1:
   c(s) = s on the empty word gives tau + a G(a;tau), while the append
   rule gives tau G(a;tau).  This matters the moment a higher-pole
   coupling has produced a rational coefficient and a later diagonal
   dlog step consumes it -- i.e. exactly on the families S1 measured as
   not pure dlog.  A tau-dependent coefficient is therefore routed
   through the full integrator, which carries c' correctly; the
   tau-free case keeps the cheap append, because it is the common case
   and one FreeQ decides between them. *)
masterTransportBWIntegrate[rep_Association, vec_List, dim_Integer, tau_] :=
  Module[{accumulate},
    accumulate = ConstantArray[<||>, dim];
    KeyValueMap[
      Function[{a, mat},
        Module[{contribution},
          contribution = masterTransportBWCombine[mat, vec];
          Do[
            If[Length[contribution[[i]]] > 0,
              KeyValueMap[
                Function[{w, c},
                  accumulate[[i]] = masterTransportBWAddMap[accumulate[[i]],
                    If[FreeQ[c, tau],
                      <|Prepend[w, a] -> c|>,
                      masterTransportBWIntegrateTerm[
                        Together[c/(tau - a)], w, tau]]]],
                contribution[[i]]]],
            {i, dim}]]],
      rep];
    accumulate];

(* ------------------------------------------------------------------ *)
(*  Integration when the coupling is NOT pure dlog                      *)
(* ------------------------------------------------------------------ *)

(* MEASURED, and the reason this section exists.  S1 of 2026-08-16
   (Scripts/Diagnostics/blockwise_structure.wls, record
   Results/.../EpsFormRoute/blockwise_structure_CF230.wl) partial-
   fractioned every epsilon-Laurent coefficient of every coupling of
   CF230 in the chart along the axis-aligned path.  Eleven of the
   fourteen block pairs are pure dlog with tau-free residues, exactly as
   both reviews assumed.  The five couplings OUT OF BLOCK 6 (class 49)
   are not: they carry poles in tau of order up to 3 and a polynomial
   part.  What removes them is the off-diagonal cleanup (the canonical
   bases of the block relative to its subsectors), not a per-class
   scalar gauge.  The reviews' word-append assumption is therefore FALSE for the
   actual target family, and an engine that appended anyway would be
   silently wrong.

   The general integral is still elementary and still exact.  For a
   coefficient c(s) rational in the path parameter and a word w,

     Int_0^tau c(s) G(w;s) ds

   is computed by partial-fractioning c in s and treating three cases:

     simple pole   q/(s-a)      ->  q G(a,w;tau)              (append)
     higher pole   q/(s-a)^k    ->  integration by parts,
        = -q/((k-1)(tau-a)^{k-1}) G(w;tau)
          + q/(k-1) Int_0^tau G(Rest w;s)/((s-a)^{k-1}(s-w1)) ds
     polynomial    p(s)         ->  integration by parts,
        = P(tau) G(w;tau) - Int_0^tau P(s) G(Rest w;s)/(s-w1) ds,
        P the antiderivative with P(0) = 0.

   The boundary terms at s = 0 vanish because every word vanishes at the
   base point (G(w;0) = 0 for w nonempty) -- which is exactly the
   hypothesis masterTransportBWLetterCheck enforces (no letter at the
   base point).  Each recursion step shortens the word by one letter, so
   it terminates in weight steps and introduces no new function class:
   the result is again a linear combination of the SAME single Chen
   words, now with RATIONAL FUNCTIONS OF THE PATH PARAMETER as
   coefficients instead of constants.  Nothing is expanded into a GPL
   basis and no shuffle is used.

   Everything downstream already tolerates tau-dependent coefficients:
   the certificate differentiates them exactly (product rule, below),
   the valuation step takes CoefficientList in tau of each collected
   coefficient, and the master series multiplies by a path-restricted T.
   The pure-dlog fast path is kept because it is the common case and it
   costs one append per word with no Apart at all. *)

(* Partial fractions in tau OVER THE EXTENSION.  Returns a list of terms

     <|"Kind" -> "Poly", "Antiderivative" -> P(tau)|>   (P(0) = 0)
     <|"Kind" -> "Pole", "Letter" -> a, "Power" -> k, "Residue" -> q|>

   with q tau-free, such that  e == P' + sum q/(tau - a)^k  EXACTLY.

   Apart does the bulk over the rational functions; a term whose
   denominator is (an irreducible quadratic)^k is then split into its
   pole parts at the two algebraic roots by masterTransportBWPolePart
   (explicit factorization).  The identity is CHECKED at the end with the
   radical-aware zero test -- a decomposition that does not reconstruct
   its input is thrown, never used. *)
masterTransportBWPartialFractions[e_, tau_] := Module[
  {t, parts, terms, out, reconstructed},
  t = Together[e];
  If[TrueQ[t === 0], Return[{}]];
  parts = Apart[t, tau];
  terms = If[Head[parts] === Plus, List @@ parts, {parts}];
  out = {};
  Do[
    Module[{s = Together[term], den, antiderivative, linearized, poles},
      den = Denominator[s];
      If[FreeQ[den, tau],
        antiderivative = Integrate[Expand[s], tau];
        AppendTo[out, <|"Kind" -> "Poly",
          "Antiderivative" -> Together[antiderivative -
            (antiderivative /. tau -> 0)]|>],
        linearized = masterTransportBWLinearize[den, tau];
        poles = linearized["Poles"];
        If[Length[poles] === 1 && FreeQ[den, Power[_, _Rational]],
          (* one linear factor over the rationals: Apart already isolated
             it, so the residue is a plain multiplication *)
          Module[{a = poles[[1]]["Letter"], k = poles[[1]]["Multiplicity"], q},
            q = Together[s (tau - a)^k];
            If[! FreeQ[q, tau],
              Throw[<|"Status" -> "ResidueNotConstantAfterApart", "Term" -> s|>,
                $masterTransportBlockwiseFailure]];
            AppendTo[out, <|"Kind" -> "Pole", "Letter" -> a, "Power" -> k,
              "Residue" -> masterTransportBWCanon[q]|>]],
          (* an irreducible quadratic (or a product that came back
             together after an earlier algebraic step): pole parts at
             every root, all orders *)
          Do[
            Module[{a = p["Letter"], m = p["Multiplicity"], coefficients},
              coefficients = masterTransportBWPolePart[s, tau, linearized, a, m];
              Do[
                If[! TrueQ[masterTransportBWZeroQ[coefficients[[j]]]],
                  AppendTo[out, <|"Kind" -> "Pole", "Letter" -> a, "Power" -> j,
                    "Residue" -> coefficients[[j]]|>]],
                {j, 1, m}]],
            {p, poles}]]]],
    {term, terms}];
  If[masterTransportCheckLevel[] =!= "Production",
    reconstructed = Together[t - Total[Table[
      If[u["Kind"] === "Poly", D[u["Antiderivative"], tau],
        u["Residue"]/(tau - u["Letter"])^u["Power"]],
      {u, out}]]];
    If[! masterTransportBWZeroQ[reconstructed],
      Throw[<|"Status" -> "PartialFractionsNotReconstructing", "Entry" -> t,
        "Residual" -> reconstructed|>, $masterTransportBlockwiseFailure]]];
  out];

masterTransportBWIntegrateTerm[c_, w_List, tau_] := Module[{terms, result},
  If[TrueQ[Together[c] === 0], Return[<||>]];
  terms = masterTransportBWPartialFractions[c, tau];
  result = <||>;
  Do[
    Module[{a, k, q, antiderivative},
      If[term["Kind"] === "Poly",
        (* ---- polynomial part ------------------------------------- *)
        antiderivative = term["Antiderivative"];
        If[w === {},
          result = masterTransportBWAddMap[result, <|{} -> antiderivative|>],
          result = masterTransportBWAddMap[result, <|w -> antiderivative|>];
          result = masterTransportBWAddMap[result,
            masterTransportBWIntegrateTerm[
              Together[-antiderivative/(tau - First[w])], Rest[w], tau]]],
        (* ---- a power of one linear factor (root possibly algebraic) *)
        a = term["Letter"]; k = term["Power"]; q = term["Residue"];
        If[k === 1,
          (* the pure-dlog case: one append *)
          result = masterTransportBWAddMap[result, <|Prepend[w, a] -> q|>],
          (* k >= 2: integration by parts *)
          If[w === {},
            result = masterTransportBWAddMap[result,
              <|{} -> Together[-q/((k - 1) (tau - a)^(k - 1)) +
                  q/((k - 1) (-a)^(k - 1))]|>],
            result = masterTransportBWAddMap[result,
              <|w -> Together[-q/((k - 1) (tau - a)^(k - 1))]|>];
            result = masterTransportBWAddMap[result,
              masterTransportBWIntegrateTerm[
                Together[q/((k - 1) (tau - a)^(k - 1) (tau - First[w]))],
                Rest[w], tau]]]]]],
    {term, terms}];
  result];

(* The partial fraction of ONE entry, computed once.

   MEASURED, and the reason this is separated from the integration: the
   couplings out of CF230's block 6 are rational functions of ~10^4-10^5
   leaves, while the source coefficients they multiply are small.
   Partial-fractioning the PRODUCT once per word (the obvious
   implementation) pays the expensive Apart once per word; partial-
   fractioning the ENTRY once and multiplying the small coefficient
   through afterwards pays it once per entry.  The word counts reach
   10^3 per block and order, so the two differ by three orders of
   magnitude on exactly the family this engine exists for. *)
masterTransportBWApartTerms[m_, tau_] := Module[{key, cached, terms},
  If[TrueQ[Together[m] === 0], Return[{}]];
  (* Codex review item 2: the same fixed coupling entry was
     partial-fractioned again for every epsilon order, every recursion
     order and the homogeneous pass, because the cache was local to one
     call.  Memoizing on the entry's content lifts it across all of
     them. *)
  (* The expression itself is already an exact Association key.  A
     cryptographic digest added a full serialization pass and could also
     conflate equal symbol names from different contexts. *)
  key = {m, tau};
  cached = Lookup[$masterTransportBlockwiseApartCache, Key[key], Missing[]];
  If[! MissingQ[cached], Return[cached]];
  (* the same decomposition the general integrator uses, over the
     extension when the entry has irreducible quadratic factors *)
  terms = masterTransportBWPartialFractions[m, tau];
  $masterTransportBlockwiseApartCache[key] = terms;
  terms];

(* Int_0^tau (sum of pre-decomposed terms)(s) c G(w;s) ds.  The same three
   cases as masterTransportBWIntegrateTerm, with the expensive Apart
   already done; the inner integrals that integration by parts generates
   carry SMALL coefficients (one or two linear factors), so they go
   through the general routine at negligible cost. *)
masterTransportBWIntegrateTermList[terms_List, c_, w_List, tau_] :=
  Module[{result},
    (* PRECONDITION, enforced rather than documented: these closed forms
       integrate the ENTRY and multiply by c afterwards, which is the
       primitive of the product only when c' = 0.  A tau-dependent c must
       go through masterTransportBWIntegrateTerm on the PRODUCT instead
       (Codex review 2026-08-16 item 1). *)
    If[! FreeQ[c, tau],
      Throw[<|"Status" -> "TauDependentCoefficientInTermList",
        "Coefficient" -> c|>, $masterTransportBlockwiseFailure]];
    result = <||>;
    Do[
      Module[{a, k, q, p},
        If[term["Kind"] === "Poly",
          p = term["Antiderivative"];
          If[w === {},
            result = masterTransportBWAddMap[result, <|{} -> c p|>],
            result = masterTransportBWAddMap[result, <|w -> c p|>];
            result = masterTransportBWAddMap[result,
              masterTransportBWIntegrateTerm[
                Together[-c p/(tau - First[w])], Rest[w], tau]]],
          a = term["Letter"]; k = term["Power"]; q = term["Residue"];
          If[k === 1,
            result = masterTransportBWAddMap[result, <|Prepend[w, a] -> c q|>],
            If[w === {},
              result = masterTransportBWAddMap[result,
                <|{} -> Together[c (-q/((k - 1) (tau - a)^(k - 1)) +
                    q/((k - 1) (-a)^(k - 1)))]|>],
              result = masterTransportBWAddMap[result,
                <|w -> Together[-c q/((k - 1) (tau - a)^(k - 1))]|>];
              result = masterTransportBWAddMap[result,
                masterTransportBWIntegrateTerm[
                  Together[c q/((k - 1) (tau - a)^(k - 1) (tau - First[w]))],
                  Rest[w], tau]]]]]],
      {term, terms}];
    result];

(* Int_0^tau M(s) . vec(s) ds for a matrix M of rational functions of the
   path parameter, with no assumption on its pole structure.  ONE Apart
   per matrix entry, then closed-form integration by parts per word. *)
masterTransportBWIntegrateGeneral[mat_, vec_List, dim_Integer, tau_] :=
  Module[{accumulate, decomposed},
    accumulate = ConstantArray[<||>, dim];
    decomposed = <||>;
    Do[
      Do[
        If[! TrueQ[Together[mat[[i, k]]] === 0] && Length[vec[[k]]] > 0,
          If[! KeyExistsQ[decomposed, {i, k}],
            decomposed[{i, k}] = masterTransportBWApartTerms[mat[[i, k]], tau]];
          KeyValueMap[
            Function[{w, c},
              accumulate[[i]] = masterTransportBWAddMap[accumulate[[i]],
                If[FreeQ[c, tau],
                  masterTransportBWIntegrateTermList[decomposed[{i, k}], c, w,
                    tau],
                  (* the entry's primitive times c is NOT the primitive of
                     the product once c depends on the path parameter, so
                     the PRODUCT is decomposed and integrated *)
                  masterTransportBWIntegrateTerm[
                    Together[mat[[i, k]] c], w, tau]]]],
            vec[[k]]]],
        {k, Length[vec]}],
      {i, dim}];
    accumulate];

(* M(tau) . vec(tau) WITHOUT integrating, for the certificate. *)
masterTransportBWApplyGeneral[mat_, vec_List, dim_Integer] :=
  masterTransportBWCombine[mat, vec];

(* the same product WITHOUT integrating: (sum_a R_a/(tau - a)) . vec.
   Used only by the certificate, where tau-dependent coefficients are
   expected and wanted. *)
masterTransportBWApply[rep_Association, vec_List, dim_Integer, tau_] :=
  Module[{accumulate},
    accumulate = ConstantArray[<||>, dim];
    KeyValueMap[
      Function[{a, mat},
        Module[{contribution},
          contribution = masterTransportBWCombine[mat, vec];
          Do[
            If[Length[contribution[[i]]] > 0,
              accumulate[[i]] = masterTransportBWAddMap[accumulate[[i]],
                Map[#/(tau - a) &, contribution[[i]]]]],
            {i, dim}]]],
      rep];
    accumulate];

(* d/dtau of a word map, by the module's own derivative rule
   d G(a,w;tau)/dtau = G(w;tau)/(tau - a).  The empty word is constant.
   B1/B2: the rule is ours and lives on TransportWord; this is the same
   rule applied to the map representation, and the two are checked
   against each other by masterTransportBWDerivativeAgrees below. *)
masterTransportBWDerivative[m_Association, tau_] := Module[{accumulate},
  accumulate = <||>;
  KeyValueMap[
    Function[{w, c},
      (* product rule.  A coefficient is tau-free in the pure-dlog case
         and rational in tau after an integration by parts, so both terms
         are needed and the tau-free case costs one FreeQ. *)
      Module[{dc},
        dc = If[FreeQ[c, tau], 0, Together[D[c, tau]]];
        If[! TrueQ[dc === 0],
          accumulate[w] = Lookup[accumulate, Key[w], 0] + dc];
        If[w =!= {},
          accumulate[Rest[w]] =
            Lookup[accumulate, Key[Rest[w]], 0] + c/(tau - First[w])]]],
    m];
  accumulate];

masterTransportBWToExpression[m_Association, tau_] :=
  Total[KeyValueMap[
    Function[{w, c}, c If[w === {}, 1, TransportWord[w, tau]]], m]];

masterTransportBWWordCount[m_Association] := Length[m];

masterTransportBWMaxWeight[m_Association] :=
  Max[Append[Length /@ Keys[m], 0]];

(* Production acceptance of an unsimplified coefficient map.  Boundary
   constants are independent indeterminates, so map them to temporary
   symbols and reuse the package's two-point exact-rational evaluator.
   A pole merely rejects that trial and draws another point. *)
masterTransportBWProductionZeroQ[values_List] := Module[
  {expressions, constants, constantSymbols, substituted, symbols,
   tries = 0, done = 0, rules, pointValues},
  expressions = DeleteCases[Flatten[{values}], 0];
  If[expressions === {}, Return[True]];
  constants = DeleteDuplicates[
    Cases[expressions, _TransportConstant, {0, Infinity}]];
  constantSymbols = Table[Unique["transportConstant$"], {Length[constants]}];
  substituted = expressions /. Thread[constants -> constantSymbols];
  symbols = DeleteDuplicates[Cases[substituted,
    s_Symbol /; Context[s] =!= "System`", {0, Infinity}]];
  While[done < 2 && tries < 12,
    tries++;
    rules = Thread[symbols ->
      RandomInteger[{3, 10^6}, Length[symbols]]/
        RandomInteger[{10^6, 10^7}, Length[symbols]]];
    pointValues = Quiet[Check[Together /@ (substituted /. rules), $Failed]];
    If[pointValues === $Failed ||
        ! FreeQ[pointValues,
          ComplexInfinity | Indeterminate | DirectedInfinity], Continue[]];
    If[! AllTrue[pointValues, masterTransportBWZeroQ], Return[False]];
    done++];
  done === 2];

(* ------------------------------------------------------------------ *)
(*  dlog decomposition of the connection, with its exact verification   *)
(* ------------------------------------------------------------------ *)

(* One entry.  Returns <|"Status" -> "OK", "Poles" -> <|a -> residue|>|>
   or a NAMED refusal.  The decomposition is not trusted: the exact
   identity entry == sum_a R_a/(tau - a) is checked, which rules out a
   polynomial part and any pole the factorization missed in one test. *)
masterTransportBWDlogEntry[entry_, tau_] := Module[
  {e, denominator, linearized, poles, letters, multiplicities, residues,
   reconstructed, numerator, numeratorDegree, denominatorDegree,
   denominatorDerivative},
  e = Together[entry];
  If[TrueQ[e === 0], Return[<|"Status" -> "OK", "Poles" -> <||>|>]];
  denominator = Denominator[e];
  If[FreeQ[denominator, tau],
    (* no pole in tau at all: then the entry is a polynomial in tau, and
       a nonzero one is exactly the polynomial part the word algebra
       cannot integrate by appending *)
    If[TrueQ[Together[e - (e /. tau -> 0)] === 0] && FreeQ[e, tau],
      Return[<|"Status" -> "NotPureDlogInTau", "Reason" -> "ConstantInTau",
        "Entry" -> e|>],
      Return[<|"Status" -> "NotPureDlogInTau", "Reason" -> "PolynomialPartInTau",
        "Degree" -> Exponent[Numerator[e], tau], "Entry" -> e|>]]];
  numeratorDegree = Exponent[Numerator[e], tau];
  denominatorDegree = Exponent[denominator, tau];
  If[numeratorDegree >= denominatorDegree,
    Return[<|"Status" -> "NotPureDlogInTau",
      "Reason" -> "PolynomialPartInTau", "Degree" -> numeratorDegree,
      "Entry" -> e|>]];
  (* linear factors give their root; irreducible quadratics give the two
     algebraic roots (see masterTransportBWLinearize); degree >= 3 and
     eps-dependent discriminants are thrown as named failures *)
  linearized = masterTransportBWLinearize[denominator, tau];
  poles = linearized["Poles"];
  multiplicities = #["Multiplicity"] & /@ poles;
  If[AnyTrue[multiplicities, # > 1 &],
    Return[<|"Status" -> "HigherPoleInTau", "Multiplicities" -> multiplicities,
      "Factors" -> DeleteDuplicates[#["Factor"] & /@ poles]|>]];
  letters = #["Letter"] & /@ poles;
  (* Every pole is simple, so N(a)/D'(a) is the residue.  This uses the
     denominator once for the whole entry instead of rebuilding the
     product of all other factors separately for every letter. *)
  numerator = Numerator[e];
  denominatorDerivative = D[denominator, tau];
  residues = Table[
    masterTransportBWCanon[
      (numerator/denominatorDerivative) /. tau -> letters[[k]]],
    {k, Length[letters]}];
  If[! FreeQ[residues, DirectedInfinity | Indeterminate | ComplexInfinity],
    Return[<|"Status" -> "HigherPoleInTau", "Reason" -> "ResidueNotFinite"|>]];
  (* In production this is already a constructive partial-fraction
     proof: Together made the fraction proper, FactorList found every
     denominator factor, every multiplicity is one, and PolePart
     computes the residues from that exact factorization.  Reassembling
     the same identity with another large Together was the dominant
     cost on CF303 and adds no independent information; the completed
     recursion is checked downstream.  Development retains the exact
     reconstruction as a diagnostic. *)
  If[masterTransportCheckLevel[] === "Production",
    Return[<|"Status" -> "OK",
      "Poles" -> Association[
        Table[letters[[k]] -> residues[[k]], {k, Length[letters]}]],
      "Verification" -> "ConstructiveFactorization"|>]];
  (* THE verification: the decomposition is an exact identity or it is
     refused.  This is what makes "pure dlog with constant residues" a
     measured fact of this connection rather than an assumption.  Over an
     extension by radicals the zero test is the exact reduction. *)
  reconstructed = Together[
    e - Sum[residues[[k]]/(tau - letters[[k]]), {k, Length[letters]}]];
  If[! masterTransportBWZeroQ[reconstructed],
    Return[<|"Status" -> "NotPureDlogInTau",
      "Reason" -> "ReconstructionNonzero",
      "Residual" -> reconstructed|>]];
  <|"Status" -> "OK",
    "Poles" -> Association[
      Table[letters[[k]] -> residues[[k]], {k, Length[letters]}]]|>];

(* One matrix -> <| letter -> residue MATRIX |>. *)
masterTransportBWDlogMatrix[m_, tau_] := Module[
  {rows, columns, decomposed, bad, letters, representation},
  rows = Length[m];
  columns = Length[First[m]];
  decomposed = Map[masterTransportBWDlogEntry[#, tau] &, m, {2}];
  bad = Cases[decomposed, a_Association /; a["Status"] =!= "OK", {2}];
  If[bad =!= {}, Return[First[bad]]];
  letters = DeleteDuplicates[
    Flatten[Table[Keys[decomposed[[i, k]]["Poles"]], {i, rows}, {k, columns}]]];
  (* M1: built in the body, never in a Module initializer that refers to
     another local of the same Module. *)
  representation = <||>;
  Do[
    Module[{matrix},
      matrix = Table[
        Lookup[decomposed[[i, k]]["Poles"], Key[a], 0],
        {i, rows}, {k, columns}];
      If[! AllTrue[Flatten[matrix], TrueQ[# === 0] &],
        representation[a] = matrix]],
    {a, letters}];
  <|"Status" -> "OK", "Rep" -> representation, "Letters" -> letters|>];

(* The two hypotheses the coefficient-wise zero test rests on, checked
   rather than assumed:

     - the canonicalized letters are pairwise distinct, so distinct word
       keys really are distinct iterated integrals;
     - no letter sits at the base point tau = 0, so every iterated
       integral CONVERGES and the representation is the ordinary
       (unregularized) one.

   A failure of either is refused by name.  Nothing downstream can
   compensate for them, and a zero test performed on top of a violated
   hypothesis is not a proof. *)
masterTransportBWLetterCheck[letters_List] := Module[{canonical, atBase, pairs},
  canonical = masterTransportBWCanon /@ letters;
  atBase = Select[canonical, masterTransportBWZeroQ];
  pairs = Select[
    Subsets[DeleteDuplicates[canonical], {2}],
    masterTransportBWZeroQ[#[[1]] - #[[2]]] &];
  <|"Distinct" -> (pairs === {}),
    "Collisions" -> pairs,
    "NoneAtBasePoint" -> (atBase === {}),
    "Letters" -> DeleteDuplicates[canonical],
    "Count" -> Length[DeleteDuplicates[canonical]]|>];

(* One epsilon-Laurent coefficient of one coupling, in the form the
   recursion consumes.  Pure dlog is the fast path (append, no Apart at
   all); anything else keeps the matrix and goes through the general
   integrator.  Which one was used is RECORDED per (i,j,r), because "this
   family needed integration by parts" is a measurement about the family,
   not an implementation detail. *)
masterTransportBWCouplingRep[mat_, tau_] := Module[{dlog, letters},
  dlog = masterTransportBWDlogMatrix[mat, tau];
  If[AssociationQ[dlog] && dlog["Status"] === "OK",
    Return[<|"Kind" -> "Dlog", "Rep" -> dlog["Rep"],
      "Letters" -> dlog["Letters"]|>]];
  (* not pure dlog: keep the matrix, and take the letters from the
     denominators so the letter hypothesis is still checked on them *)
  letters = DeleteDuplicates[Flatten[Map[
    Function[e,
      Module[{t = Together[e]},
        If[TrueQ[t === 0] || FreeQ[Denominator[t], tau], {},
          #["Letter"] & /@
            masterTransportBWLinearize[Denominator[t], tau]["Poles"]]]],
    mat, {2}]]];
  <|"Kind" -> "General", "Matrix" -> mat, "Letters" -> letters,
    "Reason" -> Lookup[dlog, "Status", "Unknown"]|>];

(* ------------------------------------------------------------------ *)
(*  the per-block schedule                                              *)
(* ------------------------------------------------------------------ *)

(* Three windows per block, all derived and none guessed:

     kmin_i   the order at which the block's CONSTANT vector starts,
              n0 + ord(T_i^-1) -- MasterTransport's own rule;
     top_i    the order to which the block must be SOLVED.  From the
              module's per-block Need recursion: a coupling of epsilon
              order r from block j into block i makes F_{i,n} read
              F_{j,n-r}, so top_j >= top_i - rmin_ij.  This is the
              module's masterTransportDepthBudget, used per block
              instead of collapsed into one global weight;
     low_i    the lowest order at which F_i can be nonzero.  The
              constant contributes from kmin_i; a coupling contributes
              from low_j + rmin_ij, which is BELOW low_j when the
              coupling has negative epsilon order.  Forward recursion
              down the DAG, the exact analogue of the monolithic
              engine's global kminF - shift, per block and therefore
              sharper. *)
masterTransportBWSchedule[rmin_, kminPerBlock_List, need_List] := Module[
  {nb, low},
  nb = Length[kminPerBlock];
  low = kminPerBlock;
  Do[
    Do[
      If[j < i && rmin[[i, j]] =!= Infinity,
        low[[i]] = Min[low[[i]], low[[j]] + rmin[[i, j]]]],
      {j, 1, i - 1}],
    {i, nb}];
  <|"Low" -> low, "Top" -> need, "KMin" -> kminPerBlock|>];

(* ------------------------------------------------------------------ *)
(*  Phi_i by Libra, cached per distinct diagonal connection             *)
(* ------------------------------------------------------------------ *)

(* The cache key is the CONTENT of the diagonal path connection (its
   canonicalized dlog representation), the weight, and the path -- not a
   class id.  Two blocks of the same class in the same family have
   literally the same conjugated diagonal block, and the 1119 blocks of
   the campaign draw on 173 classes, so keying on content gets the reuse
   the reviews ask for without trusting a label.

   Libra's weight grading and the epsilon grading COINCIDE here, because
   the diagonal block is a strict epsilon-form (assembly certificate
   "EpsFormLinear"): weight n carries exactly eps^n.  That is asserted,
   not assumed, by stripping eps^n and requiring the result to be
   eps-free. *)
masterTransportBWPhi[ahatDiagonal_, tau_, weight_Integer, root_String,
    eps_Symbol, base_, target_] := Module[
  {key, cached, backend, verification, stripped, dimension},
  dimension = Length[ahatDiagonal];
  key = Hash[{Map[Together, ahatDiagonal, {2}], weight, base, target,
    SymbolName[tau]}, "SHA256"];
  cached = Lookup[$masterTransportBlockwisePhiCache, key, Missing[]];
  If[! MissingQ[cached],
    Return[Join[cached, <|"CacheHit" -> True|>]]];
  backend = masterTransportBackendLibra[ahatDiagonal, tau, weight, root];
  If[! AssociationQ[backend] || backend["Status"] =!= "OK",
    Return[<|"Status" -> "PhiBackendFailed", "Backend" -> backend,
      "CacheHit" -> False|>]];
  (* the mandatory backend gate, unchanged: dU_n/dtau = M.U_{n-1} *)
  verification = masterTransportVerifyTransport[backend["U"], ahatDiagonal,
    tau, dimension];
  If[! TrueQ[verification["AllZero"]],
    Return[<|"Status" -> "PhiNotVerified", "Verification" -> verification,
      "CacheHit" -> False|>]];
  stripped = Table[
    Map[Together[#/eps^n] &, backend["U"][[n + 1]], {2}],
    {n, 0, weight}];
  If[! FreeQ[stripped, eps],
    Return[<|"Status" -> "PhiWeightIsNotEpsOrder", "CacheHit" -> False|>]];
  cached = <|"Status" -> "OK", "Phi" -> stripped, "Weight" -> weight,
    "Verification" -> verification|>;
  $masterTransportBlockwisePhiCache[key] = cached;
  Join[cached, <|"CacheHit" -> False|>]];

(* The independent statement: the homogeneous part of the recursion
   equals Phi_i . C_i, order by order and word by word.  Our engine and
   Libra construct the same object by different routes -- ours by
   integrating the recursion, Libra's by its own Pexp expansion -- so an
   exact agreement is a genuine cross-validation and not a tautology. *)
masterTransportBWPhiCrossCheck[homogeneous_, phi_List, constants_,
    range_List, kmin_Integer, qmax_Integer, low_Integer, top_Integer,
    tau_] := Module[{dimension, weight, verdicts},
  dimension = Length[range];
  weight = Length[phi] - 1;
  verdicts = Table[
    Module[{expected, actual, residual},
      expected = Table[
        Sum[
          If[0 <= n - q <= weight && KeyExistsQ[constants, q],
            Sum[phi[[n - q + 1, a, b]] constants[q][[b]], {b, dimension}],
            0],
          {q, kmin, qmax}],
        {a, dimension}];
      actual = Table[
        masterTransportBWToExpression[
          Lookup[homogeneous, Key[{n, a}], <||>], tau],
        {a, dimension}];
      residual = expected - actual;
      <|"Order" -> n,
        "Zero" -> DeleteDuplicates[masterTransportZeroQ /@ residual]|>],
    {n, Max[low, kmin], Min[top, kmin + weight]}];
  <|"Orders" -> Table[v["Order"], {v, verdicts}],
    "PerOrder" -> verdicts,
    "AllZero" -> AllTrue[verdicts, #["Zero"] === {True} &]|>];

(* ------------------------------------------------------------------ *)
(*  the engine                                                          *)
(* ------------------------------------------------------------------ *)

Options[masterTransportBlockwiseSolve] = {
  "Verbose" -> False,
  "PhiCrossCheck" -> Automatic,
  "PhiCrossCheckMaxWeight" -> 6,
  "ConstantDepth" -> Automatic,
  "Certify" -> True,
  "MaxWeight" -> 10,
  (* keep the internal per-block per-order word maps in the result.  Off
     by default (they are the bulk of the object); a diagnostic run turns
     them on to see WHICH word of WHICH block carries a residual. *)
  "KeepMaps" -> False,
  (* masterTransportExactDepth's record when the module carries it: its
     "Lowest" and "NMax" ARE this engine's per-block order windows, and
     they are computed from the FULL Laurent support of each coupling
     rather than from its lowest order alone.  Absent, the same two
     numbers are derived here from the module's rmin table, which is the
     same statement one notch coarser. *)
  "ExactDepth" -> None,
  (* the installation root the backend packages are loaded from; Automatic
     is the package's own root (generality pass 2026-08-23, B1: the
     default was one machine's absolute path) *)
  "Root" -> Automatic
};

(* assembly   the record masterTransportAssemble returned
   ahat       the path-restricted conjugated connection (one matrix)
   budget     masterTransportDepthBudget's record (Need, RMin)
   kminPerBlock, kmaxF, n0   MasterTransport's own depth arithmetic *)
masterTransportBlockwiseSolve[assembly_, ahat_, budget_, kminPerBlock_List,
    kmaxF_Integer, n0_Integer, tau_Symbol, eps_Symbol, variables_List,
    base_, target_, opts : OptionsPattern[]] := Catch[Module[
  {nb, ranges, dimensions, rmin, need, schedule, low, top, qmax,
   verbose, root, certify, phiOption, phiMaxWeight, maxWeight,
   couplings, letterRecord, allLetters, general, constants, solutionMaps,
   homogeneousMaps, certificates, wordCounts, coefficientSizes, start,
   status, failure, phiRecords, crossChecks, fVector, flow,
   perBlockWeight, decompositionSeconds, recursionSeconds,
   certificateSeconds, memory, trackHomogeneous},

  start = AbsoluteTime[];
  verbose = TrueQ[OptionValue["Verbose"]];
  root = masterTransportResolveInstallationRoot[OptionValue["Root"]];
  If[root === $Failed, Return[<|"Status" -> "InstallationRootUnavailable",
    "Root" -> OptionValue["Root"]|>]];
  certify = TrueQ[OptionValue["Certify"]];
  phiOption = OptionValue["PhiCrossCheck"];
  trackHomogeneous = phiOption =!= False;
  phiMaxWeight = OptionValue["PhiCrossCheckMaxWeight"];
  maxWeight = OptionValue["MaxWeight"];
  (* Denominators are family/path specific; retain their factorization
     across all entries and epsilon orders of this solve, then let the
     next solve start with a lean cache. *)
  masterTransportBlockwiseCacheReset[];

  nb = Length[assembly["Blocks"]];
  ranges = assembly["Ranges"];
  dimensions = Length /@ ranges;
  rmin = budget["RMin"];
  need = budget["Need"];

  (* ---- schedule ---------------------------------------------------- *)
  schedule = Module[{exact},
    exact = OptionValue["ExactDepth"];
    If[AssociationQ[exact] && Lookup[exact, "Status", None] === "OK" &&
       ListQ[Lookup[exact, "Lowest", None]] && Length[exact["Lowest"]] === nb &&
       ListQ[Lookup[exact, "NMax", None]] && Length[exact["NMax"]] === nb,
      <|"Low" -> exact["Lowest"], "Top" -> exact["NMax"],
        "KMin" -> kminPerBlock, "Route" -> "masterTransportExactDepth",
        "W" -> Lookup[exact, "W", None]|>,
      Join[masterTransportBWSchedule[rmin, kminPerBlock, need],
        <|"Route" -> "DepthBudgetNeed+ForwardLowestRecursion"|>]]];
  low = schedule["Low"];
  top = schedule["Top"];
  (* The constant window.  Automatic reproduces the monolithic engine's
     window EXACTLY (every block's constants run to the global kmaxF), so
     that a block-wise and a monolithic solve of the same family are the
     same general solution and can be compared entrywise.  "PerBlockNeed"
     extends each block's constants to its own Need, which is what the
     depth recursion says is required for the window to be complete when
     a coupling of negative epsilon order carries a lower block's
     constants UP into a higher block at a LOWER order.  The two agree
     whenever no coupling has negative epsilon order. *)
  qmax = Switch[OptionValue["ConstantDepth"],
    "PerBlockNeed", need,
    _, ConstantArray[kmaxF, nb]];
  perBlockWeight = Table[top[[i]] - low[[i]], {i, nb}];
  If[Max[perBlockWeight] > maxWeight,
    Return[<|"Status" -> "DepthExceedsCap", "Requested" -> Max[perBlockWeight],
      "Cap" -> maxWeight, "PerBlockWeight" -> perBlockWeight,
      "Schedule" -> schedule|>, Module]];

  masterTransportLog[verbose, "  blockwise: ", nb, " blocks, dims ", dimensions];
  masterTransportLog[verbose, "  blockwise schedule: low ", low, ", top ", top,
    ", constants to ", qmax, ", per-block weight ", perBlockWeight];

  (* ---- decompose every coupling into dlog + constant residues ------ *)
  decompositionSeconds = AbsoluteTime[];
  couplings = <||>;
  failure = None;
  allLetters = {};
  (* every (i,j,r) that needed the general integrator rather than the
     word append -- i.e. every place where the reviews' pure-dlog
     assumption is measurably false for this family *)
  general = {};
  Do[
    Do[
      If[i >= j && failure === None,
        Module[{sub, nonzero, r0, r1, laurent, reps},
          sub = ahat[[ranges[[i]], ranges[[j]]]];
          (* ahat was already canonicalized entrywise when the path
             connection was built.  A structural zero is therefore the
             only cheap screening needed here; every surviving entry is
             normalized exactly by the Laurent extractor.  Calling
             Together on every entry here repeated the dominant
             normalization before doing the actual decomposition. *)
          nonzero = DeleteCases[Flatten[sub], 0];
          If[nonzero =!= {},
            r0 = rmin[[i, j]];
            If[r0 === Infinity,
              r0 = Min[masterTransportEpsOrder[#, eps] & /@ nonzero]];
            (* the deepest order of this coupling that the recursion can
               ever read: F_{i,n} for n <= top_i reads F_{j,n-r}, and
               F_j is only nonzero from low_j upward *)
            r1 = top[[i]] - low[[j]];
            If[r1 >= r0,
              laurent = masterTransportLaurentMat[sub, {r0, r1}, eps];
              If[laurent === $Failed,
                failure = <|"Status" -> "LaurentFailed", "Block" -> {i, j}|>,
                reps = Table[
                  Module[{decomposed},
                    If[AllTrue[Flatten[laurent[[r - r0 + 1]]], TrueQ[# === 0] &],
                      None,
                      decomposed = masterTransportBWCouplingRep[
                        laurent[[r - r0 + 1]], tau];
                      allLetters = Join[allLetters, decomposed["Letters"]];
                      If[decomposed["Kind"] === "General",
                        general = Append[general,
                          <|"Block" -> {i, j}, "EpsOrder" -> r,
                            "Reason" -> decomposed["Reason"]|>]];
                      decomposed]],
                  {r, r0, r1}];
                If[failure === None,
                  couplings[{i, j}] = <|"R0" -> r0, "R1" -> r1, "Rep" -> reps|>]]]]]],
      {j, nb}],
    {i, nb}];
  (* ExactDepth retained the Laurent coefficients specifically for this
     decomposition pass.  The word recursion no longer needs their
     payload, while a later depth ledger can still reuse the support. *)
  masterTransportSupportCacheDropCoefficients[];
  If[failure =!= None,
    Return[Join[failure, <|"Schedule" -> schedule,
      "Seconds" -> AbsoluteTime[] - start|>], Module]];
  decompositionSeconds = AbsoluteTime[] - decompositionSeconds;

  (* the diagonal must be an epsilon-form: r >= 1, or the recursion in n
     is not well founded.  masterTransportEpsShift refuses the same
     structure globally; this is the local statement the recursion needs. *)
  Do[
    If[KeyExistsQ[couplings, {i, i}] && couplings[{i, i}]["R0"] < 1,
      failure = <|"Status" -> "DiagonalNotEpsForm", "Block" -> i,
        "Order" -> couplings[{i, i}]["R0"]|>],
    {i, nb}];
  If[failure =!= None,
    Return[Join[failure, <|"Schedule" -> schedule|>], Module]];

  letterRecord = masterTransportBWLetterCheck[allLetters];
  If[! (TrueQ[letterRecord["Distinct"]] && TrueQ[letterRecord["NoneAtBasePoint"]]),
    Return[<|"Status" -> "LetterHypothesisFailed", "Letters" -> letterRecord,
      "Schedule" -> schedule|>, Module]];
  masterTransportLog[verbose, "  blockwise: ", letterRecord["Count"],
    " distinct letters, none at the base point; couplings decomposed in ",
    Round[decompositionSeconds, 0.1], " s"];

  (* ---- symbolic constants, one vector per block per order ---------- *)
  constants = <||>;
  Do[
    Do[
      constants[{s, q}] = Table[TransportConstant[s, q, i],
        {i, dimensions[[s]]}],
      {q, kminPerBlock[[s]], qmax[[s]]}],
    {s, nb}];

  (* ---- THE RECURSION ---------------------------------------------- *)
  recursionSeconds = AbsoluteTime[];
  solutionMaps = <||>;
  homogeneousMaps = <||>;
  wordCounts = {};
  Do[
    Do[
      Module[{accumulate, homogeneous, seconds},
        seconds = AbsoluteTime[];
        accumulate = ConstantArray[<||>, dimensions[[i]]];
        homogeneous = If[trackHomogeneous,
          ConstantArray[<||>, dimensions[[i]]], None];
        (* the block's own constant enters at its own order *)
        If[kminPerBlock[[i]] <= n <= qmax[[i]],
          Do[
            accumulate[[a]] = masterTransportBWAddMap[accumulate[[a]],
              <|{} -> constants[{i, n}][[a]]|>];
            If[trackHomogeneous,
              homogeneous[[a]] = masterTransportBWAddMap[homogeneous[[a]],
                <|{} -> constants[{i, n}][[a]]|>]],
            {a, dimensions[[i]]}]];
        (* every source, integrated by ONE word append per word *)
        Do[
          If[KeyExistsQ[couplings, {i, j}],
            Module[{record, r0, r1},
              record = couplings[{i, j}];
              r0 = record["R0"]; r1 = record["R1"];
              Do[
                Module[{source, contribution},
                  If[record["Rep"][[r - r0 + 1]] =!= None &&
                     low[[j]] <= n - r <= top[[j]],
                    source = Table[
                      Lookup[solutionMaps, Key[{j, n - r, b}], <||>],
                      {b, dimensions[[j]]}];
                    If[AnyTrue[source, Length[#] > 0 &],
                      contribution = If[
                        record["Rep"][[r - r0 + 1]]["Kind"] === "Dlog",
                        masterTransportBWIntegrate[
                          record["Rep"][[r - r0 + 1]]["Rep"], source,
                          dimensions[[i]], tau],
                        masterTransportBWIntegrateGeneral[
                          record["Rep"][[r - r0 + 1]]["Matrix"], source,
                          dimensions[[i]], tau]];
                      Do[
                        accumulate[[a]] = masterTransportBWAddMap[
                          accumulate[[a]], contribution[[a]]],
                        {a, dimensions[[i]]}];
                      (* the homogeneous part of the SAME recursion: only
                         the diagonal propagation of this block's own
                         constants, which is what Phi_i . C_i must equal *)
                      If[trackHomogeneous && j === i,
                        Module[{homogeneousSource, homogeneousContribution},
                          homogeneousSource = Table[
                            Lookup[homogeneousMaps, Key[{i, n - r, b}], <||>],
                            {b, dimensions[[i]]}];
                          If[AnyTrue[homogeneousSource, Length[#] > 0 &],
                            homogeneousContribution = If[
                              record["Rep"][[r - r0 + 1]]["Kind"] === "Dlog",
                              masterTransportBWIntegrate[
                                record["Rep"][[r - r0 + 1]]["Rep"],
                                homogeneousSource, dimensions[[i]], tau],
                              masterTransportBWIntegrateGeneral[
                                record["Rep"][[r - r0 + 1]]["Matrix"],
                                homogeneousSource, dimensions[[i]], tau]];
                            Do[
                              homogeneous[[a]] = masterTransportBWAddMap[
                                homogeneous[[a]], homogeneousContribution[[a]]],
                              {a, dimensions[[i]]}]]]]]]],
                {r, r0, r1}]]],
          {j, 1, i}];
        Do[
          solutionMaps[{i, n, a}] = masterTransportBWTogetherMap[accumulate[[a]]];
          If[trackHomogeneous,
            homogeneousMaps[{i, n, a}] =
              masterTransportBWTogetherMap[homogeneous[[a]]]],
          {a, dimensions[[i]]}];
        AppendTo[wordCounts, <|
          "Block" -> i, "Order" -> n,
          "Words" -> Total[Table[
            masterTransportBWWordCount[solutionMaps[{i, n, a}]],
            {a, dimensions[[i]]}]],
          "MaxWeight" -> Max[Append[Table[
            masterTransportBWMaxWeight[solutionMaps[{i, n, a}]],
            {a, dimensions[[i]]}], 0]],
          "MaxCoefficientLeaves" -> Max[Append[Flatten[Table[
            LeafCount /@ Values[solutionMaps[{i, n, a}]],
            {a, dimensions[[i]]}]], 0]],
          "Seconds" -> AbsoluteTime[] - seconds|>];
        masterTransportLog[verbose, "  blockwise block ", i, "/", nb,
          " (dim ", dimensions[[i]], ") eps^", n, ": ",
          Last[wordCounts]["Words"], " words, max weight ",
          Last[wordCounts]["MaxWeight"], ", max coefficient leaves ",
          Last[wordCounts]["MaxCoefficientLeaves"], ", ",
          Round[Last[wordCounts]["Seconds"], 0.01], " s"]],
      {n, low[[i]], top[[i]]}],
    {i, nb}];
  recursionSeconds = AbsoluteTime[] - recursionSeconds;

  (* ---- the certificate: the recursion itself, exactly -------------- *)
  certificateSeconds = AbsoluteTime[];
  certificates = {};
  If[certify,
    Do[
      Do[
        Module[{lhs, rhs, residual, verdict, seconds},
          seconds = AbsoluteTime[];
          lhs = Table[
            masterTransportBWDerivative[Lookup[solutionMaps, Key[{i, n, a}], <||>], tau],
            {a, dimensions[[i]]}];
          rhs = ConstantArray[<||>, dimensions[[i]]];
          Do[
            If[KeyExistsQ[couplings, {i, j}],
              Module[{record, r0, r1},
                record = couplings[{i, j}];
                r0 = record["R0"]; r1 = record["R1"];
                Do[
                  If[record["Rep"][[r - r0 + 1]] =!= None &&
                     low[[j]] <= n - r <= top[[j]],
                    Module[{source, contribution},
                      source = Table[Lookup[solutionMaps, Key[{j, n - r, b}], <||>],
                        {b, dimensions[[j]]}];
                      If[AnyTrue[source, Length[#] > 0 &],
                        contribution = If[
                          record["Rep"][[r - r0 + 1]]["Kind"] === "Dlog",
                          masterTransportBWApply[
                            record["Rep"][[r - r0 + 1]]["Rep"], source,
                            dimensions[[i]], tau],
                          masterTransportBWApplyGeneral[
                            record["Rep"][[r - r0 + 1]]["Matrix"], source,
                            dimensions[[i]]]];
                        Do[rhs[[a]] = masterTransportBWAddMap[rhs[[a]],
                          contribution[[a]]], {a, dimensions[[i]]}]]]],
                  {r, r0, r1}]]],
            {j, 1, i}];
          (* sparse collection by word, then an exact zero test per
             rational coefficient.  No Together on a word-carrying
             expression anywhere. *)
          residual = Table[
            masterTransportBWAddMap[lhs[[a]], Map[-# &, rhs[[a]]]],
            {a, dimensions[[i]]}];
          (* the residual is kept AS A MAP (word -> coefficient) when it
             does not vanish: a bare list of coefficients names the size
             of the failure but not the word it sits on, and the word is
             what says which term of the recursion is wrong *)
          verdict = Table[
            Module[{nonzero},
              If[masterTransportCheckLevel[] === "Production",
                nonzero = DeleteCases[residual[[a]], 0];
                If[Length[nonzero] === 0 ||
                    masterTransportBWProductionZeroQ[Values[nonzero]],
                  True, nonzero],
                nonzero = Select[residual[[a]],
                  ! TrueQ[Together[#] === 0] &];
                nonzero = Select[nonzero,
                  ! masterTransportSimplifyZeroQ[#] &];
                If[Length[nonzero] === 0, True, nonzero]]],
            {a, dimensions[[i]]}];
          AppendTo[certificates, <|
            "Block" -> i, "Order" -> n,
            "Zero" -> AllTrue[verdict, TrueQ],
            "Residual" -> If[AllTrue[verdict, TrueQ], Null, verdict],
            "Words" -> Total[Table[Length[residual[[a]]], {a, dimensions[[i]]}]],
            "Seconds" -> AbsoluteTime[] - seconds|>];
          masterTransportLog[verbose, "  blockwise certificate block ", i,
            " eps^", n, ": zero ", Last[certificates]["Zero"], ", ",
            Round[Last[certificates]["Seconds"], 0.01], " s"]],
        {n, low[[i]], top[[i]]}],
      {i, nb}]];
  certificateSeconds = AbsoluteTime[] - certificateSeconds;

  (* ---- Phi_i by Libra, cached, as the independent cross-check ------ *)
  phiRecords = {}; crossChecks = {};
  If[phiOption =!= False,
    Do[
      Module[{weight, phi, cross},
        weight = Min[top[[i]] - kminPerBlock[[i]], phiMaxWeight];
        If[weight >= 0 && KeyExistsQ[couplings, {i, i}],
          phi = masterTransportBWPhi[ahat[[ranges[[i]], ranges[[i]]]], tau,
            weight, root, eps, base, target];
          AppendTo[phiRecords, Join[<|"Block" -> i, "Weight" -> weight|>,
            KeyDrop[phi, "Phi"]]];
          If[phi["Status"] === "OK",
            cross = masterTransportBWPhiCrossCheck[
              Association[Flatten[Table[{n, a} ->
                Lookup[homogeneousMaps, Key[{i, n, a}], <||>],
                {n, low[[i]], top[[i]]}, {a, dimensions[[i]]}]]],
              phi["Phi"],
              Association[Table[q -> constants[{i, q}],
                {q, kminPerBlock[[i]], qmax[[i]]}]],
              ranges[[i]], kminPerBlock[[i]], qmax[[i]], low[[i]], top[[i]], tau];
            AppendTo[crossChecks, Join[<|"Block" -> i|>, cross]];
            masterTransportLog[verbose, "  blockwise Phi cross-check block ", i,
              " (weight ", weight, ", cache ", If[TrueQ[phi["CacheHit"]],
                "HIT", "miss"], "): ", cross["AllZero"]]]]],
      {i, nb}]];

  (* ---- assemble the solution in MasterTransport's own shape -------- *)
  flow = Min[low];
  orders = Range[flow, kmaxF];
  fVector = Association @ Table[
    k -> Module[{total},
      total = ConstantArray[0, assembly["N"]];
      Do[
        If[low[[i]] <= k <= top[[i]],
          Do[
            total[[ranges[[i]][[a]]]] = masterTransportBWToExpression[
              Lookup[solutionMaps, Key[{i, k, a}], <||>], tau],
            {a, dimensions[[i]]}]],
        {i, nb}];
      total],
    {k, flow, kmaxF}];

  coefficientSizes = Max[Append[
    Table[record["MaxCoefficientLeaves"], {record, wordCounts}], 0]];
  memory = MaxMemoryUsed[];

  status = Which[
    ! certify, "SolvedNotCertified",
    AllTrue[certificates, TrueQ[#["Zero"]] &], "OK",
    True, "RecursionCertificateFailed"];

  <|"Status" -> status,
    "Solution" -> <|"F" -> fVector, "Constants" -> constants,
      "KMinPerBlock" -> kminPerBlock, "FLow" -> flow, "KMax" -> kmaxF|>,
    "Schedule" -> Join[schedule, <|"ConstantTop" -> qmax,
      "PerBlockWeight" -> perBlockWeight|>],
    "Letters" -> letterRecord,
    "GeneralIntegrator" -> <|
      "Sites" -> general,
      "Used" -> (general =!= {}),
      "Statement" -> "every (block pair, epsilon order) whose coupling is \
NOT pure dlog in the path parameter and therefore went through the exact \
integration-by-parts integrator instead of a word append"|>,
    "Certificate" -> <|
      "Statement" -> "dF_{i,n}/dtau - sum_{j<=i} sum_r Ahat_ij^[r] F_{j,n-r} \
== 0, per block and per epsilon order: exact derivative of every word by \
the module's own derivative rule, exact derivative of every coefficient, \
sparse collection by word, exact zero test per rational coefficient.",
      "Basis" -> "single Chen words over pairwise distinct tau-free letters, \
none at the base point, with rational-function coefficients; products of \
words never arise in this representation, so coefficient-wise vanishing is \
sufficient and no Lyndon/fibration reduction is needed",
      "PerBlockOrder" -> certificates,
      "AllZero" -> AllTrue[certificates, TrueQ[#["Zero"]] &],
      "Performed" -> certify,
      "Route" -> If[masterTransportCheckLevel[] === "Production",
        "TwoPointExactRational", "ExactRationalFunction"]|>,
    "Phi" -> <|"Records" -> phiRecords, "CrossChecks" -> crossChecks,
      "AllZero" -> (crossChecks === {} ||
        AllTrue[crossChecks, TrueQ[#["AllZero"]] &]),
      "Engine" -> "Libra (cached per distinct diagonal connection)"|>,
    "WordCounts" -> wordCounts,
    "MaxWordCount" -> Max[Append[
      Table[record["Words"], {record, wordCounts}], 0]],
    "MaxCoefficientLeaves" -> coefficientSizes,
    "Weight" -> Max[Append[
      Table[record["MaxWeight"], {record, wordCounts}], 0]],
    "Timing" -> <|"Decomposition" -> decompositionSeconds,
      "Recursion" -> recursionSeconds, "Certificate" -> certificateSeconds,
      "Total" -> AbsoluteTime[] - start|>,
    "PeakMemory" -> memory,
    "Maps" -> If[TrueQ[OptionValue["KeepMaps"]],
      <|"Solution" -> solutionMaps, "Homogeneous" -> homogeneousMaps,
        "Couplings" -> couplings|>, None],
    "Seconds" -> AbsoluteTime[] - start|>
], $masterTransportBlockwiseFailure];
