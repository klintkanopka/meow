---
title: 'meow: An R package for simulating computer adaptive testing'
tags:
  - R
  - psychometrics
  - computer adaptive testing
  - cat
authors:
  - name: Klint Kanopka
    orcid: 0000-0003-3196-9538
    corresponding: true
    affiliation: 1 # (Multiple affiliations must be quoted)
  - name: Sophia Deng
    affiliation: 1
affiliations:
 - name: New York University, USA
   index: 1
date: 11 June 2025
bibliography: paper.bib
---

# Summary

The forces on stars, galaxies, and dark matter under external gravitational fields lead to the dynamical evolution of structures in the universe. The orbits of these bodies are therefore key to understanding the formation, history, and future state of galaxies. The field of "galactic dynamics," which aims to model the gravitating components of galaxies to study their structure and evolution, is now well-established, commonly taught, and frequently used in astronomy. Aside from toy problems and demonstrations, the majority of problems require efficient numerical tools, many of which require the same base code (e.g., for performing numerical orbit integration).

# Statement of need

`meow` is a package written in R to facilitate innovation and research in the computer adaptive testing (CAT) space by allowing users to develop their own parameter update and item selection algorithms.

Software to simulate CAT data already exists, the most popular of which are `mirtCAT` [@chalmers2016generating] and `catR`[@magis2017computerized]. The key to understanding the purpose of these packages (and the void that `meow` fills) is that these packages exist to facilitate the administration of CATs and conduct test-design based simulations. This is facilitated with a selection of in-built item response theory models for ability estimation, item selection methods, and stopping rules. The issue, however, is that if a researcher is developing new parameter update algorithms, item selection algorithms, or stopping rules, this requires a largely from-scratch implementation to conduct simulation studies that compare their methods to existing methods. `meow` modularizes CAT simulations by dividing the CAT into three distinct parts: (1) data generation, (2) parameter updates, and (3) item selection and stopping rule. Each of these modules is supported by a central framework that provides a consistent API to facilitate simple and reproducible simulation studies. While `meow` contains a selection of built-in data generating processes (DGPs), parameter update methods, and item selection algorithms, the advance is a documented and flexible platform in which users can implement their own versions of any of these pieces and swap them in and out of simulation studies to provide directly comparable results.

# Mathematics

Single dollars (\$) are required for inline mathematics e.g. $f(x) = e^{\pi/x}$

Double dollars make self-standing equations:

$$\Theta(x) = \left\{\begin{array}{l}
0\textrm{ if } x < 0\cr
1\textrm{ else}
\end{array}\right.$$

You can also use plain \LaTeX for equations \begin{equation}\label{eq:fourier}
\hat f(\omega) = \int_{-\infty}^{\infty} f(x) e^{i\omega x} dx
\end{equation} and refer to \autoref{eq:fourier} from text.

# Citations

Citations to entries in paper.bib should be in [rMarkdown](http://rmarkdown.rstudio.com/authoring_bibliographies_and_citations.html) format.

If you want to cite a software repository URL (e.g. something on GitHub without a preferred citation) then you can do it with the example BibTeX entry below for @fidgit.

For a quick reference, the following citation commands can be used: - `@author:2001` -\> "Author et al. (2001)" - `[@author:2001]` -\> "(Author et al., 2001)" - `[@author1:2001; @author2:2001]` -\> "(Author1 et al., 2001; Author2 et al., 2002)"

# Figures

Figures can be included like this: ![Caption for example figure.](figure.png) and referenced from text using \autoref{fig:example}.

Figure sizes can be customized by adding an optional second parameter: ![Caption for example figure.](figure.png){width="20%"}

# Acknowledgements

We acknowledge contributions from Brigitta Sipocz, Syrtis Major, and Semyeong Oh, and support from Kathryn Johnston during the genesis of this project.

# References