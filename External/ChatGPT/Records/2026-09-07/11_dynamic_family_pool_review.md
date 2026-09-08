# dynamic family pool review

## Question

We are validating 345 NNLO cut masters across 91 families against AMFlow. User requests fix Frobenius DE numerical failures and dynamic pool of 8 families, total 8 cores. Mathematica installation permits 2 main kernels and 8 subkernels. AMFlow NThread=1 executes reductions locally (Kira -p1) but RunCommand starts a separate Wolfram main kernel for generated boundary-order and numerical DE scripts; scripts load DESolver.m, use Global variables and terminate Quit[]. Eight naive family processes would exceed main kernel licenses. Considering one main dispatcher, 8 subkernel family workers, and running vendor-generated numerical scripts directly within each worker under fully localized Global symbols and system settings, catching Exit/Quit and restoring directories/contexts. DESolver has package context; generated .wl and its loaded data use bare eps and j. Alternative stage-splitting: return generated scripts as independent jobs to same pool and resume parent via saved state, much more invasive. Please critically review minimal robust general architecture to honor 8 families/8 cores without modifying upstream AMFlow, losing isolation, or silently serializing. Suggest exact WL scoped isolation pattern and pitfalls (Get parsing context, preexisting Global OwnValues, $MinPrecision, BeginPackage shadowing). No need restate basics. Also current rational Frobenius backend (FLINT acb) reports nonfinite quotient despite exact rational connection jointly regular at (z,eps)=(0,0); denominator Taylor series inversion might suffer cancellation or numeric serialization. I am obtaining actual failed input. Recommend minimal discriminating diagnostics, not expensive symbolic checks. Repo local code cannot be seen by you, so ask if specific snippets needed.

## Pro response

The one-dispatcher/eight-subkernel architecture is the right minimal route. Execute each generated Wolfram script synchronously inside its existing family worker. Do not introduce a second pool or move numerical stages back onto the dispatcher.

The important correction is that “localize the script’s globals” is insufficient unless this also covers existing definitions, newly created symbols, DESolver state, and non-symbol resources. This can preserve isolation between your trusted generated jobs, but it is not a general replacement for a fresh process’s isolation.

1. Keep the family as the scheduling unit

Each subkernel should own one family at a time, including its reductions, boundary-order calculation, numerical DE stages, and final comparison. When its family finishes, it takes the next family. An inline child script occupies the same family slot; its parent is suspended on the ordinary evaluation stack, not consuming another computational slot.

ParallelSubmit and WaitNext provide the required dynamic scheduling: submissions go to available subkernels, and completion processing need not wait for an eight-family batch barrier. Load the worker package explicitly on each subkernel rather than distributing the dispatcher’s entire `Global`` context. 
Wolfram Documentation Center
+1

For example, with the pool already initialized and verified to contain eight workers:

Wolfram Language
pending = Table[
  ParallelSubmit[{file}, NNLOWorker`RunFamilyFile[file]],
  {file, familyFiles}
];

While[pending =!= {},
  {result, finished, pending} = WaitNext[pending];
  recordResult[result];
];

Keep the dispatcher’s work limited to scheduling and recording small results. Do not return large DEs or stream verbose solver output through the dispatcher.

