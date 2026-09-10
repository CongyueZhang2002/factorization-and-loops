# Phase-space denominator criterion and reduction scope

Model: gpt-6-pro; request HTTP status: 200.

Conversation: https://chatgpt.com/c/6a9fbe79-8c30-83e8-8bfb-e3ee1abad5f4

## Question

Review the mathematical validity and proper implementation scope of our phase-space denominator sign criterion before optimizing the upstream diagram -> partial fractions -> completed families -> Kira master-selection workflow. Please independently challenge the theorem and its use; do not assume that a past Pro review is correct. Current code commit: https://github.com/CongyueZhang2002/factorization-and-loops/commit/6594c2aca693b787a9abc358b705111cd814b9ec

Two future null incoming beams have s>0; n>=2 future null final momenta sum to the incoming total. For R=a ka+b kb+sum c_i p_i, real coefficients, the claimed exact closure range R^2/s is [min_{i!=j}(a+c_i)(b+c_j), max_{i!=j}(a+c_i)(b+c_j)]. A one-sign set with one nonzero entry is claimed strictly signed in the nonsoft, noncollinear interior (including no beam-collinear particles), allowing boundary zeros. It is constant-coefficient kinematic geometry, not a virtual-loop theorem. Linear P.Q is reduced to (P+Q)^2/2 only when both P^2 and Q^2 are identically zero on the full phase space.

Current code checks ALL completed uncut propagators, including unused completion ISPs. It rejects unsupported/mixed-sign cases, skips virtual-loop-dependent denominators, and returns only True/$Failed. It does not itself prove a convergence strip for the whole term. AMFlow prescription is generated separately as real cut integration directions 0, amplitude virtual +1, conjugate virtual -1.

Please address: (1) proof/counterexample, especially strict interior sign and n=2; (2) exact assumptions and meaning when some external kinematics are held fixed; (3) whether sign independence permits dropping Feynman i0, and what additional endpoint/meromorphic hypotheses are necessary; (4) whether unused or numerator-only ISPs should be rejected, versus restricting sectors/positive powers, without creating spurious cut singularities in selected masters; (5) cheap mathematically sound implementation improvements and essential adversarial tests. Recommend conservative behavior for unknown geometry, rather than removing a justified causal restriction. Keep conclusions practical and clearly scoped.

CURRENT CODE EXCERPT:
  forward = Lookup[setup, "ForwardAmplitudes", <||>];
  conjugate = Lookup[setup, "ConjugateAmplitudes", <||>];
  If[! AssociationQ[forward] || ! AssociationQ[conjugate],
    Return[$Failed]
  ];
  loops = {
    Lookup[forward, "LoopMomenta", {}],
    Lookup[conjugate, "LoopMomenta", {}]
  };
  If[! AllTrue[loops, ListQ], Return[$Failed]];
  DeleteDuplicates[Flatten[loops]]
];


