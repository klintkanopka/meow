# Elo-style updates with paired item comparisons (Prowise Learn).

Updates both person and item parameters following Vermeiren et al.
(2025), "Psychometrics of an Elo-based large-scale online learning
system." Item difficulties are updated using paired comparisons of
consecutively administered items, which controls the rating drift that
can occur with naive Elo updates.

## Usage

``` r
update_prowise_learn(pers, item, R, admin, K_theta = 0.1, K_b = 0.1)
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
upd <- update_prowise_learn(data$pers_tru, data$item_tru, R, admin)
```
