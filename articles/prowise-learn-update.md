# Implementing the Prowise Learn Update Algorithm

The Prowise Learn algorithm (Vermeiren et al., 2025) extends the
Elo-style Maths Garden updates
([`vignette("maths-garden-update")`](https://klintkanopka.com/meow/articles/maths-garden-update.md))
with **paired item updates** that counteract rating drift — the tendency
for item difficulty estimates to slide systematically over time.

## Mathematical foundation

Abilities are updated exactly as in Maths Garden:

``` math
\theta_j^{new} = \theta_j + K_\theta \sum_{i \in I_j} (S_{ij} - E(S_{ij})).
```

Item difficulties, however, are updated in **consecutive pairs** of
items administered to the same respondent. For a pair (previous item,
current item),

``` math
\kappa = 0.5\,\big(K_b (S_{now} - E_{now}) - K_b (S_{prev} - E_{prev})\big),
\qquad
b_{now} \mathrel{+}= \kappa, \quad b_{prev} \mathrel{-}= \kappa.
```

Because each pair adds $`+\kappa`$ to one item and $`-\kappa`$ to the
other, the total difficulty mass is conserved, so items keep their
relative positions and do not drift en masse. Expected responses use the
Rasch model, $`E(S_{ij}) = 1 / (1 + e^{-(\theta_j - b_i)})`$.

## Implementation in `meow`

Paired updates are inherently **order dependent**, so
[`update_prowise_learn()`](https://klintkanopka.com/meow/reference/update_prowise_learn.md)
uses `meow_long(R, admin)`, which returns the administered responses
ordered by respondent and then by administration order. Consecutive
within-respondent rows form the pairs; the per-item contributions are
aggregated with [`tapply()`](https://rdrr.io/r/base/tapply.html):

``` r

update_prowise_learn <- function(pers, item, R, admin, K_theta = 0.1, K_b = 0.1) {
  long  <- meow_long(R, admin)
  E_Sij <- stats::plogis(pers$theta[long$id] - item$b[long$item])

  # ability update (as in Maths Garden)
  dtheta <- tapply(long$resp - E_Sij, long$id, sum)
  pers$theta[as.integer(names(dtheta))] <-
    pers$theta[as.integer(names(dtheta))] + K_theta * dtheta

  # paired item updates over consecutive administrations
  n <- nrow(long)
  if (n >= 2) {
    nxt <- 2:n; prv <- 1:(n - 1)
    pair <- which(long$id[nxt] == long$id[prv])
    if (length(pair) > 0) {
      now <- nxt[pair]; pre <- prv[pair]
      kappa <- 0.5 * (K_b * (long$resp[now] - E_Sij[now]) -
                      K_b * (long$resp[pre] - E_Sij[pre]))
      add_now <- tapply(kappa,  long$item[now], sum)
      add_pre <- tapply(-kappa, long$item[pre], sum)
      item$b[as.integer(names(add_now))] <- item$b[as.integer(names(add_now))] + add_now
      item$b[as.integer(names(add_pre))] <- item$b[as.integer(names(add_pre))] + add_pre
    }
  }
  list(pers = pers, item = item)
}
```

## Using it

``` r

sim <- meow(
  select_fun  = select_max_info,
  update_fun  = update_prowise_learn,
  data_loader = data_simple_1pl,
  data_args   = list(N_persons = 100, N_items = 50),
  update_args = list(K_theta = 0.05, K_b = 0.05)
)
head(sim$results[, 1:3])
#>   iter pers_theta_1_est pers_theta_2_est
#> 1    1        0.1250000       -0.1250000
#> 2    2        0.2656826       -0.2657371
#> 3    3        0.3692123       -0.3715956
#> 4    4        0.4806109       -0.4711769
#> 5    5        0.5559021       -0.6101828
#> 6    6        0.6200887       -0.7172594
```

## Practical notes

- Paired updates require respondents to answer at least two items, so
  the item difficulties only begin to move once administration is under
  way.
- Effectiveness depends on the administration order; this is exactly why
  the matrix `admin` carries the order of administration.
- As with Maths Garden, keep learning rates modest and consider bounding
  the estimates for stability.
