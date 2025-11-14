# Enhanced network-based item selection with configurable edge weights

This function extends `select_max_dist` with flexible edge weight
calculations.

## Usage

``` r
select_max_dist_enhanced(
  pers,
  item,
  resp,
  resp_cur = NULL,
  adj_mat = NULL,
  n_candidates = 1,
  edge_weight_fun = edge_weight_inverse,
  edge_weight_args = list()
)
```

## Arguments

- pers:

  A dataframe of current respondent ability estimates.

- item:

  A dataframe of current item parameter estimates.

- resp:

  A long-form dataframe of all potential pre-simulated item responses.

- resp_cur:

  A long-form dataframe of administered item responses.

- adj_mat:

  An item-item adjacency matrix.

- n_candidates:

  Number of farthest items to consider before applying information
  criterion.

- edge_weight_fun:

  Function to calculate edge weights from adjacency matrix.

- edge_weight_args:

  Additional arguments for the edge weight function.

## Value

A long-form dataframe of all previously administered item responses with
the new responses from this iteration appended to the end.
