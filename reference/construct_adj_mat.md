# Construct an item-pool adjacency matrix.

For an item pool with N items, this returns an N x N matrix. The
diagonal elements contain the number of times each item has been
administered. The off-diagonal element \\(i, j)\\ contains the number of
respondents who have been administered both item \\i\\ and item \\j\\.
In general this function is not called directly, but is instead called
within [`meow()`](https://klintkanopka.com/meow/reference/meow.md). It
is exposed to aid users who are testing item selection functions they
have written.

## Usage

``` r
construct_adj_mat(admin)
```

## Arguments

- admin:

  An administration matrix with one row per respondent and one column
  per item. Non-zero entries indicate that an item has been administered
  to a respondent (see
  [`meow()`](https://klintkanopka.com/meow/reference/meow.md) for
  details of the matrix-based simulation state). A logical matrix is
  also accepted.

## Value

An item-item adjacency matrix of type `matrix`.

## Examples

``` r
admin <- matrix(c(1, 1, 0,
                  1, 0, 1), nrow = 2, byrow = TRUE)
construct_adj_mat(admin)
#>        item_1 item_2 item_3
#> item_1      2      1      1
#> item_2      1      1      0
#> item_3      1      0      1
```
