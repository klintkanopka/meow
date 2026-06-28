# Update person ability via maximum likelihood estimation.

This update function treats item parameters as fixed and known and
updates person ability estimates after each iteration with a maximum
likelihood estimate based on a 2PL item response function.

## Usage

``` r
update_theta_mle(pers, item, R, admin)
```

## Arguments

- pers:

  A data frame of current respondent parameter estimates.

- item:

  A data frame of item parameter values.

- R:

  A respondent-by-item matrix of potential responses.

- admin:

  An integer administration matrix; non-zero entries indicate
  administered items. See
  [`meow()`](http://klintkanopka.com/meow/reference/meow.md) for
  details.

## Value

A list with two entries: `pers`, a data frame with updated respondent
ability estimates, and `item`, the unchanged data frame of item
parameters.

## Examples

``` r
data <- data_simple_1pl(N_persons = 10, N_items = 10)
admin <- matrix(0L, 10, 10)
admin[, 1:5] <- 1L
R <- matrix(data$resp$resp, nrow = 10, byrow = TRUE)
upd <- update_theta_mle(data$pers_tru, data$item_tru, R, admin)
head(upd$pers)
#>   id      theta
#> 1  1  0.3489388
#> 2  2 -1.6450743
#> 3  3  1.4305338
#> 4  4 -4.0000000
#> 5  5  1.4305196
#> 6  6 -1.6450809
```