momentumCoordinates[q_, basis_List] := Module[{coefficients, remainder},
  coefficients = Coefficient[Expand[q], #] & /@ basis;
  remainder = Expand[q - coefficients . basis];
  If[
    AllTrue[coefficients, exactRationalQ] && exactZeroQ[remainder],
    coefficients,
    $Failed
  ]
];


masslessSquareBounds[coefficients_List, finalCount_Integer] := Module[
  {a, b, c, values},
  If[Length[coefficients] =!= finalCount + 2, Return[$Failed]];
  a = coefficients[[1]];
  b = coefficients[[2]];
  c = Drop[coefficients, 2];
  values = Flatten @ Table[
    If[i === j, Nothing, (a + c[[i]]) (b + c[[j]])],
    {i, finalCount},
    {j, finalCount}
  ];
  {Min @@ values, Max @@ values}
];


safePropagatorData[setup_Association, propagator_] := Module[
  {
    partonRule, incoming, outgoing, partonMomenta, massless,
    virtualLoops, descriptor, coefficients, squareScale = 1,
    pairObjects, pair, pairScale, pairMomenta, pairCoordinates,
    rawBounds, scaledBounds, lower, upper, a, b, c, key, coreKey, first
  },

  partonRule = Lookup[setup, "PartonMomentum", Missing["NotFound"]];
  massless = Lookup[setup, "SetMassZero", Missing["NotFound"]];
  virtualLoops = setupVirtualLoopMomenta[setup];
  If[
    ! MatchQ[partonRule, Rule[_List, _List]] ||
      ! ListQ[massless] || virtualLoops === $Failed,
    Message[IdentifySafePropagator::setup];
    Return[$Failed]
  ];
  {incoming, outgoing} = List @@ partonRule;
  partonMomenta = Join[incoming, outgoing];
  If[
    Length[incoming] =!= 2 || Length[outgoing] < 2 ||
      ! DuplicateFreeQ[partonMomenta] ||
      ! ContainsAll[massless, partonMomenta],
    Message[IdentifySafePropagator::setup];
    Return[$Failed]
  ];
  If[AnyTrue[virtualLoops, ! FreeQ[propagator, #] &],
    Message[IdentifySafePropagator::virtual, propagator];
    Return[$Failed]
  ];

  descriptor = propagatorDescriptor[propagator];
  If[descriptor === $Failed,
    Message[IdentifySafePropagator::form, propagator];
    Return[$Failed]
  ];

  coefficients = Switch[descriptor["Type"],
    "QuadraticLorentzian",
      momentumCoordinates[descriptor["Momentum"], partonMomenta],
    "LinearLorentzian",
      pairObjects = Cases[
        descriptor["UnitCore"],
        pair_FeynCalc`Pair :> pair,
        {0, Infinity}
      ];
      If[Length[pairObjects] =!= 1, $Failed,
        pair = First[pairObjects];
        pairScale = Quiet @ Check[
          Cancel[Together[descriptor["UnitCore"]/pair]],
          $Failed
        ];
        pairMomenta = List @@ pair /. FeynCalc`Momentum[q_, ___] :> q;
        pairCoordinates = momentumCoordinates[#, partonMomenta] & /@
          pairMomenta;
        If[
          pairScale === $Failed || ! exactRationalQ[pairScale] ||
            exactZeroQ[pairScale] || MemberQ[pairCoordinates, $Failed] ||
            ! AllTrue[
              pairCoordinates,
              masslessSquareBounds[#, Length[outgoing]] === {0, 0} &
            ],
          $Failed,
          squareScale = pairScale/2;
          Total[pairCoordinates]
        ]
      ],
    _, $Failed
  ];
  If[coefficients === $Failed,
    Message[IdentifySafePropagator::form, propagator];
    Return[$Failed]
  ];

  a = coefficients[[1]];
  b = coefficients[[2]];
  c = Drop[coefficients, 2];
  rawBounds = masslessSquareBounds[coefficients, Length[outgoing]];
  scaledBounds = squareScale rawBounds;
  lower = Min @@ scaledBounds;
  upper = Max @@ scaledBounds;
  coreKey = Join[a + c, b + c];
  first = FirstCase[coreKey, value_ /; value =!= 0, 0];
  If[first < 0, coreKey = -coreKey];
  key = Prepend[coreKey, squareScale];

  {key, lower, upper, propagator}
];


IdentifySafePropagator[setup_Association, propagator_] := Module[{data},
  data = safePropagatorData[setup, propagator];
  If[data === $Failed, Return[$Failed]];
  If[TrueQ[
      (data[[2]] >= 0 && data[[3]] > 0) ||
        (data[[2]] < 0 && data[[3]] <= 0)
    ],
    True,
    Message[
      IdentifySafePropagator::unsafe,
      propagator,
      data[[2]],
      data[[3]]
    ];
    $Failed
  ]
];

IdentifySafePropagator[setup_, propagator_] := (
  Message[IdentifySafePropagator::setup];
  $Failed
);


checkCompletedPropagators[setup_Association, families_List] := Module[
  {virtualLoops, propagators, candidates, data, unique},
  virtualLoops = setupVirtualLoopMomenta[setup];
  If[virtualLoops === $Failed,
    Message[IdentifySafePropagator::setup];
    Return[$Failed]
  ];
  propagators = Flatten @ Map[
    Function[family,
      With[
        {
          all = family["Topology"][[2]],
          cuts = family["CutIndices"]
        },
        all[[Complement[Range[Length[all]], cuts]]]
      ]
    ],
    families
  ];
  candidates = Select[
    propagators,
    Function[propagator,
      AllTrue[virtualLoops, FreeQ[propagator, #] &]
    ]
  ];
  data = safePropagatorData[setup, #] & /@ candidates;
  If[MemberQ[data, $Failed], Return[$Failed]];
  unique = DeleteDuplicatesBy[data, First];
  If[AnyTrue[
      unique,
      ! TrueQ[(#[[2]] >= 0 && #[[3]] > 0) ||
        (#[[2]] < 0 && #[[3]] <= 0)] &
    ],
    With[{bad = SelectFirst[
        unique,
        ! TrueQ[(#[[2]] >= 0 && #[[3]] > 0) ||
          (#[[2]] < 0 && #[[3]] <= 0)] &
      ]},
      Message[
        IdentifySafePropagator::unsafe,
        bad[[4]],
        bad[[2]],
        bad[[3]]
      ]
    ];
    Return[$Failed]
  ];
  True
];

PRIOR PROOF TO AUDIT:
\section{Exact fixed-sign test for non-virtual massless denominators}
\label{app:fixed-sign}

This appendix considers quadratic denominators whose momentum depends only on
the two physical incoming beams and on real on-shell final-state momenta.  It
does not apply to a denominator containing a virtual loop momentum.

\subsection{Physical domain and statement of the theorem}

Let \(n\geq2\), and let \(k_a\) and \(k_b\) be future-directed null incoming
momenta satisfying
\begin{equation}
 k_a^2=k_b^2=0,
 \qquad
 s:=2k_a\cdot k_b>0.
 \label{eq:sign-theorem-kinematics}
\end{equation}
Define
\begin{equation}
 P:=k_a+k_b,
 \qquad
 P^2=s.
 \label{eq:sign-theorem-total-momentum}
\end{equation}
The closure of the physical massless \(n\)-particle phase space is
\begin{equation}
 \overline{\Omega}_n(P)
 :=
 \left\{
  (p_1,\ldots,p_n)\ \middle|\
  p_i^2=0,\quad p_i^0\geq0,\quad
  \sum_{i=1}^{n}p_i=P
 \right\}.
 \label{eq:closed-massless-phase-space}
\end{equation}
Soft momenta and collinear configurations are included in
\(\overline{\Omega}_n(P)\).

The nonsoft and noncollinear interior used below is
\begin{align}
 \Omega_n^\circ(P)
 :=
 \Bigl\{
  (p_1,\ldots,p_n)\in\overline{\Omega}_n(P)
  \ \Bigm|\
  &p_i^0>0,\quad
  k_a\cdot p_i>0,\quad
  k_b\cdot p_i>0,
  \notag\\
  &p_i\cdot p_j>0
  \quad\text{for all }i\neq j
 \Bigr\}.
 \label{eq:open-massless-phase-space}
\end{align}

For real coefficients \(a,b,c_1,\ldots,c_n\), consider the momentum
\begin{equation}
 R
 :=
 ak_a+bk_b+\sum_{i=1}^{n}c_ip_i.
 \label{eq:sign-theorem-linear-combination}
\end{equation}
Momentum conservation makes the coefficient representation redundant:
\begin{equation}
 (a,b,c_1,\ldots,c_n)
 \longmapsto
 (a+\tau,b+\tau,c_1-\tau,\ldots,c_n-\tau)
 \label{eq:sign-theorem-coefficient-redundancy}
\end{equation}
leaves \(R\) unchanged for every \(\tau\in\mathbb R\).  The combinations
\begin{equation}
 A_i:=a+c_i,
 \qquad
 B_i:=b+c_i
 \label{eq:sign-theorem-invariant-coefficients}
\end{equation}
are invariant under Eq.~\eqref{eq:sign-theorem-coefficient-redundancy}.
For every ordered pair \(i\neq j\), define
\begin{equation}
 \mu_{ij}:=A_iB_j=(a+c_i)(b+c_j).
 \label{eq:sign-theorem-mu}
\end{equation}

\paragraph{Theorem.}
For every point of \(\overline{\Omega}_n(P)\),
\begin{equation}
 \min_{i\neq j}\mu_{ij}
 \leq
 \frac{R^2}{s}
 \leq
 \max_{i\neq j}\mu_{ij}.
 \label{eq:fixed-sign-bound}
\end{equation}
Both bounds are exact:
\begin{align}
 \min_{(p_1,\ldots,p_n)\in\overline{\Omega}_n(P)}
 \frac{R^2}{s}
 &=
 \min_{i\neq j}\mu_{ij},
 \notag\\
 \max_{(p_1,\ldots,p_n)\in\overline{\Omega}_n(P)}
 \frac{R^2}{s}
 &=
 \max_{i\neq j}\mu_{ij}.
 \label{eq:fixed-sign-exact-extrema}
\end{align}
Consequently,
\begin{align}
 R^2\geq0
 \quad\text{on }\overline{\Omega}_n(P)
 &\quad\Longleftrightarrow\quad
 \mu_{ij}\geq0
 \quad\text{for every }i\neq j,
 \label{eq:nonnegative-iff}\\
 R^2\leq0
 \quad\text{on }\overline{\Omega}_n(P)
 &\quad\Longleftrightarrow\quad
 \mu_{ij}\leq0
 \quad\text{for every }i\neq j.
 \label{eq:nonpositive-iff}
\end{align}
If all \(\mu_{ij}\geq0\) and at least one \(\mu_{ij}>0\), then
\begin{equation}
 R^2>0
 \qquad
 \text{throughout }\Omega_n^\circ(P).
 \label{eq:strictly-positive-interior}
\end{equation}
Similarly, if all \(\mu_{ij}\leq0\) and at least one
\(\mu_{ij}<0\), then
\begin{equation}
 R^2<0
 \qquad
 \text{throughout }\Omega_n^\circ(P).
 \label{eq:strictly-negative-interior}
\end{equation}
Thus zeros are admitted on soft or collinear boundary strata.  If every
\(\mu_{ij}=0\), then \(R^2\) vanishes identically on the whole phase space.

\subsection{Normalized scalar products}

Introduce
\begin{equation}
 x_i:=\frac{2k_b\cdot p_i}{s},
 \qquad
 y_i:=\frac{2k_a\cdot p_i}{s},
 \qquad
 z_{ij}:=\frac{2p_i\cdot p_j}{s}=z_{ji},
 \qquad
 i\neq j.
 \label{eq:sign-edge-data}
\end{equation}
Future-directedness implies
\begin{equation}
 x_i\geq0,
 \qquad
 y_i\geq0,
 \qquad
 z_{ij}\geq0.
 \label{eq:sign-edge-positivity}
\end{equation}
Using
\(\sum_i p_i=k_a+k_b\), one obtains
\begin{equation}
 \sum_{i=1}^{n}x_i
 =
 \sum_{i=1}^{n}y_i
 =
 1,
 \qquad
 x_i+y_i
 =
 \sum_{j\neq i}z_{ij},
 \qquad
 \sum_{1\leq i<j\leq n}z_{ij}=1.
 \label{eq:sign-edge-relations}
\end{equation}

For a subset
\begin{equation}
 A\subseteq\{1,\ldots,n\},
 \label{eq:sign-subset}
\end{equation}
define
\begin{equation}
 K_A:=\sum_{i\in A}p_i,
 \qquad
 x_A:=\sum_{i\in A}x_i,
 \qquad
 y_A:=\sum_{i\in A}y_i,
 \qquad
 z_A:=\sum_{\substack{i<j\\i,j\in A}}z_{ij}.
 \label{eq:sign-subset-data}
\end{equation}
The Sudakov decomposition of \(K_A\) is
\begin{equation}
 K_A
 =
 x_Ak_a+y_Ak_b+K_{A\perp},
 \qquad
 K_{A\perp}\cdot k_a
 =
 K_{A\perp}\cdot k_b
 =
 0.
 \label{eq:subset-sudakov-decomposition}
\end{equation}
Define
\begin{equation}
 \kappa_A:=-\frac{K_{A\perp}^2}{s}\geq0.
 \label{eq:subset-transverse-square}
\end{equation}
Since \(K_A^2/s=z_A\),
Eq.~\eqref{eq:subset-sudakov-decomposition} gives
\begin{equation}
 z_A=x_Ay_A-\kappa_A.
 \label{eq:subset-invariant}
\end{equation}
Because \(0\leq x_A,y_A\leq1\),
\begin{align}
 \frac{(k_b-K_A)^2}{s}
 &=
 z_A-x_A
 =
 -x_A(1-y_A)-\kappa_A
 \leq0,
 \notag\\
 \frac{(k_a-K_A)^2}{s}
 &=
 z_A-y_A
 =
 -y_A(1-x_A)-\kappa_A
 \leq0.
 \label{eq:subset-inequality}
\end{align}
Hence
\begin{equation}
 z_A\leq x_A,
 \qquad
 z_A\leq y_A
 \qquad
 \text{for every }A\subseteq\{1,\ldots,n\}.
 \label{eq:subset-flow-inequalities}
\end{equation}

For every nonempty proper subset \(A\), the inequalities are strict in
\(\Omega_n^\circ(P)\).  Indeed,
\begin{equation}
 x_A>0,
 \qquad
 1-y_A=y_{A^c}>0,
 \label{eq:strict-subset-conditions}
\end{equation}
and therefore
\begin{equation}
 x_A-z_A
 =
 x_A(1-y_A)+\kappa_A
 >0.
 \label{eq:strict-subset-inequality}
\end{equation}
The analogous statement holds with \(x\) and \(y\) interchanged.

\subsection{Flow decomposition}

Consider a directed network with:

\begin{enumerate}
 \item a source node \(s_0\);
 \item one edge node \(e_{ij}=e_{ji}\) for every unordered pair \(i<j\);
 \item one vertex node \(v_i\) for every final-state label \(i\);
 \item a sink node \(t_0\).
\end{enumerate}

Assign capacities
\begin{align}
 s_0\longrightarrow e_{ij}
 &: z_{ij},
 \notag\\
 e_{ij}\longrightarrow v_i,
 \quad
 e_{ij}\longrightarrow v_j
 &: \infty,
 \notag\\
 v_i\longrightarrow t_0
 &: x_i,
 \label{eq:sign-flow-network}
\end{align}
where \(\infty\) denotes any capacity larger than the total possible flow,
which is one.

For a fixed set \(A\) of vertex nodes on the source side of a finite cut,
the minimum cut of that form places \(e_{ij}\) on the source side exactly
when \(i,j\in A\).  Its capacity is
\begin{equation}
 \operatorname{cap}(A)
 =
 1-z_A+x_A.
 \label{eq:sign-cut-capacity}
\end{equation}
Equation~\eqref{eq:subset-flow-inequalities} implies
\begin{equation}
 \operatorname{cap}(A)\geq1
 \qquad
 \text{for every }A.
 \label{eq:sign-min-cut-bound}
\end{equation}
Since the total capacity leaving \(s_0\) is one, the max-flow/min-cut theorem
therefore gives a flow of total value one.

Let \(\lambda_{ij}\) be the flow from the edge node \(e_{ij}\) into
the vertex node \(v_i\).  Saturation of the source and sink capacities gives
nonnegative numbers satisfying
\begin{equation}
 \lambda_{ij}+\lambda_{ji}=z_{ij},
 \qquad
 \sum_{j\neq i}\lambda_{ij}=x_i,
 \qquad
 \sum_{i\neq j}\lambda_{ij}=y_j,
 \qquad
 \sum_{i\neq j}\lambda_{ij}=1.
 \label{eq:edge-orientation}
\end{equation}
The third relation follows from the first two and
Eq.~\eqref{eq:sign-edge-relations}:
\begin{equation}
 \sum_{i\neq j}\lambda_{ij}
 =
 \sum_{i\neq j}z_{ij}
 -
 \sum_{i\neq j}\lambda_{ji}
 =
 x_j+y_j-x_j
 =
 y_j.
 \label{eq:edge-column-marginal}
\end{equation}

In the open domain \(\Omega_n^\circ(P)\), the \(\lambda_{ij}\) may be chosen
strictly positive.  To see this, choose \(\delta>0\) such that
\begin{equation}
 2\delta<\min_{i<j}z_{ij},
 \qquad
 \delta<
 \min_{\varnothing\neq A\subsetneq\{1,\ldots,n\}}
 \frac{x_A-z_A}{|A|(n-|A|)}.
 \label{eq:strict-flow-delta}
\end{equation}
Define
\begin{equation}
 z_{ij}^{(\delta)}:=z_{ij}-2\delta,
 \qquad
 x_i^{(\delta)}:=x_i-(n-1)\delta.
 \label{eq:strict-flow-reduced-data}
\end{equation}
For every nonempty proper \(A\),
\begin{equation}
 x_A^{(\delta)}-z_A^{(\delta)}
 =
 x_A-z_A-|A|(n-|A|)\delta
 \geq0.
 \label{eq:strict-flow-reduced-inequality}
\end{equation}
The same flow argument therefore produces
\(\lambda_{ij}^{(\delta)}\geq0\) for the reduced data.  Then
\begin{equation}
 \lambda_{ij}:=\lambda_{ij}^{(\delta)}+\delta
 \label{eq:strict-flow-positive-solution}
\end{equation}
satisfies Eq.~\eqref{eq:edge-orientation} and obeys
\begin{equation}
 \lambda_{ij}>0
 \qquad
 \text{for every }i\neq j.
 \label{eq:strict-flow-positivity}
\end{equation}

\subsection{Convex representation and exact extrema}

Expanding Eq.~\eqref{eq:sign-theorem-linear-combination} gives
\begin{equation}
 \frac{R^2}{s}
 =
 ab
 +a\sum_{i=1}^{n}c_i y_i
 +b\sum_{i=1}^{n}c_i x_i
 +\sum_{1\leq i<j\leq n}c_ic_jz_{ij}.
 \label{eq:sign-expanded-square}
\end{equation}
Using Eq.~\eqref{eq:edge-orientation}, this becomes
\begin{align}
 \frac{R^2}{s}
 &=
 \sum_{i\neq j}
 \lambda_{ij}
 (a+c_i)(b+c_j)
 \notag\\
 &=
 \sum_{i\neq j}\lambda_{ij}\mu_{ij}.
 \label{eq:sign-convex-combination}
\end{align}
Because
\begin{equation}
 \lambda_{ij}\geq0,
 \qquad
 \sum_{i\neq j}\lambda_{ij}=1,
 \label{eq:sign-convex-weights}
\end{equation}
Eq.~\eqref{eq:sign-convex-combination} proves
Eq.~\eqref{eq:fixed-sign-bound}.

It remains to show that every \(\mu_{ij}\) is an actual boundary value.
Fix an ordered pair \(i\neq j\).  For every remaining label
\(r\neq i,j\), choose a positive number \(\varepsilon_r\) with
\begin{equation}
 \varepsilon:=\sum_{r\neq i,j}\varepsilon_r<1.
 \label{eq:boundary-soft-parameters}
\end{equation}
The boundary configuration
\begin{equation}
 p_i=(1-\varepsilon)k_a,
 \qquad
 p_j=k_b,
 \qquad
 p_r=\varepsilon_r k_a
 \quad(r\neq i,j)
 \label{eq:boundary-extremal-configuration}
\end{equation}
consists of future-directed null momenta and satisfies exact momentum
conservation.  Taking every \(\varepsilon_r\to0^+\) gives
\begin{equation}
 p_i\longrightarrow k_a,
 \qquad
 p_j\longrightarrow k_b,
 \qquad
 p_r\longrightarrow0
 \quad(r\neq i,j).
 \label{eq:boundary-extremal-limit}
\end{equation}
Along this limit,
\begin{equation}
 R
 \longrightarrow
 (a+c_i)k_a+(b+c_j)k_b,
 \qquad
 \frac{R^2}{s}
 \longrightarrow
 (a+c_i)(b+c_j)
 =
 \mu_{ij}.
 \label{eq:boundary-extremal-value}
\end{equation}
Every \(\mu_{ij}\) is therefore attained on
\(\overline{\Omega}_n(P)\), proving
Eq.~\eqref{eq:fixed-sign-exact-extrema}.

In the open domain, Eq.~\eqref{eq:strict-flow-positivity} shows that
Eq.~\eqref{eq:sign-convex-combination} is a strictly positive weighted sum
of all \(\mu_{ij}\).  This proves
Eqs.~\eqref{eq:strictly-positive-interior} and
\eqref{eq:strictly-negative-interior}.

\subsection{Use and limitations}

For a massless ordinary denominator
\begin{equation}
 \Delta_R:=R^2
 \label{eq:fixed-sign-denominator}
\end{equation}
of the form in Eq.~\eqref{eq:sign-theorem-linear-combination}, the theorem
gives an exact necessary-and-sufficient fixed-sign test:

\begin{enumerate}
 \item If every \(\mu_{ij}>0\), then
 \(\Delta_R>0\) on the full phase-space closure.

 \item If every \(\mu_{ij}<0\), then
 \(\Delta_R<0\) on the full phase-space closure.

 \item If every \(\mu_{ij}\geq0\), with at least one strict inequality, then
 \(\Delta_R>0\) in \(\Omega_n^\circ(P)\), while zeros may occur only on soft
 or collinear boundary strata.

 \item If every \(\mu_{ij}\leq0\), with at least one strict inequality, then
 \(\Delta_R<0\) in \(\Omega_n^\circ(P)\), while zeros may occur only on soft
 or collinear boundary strata.

 \item If every \(\mu_{ij}=0\), then \(\Delta_R\equiv0\), so it cannot serve
 as an ordinary propagator denominator.

 \item If
 \[
  \min_{i\neq j}\mu_{ij}<0<
  \max_{i\neq j}\mu_{ij},
 \]
 then \(\Delta_R\) takes both signs on the phase-space closure and has no
 fixed sign.
\end{enumerate}

When zeros occur only on the physical boundary, this theorem establishes
their location but does not by itself justify combining opposite source-side
\(i0\) prescriptions.  That additional step requires the endpoint
meromorphy and absolute-convergence condition stated in
Sec.~\ref{subsec:reverse-unitarity-causal}.

The theorem does not classify:

\begin{enumerate}
 \item denominators containing forward or conjugate virtual-loop momenta;
 \item denominators mixing the two virtual-loop sets;
 \item linear eikonal denominators;
 \item denominators whose coefficients depend on integration momenta;
 \item massive denominators \(R^2-m^2\) unless their shifted extrema are
 analyzed separately.
\end{enumerate}



## Pro response

The extrema theorem and the strict-interior sign claim are correct on the stated massless physical domain, including n=2. The implementation has a genuine false-acceptance path, however: its quadratic branch can classify a massive/shifted denominator using only the unshifted momentum square. Separately, rejecting unused or numerator-only completion ISPs is unnecessarily restrictive. Removing that rejection is sound only when those slots cannot become positive-power denominators in the reduction and selected masters.

The geometric certificate must remain distinct from permission to erase causal prescriptions.

1. The theorem survives an independent audit

The essential fact is stronger than a separate bound for each R: at each physical phase-space point, one set of nonnegative weights works simultaneously for every constant-coefficient R.

Using your x
i
	​

,y
i
	​

,z
ij
	​

, the subset inequality is valid:

x
A
	​

−z
A
	​

=x
A
	​

(1−y
A
	​

)+κ
A
	​

≥0.

In the specified interior, a nonempty proper subset satisfies

x
A
	​

>0,1−y
A
	​

=y
A
c
	​

>0,

so this inequality is strict. This step uses future-directedness and momentum conservation, not merely the individual mass-shell equations.

The network argument then gives

λ
ij
	​

+λ
ji
	​

=z
ij
	​

,
j

=i
∑
	​

λ
ij
	​

=x
i
	​

,
i

=j
∑
	​

λ
ij
	​

=y
j
	​

.

The last equality follows from the first two; there is no missing independent compatibility condition. Consequently,

s
R
2
	​

=
i

=j
∑
	​

λ
ij
	​

(a+c
i
	​

)(b+c
j
	​

),
i

=j
∑
	​

λ
ij
	​

=1.

Your strict-flow construction is also valid. The singleton-subset bounds ensure that the reduced sink capacities

x
i
	​

−(n−1)δ

are positive, while 2δ<z
ij
	​

 ensures positive reduced edge capacities. Thus the reduced flow exists, and adding δ produces strictly positive weights on every ordered pair. A one-sign coefficient set with at least one nonzero entry therefore gives a strict interior sign.

For sharpness, the closure already contains

p
i
	​

=k
a
	​

,p
j
	​

=k
b
	​

,p
r
	​

=0(r

=i,j),

so every μ
ij
	​

 is attained directly; the soft-limit construction is not necessary.

The n=2 case is especially transparent

Let

χ=
s
2k
b
	​

⋅p
1
	​

	​

∈[0,1].

Then

λ
12
	​

=χ,λ
21
	​

=1−χ,

and

s
R
2
	​

=χμ
12
	​

+(1−χ)μ
21
	​

.
	​


Your interior requires 0<χ<1, so both weights are strictly positive. There is no exception at n=2.

Excluding beam-collinear particles is essential. For example, R=k
a
	​

−p
1
	​

 has bounds [−1,0], but vanishes at p
1
	​

=k
a
	​

, p
2
	​

=k
b
	​

, despite both final particles being nonsoft and mutually noncollinear.

In ordinary four-dimensional kinematics, the full image is the interval between the extrema: for n=2, rotate the two-body configuration; for n≥3, the extremal configurations can be connected through continuous beam-collinear momentum-splitting configurations in the closure. This is not a literal statement about a phase space of noninteger dimension; dimensional continuation is a separate analytic step.

A useful exact extension to bilinears

Your current null-only reduction of P⋅Q is conservative and valid for sign testing. But arbitrary bilinears within the same constant-coefficient physical basis can also be classified without assuming either vector null.

Write their invariant coefficient arrays as A
i
P
	​

,B
i
P
	​

 and A
i
Q
	​

,B
i
Q
	​

. Polarizing the common-weight representation gives

s
P⋅Q
	​

=
i

=j
∑
	​

λ
ij
	​

ν
ij
	​

,ν
ij
	​

=
2
A
i
P
	​

B
j
Q
	​

+A
i
Q
	​

B
j
P
	​

	​

.

The same boundary configurations attain each ν
ij
	​

, so its minimum and maximum are exact bounds.

This is a justified, inexpensive future extension—not permission to apply (P+Q)
2
/2 when P
2
 or Q
2
 is nonzero. It still excludes eikonal vectors outside the declared physical basis.

2. A concrete bug in the committed quadratic parser

At the pinned commit, propagatorDescriptor classifies a standard propagator as "QuadraticLorentzian" whenever its quadratic field is nonzero and its linear field is zero. It retains the mass/constant field in "UnitCore" but does not require that field to vanish. safePropagatorData then uses only "Momentum" in its quadratic branch.

That matters because a StandardPropagatorDenominator explicitly supports an additive mass term as well as the quadratic momentum. 
FeynCalc

A decisive counterexample is

D=(k
a
	​

+p
1
	​

)
2
−
2
s
	​


in two-body massless phase space. The routine computes the unshifted bounds

s
(k
a
	​

+p
1
	​

)
2
	​

∈[0,1]

and therefore accepts. But the actual denominator satisfies

s
D
	​

∈[−
2
1
	​

,
2
1
	​

],
	​


with a zero at an ordinary interior scattering angle.

This is a static-code finding; I have not executed the Wolfram fixture.

Fix this locally in the sign classifier, not by making the shared propagator parser reject massive virtual integrals. Before applying the square theorem, establish that the actual inverse propagator has the admitted form

D=κR
2
,κ∈Q∖{0},

with real constant-coefficient R, and retain κ in the bounds. Otherwise return unsupported, or explicitly analyze the additive shift.

This also protects against incorrect signed bounds when a representation encodes −R
2
 through an imaginary momentum factor. The current descriptor has special handling that removes such an I from the extracted momentum; the sign checker should not infer the actual core’s normalization solely from that extracted momentum.

3. Fixed external kinematics change sharpness, not the sufficient sign implication

For a constrained physical slice Ω(X)⊂
Ω
n
	​

(P), the global bounds remain valid:

L≤R
2
/s≤U.

But they need not be attained on that slice. Thus:

A global one-sign certificate remains sufficient on a slice lying in the stated interior.

A globally mixed range is not proof of a sign change on the selected slice.

For example,

R=k
a
	​

−k
b
	​

+2p
1
	​

,R
2
/s=1−4χ

has global range [−3,1]. On the fixed-angle slice χ=
2
1
	​

, it is identically −1.

Accordingly, distinguish “mixed on unrestricted massless phase space” from “unsafe on this fixed physical slice.” Conservative rejection is appropriate when no slice-specific proof is implemented; the diagnostic should not overstate what was proved.

Two further scope conditions matter:

The outgoing list must represent all physical final particles, including fixed observed and eliminated recoil particles—not just the variables being integrated.

Strictness refers to your full nonsoft/noncollinear interior. A slice constrained to a collinear boundary can have an identically vanishing denominator even when the global theorem gives a strict interior sign.

The shown setup checks establish list structure and massless declarations, but do not themselves establish future orientation, s>0, or the physical momentum-conservation interpretation. Those should be established once from the process/analytic context and then reused.

The exact-rational coefficient restriction is a sound conservative implementation of a theorem stated for real constants. Do not replace it with numerical sign sampling for symbolic coefficients.

4. What is actually required to drop i0

Fixed sign is not, by itself, equality of endpoint distributions with opposite prescriptions.

For a simple illustration, t>0 on the open integration interval, yet

η↓0
lim
	​

∫
0
1
	​

(
t+iη
1
	​

−
t−iη
1
	​

)dt=−iπ.

The individual integrals diverge at the endpoint. Pointwise agreement away from zero does not determine their endpoint extensions.

A sufficient argument for your application is the following. For positive integer propagator powers m
j
	​

, require a nonempty open regulator domain U where the complete term

W(e,p)
j
∏
	​

D
j
	​

(p)
−m
j
	​


is absolutely integrable, with the required locally uniform control in the regulator. For real D
j
	​

,

∣D
j
	​

+iσ
j
	​

η∣
−m
j
	​

≤∣D
j
	​

∣
−m
j
	​

.

Dominated convergence then makes all prescribed limits equal to the same ordinary integral on U. If the definitions admit compatible meromorphic continuation, equality continues to the desired epsilon region.

The missing hypotheses are therefore:

Full-term endpoint convergence. It must include simultaneous soft/collinear limits, the actual powers, numerator, measurement weight, and any remaining virtual factor. Individual denominator signs do not supply it.

A compatible meromorphic definition. When dimensional regularization alone gives no common convergence region, another regulator or subtraction argument must be justified explicitly. Do not infer the equality merely from formal analytic continuation.

Applicability to the terms actually integrated. A convergence argument for a sum whose singularities cancel does not automatically justify integrating its partial-fraction summands separately.

For negative denominators and noninteger powers, even interior branch information survives:

(−x±i0)
−ν
=e
∓iπν
x
−ν
.

Thus a sign certificate does not authorize discarding phases from epsilon-dependent powers or logarithms. Nor does it authorize replacing D by ∣D∣.

Dotted cuts and auxiliary deformations need separate care

The theorem concerns the massless cut surface. Higher cut powers represent normal derivatives of delta distributions. Therefore an identity valid only after setting cut denominators to zero is not generally an identity for dotted-cut integrals:

xδ
′
(x)=−δ(x).

In particular, using the null identity for P⋅Q to classify its sign is fine; using it to replace the actual family polynomial modulo cut equations can be wrong once cuts are raised. Preserve the off-shell defining polynomials, and require the endpoint argument appropriate to the derivative cuts.

Likewise, the massless sign result does not extend automatically along an auxiliary-mass deformation. Already for two bodies,

(p
1
	​

−p
2
	​

)
2
=2m
1
2
	​

+2m
2
2
	​

−s,

which is strictly negative in the massless case but can become positive for allowed unequal masses.

Your separate AMFlow prescription construction should therefore remain separate. In the inspected code, its side information is determined from virtual-loop membership, and mixed-side active slots are checked independently. Passing the geometric test should not overwrite those data.

5. Restrict the gate to denominator support—but enforce that restriction through reduction

For an integral

I(ν)=∫dΦ
j
∏
	​

D
j
−ν
j
	​

	​

,

an ordinary slot with ν
j
	​

=0 is absent, and one with ν
j
	​

<0 is a polynomial numerator. Neither creates a singularity where D
j
	​

=0. Kira explicitly treats auxiliary propagators appearing with nonpositive powers as numerator coordinates. 
arXiv

Consequently, it is mathematically unnecessary to reject such an ISP because its polynomial changes sign, is outside this theorem, or vanishes on the massless cut surface. It must still be a valid algebraic coordinate for the family.

The safe optimization is not merely “check the original positive powers.” It is:

Determine the allowed positive-support sectors from the actual targets, keeping all required cuts.

Permit unclassified completion slots only with nonpositive powers throughout that reduction scope.

Check every selected master’s positive-power ordinary slots before accepting it for the physical integration route.

For ordinary polynomial IBP identities, a numerator-only slot need not become a denominator: differentiating D
j
m
	​

 lowers its polynomial power, and at power zero the derivative contribution vanishes. The risk arises when the generated seed sectors, preferred masters, or symmetry mappings enlarge the allowed scope.

In particular, Kira can generate sectors introduced through preferred_masters even when they were not otherwise requested. A preferred-master list is not an exclusion mechanism. 
arXiv

The inspected exporter passes familyTargets to FeynHelpers’ configuration/job generators, then combines their output and inserts cut metadata. Before removing the all-completion gate, verify the emitted sector masks and the returned master exponents, rather than assuming those helper calls enforce the desired restriction.

Also retain the collection of actual maximal supports rather than automatically replacing it with their bitwise union: the union can introduce an unnecessarily larger sector.

Never mark an unsupported or mixed-sign sector as zero. It is outside the admitted causal-integration route, not a vanishing integral. Keep it out of the reduction scope, choose a different admissible basis, or retain a properly supported causal treatment.

This preserves the justified restriction while allowing harmless numerator coordinates.

6. Cheap improvements and adversarial tests

The first performance changes should remove repeated work, not weaken the theorem:

Validate the physical setup once per call and deduplicate before expensive parsing. Currently, safePropagatorData runs on every candidate before DeleteDuplicatesBy removes equivalent entries. Cache the parsed core and its sign result, then reuse it across sectors. The cache must include the actual scalar multiplier/shift; a momentum-only key is insufficient.

Keep the certificate’s scope explicit internally. Distinguish positive, negative, identically zero, mixed, and unsupported. Public True/$Failed can remain, but True should mean only that the checked active denominators have the proved geometric property—not that the term converges or that its prescriptions have been erased legitimately.

Do not run a flow algorithm in production. It proves the theorem; evaluating the finite corner products implements it. For the small final-state multiplicities here, support filtering and descriptor reuse are more consequential targets than the n(n−1) product table.

The essential exact fixtures are:

Fixture	Required result
n=2: R=P, k
a
	​

−k
b
	​

, p
1
	​

, k
a
	​

−p
1
	​

, k
a
	​

+p
1
	​

	Bounds [1,1],[−1,−1],[0,0],[−1,0],[0,1], respectively.
R=k
a
	​

−k
b
	​

+2p
1
	​

	Bounds [−3,1]; an interior zero exists. A fixed χ=
2
1
	​

 slice is nevertheless negative.
Beam-collinear and final-final-collinear configurations	Boundary zeros must not contradict the strict-interior result; omitting either exclusion must be detected by fixtures.
D=(k
a
	​

+p
1
	​

)
2
−s/2	Reject under the massless-only classifier, or return the correctly shifted mixed bounds. This catches the current parser defect.
Momentum-conservation shift, R→−R, and D→−D	The first two preserve bounds; the last sends [L,U]→[−U,−L].
A mixed-sign ISP at powers 0,−1,+1	No sign rejection for the first two; the positive-power occurrence must pass an appropriate causal-admissibility check. Test a preferred master that tries to activate it.
Bilinear with a nonnull operand	Never apply the null-only half-square identity. Return unsupported or use the polarized bound above.
Dotted-cut numerator and endpoint prescription fixtures	Preserve xδ
′
(x)=−δ(x); do not turn the half-line i0 example into prescription independence without its regulator argument.

Recommendation: fix the local quadratic-core admissibility check first. Then replace the all-completion rejection with a positive-support policy enforced at sector generation and final-master acceptance. Preserve the convergence/meromorphic causal condition, the original cut polynomials, and the separate virtual prescriptions. The theorem supports that narrower, less wasteful implementation; it does not support removing the causal restriction wholesale.
