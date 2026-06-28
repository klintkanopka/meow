# Item selection by item id, simulating a fixed test form.

This function administers the next unadministered item to each
respondent in increasing item-id order, producing a fixed linear test
form.

## Usage

``` r
select_sequential(pers, item, R, admin, adj_mat = NULL)
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
  [`meow()`](http://klintkanopka.com/meow/reference/meow.md) for
  details.

- adj_mat:

  An item-item adjacency matrix. See
  [`construct_adj_mat()`](http://klintkanopka.com/meow/reference/construct_adj_mat.md).

## Value

An updated administration matrix with each respondent's next item marked
as administered.

## Examples

``` r
sim <- meow(select_sequential, update_theta_mle, data_simple_1pl,
            data_args = list(N_persons = 10, N_items = 10), fix = "item")
nrow(sim$results)
#> [1] 6
```
