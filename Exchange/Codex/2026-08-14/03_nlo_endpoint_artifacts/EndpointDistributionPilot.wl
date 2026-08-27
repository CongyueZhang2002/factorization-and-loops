ClearAll[ExpandEndpointFamilies];

ExpandEndpointFamilies::data =
  "Each endpoint family must contain PowerSlope and LaurentCoefficients with integer Laurent orders.";

ExpandEndpointFamilies[
    families_Association,
    regulator_Symbol,
    {minimumOrder_Integer, maximumOrder_Integer}
  ] /; minimumOrder <= maximumOrder := Module[
  {
    valid, minimumLaurentOrder, maximumLog, withinRange,
    byFamily, mergeOrders
  },

  valid = AllTrue[
    Values[families],
    Function[family,
      AssociationQ[family] &&
        IntegerQ[Lookup[family, "PowerSlope", Missing[]]] &&
        Lookup[family, "PowerSlope", 0] > 0 &&
        AssociationQ[Lookup[family, "LaurentCoefficients", Missing[]]] &&
        Lookup[family, "LaurentCoefficients", <||>] =!= <||> &&
        AllTrue[Keys[family["LaurentCoefficients"]], IntegerQ]
    ]
  ];
  If[! valid,
    Message[ExpandEndpointFamilies::data];
    Return[$Failed]
  ];

  minimumLaurentOrder = Min[
    Flatten[Keys[#] & /@ Lookup[Values[families], "LaurentCoefficients"]]
  ];
  maximumLog = Max[0, maximumOrder - minimumLaurentOrder];
  withinRange[orders_Association] := KeySelect[
    orders,
    minimumOrder <= # <= maximumOrder &
  ];
  mergeOrders[associations_List] := If[
    associations === {},
    <||>,
    KeySort[Merge[associations, Total]]
  ];

  byFamily = AssociationMap[
    Function[label,
      With[
        {
          slope = families[label]["PowerSlope"],
          coefficients = families[label]["LaurentCoefficients"]
        },
        <|
          "Power" -> -1 - slope regulator,
          "Delta" -> withinRange @ Association @ KeyValueMap[
            (#1 - 1) -> (-#2/slope) &,
            coefficients
          ],
          "Plus" -> AssociationMap[
            Function[logPower,
              withinRange @ Association @ KeyValueMap[
                (#1 + logPower) ->
                  ((-slope)^logPower #2/Factorial[logPower]) &,
                coefficients
              ]
            ],
            Range[0, maximumLog]
          ]
        |>
      ]
    ],
    Keys[families]
  ];

  <|
    "Regulator" -> regulator,
    "OrderRange" -> {minimumOrder, maximumOrder},
    "MaximumLogPower" -> maximumLog,
    "ByFamily" -> byFamily,
    "Total" -> <|
      "Delta" -> mergeOrders[Lookup[Values[byFamily], "Delta"]],
      "Plus" -> AssociationMap[
        mergeOrders[
          Lookup[Lookup[Values[byFamily], "Plus"], #, <||>]
        ] &,
        Range[0, maximumLog]
      ]
    |>
  |>
];

ExpandEndpointFamilies[___] := (
  Message[ExpandEndpointFamilies::data];
  $Failed
);
