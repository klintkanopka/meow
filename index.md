# meow

`meow` is a package for conducting simulations of computer adaptive
testing (CAT). The pitch here is that `meow` is a framework that
facilitates reproducible comparisons between different combinations of
data generating processes (DGPs), item selection algorithms, and
parameter update algorithms.

We do this by functionalizing these components as treating them modular
for use in a core simulation harness that produces consistent outputs
with some `ggplot2`-based visualization tools. The goal is to expose the
structure of these component functions to the user, allowing them to
implement their own custom DGPs, selection algorithms, and update
algorithms.

Users are also encouraged to contribute function modules associated with
their research projects, facilitating more community interaction.

## Installation

Interested users can install using:

``` r

devtools::install_github("klintkanopka/meow")
```

## Usage

A simulation is a single call to
[`meow()`](http://klintkanopka.com/meow/reference/meow.md), which takes
an item selection function, a parameter update function, and a data
loader:

``` r

library(meow)

sim <- meow(
  select_fun  = select_max_info,    # item selection algorithm
  update_fun  = update_theta_mle,   # parameter update algorithm
  data_loader = data_simple_1pl,    # data generating process
  data_args   = list(N_persons = 100, N_items = 50),
  fix         = "item"              # treat item parameters as known
)

head(sim$results)   # per-iteration estimates and bias
```

`sim$results` is a tidy data frame (one row per iteration, est/bias
columns per parameter) that plugs directly into `ggplot2`.
`sim$adj_mats` holds the item co-exposure adjacency matrices.

## Writing your own modules

The real value of `meow` is in swapping in your own algorithms.
Internally the simulation state is matrix-based for speed: item
selection and parameter update functions receive a respondent-by-item
response matrix `R` and an integer administration matrix `admin`, and
person/item parameters stay as data frames so you can add arbitrary
columns. See
[`vignette("extending-meow")`](http://klintkanopka.com/meow/articles/extending-meow.md)
for the full module contracts, or use
[`meow_long()`](http://klintkanopka.com/meow/reference/meow_long.md) to
work with long data frames instead.
