# Data Loaders

The `meow` framework is built around a central function,
[`meow()`](https://klintkanopka.com/meow/reference/meow.md). This
function relies on three other ingredients to build your simulation:

1.  A *data loader* that either loads or generates the data to simulate
    on.
2.  An *item selection function* that selects the next item for each
    respondent.
3.  A *parameter update function* that updates the internal person and
    item parameters.

This vignette covers data loaders: what they are, how to use the bundled
ones, and how to write your own.

## What a data loader returns

A data loader returns a list with three named components: `resp`,
`pers_tru`, and `item_tru`. The simplest loader,
[`data_existing()`](https://klintkanopka.com/meow/reference/data_existing.md),
just reads them from files:

``` r

data_existing <- function(resp_path, pers_path, item_path) {
  list(
    resp = utils::read.csv(resp_path),
    pers_tru = utils::read.csv(pers_path),
    item_tru = utils::read.csv(item_path)
  )
}
```

#### The `resp` object

`resp` is a long-form data frame of item responses with three numeric
columns, aligned to the standard used by the [Item Response
Warehouse](https://itemresponsewarehouse.org/): `id` (a 1-indexed
respondent identifier), `item` (a 1-indexed item identifier), and `resp`
(the response $`x_{ij}`$, with $`x_{ij} \in \{0, 1\}`$ for dichotomous
items). [`meow()`](https://klintkanopka.com/meow/reference/meow.md)
converts this long table into a respondent-by-item matrix once, before
the simulation loop.

#### The `pers_tru` object

`pers_tru` is a data frame of true person parameters. Its first column,
`id`, identifies respondents; the remaining columns are parameters
(e.g. `theta`). Using a data frame lets you add parameters — for
instance, extra dimensions for a multidimensional model — without
changing the framework.

#### The `item_tru` object

`item_tru` is a data frame of true item parameters, with `item` as its
first column followed by parameter columns such as `b` (difficulty) and
`a` (discrimination). As with person parameters, you can add columns
freely.

### Function arguments

A data loader is the first thing
[`meow()`](https://klintkanopka.com/meow/reference/meow.md) calls, so it
has no required arguments — it may take whatever you pass through
`data_args`. The only names to avoid are those the harness supplies to
the other modules: `pers`, `item`, `R`, `admin`, `adj_mat`, and
`select_seed`.

## The bundled 1PL loader

[`data_simple_1pl()`](https://klintkanopka.com/meow/reference/data_simple_1pl.md)
generates data from a 1PL model with standard-normal abilities and
difficulties:

``` r

data_simple_1pl <- function(N_persons = 100, N_items = 50, data_seed = 242424) {
  set.seed(data_seed)
  pers_tru <- data.frame(id = 1:N_persons, theta = stats::rnorm(N_persons))
  item_tru <- data.frame(item = 1:N_items, b = stats::rnorm(N_items), a = 1)

  theta_mat <- matrix(pers_tru$theta, N_persons, N_items)
  diff_mat  <- matrix(item_tru$b, N_persons, N_items, byrow = TRUE)
  p <- stats::plogis(theta_mat - diff_mat)
  resp_mat <- matrix(stats::rbinom(length(p), 1, p), N_persons, N_items)

  resp <- data.frame(
    id = rep(seq_len(N_persons), each = N_items),
    item = rep(seq_len(N_items), times = N_persons),
    resp = as.vector(t(resp_mat))
  )
  set.seed(NULL)
  list(resp = resp, pers_tru = pers_tru, item_tru = item_tru)
}
```

It draws abilities $`\theta_i \sim \mathcal{N}(0, 1)`$ and difficulties
$`b_j \sim \mathcal{N}(0, 1)`$, then generates responses from the 1PL
item response function
``` math
P(x_{ij} = 1 \mid \theta_i) = \frac{1}{1 + e^{-(\theta_i - b_j)}}.
```

``` r

data <- data_simple_1pl(N_persons = 6, N_items = 4)
str(data, max.level = 1)
#> List of 3
#>  $ resp    :'data.frame':    24 obs. of  3 variables:
#>  $ pers_tru:'data.frame':    6 obs. of  2 variables:
#>  $ item_tru:'data.frame':    4 obs. of  3 variables:
head(data$resp)
#>   id item resp
#> 1  1    1    1
#> 2  1    2    0
#> 3  1    3    1
#> 4  1    4    0
#> 5  2    1    0
#> 6  2    2    0
```

## A note on random seeds

If your data loader uses random number generation and accepts a seed for
reproducibility, **clear the seed at the end** with `set.seed(NULL)`.
Otherwise the seed persists into the rest of the simulation and makes
the downstream item selection and parameter updates deterministic, which
will prevent you from comparing multiple stochastic runs on the same
data set.
