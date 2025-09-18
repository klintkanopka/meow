---
title: 'meow: A unified framework for conducting simulations of computer adaptive testing (CAT) algorithms in R'
tags:
  - R
  - psychometrics
  - computer adaptive testing
  - cat
  - simulation studies
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
date: 17 Sept 2025
bibliography: paper.bib
---

# Summary

Computer adaptive testing (CAT) is an approach to assessment where the responses an examinee have previously given to questions play some role in deciding the subsequent questions they will be presented with. This style of testing allows for increased measurement precision with fewer items, a benefit for test administrators and test takers alike. Advances in CAT are done at the algorithmic level; new methods are developed to better select next items, update person and item parameters, control how often items are exposed to respondents, and decide when to stop administering new questions. Determining the potential measurement consequences of new algorithmic decisions requires developers to run comparison simulations that demonstrate effectiveness and tradeoffs. This demands porting the methods of other researchers into ad hoc simulation frameworks that are often designed to conduct single simulation studies. With `meow`, we modularize the core components of the CAT administration process and allow users to conduct standardized, comparable, and reproducible simulation studies.

# Statement of need

`meow` is a package written in R to facilitate psychometric research in the computer adaptive testing (CAT) space that focuses on the development of new CAT algorithms. Software to simulate CAT data already exists, the most popular of which are `mirtCAT` [@chalmers2016generating] and `catR`[@magis2017computerized], but others also exist[@choi2009firestar;@han2012simulcat;@oppl2017flexible]. The key to understanding the purpose of these packages (and the gap that `meow` fills) is that existing software facilitates simulating the _administration_ of CATs for the purpose of comparing test designs in a given context with a given item pool. As such, these packages come with a selection of in-built item response theory models for ability estimation and pre-built item selection methods, exposure controls, and stopping rules. The issue, however, is that if a researcher is _developing_ any new parameter update algorithms, item selection algorithms, exposure controls, or stopping rules, this requires a largely from-scratch implementation to conduct simulation studies that compare their new methods to existing approaches. As CAT research increasingly augments traditional psychometrics with computational approaches [@liu2024survey], the need for algorithmic comparison studies only increases. Using `meow`, users can easily implement new CAT algorithms that can be quickly integrated into existing simulation studies and shared with other researchers doing CAT development work.

# Features

To avoid frequent reinvention of the wheel, `meow` modularizes CAT simulations by dividing the CAT administration into three distinct parts: (1) data generation, (1) item selection (including exposure control and a stopping rule), and (3) parameter updates. Each of these modules is supported by a central simulation framework, providing a consistent API to facilitate simple and reproducible simulation studies. While `meow` contains a selection of built-in data generating processes (DGPs), item selection algorithms, and parameter update methods, the advance is a documented and flexible platform in which users can implement their own versions of any of these pieces. The end result is the ability to swap algorithms in and out of larger simulation studies to provide directly comparable and reproducible results.

Simulations in `meow` are built around conducting a single call to the function `meow()`. As arguments, this takes an item selection function, a parameter update function, and a data loader function. These three components dictate how the simulation will be carried out, and `meow` comes bundled with off-the-shelf implementations of a selection of common parameter update and item selection algorithms, including classic methods and example implementations of recently published methods [@gorney2025using;klinkenberg2011mathsgarden;@van2000computerized;@vermeiren2025psychometrics]. Users also have the ability to supply initial values for internal parameters and set random seeds for each individual component of the simulation, allowing for customizability, reproducibility, and comparability between runs. Each simulation outputs consistently formatted estimates and bias for each internal parameter at each iteration of the simulation, allowing users to easily parse and recycle visualization code using commonly available `R` tools. 

The real value of `meow` is to the developer of new algorithms, however. Using a common API, users can implement their own methodological developments quickly and easily in `meow`. Vignettes walk users through the development process. To facilitate easier development, internally parameter values are currently stored in dataframes. This has two advantages: First, it allows users to easily add more person or item parameters while still handing off the same internal objects. Second, it allows the use of `tidyverse` style data manipulation within the user-developed modules. This does have performance ramifications, however. As such, future versions of `meow` may implement changes to the structure of these objects in response to community feedback.

Output is designed to be easily visualized using commonly used tools, such as `ggplot2.` The output object structure is defined by the framework itself, not by any specific algorithmic component, allowing for reuse of visualization and analysis pipelines. A visualization-focused vignette walks users through understanding the structure of output objects and builds some commonly used visualizations, such as parameter trajectories and RMSE curves. Additionally, the output objects also contain adjacency matrices that count the number of respondents each pair of item has been exposed to. In addition to being useful for implementing simple exposure controls, this allows for simplified analysis and visualization of item utilization patterns.

The goal of the `meow` project is to advance CAT algorithm development research by serving as a central repository for implementations of new work. Users are encouraged to submit pull requests to merge their algorithmic advances back into the package so that they can easily have their work integrated into simulation studies conducted by future researchers. This goal has led to `meow` being developed with expandability and future maintenance in mind.

# Ongoing Research

Development of `meow` was motivated by ongoing research by the authors in CAT algorithm development that models the item pool as a network object.

# Acknowledgements

We specifically thank Kylie Gorney for valuable feedback on the implementation and usability of this software.

# References