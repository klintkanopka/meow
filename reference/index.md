# Package index

## Simulation Function

The core of any individual simulation.

- [`meow()`](http://klintkanopka.com/meow/reference/meow.md) : Conducts
  a full CAT simulation.

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
  : Item selection function based on network distance criterion.
- [`select_max_dist_enhanced()`](http://klintkanopka.com/meow/reference/select_max_dist_enhanced.md)
  : Enhanced network-based item selection with configurable edge weights
- [`select_max_info()`](http://klintkanopka.com/meow/reference/select_max_info.md)
  : Item selection function that delivers the the remaining item with
  the highest information.
- [`select_random()`](http://klintkanopka.com/meow/reference/select_random.md)
  : Item selection function that delivers an item an item drawn at
  random from the item bank to each respondent.
- [`select_sequential()`](http://klintkanopka.com/meow/reference/select_sequential.md)
  : Item selection function that delivers the next item by item id
  number, simulating a fixed test form.

## Parameter Update Functions

Included parameter update functions. Note that some only operate on
person parameters, while others simultaneously update person and item
parameters.

- [`update_maths_garden()`](http://klintkanopka.com/meow/reference/update_maths_garden.md)
  : Elo-style updates of person and item parameters
- [`update_prowise_learn()`](http://klintkanopka.com/meow/reference/update_prowise_learn.md)
  : Elo-style updates of person and item parameters
- [`update_theta_mle()`](http://klintkanopka.com/meow/reference/update_theta_mle.md)
  : Updated person parameters based on MLE estimates

## Utilities

Additional helper functions.

- [`construct_adj_mat()`](http://klintkanopka.com/meow/reference/construct_adj_mat.md)
  : Constructs an item pool adjacency matrix.
- [`edge_weight_inverse()`](http://klintkanopka.com/meow/reference/edge_weight_inverse.md)
  [`edge_weight_negative_log()`](http://klintkanopka.com/meow/reference/edge_weight_inverse.md)
  [`edge_weight_linear()`](http://klintkanopka.com/meow/reference/edge_weight_inverse.md)
  [`edge_weight_power()`](http://klintkanopka.com/meow/reference/edge_weight_inverse.md)
  [`edge_weight_exponential()`](http://klintkanopka.com/meow/reference/edge_weight_inverse.md)
  : Alternative edge weight functions for network-based item selection
