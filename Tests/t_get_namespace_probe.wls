#!/usr/bin/env wolframscript
(* Diagnostic: determine whether Get interns symbols from later expressions
   before evaluating the first expression.  Submit only through a minimal
   direct KernelPool wrapper, never through kpsubmit's target pre-parser. *)

getProbeBefore = System`Names["Global`GetProbeLaterSymbol"];
Print["GET NAMESPACE PROBE before_later_expression=",
  System`InputForm[getProbeBefore]];

GetProbeLaterSymbol = 1;

<|"BeforeLaterExpression" -> getProbeBefore,
  "SequentialQ" -> (getProbeBefore === {})|>
