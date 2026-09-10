# Native algebra runtime

Run `python3 Scripts/Setup/install_form.py` from WSL to install the pinned
upstream FORM 5.0.1 Linux x86-64 release. The installer records the release URL,
archive checksum, version output, source-code URL and license in
`Addon/Other_Addon/FORM/`. Native binaries are local dependencies and are not
checked into this repository.

`FeynFacet/Interfaces/FORM.wl` translates declared Dirac traces and
Lorentz tensors. It preserves propagators and scalar normalization factors.
BMHV mode lowers gamma5 with an explicit physical epsilon tensor and retains
the rank-four projector, including full-D integrated momenta. Its algebra is
checked before process production; the automatic contraction keeps the
FeynCalc fallback for unsupported objects.

Sources: https://github.com/form-dev/form/releases/tag/v5.0.1 and
https://github.com/form-dev/form/blob/v5.0.1/COPYING.
