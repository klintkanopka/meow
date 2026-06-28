# Network-based item selection with configurable edge weights.

Extends
[`select_max_dist()`](https://klintkanopka.com/meow/reference/select_max_dist.md)
with a flexible edge weight calculation.

## Usage

``` r
select_max_dist_enhanced(
  pers,
  item,
  R,
  admin,
  adj_mat = NULL,
  n_candidates = 1,
  edge_weight_fun = edge_weight_inverse,
  edge_weight_args = list()
)
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

- edge_weight_fun:

  A function that computes edge weights from the adjacency matrix. See
  [`edge_weight_inverse()`](https://klintkanopka.com/meow/reference/edge_weight_inverse.md).

- edge_weight_args:

  A named list of additional arguments for `edge_weight_fun`.

## Value

An updated administration matrix with the selected item marked for each
respondent.

## Examples

``` r
sim <- meow(select_max_dist_enhanced, update_theta_mle, data_simple_1pl,
            data_args = list(N_persons = 10, N_items = 10), fix = "item",
            select_args = list(edge_weight_fun = edge_weight_power))
nrow(sim$results)
#> [1] 6
```
