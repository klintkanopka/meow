# Changelog

## meow 1.0.0

First public release.

### Features

- [`meow()`](http://klintkanopka.com/meow/reference/meow.md) runs a full
  CAT administration simulation from three swappable modules: a data
  loader, an item selection function, and a parameter update function.
- The simulation state is matrix-based for speed. Item selection and
  parameter update functions receive a respondent-by-item response
  matrix `R` and an integer administration matrix `admin`; person and
  item parameters are kept as data frames so users can add arbitrary
  parameters.
  - Item selection functions take `(pers, item, R, admin, adj_mat, ...)`
    and return an updated `admin` matrix with newly administered cells
    marked non-zero.
  - Parameter update functions take `(pers, item, R, admin, ...)` and
    return a list with updated `pers` and `item` data frames.
- Bundled data loaders
  ([`data_existing()`](http://klintkanopka.com/meow/reference/data_existing.md),
  [`data_simple_1pl()`](http://klintkanopka.com/meow/reference/data_simple_1pl.md)),
  item selectors
  ([`select_sequential()`](http://klintkanopka.com/meow/reference/select_sequential.md),
  [`select_random()`](http://klintkanopka.com/meow/reference/select_random.md),
  [`select_max_info()`](http://klintkanopka.com/meow/reference/select_max_info.md),
  [`select_max_dist()`](http://klintkanopka.com/meow/reference/select_max_dist.md),
  [`select_max_dist_enhanced()`](http://klintkanopka.com/meow/reference/select_max_dist_enhanced.md)),
  and parameter updaters
  ([`update_theta_mle()`](http://klintkanopka.com/meow/reference/update_theta_mle.md),
  [`update_maths_garden()`](http://klintkanopka.com/meow/reference/update_maths_garden.md),
  [`update_prowise_learn()`](http://klintkanopka.com/meow/reference/update_prowise_learn.md)).
- Helpers for module authors:
  [`meow_long()`](http://klintkanopka.com/meow/reference/meow_long.md)
  converts the matrix state to a long `(id, item, resp)` data frame,
  [`meow_administered()`](http://klintkanopka.com/meow/reference/meow_administered.md)
  returns a logical mask of administered items, and
  [`construct_adj_mat()`](http://klintkanopka.com/meow/reference/construct_adj_mat.md)
  builds the item co-exposure matrix.
- [`meow()`](http://klintkanopka.com/meow/reference/meow.md) accepts a
  `keep_adj_mats` argument; set it to `FALSE` to retain only the final
  adjacency matrix and save memory on large or long simulations.
- Vignettes cover getting started, each module type, the bundled
  algorithms, and a dedicated “Extending meow” guide to writing your own
  modules.
