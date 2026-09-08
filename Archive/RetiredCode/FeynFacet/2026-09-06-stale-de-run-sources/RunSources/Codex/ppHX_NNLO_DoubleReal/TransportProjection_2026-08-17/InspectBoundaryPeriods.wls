If[Length[$ScriptCommandLine] < 2,
  Print["usage: wolframscript -file InspectBoundaryPeriods.wls <period-record> [ids...]"];
  Exit[2]
];

record = Get[$ScriptCommandLine[[2]]];
ids = ToExpression /@ Drop[$ScriptCommandLine, 2];
periods = Select[record["Periods"], MemberQ[ids, #1["PeriodID"]] &];
Print[Dataset[periods]];
