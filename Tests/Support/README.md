# Independent mathematical references

These files are loaded explicitly by tests, never by the production package:

- FamilyRowBasisTransformationFiniteField.wl independently evaluates row basis
  transformations over finite fields, for comparison with the production
  multiquadratic implementation.
- MultiquadraticMixedGradeLetters.wl supplies the experimental letter-discovery
  reference exercised by the off-diagonal transformation tests.
- NLO/numeric_nlo_masters.wls independently integrates the seven NLO example
  masters over angular variables. It records the origin of the numerical
  reference values in Reconstruction/t_nlo_masters.wls.

The first two implementations moved from Prototypes without changing their
mathematics. They are references for tests, not supported production interfaces.
