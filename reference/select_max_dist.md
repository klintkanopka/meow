# Item selection by network distance criterion.

Administers the item farthest in the item network from the items a
respondent has already answered, with edges weighted by the inverse of
their entry in the item-item adjacency matrix. Ties are broken using the
maximum information criterion.

## Usage

``` r
select_max_dist(pers, item, R, admin, adj_mat = NULL, n_candidates = 1)
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

- n_candidates:

  The number of farthest items to assemble into a candidate pool before
  selecting the next item by maximum information. Allows users to trade
  off network density against estimation efficiency.

## Value

An updated administration matrix with the selected item marked for each
respondent.

## Examples

``` r
sim <- meow(select_max_dist, update_theta_mle, data_simple_1pl,
            data_args = list(N_persons = 10, N_items = 10), fix = "item")
nrow(sim$results)
#> [1] 6
```
