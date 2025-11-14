# Data Loaders

The `meow` framework is built around a central function,
[`meow()`](http://klintkanopka.com/meow/reference/meow.md). This
function relies on three other ingredients to build your simulation: 1.
A *data loader* that either loads or generates data to perform the
simulation on 2. An *item selection function* that implements the
algorithm that selects the next item for your respondents 3. A
*parameter update function* that implements the algorithm that is used
to update the internal person and item parameters

In this vignette, we will talk about what data loaders are, how to use
the ones we’ve supplied, and how to write your own.

## Writing your own data loaders

Data loaders are where you encode your data generating process (DGP) for
a simulation. We provide two very basic data loaders, one that loads
pre-generated parameters and responses from files, and one that
generates data according to a 1PL IRT model. Let’s start with the loader
that reads existing data to take a look at the core features any data
loader function needs to participate cooperatively in the `meow`
ecosystem.

``` r
data_existing <- function(
  resp_path = 'data/sample-resp.csv',
  pers_path = 'data/true-sample-theta.rds',
  item_path = 'data/true-sample-diff.rds'
) {
  out <- list(
    resp = utils::read.csv(resp_path),
    pers_tru = readRDS(pers_path),
    item_tru = readRDS(item_path)
  )
  return(out)
}
```

### Function arguments

Interestingly enough, there are no required inputs for a data loader
function, as it’s the first thing that gets called in an internal `meow`
simulation. Your data loader can have, theoretically, whatever arguments
you like with only a few exceptions.

The arguments `pers`, `item`, `resp`, `resp_cur`, `adj_mat`, and
`select_seed` should not be used, as these are standard arguments used
in the item selection and parameter update functions.

Besides these, any argument names are generally fine and can be passed
directly through to your data loader as named arguments to the
[`meow()`](http://klintkanopka.com/meow/reference/meow.md) function.

### Return values

First, let’s look at the output. You can see that it’s a list with three
named components: `resp`, `pers_tru`, and `item_tru`.

#### The `$resp` object

A `resp` object is a dataframe of item response data in *long form*. It
contains three columns, each containing *numeric* data, and the response
matrix is aligned to the data standard in the [Item Response
Warehouse](https://itemresponsewarehouse.org/). The first, `id`,
contains a 1-indexed integer respondent id for person $i$. The second,
`item`, contains a 1-indexed item identifier for item $j$. The third,
`resp`, contains the simulated response of person $i$ to item $j$,
$x_{ij}$. For dichotomous responses, we use a binary response variable,
$x_{ij} \in \{ 0,1\}$.

#### The `$pers_tru` object

Next, we have the `pers_tru` object. Currently, this is implemented as a
dataframe that contains the true abilities, where the `i`th element of
the column`$theta`, $\theta_{i}$, is the true ability of the
$i^{\text{th}}$ respondent. This is implemented as a dataframe to allow
for users to expand the number of person parameters used in case they
want to implement multidimensional items, for example.

#### The `$item_tru` object

Finally, we come to the `item_tru` object. Currently, this is
implemented as a dataframe that contains the true abilities, where the
`j`th element of the column `$b`, $b_{j}$, is the true difficulty of the
$j^{\text{th}}$ item. Additional columns, like `$a`, contain
discrimination parameters. Again, dataframes are used to facilitate
easily extending the amount of item parameters that are passed around.

## Implementing a 1PL data loader

Now let’s look at our default 1PL based data loader. The code for it is
shown below:

``` r
data_simple_1pl <- function(
  N_persons = 100,
  N_items = 50,
  data_seed = 242424
) {
  # note default behavior is fixed seed to ensure data consistency across runs
  set.seed(data_seed)

  pers_tru <- data.frame(id = 1:N_persons, theta = stats::rnorm(N_persons))
  item_tru <- data.frame(item = 1:N_items, b = stats::rnorm(N_items), a = 1)

  theta_mat <- matrix(
    pers_tru$theta,
    nrow = N_persons,
    ncol = N_items,
    byrow = FALSE
  )
  diff_mat <- matrix(item_tru$b, nrow = N_persons, ncol = N_items, byrow = TRUE)
  disc_mat <- matrix(item_tru$a, nrow = N_persons, ncol = N_items, byrow = TRUE)

  p <- stats::plogis(disc_mat * (theta_mat - diff_mat))
  resp <- matrix(
    stats::rbinom(length(p), 1, p),
    nrow = N_persons,
    ncol = N_items
  ) |>
    as.data.frame() |>
    dplyr::mutate(id = 1:N_persons) |>
    tidyr::pivot_longer(
      tidyselect::starts_with('V'),
      names_to = 'item',
      values_to = 'resp',
      names_prefix = 'V'
    ) |>
    dplyr::select(.data$id, .data$item, .data$resp) |>
    dplyr::mutate(dplyr::across(tidyselect::everything(), as.numeric))

  out <- list(resp = resp, pers_tru = pers_tru, item_tru = item_tru)
  set.seed(NULL)
  return(out)
}
```

This function simulates data according to a very simple and inflexible
DGP. It takes a number of respondents, `N_persons`, a number of items,
`N_items`, and a random seed, `data_seed`, and does the following:

1.  Sets a seed according to the supplied `data_seed`.
2.  Simulates person abilities, $\theta_{i}$, for
    $i \in \{ 1,...,N_{\text{persons}}\}$ where
    $$\theta_{i} \sim \mathcal{N}(0,1)$$
3.  Simulates item difficulties, $b_{j}$, for
    $j \in \{ 1,...,N_{\text{items}}\}$ where
    $$b_{j} \sim \mathcal{N}(0,1)$$
4.  Simulates dichotomous item responses, $x_{ij} \in \{ 0,1\}$,
    according to a 1PL item response function:
    $$P\left( x_{ij} = 1|\theta_{i} \right) = \frac{1}{1 + e^{-{(\theta_{i} - b_{j})}}}$$
5.  Clears the seed by calling `set.seed(NULL)`, so that the subsequent
    analysis is not determined by the data seed.
6.  Packages these items up in their respective dataframes and returns
    them inside of a list object.

## Final important note on setting random seeds

If your data loader uses any random number generation and you allow it
to take a random seed for reproducibility, make sure to clear the seed
at the end of your data loader by calling `set.seed(NULL)`. If you
don’t, the current version of that seed will persist for all of the
downstream simulation, and the full process will become deterministic.
Specifically, if you want to compare multiple runs of an item selection
and/or parameter update algorithm that uses some degree of randomization
when applied to the same dataset, failing to clear the seed at the end
of the data loader will make this impossible.
