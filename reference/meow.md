# Conducts a full CAT simulation.

`meow()` is the core function of this simulation framework and exists to
help users compare efficiency tradeoffs across different item selection
algorithms, parameter update algorithms, and data generating processes.
It takes as arguments an item selection function, a parameter update
function, and a data loader function and uses these to carry out a
simulation of a full CAT administration. Default behavior is proceed
until all items have been administered. Since internal simulation logic
checks to see if additional items are being administered, early stopping
conditions should be implemented within the item selection functions.
Internal parameters are passed around as dataframes for maximum
flexibility.

## Usage

``` r
meow(
  select_fun,
  update_fun,
  data_loader,
  select_args = list(),
  update_args = list(),
  data_args = list(),
  init = NULL,
  fix = "none"
)
```

## Arguments

- select_fun:

  A function that specifies the item selection algorithm.

- update_fun:

  A function that specifies the parameter update algorithm.

- data_loader:

  A function that specifies the data generating process.

- select_args:

  A named list of arguments to be passed to `select_fun`.

- update_args:

  A named list of arguments to be passed to `update_fun`.

- data_args:

  A named list of arguments to be passed to `data_loader`.

- init:

  A list of initialization values for estimated person and item
  parameters. Currently accepts a named list with two entities: `pers`
  and `item`, for initial estimated values of ability and difficulty,
  respectively. Defaults to `NULL`, which initializes all estimated
  parameters to zero.

- fix:

  Which estimated parameters to treat as fixed. Currently defaults to
  `none`, but accepts `pers`, `item`, or `both`.\`

## Value

A list of four named entities, `results` is a dataframe with one row per
iteration of the simulation. It contains one `iter` for the iteration
number and two columns per person and item parameter, one for the
associated estimated parameter and one for the bias in that estimate.
Next is a list of item-item adjacency matrices, contained in `adj_mats`.
One matrix is provided per iteration of the simulation, and edge weights
are the number of respondents who have responded to each pair of items.
Finally, true ability and difficulty dataframes are returned in
`pers_tru` and `item_tru`.
