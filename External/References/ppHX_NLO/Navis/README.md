<h1 align="center">ηaνis</h1>

<p align="justify">
  <b>ηaνis</b> is a code that computes both polarized and unpolarized single-inclusive
  hadron production in proton-proton collision up to next-to-leading order (NLO) in
  QCD⊗QED and dump the results in the form of
  <a href="https://github.com/NNPDF/pineappl">PineAPPL</a>
  fast interpolation grids. It is based on the following papers:
  <a href="https://arxiv.org/abs/hep-ph/0210442">[arXiv:0210442]</a>,
  <a href="https://arxiv.org/abs/hep-ph/0211007">[arXiv:0211007]</a>,
  <a href="https://bib-pubdb1.desy.de/record/517576/files/">[DESY94-042]</a>,
  and <a href="https://inspirehep.net/literature/342979">[iNSPIRE:342979]</a>.
</p>

## Installation

ηaνis is published in [crates.io](https://crates.io/crates/navis-cli). To install it,
simply run the following command:

```sh
cargo install navis-cli
```

Otherwise, to compile it from source, run the following commands instead:

```sh
git clone https://github.com/QCDLab/navis.git
cargo install --path navis-cli
```

This will install two binaries `navis-pol` and `navis-unpol` that can be used to run
a YAML card containing the input settings. For example:

```sh
navis-unpol ./runcards/example.yml
```

## Citation

If you use **ηaνis**, please cite the papers above and the following:

<table>
  <tr>
  <td valign="middle"><b>ηaνis</b> itself</td>
  <td valign="middle">
    <a href="https://doi.org/10.5281/zenodo.22062166"><img
          alt="zenodo"
          src="https://img.shields.io/badge/DOI-10.5281%2Fzenodo.22062166-blue.svg?style=for-the-badge&logo=zenodo"
          height="25"
    /></a>
  </td>
  <tr>
  <td valign="middle"><b>MCHEP</b> for the MC integration</td>
  <td valign="middle">
    <a href="https://doi.org/10.5281/zenodo.21206363"><img
          alt="zenodo"
          src="https://img.shields.io/badge/DOI-10.5281%2Fzenodo.21206363-blue.svg?style=for-the-badge&logo=zenodo"
          height="25"
    /></a>
  </td>
  </tr>
  <tr>
  <td valign="middle"><b>NeoPDF</b> for the PDF/FF interpolation</td>
  <td valign="middle">
    <a href="https://doi.org/10.5281/zenodo.17286769"><img
          alt="zenodo"
          src="https://img.shields.io/badge/DOI-10.5281%2Fzenodo.17286769-blue.svg?style=for-the-badge&logo=zenodo"
          height="25"
    /></a>
    <a href="https://arxiv.org/abs/2606.17134"><img
          alt="arXiv"
          src="http://img.shields.io/badge/hep.ph-2606.17134-B31B1B.svg?style=for-the-badge&logo=arxiv&logoColor=red"
          height="25"
    /></a>
  </td>
  </tr>
  <tr>
  <td valign="middle"><b>PineAPPL</b> for the fast interpolation grid</td>
  <td valign="middle">
    <a href="https://doi.org/10.5281/zenodo.15635174"><img
          alt="zenodo"
          src="https://img.shields.io/badge/DOI-10.5281%2Fzenodo.15635174-blue.svg?style=for-the-badge&logo=zenodo"
          height="25"
    /></a>
    <a href="https://arxiv.org/abs/2510.05079"><img
          alt="arXiv"
          src="http://img.shields.io/badge/hep.ph-2510.05079-B31B1B.svg?style=for-the-badge&logo=arxiv&logoColor=red"
          height="25"
    /></a>
  </td>
  </tr>
</table>
