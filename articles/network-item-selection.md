# Network-Based Item Selection

[`select_max_dist()`](http://klintkanopka.com/meow/reference/select_max_dist.md)
selects items using the *entire* item-exposure history. It treats the
item pool as a weighted graph and administers the item farthest, in
shortest-path distance, from the items a respondent has already seen.
This balances exposure control against measurement efficiency.

## Mathematical foundation

The item pool is a weighted graph: nodes are items, and edge weights
derive from the co-exposure matrix `adj_mat` (entry $`(i, j)`$ is the
number of respondents who have seen both items). The Floyd–Warshall
algorithm ([`Rfast::floyd()`](https://rdrr.io/pkg/Rfast/man/floyd.html))
turns the edge-weight matrix $`W`$ into an all-pairs shortest-path
distance matrix $`D`$. For each respondent, the distance of a candidate
item to the set of administered items is the minimum distance to any of
them, and the farthest candidate is administered (ties broken by maximum
information).

## Edge weight strategies

The edge-weight function maps co-exposure counts to graph weights, and
the choice shapes behavior. All of these are bundled and unchanged:

``` r

edge_weight_inverse(adj_mat, alpha = 1)              # 1 / (adj_mat + alpha)
edge_weight_negative_log(adj_mat, alpha = 1)         # -log(adj_mat + alpha)
edge_weight_linear(adj_mat, max_co_responses = NULL) # adj_mat / max(adj_mat)
edge_weight_power(adj_mat, beta = 0.5, alpha = 1)    # (adj_mat + alpha)^beta
edge_weight_exponential(adj_mat, lambda = 0.1)       # exp(-lambda*(adj_mat+alpha))
```

- **Inverse / negative log / exponential**: more co-responses give
  *smaller* weights, so frequently co-administered items are “closer”
  and the algorithm spreads exposure across dissimilar items.
- **Linear**: more co-responses give *larger* weights, inverting that
  logic.
- **Power**: `beta < 1` dampens and `beta > 1` amplifies the effect of
  high co-response counts.

## Implementation

[`select_max_dist()`](http://klintkanopka.com/meow/reference/select_max_dist.md)
follows the item selection contract
([`vignette("item-selection")`](http://klintkanopka.com/meow/articles/item-selection.md)):
it works on the matrix administration state and returns an updated
`admin`. After the distance matrix is computed, the per-item distances
are obtained with
[`Rfast::colMins()`](https://rdrr.io/pkg/Rfast/man/colMins.html) rather
than a row-wise data-frame operation:

``` r

select_max_dist <- function(pers, item, R, admin, adj_mat = NULL, n_candidates = 1) {
  if (!any(admin != 0)) {
    admin[, seq_len(min(5, ncol(admin)))] <- 1L     # seed five items
    return(admin)
  }
  dist_mat <- Rfast::floyd(1 / adj_mat)              # all-pairs shortest paths
  info <- {                                          # 2PL information matrix
    lin <- sweep(outer(pers$theta, item$b, "-"), 2, item$a, "*")
    P <- stats::plogis(lin); sweep(P * (1 - P), 2, item$a^2, "*")
  }
  for (i in which(rowSums(admin == 0) > 0)) {
    administered <- which(admin[i, ] != 0)
    candidates   <- which(admin[i, ] == 0)
    sub <- dist_mat[administered, candidates, drop = FALSE]
    cand_dist <- if (length(administered) == 1L) sub[1, ] else Rfast::colMins(sub, value = TRUE)
    pool <- candidates[cand_dist >= max(cand_dist)]  # farthest items
    admin[i, pool[which.max(info[i, pool])]] <- 1L   # tie-break by information
  }
  admin
}
```

[`select_max_dist_enhanced()`](http://klintkanopka.com/meow/reference/select_max_dist_enhanced.md)
is identical except that the edge weights come from a user-supplied
`edge_weight_fun` applied to `adj_mat` before
[`Rfast::floyd()`](https://rdrr.io/pkg/Rfast/man/floyd.html).

## Using different edge weight strategies

A small runnable example with the default inverse weights:

``` r

sim <- meow(
  select_fun  = select_max_dist,
  update_fun  = update_theta_mle,
  data_loader = data_simple_1pl,
  data_args   = list(N_persons = 50, N_items = 30),
  select_args = list(n_candidates = 3),
  fix         = "item"
)
nrow(sim$results)
#> [1] 26
```

Swap in a different edge-weight function through
[`select_max_dist_enhanced()`](http://klintkanopka.com/meow/reference/select_max_dist_enhanced.md):

``` r

# Power transformation with beta = 0.3
meow(
  select_fun  = select_max_dist_enhanced,
  update_fun  = update_theta_mle,
  data_loader = data_simple_1pl,
  data_args   = list(N_persons = 100, N_items = 50),
  select_args = list(
    n_candidates = 3,
    edge_weight_fun = edge_weight_power,
    edge_weight_args = list(beta = 0.3, alpha = 1)
  ),
  fix = "item"
)
```

## Choosing a strategy

| Strategy | Goal | Trade-off |
|----|----|----|
| Inverse (default) | spread exposure across dissimilar items | may over-expose clusters |
| Linear | keep item clusters / topic areas together | can reduce efficiency |
| Power | tune sensitivity to co-response counts | requires choosing `beta` |
| Exponential | strong exposure control | can reduce efficiency |

## Considerations

- [`Rfast::floyd()`](https://rdrr.io/pkg/Rfast/man/floyd.html) is
  $`O(n^3)`$ in the number of items and is run each iteration, so
  network selection is more expensive than
  [`select_max_info()`](http://klintkanopka.com/meow/reference/select_max_info.md).
- Experiment with `n_candidates` (1–5) to trade exposure control against
  measurement efficiency, and compare against simpler selectors as a
  baseline.