Intercept only the Wolfram-script branch of AMFlowRunCommand`. Leave Kira and native numerical executables as external processes. They do not create the Wolfram main-kernel problem you identified.

The adapter should recognize the actual executable and argument structure, resolve the script and ProcessDirectory correctly, reproduce its logging contract, and execute inline. An unrecognized command that launches Wolfram must fail explicitly rather than fall back to starting another main kernel. In the public AMFlow source, RunCommand returns elapsed time on success and aborts on unsuccessful execution—not a RunProcess association. Match your installed version’s actual contract. 
gitlab.com

Do not enqueue a child numerical job and then wait for it from the occupied parent worker. Eight parents waiting for children queued to the same eight-worker pool can deadlock. Your proposed continuation-based stage splitting avoids that only by genuinely releasing the parent slots; it is unnecessary here.

Eight workers is not automatically eight cores

At worker initialization, set the supported Wolfram "ParallelThreadNumber" and "MKLThreadNumber" settings to one and verify their readback. Merely changing $ProcessorCount does not impose these limits. Preserve NThread=1 and Kira -p1; initialize your native FLINT backend with flint_set_num_threads(1) where you control that backend. 
Wolfram Community
+1

For a literal eight-core ceiling, also constrain the process tree to an eight-CPU affinity set. Thread settings prevent oversubscription; affinity supplies the hard CPU boundary. Log worker PID, $KernelID, family, start, and finish so genuine overlap is observable.

2. Use two scopes, not one

The outer family scope owns AMFlow configuration, reducer state, family globals, and writable directories. A worker reused for another family must start from a known state: either restore a clean package baseline or clear/reload the configured mutable package contexts. Do not rely on setting the next family’s obvious input fields to erase all previous memoized state.

The inner generated-script scope temporarily hides the parent’s globals, starts DESolver from clean WL definitions, runs the script, and restores the suspended parent’s environment.

For the inner scope, retain the normal fresh-session parsing environment:

Wolfram Language
$Context = "Global`";
$ContextPath = {"System`", "Global`"};

Then allow Get[DESolver.m] and BeginPackage to modify the path normally.

A fresh arbitrary context is not a safe substitute. Public AMFlow explicitly constructs Globaleps, Globaleta, and Globalj; meanwhile DESolver exports its own eta`. Consequently, both “put everything in a unique context” and “force every bare symbol into Global” can change identities relative to a standalone script. 
GitLab
+1

The crucial held-localization pattern

The dangerous construction is:

Wolfram Language
syms = ToExpression /@ Names["Global`*"];

Existing OwnValues can evaluate during construction of syms, before localization begins. Instead, construct the symbol list under a holding function that immediately installs the scope. ToExpression’s third argument is applied before the parsed expression evaluates. 
Wolfram Documentation Center

Here is the core pattern I would use. It intentionally isolates complete context subtrees and removes newly created symbols. All bridge implementation symbols must live outside those subtrees.

Wolfram Language
BeginPackage["NNLOScriptScope`"];
RunGeneratedScript::usage =
  "RunGeneratedScript[file] returns an exit status or Failure.";
Begin["`Private`"];

