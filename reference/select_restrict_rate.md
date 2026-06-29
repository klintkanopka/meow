# Maximum-information item selection with an exposure-rate cap.

A maximum Fisher information selector with a simple exposure control.
Each item's share of all administrations so far (the diagonal of
`adj_mat`, normalized to sum to one) is treated as an exposure rate, and
items whose rate has reached `r_max` are withheld. The most informative
permitted item is then administered to each respondent. If a respondent
has no permitted unadministered item, they receive no item that
iteration; when this occurs for every remaining respondent at once, the
simulation administers nothing new and stops, so this selector also acts
as an implicit stopping rule.

## Usage

``` r
select_restrict_rate(pers, item, R, admin, adj_mat = NULL, r_max = 0.025)
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

- r_max:

  The maximum permitted exposure rate (an item's share of all
  administrations) before that item is withheld. Defaults to 0.025.

## Value

An updated administration matrix with the most informative permitted
item marked for each respondent who still has one.

## Details

Because the exposure rate is each item's share of all administrations,
its average across items is `1 / N_items`. Values of `r_max` above
`1 / N_items` rarely bind, values near it bind only transiently, and
values below it induce early stopping.

## Examples

``` r
sim <- meow(select_restrict_rate, update_theta_mle, data_simple_1pl,
            data_args = list(N_persons = 10, N_items = 10), fix = "item",
            select_args = list(r_max = 0.2))
nrow(sim$results)
#> [1] 6
```
