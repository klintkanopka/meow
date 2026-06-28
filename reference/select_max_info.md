# Item selection by maximum Fisher information.

Administers the remaining item with the highest information for each
respondent, computed from the current parameter estimates and a 2PL item
response function.

## Usage

``` r
select_max_info(pers, item, R, admin, adj_mat = NULL)
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

## Value

An updated administration matrix with the most informative remaining
item marked for each respondent.

## Examples

``` r
sim <- meow(select_max_info, update_theta_mle, data_simple_1pl,
            data_args = list(N_persons = 10, N_items = 10), fix = "item")
nrow(sim$results)
#> [1] 6
```