(* Return fully qualified names, including private subcontexts. *)
ownedNames[roots_List] := Block[
  {$Context = "NNLOScriptScope`Private`",
   $ContextPath = {}, $ContextAliases},
  DeleteDuplicates @ Flatten[
    Names[# <> "*", ResolveContextAliases -> False] & /@
      Select[
        Contexts["*", ResolveContextAliases -> False],
        Function[c,
          AnyTrue[roots, Function[r, StringStartsQ[c, r]]]
        ]
      ]
  ]
];

SetAttributes[withFreshContexts, HoldRest];

withFreshContexts[roots_List, body_] := Module[
  {before = ownedNames[roots]},

  If[AnyTrue[before, MemberQ[Attributes[#], Locked] &],
    Return[Failure["LockedOwnedSymbol", <|"Roots" -> roots|>]]
  ];

  ToExpression[
    "{" <> StringRiffle[before, ","] <> "}",
    InputForm,
    Function[heldSymbols,
      Internal`InheritedBlock[heldSymbols,
        WithCleanup[
          Scan[(Unprotect[#]; ClearAll[#]) &, before],

          body,

          Scan[
            (Unprotect[#]; Remove[#]) &,
            Complement[ownedNames[roots], before]
          ]
        ]
      ],
      HoldAllComplete
    ]
  ]
];

(* Restore additional directory pushes; reject stack corruption. *)
restoreDirectoryStack[before_List] := Module[
  {after = DirectoryStack[], extra},
  extra = Length[after] - Length[before];

  If[extra < 0 || Drop[after, extra] =!= before,
    Return[False]
  ];

  Do[ResetDirectory[], {extra}];
  DirectoryStack[] === before
];

RunGeneratedScript[file_String] := Module[
  {absolute = ExpandFileName[file],
   exitTag = Unique["NNLOScriptScope`Private`exit$"],
   directories = DirectoryStack[],
   cleanupOK = True,
   result},

  If[!FileExistsQ[absolute],
    Return[Failure["MissingScript", <|"File" -> absolute|>]]
  ];

  result = CheckAbort[
    Block[
      {$Context = "Global`",
       $ContextPath = {"System`", "Global`"},
       $ContextAliases,
       $Packages = Select[
         $Packages, !StringStartsQ[#, "DESolver`"] &
       ],
       $Path = $Path,
       $MinPrecision = 0,
       $MaxPrecision = Infinity,
       $MaxExtraPrecision = 50,
       $Assumptions = True,
       $HistoryLength = 0,
       $RecursionLimit = $RecursionLimit,
       $IterationLimit = $IterationLimit,
       $Output = $Output,
       $Messages = $Messages,
       $Pre, $Post, $PreRead, $Epilog},

      withFreshContexts[{"Global`", "DESolver`"},
        Internal`InheritedBlock[{System`Quit, System`Exit},
          Unprotect[System`Quit, System`Exit];

          System`Quit[n_Integer : 0] := Throw[n, exitTag];
          System`Exit[n_Integer : 0] := Throw[n, exitTag];

          WithCleanup[
            Null,

            Catch[
              If[Get[absolute] === $Failed,
                Failure["GetFailed", <|"File" -> absolute|>],
                0
              ],
              exitTag
            ],

            cleanupOK = restoreDirectoryStack[directories]
          ]
        ]
      ]
    ],
    Failure["ScriptAborted", <|"File" -> absolute|>]
  ];

  If[TrueQ[cleanupOK],
    result,
    Failure["TaintedWorker", <|"File" -> absolute|>]
  ]
];

End[];
EndPackage[];

This is a scope core, not a complete RunCommand adapter, and I have not executed it in your installation. InternalInheritedBlock` is an undocumented dependency: pin the Wolfram version and test restoration of values, attributes, protection, and options before using it on campaign workers. The inherited-block mechanism preserves initial definitions, so the explicit clearing inside the scope is essential for fresh script state. 
Wolfram Cloud Resources

The code assumes the generated scripts use the stated Quit[]/integer-exit forms, do not remove or lock preexisting owned symbols, and use balanced package loading. Those are reasonable generator-level contracts, not facts to assume about arbitrary WL programs.

Its return value is an execution status. Zero is not yet validation success: the adapter must still verify the expected output files and their basic structure.

3. The important scope pitfalls
Parsing must happen inside the scope, in execution order

Use Get[absoluteScriptPath] inside the scope. Do not parse the complete script into a held expression outside it and expect changing $Context afterward to rename its symbols. Likewise, Module[{eps, j}, Get[file]] does not lexically substitute names inside subsequently read file text.

Preserve expression-by-expression package loading. In particular, do not convert separate source expressions into one pre-parsed compound expression containing both Get[DESolver.m] and later unqualified DESolver calls. BeginPackage changes how subsequent input is parsed; it cannot repair symbols already bound by an earlier parse. 
Wolfram Documentation Center
+1

Do not preload helper stubs into Global`` or put the bridge’s private context on the generated script’s search path. Fully qualify bridge calls. Let DESolver’s exported context take the same precedence it would acquire in a fresh script session. $ContextPath` ordering matters, including when same-named symbols already exist. 
Wolfram Documentation Center

Clear definitions, not just scalar values

Clear[eps, j] or a hand-maintained list of script variables misses other globals and package caches. The generic census should include the owned package’s private subcontexts. DESolver stores system-dependent objects indexed by system IDs; resetting its default options is not equivalent to removing those objects. 
GitLab
+1

The context scope must also clean up symbols first created during execution. Conversely, do not remove preexisting symbols while their definitions are saved for restoration: removal/recreation can invalidate references held by the suspended parent. Return only plain status metadata across this inner scope; let the parent read the vendor’s output files after restoration.

Precision settings need initialization and restoration

Scope $MinPrecision, $MaxPrecision, and $MaxExtraPrecision together, but allow the script to establish its requested working precision inside that scope. DESolver explicitly changes the precision bounds and sets $MaxExtraPrecision. 
GitLab
+1

A leaked positive $MinPrecision is particularly misleading: Wolfram can pad arbitrary-precision values to that nominal precision. It does not recreate digits already lost through cancellation or serialization. Consequently, a large reported Precision is not evidence that the input was accurate to that precision. 
Wolfram Documentation Center

Do not blanket-localize every System`` symbol. In particular, do not roll back uniqueness machinery such as $ModuleNumber`.

Intercept termination, rather than suppressing it

Quit[] := Null is wrong: an early successful exit would continue into code that was supposed to be unreachable. A private tagged Throw preserves the required nonlocal termination. Distinguish normal exit, nonzero exit, abort, and cleanup failure.

The interception also bypasses normal kernel-termination $Epilog behavior. Therefore, the admitted scripts must finish required output themselves rather than rely on an epilog. Real Quit/Exit perform session termination; a scoped replacement does not. 
Wolfram Documentation Center
+1

Use WithCleanup rather than body; cleanup: it runs cleanup across ordinary aborts and control transfers. Keep its initialization and cleanup small because they receive special protection from interruption. 
Wolfram Documentation Center

Directories and resources are not just symbols

A final SetDirectory[oldDirectory] restores the current location but adds another directory-stack entry. The directory helper above instead unwinds the script’s additional pushes and reports a tainted worker if the parent stack was disturbed. Each SetDirectory pushes and each ResetDirectory pops. 
Wolfram Documentation Center

Add per-script output/message streams around this core and close the streams you own before the parent reads results. Keep all writable scratch, solver input/output, and logs family/attempt-specific. A unique working directory is insufficient when a native helper writes to a fixed installation-relative path.

Finally, Block does not undo native-library state, SetSystemOptions changes, orphaned subprocesses, or a partially completed package initialization. Establish thread settings at worker bootstrap; explicitly restore any other admitted system-option changes. On failed package initialization or failed cleanup, terminate that family evaluation and recycle the worker rather than resume the suspended parent under uncertain state.

4. Frobenius failure: inspect the actual inversion boundary

Accepting your statement that the rational connection is jointly regular at (z,ϵ)=(0,0), that does not establish that every denominator handed to the numerical inverter is invertible there.

For example,

z+ϵ
z+ϵ
	​

=1

has a regular reduced germ, but attempting to construct a bivariate Taylor inverse of z+ϵ is invalid. The same issue can arise when individually singular summands are expanded before their cancellation is assembled.

The first diagnostic is therefore not another global regularity check. It is:

What precise polynomial or series is being inverted, in which variable, at which center, after which substitutions?

Also distinguish denominator-series inversion from a later Frobenius recurrence division. Regularity of the connection does not by itself diagnose a failure in the latter.

Capture one failing scalar operation

For the first failure, retain the exact numerator/denominator representation immediately before conversion, the actual center and numerical ϵ if applicable, the expansion variable/order, polynomial lengths, precision in bits, and first nonfinite coefficient index.

At the numerical boundary, log only:

input coefficients finite?
denominator constant: midpoint and radius
denominator constant is exactly zero?
denominator constant contains zero?
denominator constant relative accuracy in bits
first nonfinite stage: input / shift / inverse / quotient / recurrence

FLINT provides distinct zero-containment and relative-accuracy tests. For inversion, “the midpoint is nonzero” is not the relevant condition; the denominator ball must exclude zero. 
Flint Library
+1

Compute the denominator’s constant term exactly for that failing scalar, preferably from its existing polynomial representation. This is cheap and discriminating:

Observation	Likely issue / next action
Exact constant term is zero	The presented denominator is not a Taylor unit: inspect uncancelled factors, Laurent shifts, or the actual expansion center. More precision will not fix this.
Exact constant is nonzero, numerical enclosure contains zero	Loss occurred during coefficient evaluation/conversion, or the input enclosure is too wide.
Constant excludes zero, but some input coefficient is already nonfinite	The fault precedes inversion. Inspect conversion or shifting.
Finite inputs and zero-excluding constant, but the first inverse coefficient is nonfinite	Prioritize API arguments, initialization, lengths, aliasing, and input representation—not a physical singularity.
The captured operation succeeds alone but fails under concurrency	Prioritize shared scratch files or state contamination, using identical captured inputs.
Three small replays, not a campaign-wide precision increase

Replay that operation through the current path at precision p. Then rebuild its coefficients directly from exact rationals at the same p. Finally, rebuild again from exact rationals at p+64 bits, or another modest increment.

For the direct path, use exact rational conversion such as acb_set_fmpq; construct rational real and imaginary components separately when needed. This avoids making decimal text the intermediary. 
Flint Library

Interpret the differences carefully. Success only on the exact-input path identifies the coefficient-construction/conversion path, not automatically the serializer alone. Success only after rebuilding at higher precision supports insufficient working precision. Increasing the nominal precision of already rounded inputs is not this test.

At the writer/parser boundary, check one actual troublesome token and its parse status. Specifically inspect precision backticks, WL *^ exponents, rational syntax, unintended machine-number conversion, and whether a failed parse silently leaves a zero coefficient. Check coefficient ordering and lengths at the same time.

A tiny independent quotient calculation

For the first few coefficients, compare the FLINT result with the direct recurrence

c
0
	​

=
q
0
	​

p
0
	​

	​

,c
k
	​

=
q
0
	​

p
k
	​

−∑
ℓ=1
k
	​

q
ℓ
	​

c
k−ℓ
	​

	​

.

Use the same input balls. For genuinely bivariate expansion, use the corresponding multi-index recurrence with divisor q
00
	​

. This requires no symbolic simplification and avoids exercising the same inversion algorithm twice: FLINT’s series inversion uses Newton iteration. 
Flint Library

If the direct recurrence works but the library-call path fails on the same coefficients, inspect the call boundary before changing mathematics. If both fail because q
0
	​

 contains zero, diagnose how that coefficient was built.

Once finite, check the low-order numerical residual

QC−P=O(z
N+1
),

requiring both zero containment and useful enclosure widths. Very wide balls containing zero are not a meaningful acceptance criterion.

I would not yet add global Together, FullSimplify, multivariate factorization, or indiscriminate retries. If the exact constant term reveals an uncancelled factor, normalize only the failing scalar fraction or strip the proven monomial valuation.

5. Minimal acceptance tests before the full run

Use a disposable subkernel first. Poison GlobalepsandGlobalj with definitions, add a DESolver cached value, and run a tiny script that changes precision and exits. Verify the script saw clean state and the parent’s definitions and settings returned unchanged. Repeat with an early Quit[7] and Abort[]; a statement after the exit must not execute.

Then run two scripts consecutively with different working precisions, and nine uneven-duration stub family jobs on the pool. That exposes precision leakage and batch barriers without rerunning the masters. Follow with two real families concurrently in distinct scratch trees.

The implementation priority is the synchronous command adapter plus explicit scopes; the numerical priority is exact-versus-ball inspection of the actual denominator constant. Neither requires the invasive stage-splitting design.

Please send the installed RunCommand definition with one actual command/options call, one complete generated script with a small representative eps/j data file, and the failed scalar input together with its writer, parser, and inversion call.
