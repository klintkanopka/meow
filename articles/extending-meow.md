# Extending meow: Writing Your Own Modules

The whole point of `meow` is that you can drop your own algorithms into
a shared simulation harness and compare them, on equal footing, against
existing methods. This vignette is the authoritative reference for the
three kinds of module you can write: **data loaders**, **item selection
functions**, and **parameter update functions**.

## The simulation state

A `meow` simulation is a single call to
[`meow()`](https://klintkanopka.com/meow/reference/meow.md), which
repeatedly alternates between an item selection step and a parameter
update step until no further items are administered. For speed, the
simulation state is represented with **matrices** rather than long data
frames:

| Object | Type | Meaning |
|----|----|----|
| `R` | respondents x items matrix | The (potential) response of every respondent to every item. |
| `admin` | respondents x items integer | `0` if an item has not been administered; a positive value if it has. |
| `pers` | data frame | Person parameter estimates. First column `id`, then one column per parameter. |
| `item` | data frame | Item parameter estimates. First column `item`, then one column per parameter. |
| `adj_mat` | items x items matrix | Item co-exposure counts (see [`construct_adj_mat()`](https://klintkanopka.com/meow/reference/construct_adj_mat.md)). |

Two design choices are worth calling out:

- **Responses are matrices.** Finding the items a respondent has *not*
  yet seen is a single logical comparison (`admin[i, ] == 0`) instead of
  a join over a growing table. The positive values in `admin`
  additionally encode the **order** in which items were administered,
  which order-sensitive algorithms (such as paired-comparison updates)
  can use.
- **Parameters are data frames.** This preserves the flexibility to
  carry arbitrary person or item parameters: add a column to `pers` or
  `item` and it flows through the simulation untouched.

If you would rather work with long data frames inside your module, call
`meow_long(R, admin)` to get the administered responses as an
`id`/`item`/`resp` data frame, ordered by respondent and administration
order.

``` r

R <- matrix(c(1, 0, 1, 1), nrow = 2)
admin <- matrix(c(1L, 0L, 2L, 1L), nrow = 2)
meow_long(R, admin)
#>   id item resp
#> 1  1    1    1
#> 2  1    2    1
#> 3  2    2    1
```

## Data loaders

A data loader sets up a simulation. It takes any arguments you like
(passed through `data_args`) and returns a list with three elements:

- `resp` — a long data frame with columns `id`, `item`, and `resp`.
- `pers_tru` — true person parameters; first column `id`, then
  parameters.
- `item_tru` — true item parameters; first column `item`, then
  parameters.

[`meow()`](https://klintkanopka.com/meow/reference/meow.md) turns `resp`
into the response matrix `R` once, before the loop starts, so the
loader’s job is only to produce the bank of potential responses and the
ground-truth parameters.

``` r

data_two_groups <- function(N_per_group = 50, N_items = 40, data_seed = 1) {
  set.seed(data_seed)
  N <- 2 * N_per_group
  theta <- c(stats::rnorm(N_per_group, -0.5), stats::rnorm(N_per_group, 0.5))
  b <- stats::rnorm(N_items)
  pers_tru <- data.frame(id = seq_len(N), theta = theta)
  item_tru <- data.frame(item = seq_len(N_items), b = b, a = 1)

  p <- stats::plogis(outer(theta, b, "-"))
  resp_mat <- matrix(stats::rbinom(length(p), 1, p), nrow = N)
  resp <- data.frame(
    id = rep(seq_len(N), each = N_items),
    item = rep(seq_len(N_items), times = N),
    resp = as.vector(t(resp_mat))
  )
  set.seed(NULL)
  list(resp = resp, pers_tru = pers_tru, item_tru = item_tru)
}

str(data_two_groups(N_per_group = 3, N_items = 4), max.level = 1)
#> List of 3
#>  $ resp    :'data.frame':    24 obs. of  3 variables:
#>  $ pers_tru:'data.frame':    6 obs. of  2 variables:
#>  $ item_tru:'data.frame':    4 obs. of  3 variables:
```

Reserved argument names a loader must **not** use are the ones the
harness supplies to the other modules: `pers`, `item`, `R`, `admin`,
`adj_mat`, and `select_seed`.

## Item selection functions

An item selection function decides which item to administer next. Its
signature is

``` r

select_fun <- function(pers, item, R, admin, adj_mat, ...) { ... }
```

and it returns an **administration matrix** with the newly chosen cells
marked non-zero. You only need to *add* items; the harness records the
administration order for you, so setting a cell to `TRUE` or `1` is
enough. Leave previously administered cells as they were. To stop
administering items (a stopping rule), simply return `admin` unchanged —
the simulation halts when an iteration adds nothing.

Here is a complete custom selector that administers the easiest
remaining item to each respondent (a deliberately naive rule), seeding
the first five items on the first iteration:

``` r

select_easiest <- function(pers, item, R, admin, adj_mat = NULL) {
  if (!any(admin != 0)) {       # first iteration: seed five items
    admin[, seq_len(min(5, ncol(admin)))] <- 1L
    return(admin)
  }
  difficulty <- item$b
  for (i in which(rowSums(admin == 0) > 0)) {
    remaining <- which(admin[i, ] == 0)
    pick <- remaining[which.min(difficulty[remaining])]
    admin[i, pick] <- 1L
  }
  admin
}
```

A few patterns to notice, all of which avoid touching a growing data
frame:

- `admin[i, ] == 0` gives the unadministered items for respondent `i`.
- `rowSums(admin == 0) > 0` identifies respondents who still need an
  item.
- Setting `admin[i, pick] <- 1L` administers item `pick`.

If you prefer to compute on long data, `meow_long(R, admin)` is always
available.

## Parameter update functions

A parameter update function re-estimates parameters from the
administered responses. Its signature is

``` r

update_fun <- function(pers, item, R, admin, ...) { ... }
```

and it returns a list with two elements, `pers` and `item`, the updated
estimate data frames. The administered responses are `R[admin != 0]`,
and their respondent/item indices come from
`which(admin != 0, arr.ind = TRUE)`.

This custom updater nudges each ability toward a simple
proportion-correct heuristic and leaves items fixed:

``` r

update_pct_correct <- function(pers, item, R, admin, rate = 0.5) {
  idx <- which(admin != 0, arr.ind = TRUE)
  person <- idx[, 1]
  resp <- R[idx]
  pct <- tapply(resp, person, mean)
  target <- stats::qlogis(pmin(pmax(pct, 0.02), 0.98)) # logit of proportion
  pers$theta[as.integer(names(target))] <-
    (1 - rate) * pers$theta[as.integer(names(target))] + rate * target
  list(pers = pers, item = item)
}
```

## Putting it together

Custom modules plug into
[`meow()`](https://klintkanopka.com/meow/reference/meow.md) exactly like
the bundled ones. Extra arguments are passed through `select_args`,
`update_args`, and `data_args`.

``` r

sim <- meow(
  select_fun  = select_easiest,
  update_fun  = update_pct_correct,
  data_loader = data_two_groups,
  data_args   = list(N_per_group = 25, N_items = 20),
  update_args = list(rate = 0.3),
  fix         = "item"
)

head(sim$results[, 1:4])
#>   iter pers_theta_1_est pers_theta_2_est pers_theta_3_est
#> 1    1        0.1216395       -0.1216395      -0.12163953
#> 2    2        0.2930918       -0.2930918      -0.08514767
#> 3    3        0.2914689       -0.4800515      -0.14590799
#> 4    4        0.3572759       -0.4892837      -0.25538328
#> 5    5        0.3170362       -0.4094417      -0.38671245
#> 6    6        0.2219253       -0.4082487      -0.39233825
```

The output object has the same shape no matter which modules you use — a
`results` data frame (one row per iteration, an `est` and `bias` column
for each parameter), a list of adjacency matrices in `adj_mats`, and the
true parameters in `pers_tru` and `item_tru`. That consistency is what
lets you reuse analysis and plotting code across studies; see
[`vignette("meow-viz")`](https://klintkanopka.com/meow/articles/meow-viz.md).

## Checklist

- Data loaders return `list(resp, pers_tru, item_tru)` with long `resp`.
- Item selection functions take `(pers, item, R, admin, adj_mat, ...)`
  and return an administration matrix with new cells marked non-zero.
- Parameter update functions take `(pers, item, R, admin, ...)` and
  return `list(pers, item)`.
- Use `admin != 0` (or
  [`meow_administered()`](https://klintkanopka.com/meow/reference/meow_administered.md))
  for the administered mask, and
  [`meow_long()`](https://klintkanopka.com/meow/reference/meow_long.md)
  if you want long data frames.
- Do not un-administer items, and implement stopping rules by declining
  to administer anything further.
