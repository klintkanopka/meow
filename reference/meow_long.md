# Convert the matrix simulation state to a long data frame of responses.

[`meow()`](https://klintkanopka.com/meow/reference/meow.md) represents
responses as a respondent-by-item matrix (`R`) together with an
administration matrix (`admin`). This helper returns the administered
responses as a long data frame with columns `id`, `item`, and `resp`,
ordered by respondent and then by the order in which items were
administered. It is the recommended bridge for module authors who prefer
to work with tidyverse-style long data inside their own item selection
or parameter update functions.

## Usage

``` r
meow_long(R, admin)
```

## Arguments

- R:

  A respondent-by-item matrix of (potential) responses.

- admin:

  An administration matrix the same shape as `R`. Non-zero entries
  indicate administered items; positive integer entries additionally
  encode the order of administration.

## Value

A long-form data frame with columns `id`, `item`, and `resp` containing
only the administered responses.

## Examples

``` r
R <- matrix(c(1, 0, 1, 1), nrow = 2)
admin <- matrix(c(1L, 0L, 2L, 1L), nrow = 2)
meow_long(R, admin)
#>   id item resp
#> 1  1    1    1
#> 2  1    2    1
#> 3  2    2    1
```
