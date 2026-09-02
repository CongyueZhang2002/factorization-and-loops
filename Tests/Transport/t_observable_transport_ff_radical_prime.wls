#!/usr/bin/env wolframscript

(* Round 4 (2026-09-02), Codex correctness point 2: the fresh-prime
   selectors of the two multiquadratic inclusion certificates gated only
   the declared CONSTANT root squares; a numeric radical constant of the
   normalized matrix (a {"SquareRootConstant", s} node, e.g. the Sqrt[5]
   of a rescaled CF259 root) was not consulted, so a seed whose first
   candidate prime has (s|p) = -1 made every validation point at that
   prime fail and the run refused, seed-dependently.  The existing
   t_observable_transport_ff_radical_scale test chooses a prime with
   (5|p) = 1 and cannot see this.  Here the seed is chosen so that the
   selector's FIRST candidate prime has (5|p) = -1; the selectors must
   skip it and accept at later primes with (5|p) = 1. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

u = Symbol["Global`radicalPrimeU"];
v = Symbol["Global`radicalPrimeV"];
squares = {1 + u, 1 + v};
tracePrime = FeynFacet`Private`$observableTransportFFTracePrime;

(* the selector's own draw: SeedRandom[seed], then RandomPrime[{2^30, 2^31-1}]
   until p == 3 (mod 4) and p is not the trace prime *)
firstCandidate[seed_Integer] := BlockRandom[
  SeedRandom[seed];
  Module[{p = 1},
    While[Mod[p, 4] =!= 3 || p === tracePrime,
      p = RandomPrime[{2^30, 2^31 - 1}]];
    p]];
seed = SelectFirst[Range[1, 400], JacobiSymbol[5, firstCandidate[#]] === -1 &];
FTAssert["a seed exists whose first candidate prime has (5|p) = -1",
  IntegerQ[seed]];
p1 = firstCandidate[seed];

space = {{Sqrt[5] Sqrt[1 + u], Sqrt[1 + v]}};
candidates = {{3 Sqrt[5] Sqrt[1 + u], 3 Sqrt[1 + v]}};
compiled = FeynFacet`Private`observableTransportFFCompileAlgebraicMatrix[
  Join[space, candidates], {u, v}, squares];
FTAssert["the compiled matrix records the radical constant 5 and no constant root square",
  AssociationQ[compiled] && compiled["RadicalConstants"] === {5} &&
    Select[Lookup[compiled["Roots"], "RootSquare", {}],
      FreeQ[#, u | v] &] === {}];

included = FeynFacet`Private`observableTransportModularAlgebraicSubspaceInclusion[
  space, candidates, {u, v}, squares,
  "ValidationPrimeCount" -> 2, "ValidationPointsPerPrime" -> 1,
  "ValidationSeed" -> seed];
FTAssert["the materialized inclusion is accepted although the first candidate prime is a non-residue for 5",
  Lookup[included, "Status", None] === "FreshModularSubspaceInclusionAccepted" &&
    Length[Lookup[included, "AcceptedTrials", {}]] === 2];
usedPrimes = Lookup[Lookup[included, "AcceptedTrials", {}], "Prime", {}];
FTAssert["the non-residue prime was skipped and every prime used has (5|p) = 1",
  ! MemberQ[usedPrimes, p1] && usedPrimes =!= {} &&
    AllTrue[usedPrimes, JacobiSymbol[5, #] === 1 && Mod[#, 4] === 3 &]];
excluded = FeynFacet`Private`observableTransportModularAlgebraicSubspaceInclusion[
  space, {{Sqrt[1 + v], 0}}, {u, v}, squares,
  "ValidationPrimeCount" -> 2, "ValidationPointsPerPrime" -> 1,
  "ValidationSeed" -> seed];
FTAssert["a false inclusion is still rejected at the same seed",
  Lookup[excluded, "Status", None] === "FreshModularSubspaceInclusionRejected"];

(* the covariant selector: nabla B = B/(2(1+u)) lies in the span of B *)
basis = {{Sqrt[5] Sqrt[1 + u], 0}};
connection = {{0, 0}, {0, 0}};
covariant = FeynFacet`Private`observableTransportModularAlgebraicCovariantSubspaceInclusion[
  basis, connection, u, {u, v}, squares,
  "ValidationPrimeCount" -> 2, "ValidationPointsPerPrime" -> 1,
  "ValidationSeed" -> seed];
FTAssert["the covariant inclusion is accepted at residue primes only",
  Lookup[covariant, "Status", None] === "FreshModularSubspaceInclusionAccepted" &&
    With[{primes = Lookup[Lookup[covariant, "AcceptedTrials", {}], "Prime", {}]},
      Length[primes] === 2 && ! MemberQ[primes, p1] &&
        AllTrue[primes, JacobiSymbol[5, #] === 1 &]]];
covariantOpen = FeynFacet`Private`observableTransportModularAlgebraicCovariantSubspaceInclusion[
  basis, {{0, 1}, {0, 0}}, u, {u, v}, squares,
  "ValidationPrimeCount" -> 2, "ValidationPointsPerPrime" -> 1,
  "ValidationSeed" -> seed];
FTAssert["a non-invariant covariant row space is still rejected at the same seed",
  Lookup[covariantOpen, "Status", None] === "FreshModularSubspaceInclusionRejected"];
FTReport[];
