# Parameter Update Functions

Parameter update functions re-estimate person and item parameters from
the responses administered so far. They are the estimation engine of a
`meow` simulation and can form the bulk of your runtime. For the full
module contract, see
[`vignette("extending-meow")`](https://klintkanopka.com/meow/articles/extending-meow.md).

## Function signature

Every parameter update function has the signature

``` r

update_fun <- function(pers, item, R, admin, ...) {
  # ... re-estimate parameters ...
  list(pers = updated_pers, item = updated_item)
}
```

It receives the current person and item parameter estimates (`pers`,
`item`), the full response matrix `R`, and the non-negative integer
valued administration matrix `admin`. Parameter update functions return
a list with the updated `pers` and `item` data frames. The responses to
administered items are obtained from the matrix state:

``` r

idx    <- which(admin != 0, arr.ind = TRUE)
persons <- unique(idx[, 1])
items <- unique(idx[, 2])
resp   <- R[idx]
```

or, equivalently, as a long data frame with `meow_long(R, admin)`.

## Bundled updaters

### Maximum likelihood ability estimation

[`update_theta_mle()`](https://klintkanopka.com/meow/reference/update_theta_mle.md)
treats item parameters as fixed and finds each respondent’s 2PL maximum
likelihood ability estimate, constrained to $`[-4, 4]`$. The
log-likelihood is fully vectorized over the administered responses:

``` r

loglik <- function(theta) {
  p <- stats::plogis(item$a[item_j] * (theta[person] - item$b[item_j]))
  sum(resp * log(p) + (1 - resp) * log(1 - p))
}
est <- stats::optim(pers$theta, loglik, lower = -4, upper = 4,
                    method = "L-BFGS-B", control = list(fnscale = -1))
```

### Elo-style updates (Maths Garden)

[`update_maths_garden()`](https://klintkanopka.com/meow/reference/update_maths_garden.md)
updates both abilities and difficulties with the on-the-fly Elo rule of
Klinkenberg, Straatemeier, and van der Maas (2011):

``` math
\hat\theta_j = \theta_j + K_\theta \sum_i (S_{ij} - E(S_{ij})), \qquad
\hat b_i = b_i + K_b \sum_j (E(S_{ij}) - S_{ij}).
```

See
[`vignette("maths-garden-update")`](https://klintkanopka.com/meow/articles/maths-garden-update.md).

### Paired Elo updates (Prowise Learn)

[`update_prowise_learn()`](https://klintkanopka.com/meow/reference/update_prowise_learn.md)
updates abilities with the same rule, but updates item difficulties
through paired comparisons of consecutively administered items, which
controls rating drift (Vermeiren et al., 2025). See
[`vignette("prowise-learn-update")`](https://klintkanopka.com/meow/articles/prowise-learn-update.md).

## Best practices

1.  **Return `list(pers, item)`** with both objects as both data frames,
    even if one is unchanged.
2.  **Bound estimates** to a sensible range to avoid divergence.
3.  **Vectorize** over the administered responses
    ([`tapply()`](https://rdrr.io/r/base/tapply.html), matrix indexing)
    rather than looping over respondents or items.
4.  **Respect administration order** when it matters: The best method is
    to use values from the `admin` matrix, but
    [`meow_long()`](https://klintkanopka.com/meow/reference/meow_long.md)
    returns responses ordered by respondent and then by administration
    order.
