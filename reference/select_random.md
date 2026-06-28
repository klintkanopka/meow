# Item selection by random draw from the remaining item bank.

Each respondent's next item is drawn at random from the items they have
not yet been administered.

## Usage

``` r
select_random(pers, item, R, admin, adj_mat = NULL, select_seed = NULL)
```

## Arguments

- pers:

  A data frame of current respondent ability estimates.

- item:

  A data frame of current item parameter estimates.

- R:

  A respondent-by-item matrix of potential responses.

- admin:

  An integer administration matrix; `0` indicates an item has not been
  administered to a respondent. See
  [`meow()`](https://klintkanopka.com/meow/reference/meow.md) for
  details.

- adj_mat:

  An item-item adjacency matrix. See
  [`construct_adj_mat()`](https://klintkanopka.com/meow/reference/construct_adj_mat.md).

- select_seed:

  A random seed used only for item selection. The seed is cleared after
  use so that successive simulations vary unless a seed is given.

## Value

An updated administration matrix with a random next item marked for each
respondent.

## Examples

``` r
sim <- meow(select_random, update_theta_mle, data_simple_1pl,
            data_args = list(N_persons = 10, N_items = 10), fix = "item",
            select_args = list(select_seed = 1))
nrow(sim$results)
#> [1] 6
```
