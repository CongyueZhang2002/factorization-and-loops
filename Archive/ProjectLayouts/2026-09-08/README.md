# Retired project layouts (2026-09-08)

These are historical cards, accepted results and local generated data.
The production package does not read them. New runs use ppHX_UU_NNLO,
ppHX_LL_NLO and ppHX_TT_NLO, with order/channel directories and root card.wl.
No result migration or old-card compatibility is provided.

The older ppHX_NLO/TT card describes incoming-to-outgoing spin transfer.
It is not the double-incoming transversity used by ppHX_TT_NLO.
Tests that explicitly read archived data use it as a frozen reference.
Original external NLO references now live in External/References/ppHX_NLO.


The user subsequently authorized removal of old NLO results. Results and Kira
directories of ppHX_NLO and ppHX_NLO_qqprime were deleted (142,319,587 bytes).
Their cards and notes are retained as code history. Tests requiring these old
results were retired; current NLO runs and independent physics checks replace
the obsolete replay tests. NNLO historical data was not part of this deletion.
