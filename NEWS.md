# meow 1.0.0

First public release.

## Features

* `meow()` runs a full CAT administration simulation from three swappable
  modules: a data loader, an item selection function, and a parameter update
  function.
* The simulation state is matrix-based for speed. Item selection and parameter
  update functions receive a respondent-by-item response matrix `R` and an
  integer administration matrix `admin`; person and item parameters are kept as
  data frames so users can add arbitrary parameters.
  * Item selection functions take `(pers, item, R, admin, adj_mat, ...)` and
    return an updated `admin` matrix with newly administered cells marked
    non-zero.
  * Parameter update functions take `(pers, item, R, admin, ...)` and return a
    list with updated `pers` and `item` data frames.
* Bundled data loaders (`data_existing()`, `data_simple_1pl()`), item selectors
  (`select_sequential()`, `select_random()`, `select_max_info()`,
  `select_max_dist()`, `select_max_dist_enhanced()`), and parameter updaters
  (`update_theta_mle()`, `update_maths_garden()`, `update_prowise_learn()`).
* Helpers for module authors: `meow_long()` converts the matrix state to a long
  `(id, item, resp)` data frame, `meow_administered()` returns a logical mask of
  administered items, and `construct_adj_mat()` builds the item co-exposure
  matrix.
* `meow()` accepts a `keep_adj_mats` argument; set it to `FALSE` to retain only
  the final adjacency matrix and save memory on large or long simulations.
* Vignettes cover getting started, each module type, the bundled algorithms, and
  a dedicated "Extending meow" guide to writing your own modules.
