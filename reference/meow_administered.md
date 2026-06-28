# Logical mask of administered items.

A convenience helper for use inside user-written modules. Returns a
logical matrix that is `TRUE` wherever an item has been administered to
a respondent.

## Usage

``` r
meow_administered(admin)
```

## Arguments

- admin:

  An administration matrix (see
  [`meow()`](http://klintkanopka.com/meow/reference/meow.md)).

## Value

A logical matrix the same shape as `admin`.

## Examples

``` r
admin <- matrix(c(1L, 2L, 0L, 1L), nrow = 2)
meow_administered(admin)
#>      [,1]  [,2]
#> [1,] TRUE FALSE
#> [2,] TRUE  TRUE
```
