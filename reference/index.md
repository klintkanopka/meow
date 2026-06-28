# Package index

## Simulation Function

The core of any individual simulation.

- [`meow()`](http://klintkanopka.com/meow/reference/meow.md) : Conduct a
  full CAT simulation.

## Data Loaders

Load existing or simulate new data for use in a `meow` simulation.

- [`data_existing()`](http://klintkanopka.com/meow/reference/data_existing.md)
  : Load data from existing files
- [`data_simple_1pl()`](http://klintkanopka.com/meow/reference/data_simple_1pl.md)
  : A default data generation function that simulates normally
  distributed respondent abilities and item difficulties

## Selection Functions

Included item selection algorithms.

- [`select_max_dist()`](http://klintkanopka.com/meow/reference/select_max_dist.md)
  : Item selection by network distance criterion.
- [`select_max_dist_enhanced()`](http://klintkanopka.com/meow/reference/select_max_dist_enhanced.md)
  : Network-based item selection with configurable edge weights.
- [`select_max_info()`](http://klintkanopka.com/meow/reference/select_max_info.md)
  : Item selection by maximum Fisher information.
- [`select_random()`](http://klintkanopka.com/meow/reference/select_random.md)
  : Item selection by random draw from the remaining item bank.
- [`select_sequential()`](http://klintkanopka.com/meow/reference/select_sequential.md)
  : Item selection by item id, simulating a fixed test form.

## Parameter Update Functions

Included parameter update functions. Note that some only operate on
person parameters, while others simultaneously update person and item
parameters.

- [`update_maths_garden()`](http://klintkanopka.com/meow/reference/update_maths_garden.md)
  : Elo-style updates of person and item parameters (Maths Garden).
- [`update_prowise_learn()`](http://klintkanopka.com/meow/reference/update_prowise_learn.md)
  : Elo-style updates with paired item comparisons (Prowise Learn).
- [`update_theta_mle()`](http://klintkanopka.com/meow/reference/update_theta_mle.md)
  : Update person ability via maximum likelihood estimation.

## Utilities

Additional helper functions.

- [`construct_adj_mat()`](http://klintkanopka.com/meow/reference/construct_adj_mat.md)
  : Construct an item-pool adjacency matrix.
- [`meow_administered()`](http://klintkanopka.com/meow/reference/meow_administered.md)
  : Logical mask of administered items.
- [`meow_long()`](http://klintkanopka.com/meow/reference/meow_long.md) :
  Convert the matrix simulation state to a long data frame of responses.
- [`edge_weight_inverse()`](http://klintkanopka.com/meow/reference/edge_weight_inverse.md)
  [`edge_weight_negative_log()`](http://klintkanopka.com/meow/reference/edge_weight_inverse.md)
  [`edge_weight_linear()`](http://klintkanopka.com/meow/reference/edge_weight_inverse.md)
  [`edge_weight_power()`](http://klintkanopka.com/meow/reference/edge_weight_inverse.md)
  [`edge_weight_exponential()`](http://klintkanopka.com/meow/reference/edge_weight_inverse.md)
  : Alternative edge weight functions for network-based item selection
