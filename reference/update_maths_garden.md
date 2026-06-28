# Elo-style updates of person and item parameters (Maths Garden).

Updates both person and item parameters following Klinkenberg,
Straatemeier, and van der Maas (2011), "Computer adaptive practice of
Maths ability using a new item response model for on the fly ability and
difficulty estimation." Learning rates are tunable through `K_theta` and
`K_b`.

## Usage

``` r
update_maths_garden(pers, item, R, admin, K_theta = 0.1, K_b = 0.1)
```

## Arguments

- pers:

  A data frame of current respondent parameter estimates.

- item:

  A data frame of current item parameter estimates.

- R:

  A respondent-by-item matrix of potential responses.

- admin:

  An integer administration matrix; non-zero entries indicate
  administered items. See
  [`meow()`](https://klintkanopka.com/meow/reference/meow.md) for
  details.

- K_theta:

  Learning rate for person ability updates. Defaults to 0.1.

- K_b:

  Learning rate for item difficulty updates. Defaults to 0.1.

## Value

A list with two entries: `pers` and `item`, the data frames of updated
respondent and item parameter estimates.

## Examples

``` r
data <- data_simple_1pl(N_persons = 10, N_items = 10)
admin <- matrix(0L, 10, 10)
admin[, 1:5] <- 1L
R <- matrix(data$resp$resp, nrow = 10, byrow = TRUE)
upd <- update_maths_garden(data$pers_tru, data$item_tru, R, admin)
```
