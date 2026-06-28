# Implementing the Maths Garden Update Algorithm

The Maths Garden algorithm (Klinkenberg, Straatemeier, and van der Maas,
2011) is a gradient-based, Elo-style estimation method for computer
adaptive practice systems. It updates person abilities and item
difficulties on the fly, which makes it well suited to real-time
educational applications.

## Mathematical foundation

The algorithm updates both abilities ($`\theta`$) and difficulties
($`b`$) from prediction errors:

``` math
\theta_j^{new} = \theta_j + K_\theta \sum_{i \in I_j} (S_{ij} - E(S_{ij})),
\qquad
b_i^{new} = b_i + K_b \sum_{j \in J_i} (E(S_{ij}) - S_{ij}),
```

where $`S_{ij} \in \{0, 1\}`$ is the observed response, $`I_j`$ and
$`J_i`$ are the items answered by person $`j`$ and the people who
answered item $`i`$, and $`K_\theta`$, $`K_b`$ are learning rates. The
expected response follows the Rasch (1PL) model,

``` math
E(S_{ij}) = \frac{1}{1 + e^{-(\theta_j - b_i)}}.
```

Intuitively, performing better than expected raises an ability estimate;
an item answered correctly more often than expected becomes easier.

## Implementation in `meow`

[`update_maths_garden()`](https://klintkanopka.com/meow/reference/update_maths_garden.md)
follows the parameter update contract
([`vignette("parameter-update")`](https://klintkanopka.com/meow/articles/parameter-update.md)):
it reads the administered responses from the matrix state and returns
updated `pers` and `item` data frames. The prediction errors are
aggregated per respondent and per item with
[`tapply()`](https://rdrr.io/r/base/tapply.html) rather than explicit
loops:

``` r

update_maths_garden <- function(pers, item, R, admin, K_theta = 0.1, K_b = 0.1) {
  idx    <- which(admin != 0, arr.ind = TRUE)
  person <- idx[, 1]
  itm    <- idx[, 2]
  resp   <- R[idx]

  E_Sij <- stats::plogis(pers$theta[person] - item$b[itm])

  dtheta <- tapply(resp - E_Sij, person, sum)
  pers$theta[as.integer(names(dtheta))] <-
    pers$theta[as.integer(names(dtheta))] + K_theta * dtheta

  db <- tapply(E_Sij - resp, itm, sum)
  item$b[as.integer(names(db))] <-
    item$b[as.integer(names(db))] + K_b * db

  list(pers = pers, item = item)
}
```

## Using it

Learning rates are passed through `update_args`:

``` r

sim <- meow(
  select_fun  = select_max_info,
  update_fun  = update_maths_garden,
  data_loader = data_simple_1pl,
  data_args   = list(N_persons = 100, N_items = 50),
  update_args = list(K_theta = 0.05, K_b = 0.05)
)
head(sim$results[, 1:3])
#>   iter pers_theta_1_est pers_theta_2_est
#> 1    1        0.1250000       -0.1250000
#> 2    2        0.2719033       -0.2595475
#> 3    3        0.3638822       -0.3739552
#> 4    4        0.4624840       -0.4569931
#> 5    5        0.5127578       -0.5627726
#> 6    6        0.5456892       -0.6114085
```

## Extending the algorithm

Because update functions are ordinary R functions, variations are easy.
The following adds **adaptive learning rates** (shrinking as a
respondent answers more items) and **bounds** on the estimates, while
staying within the matrix contract:

``` r

update_maths_garden_adaptive <- function(pers, item, R, admin,
                                         base_K = 0.1, decay = 0.05,
                                         bounds = c(-4, 4)) {
  idx    <- which(admin != 0, arr.ind = TRUE)
  person <- idx[, 1]
  itm    <- idx[, 2]
  resp   <- R[idx]
  E_Sij  <- stats::plogis(pers$theta[person] - item$b[itm])

  n_person <- tapply(resp, person, length)
  err_p    <- tapply(resp - E_Sij, person, sum)
  who_p    <- as.integer(names(err_p))
  K_p      <- base_K / (1 + n_person * decay)
  pers$theta[who_p] <- pers$theta[who_p] + K_p * err_p
  pers$theta <- pmin(pmax(pers$theta, bounds[1]), bounds[2])

  n_item <- tapply(resp, itm, length)
  err_i  <- tapply(E_Sij - resp, itm, sum)
  who_i  <- as.integer(names(err_i))
  K_i    <- base_K / (1 + n_item * decay)
  item$b[who_i] <- item$b[who_i] + K_i * err_i
  item$b <- pmin(pmax(item$b, bounds[1]), bounds[2])

  list(pers = pers, item = item)
}
```

## Practical notes

- Start with modest learning rates ($`K_\theta = K_b = 0.1`$) and check
  that estimates stabilize across iterations.
- Large learning rates can make estimates oscillate; bounding the
  estimates helps.
- The algorithm assumes a Rasch model; if your data need discrimination
  parameters, consider an MLE updater or a 2PL extension.
