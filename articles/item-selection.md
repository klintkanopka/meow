# Item Selection Functions

Item selection functions determine which item is administered next to
each respondent. They are one of the three swappable components of a
`meow` simulation. For the full module contract, see
[`vignette("extending-meow")`](http://klintkanopka.com/meow/articles/extending-meow.md);
this vignette focuses on the bundled selectors and how to write your
own.

## Function signature

Every item selection function has the signature

``` r

select_fun <- function(pers, item, R, admin, adj_mat, ...) {
  # ... decide which items to administer ...
  return(admin)
}
```

It receives the current person estimates (`pers`), item estimates
(`item`), the respondent-by-item response matrix (`R`), the integer
administration matrix (`admin`), and the item co-exposure matrix
(`adj_mat`). It returns an administration matrix with the newly chosen
cells marked non-zero. The harness records the order of administration,
so you only need to *add* items.

The unadministered items for respondent `i` are
`which(admin[i, ] == 0)`, and the respondents still needing an item are
`which(rowSums(admin == 0) > 0)`.

## Bundled selectors

### Sequential

[`select_sequential()`](http://klintkanopka.com/meow/reference/select_sequential.md)
administers the lowest-numbered remaining item to each respondent,
producing a fixed linear form.

``` r

select_sequential <- function(pers, item, R, admin, adj_mat = NULL) {
  if (!any(admin != 0)) {
    admin[, seq_len(min(5, ncol(admin)))] <- 1L  # seed the first five items
    return(admin)
  }
  unadmin <- admin == 0
  has <- which(rowSums(unadmin) > 0)
  nextcol <- max.col(unadmin[has, , drop = FALSE] + 0, ties.method = "first")
  admin[cbind(has, nextcol)] <- 1L
  admin
}
```

### Random

[`select_random()`](http://klintkanopka.com/meow/reference/select_random.md)
draws one remaining item per respondent at random. It accepts a
`select_seed` for reproducibility, which it clears after use.

### Maximum information

[`select_max_info()`](http://klintkanopka.com/meow/reference/select_max_info.md)
administers the remaining item with the greatest 2PL Fisher information,
$`I(\theta) = a^2 P(\theta)(1 - P(\theta))`$, evaluated at each
respondent’s current ability estimate. The information for every
respondent-by-item combination is computed as a single matrix, and the
maximum is taken per row.

### Network distance

[`select_max_dist()`](http://klintkanopka.com/meow/reference/select_max_dist.md)
and
[`select_max_dist_enhanced()`](http://klintkanopka.com/meow/reference/select_max_dist_enhanced.md)
treat the item pool as a network whose edge weights are derived from the
co-exposure matrix `adj_mat`. They administer the item farthest (by
shortest-path distance) from the items a respondent has already seen,
breaking ties by maximum information. See
[`vignette("network-item-selection")`](http://klintkanopka.com/meow/articles/network-item-selection.md).

## Writing a custom selector

A custom selector need only follow the signature and return an updated
`admin`. Here we administer the item whose difficulty is closest to a
respondent’s current ability — a simple “target the trait” rule.

``` r

select_targeted <- function(pers, item, R, admin, adj_mat = NULL) {
  if (!any(admin != 0)) {
    admin[, seq_len(min(5, ncol(admin)))] <- 1L
    return(admin)
  }
  for (i in which(rowSums(admin == 0) > 0)) {
    remaining <- which(admin[i, ] == 0)
    gap <- abs(item$b[remaining] - pers$theta[i])
    admin[i, remaining[which.min(gap)]] <- 1L
  }
  admin
}
```

Use it in a simulation by passing it as `select_fun`:

``` r

sim <- meow(
  select_fun  = select_targeted,
  update_fun  = update_theta_mle,
  data_loader = data_simple_1pl,
  data_args   = list(N_persons = 50, N_items = 30),
  fix         = "item"
)
nrow(sim$results)
#> [1] 26
```

## Best practices

1.  **Handle the first iteration** with `if (!any(admin != 0))` to seed
    an initial set of items.
2.  **Never un-administer** an item that has already been given.
3.  **Implement stopping rules** by returning `admin` unchanged once a
    respondent should receive no more items.
4.  **Prefer matrix operations** over per-row loops where possible; use
    [`meow_long()`](http://klintkanopka.com/meow/reference/meow_long.md)
    only when long data is genuinely more convenient.
