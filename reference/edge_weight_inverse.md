# Alternative edge weight functions for network-based item selection

These functions provide different approaches to calculating edge weights
from the adjacency matrix.

## Usage

``` r
edge_weight_inverse(adj_mat, alpha = 1)

edge_weight_negative_log(adj_mat, alpha = 1)

edge_weight_linear(adj_mat, max_co_responses = NULL)

edge_weight_power(adj_mat, beta = 0.5, alpha = 1)

edge_weight_exponential(adj_mat, lambda = 0.1, alpha = 1)
```

## Arguments

- adj_mat:

  The adjacency matrix where entry i,j is the number of co-responses
  between items i and j

- alpha:

  Smoothing parameter for avoiding division by zero

- max_co_responses:

  Scaling factor for linear weighting

- beta:

  Exponent for power transformation

- lambda:

  Decay constant for exponential decay weighting

## Value

A matrix of edge weights for use in distance calculations
