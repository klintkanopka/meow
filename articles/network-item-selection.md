# Network-Based Item Selection

The `select_max_dist` function implements an elegant network-based item
selection strategy that considers a person’s entire item history and
uses graph theory concepts to select items that are “farthest” from
previously administered items. This approach balances exposure control
with measurement efficiency.

In this vignette, we will explore the mathematical foundations of this
algorithm, examine different edge weight strategies, and discuss when to
use each approach.

## Mathematical Foundation

### Network Representation

The algorithm represents the item pool as a weighted graph where:

- **Nodes**: Individual items in the pool
- **Edges**: Connections between items, weighted by co-response patterns
- **Edge Weight**: Reflects how frequently two items are answered
  together by the same respondents

### Distance Calculation

The algorithm uses the Floyd-Warshall algorithm to compute shortest
paths between all item pairs:

1.  **Edge Weight Matrix**: $W_{ij}$ represents the weight between items
    $i$ and $j$
2.  **Distance Matrix**: $D_{ij}$ represents the shortest path distance
    from item $i$ to item $j$
3.  **Item Selection**: For each person, select items with maximum
    distance from their answered items

### Edge Weight Strategies

The choice of edge weight function significantly impacts the algorithm’s
behavior. Here are several approaches:

#### 1. Inverse Weight (Original)

``` r
edge_weight_inverse <- function(adj_mat, alpha = 1) {
  return(1 / (adj_mat + alpha))
}
```

**Logic**: Higher co-responses = lower weights = shorter distances -
Items frequently answered together are considered “closer” - Encourages
selection of items that are rarely answered together - `alpha` parameter
prevents division by zero

#### 2. Negative Log Weight

``` r
edge_weight_negative_log <- function(adj_mat, alpha = 1) {
  return(-log(adj_mat + alpha))
}
```

**Logic**: Similar to inverse but with logarithmic scaling - Reduces the
impact of very high co-response counts - More gradual transition between
different co-response levels

#### 3. Linear Weight (Inverted Logic)

``` r
edge_weight_linear <- function(adj_mat, max_co_responses = NULL) {
  if (is.null(max_co_responses)) {
    max_co_responses <- max(adj_mat)
  }
  return(adj_mat / max_co_responses)
}
```

**Logic**: Higher co-responses = higher weights = longer distances -
**Inverts the original logic**: items frequently answered together are
considered “farther apart” - This might be more intuitive for some
applications - Encourages selection of items that are frequently
answered together (exposure control)

#### 4. Power Weight

``` r
edge_weight_power <- function(adj_mat, beta = 0.5, alpha = 1) {
  return((adj_mat + alpha)^beta)
}
```

**Logic**: Flexible transformation with parameter control - `beta < 1`:
Reduces impact of high co-response counts - `beta > 1`: Amplifies impact
of high co-response counts - `beta = 1`: Linear relationship

#### 5. Exponential Weight

``` r
edge_weight_exponential <- function(adj_mat, lambda = 0.1, alpha = 1) {
  return(exp(-lambda * (adj_mat + alpha)))
}
```

**Logic**: Exponential decay of weights - Higher co-responses lead to
much lower weights - Very sensitive to small changes in co-response
counts - `lambda` controls the rate of decay

## Algorithm Implementation

### Core Algorithm

The `select_max_dist` function implements this strategy:

``` r
select_max_dist <- function(
  pers,
  item,
  resp,
  resp_cur = NULL,
  adj_mat = NULL,
  n_candidates = 1
) {
  if (is.null(resp_cur)) {
    return(resp[resp$item <= 5, ])
  } else {
    # Calculate distance matrix using inverse edge weights
    dist_mat <- Rfast::floyd(1 / adj_mat)

    # Get each person's answered items
    local_items <- resp_cur |>
      dplyr::select(.data$id, .data$item) |>
      dplyr::group_by(.data$id) |>
      dplyr::mutate(seq = 1:dplyr::n()) |>
      dplyr::ungroup() |>
      tidyr::pivot_wider(
        id_cols = .data$id,
        names_from = .data$seq,
        names_prefix = 'item_',
        values_from = .data$item
      ) |>
      dplyr::arrange(.data$id) |>
      dplyr::select(-.data$id) |>
      as.matrix()

    # Calculate distance from answered items to each candidate
    get_distance <- function(id, item, dist_mat, local_items) {
      dist <- min(dist_mat[local_items[id, ], item])
      return(dist)
    }

    # Select items with maximum distance
    resp_new <- dplyr::anti_join(
      resp,
      resp_cur,
      by = c('id', 'item', 'resp')
    )

    if (nrow(resp_new) > 0) {
      resp_new <- resp_new |>
        dplyr::rowwise() |>
        dplyr::mutate(
          distance = get_distance(.data$id, .data$item, dist_mat, local_items)
        ) |>
        dplyr::ungroup() |>
        dplyr::slice_max(.data$distance, n = n_candidates, by = .data$id) |>
        dplyr::left_join(pers, by = 'id') |>
        dplyr::left_join(item, by = 'item') |>
        dplyr::mutate(
          info = .data$a^2 *
            stats::plogis(.data$a * (.data$theta - .data$b)) *
            (1 - stats::plogis(.data$a * (.data$theta - .data$b)))
        ) |>
        dplyr::slice_max(.data$info, n = 1, by = .data$id) |>
        dplyr::select(.data$id, .data$item, .data$resp)
    }
    resp_new <- dplyr::bind_rows(resp_cur, resp_new)
  }
  return(resp_new)
}
```

### Enhanced Version with Configurable Edge Weights

The `select_max_dist_enhanced` function allows you to specify different
edge weight strategies:

``` r
select_max_dist_enhanced <- function(
  pers,
  item,
  resp,
  resp_cur = NULL,
  adj_mat = NULL,
  n_candidates = 1,
  edge_weight_fun = edge_weight_inverse,
  edge_weight_args = list()
) {
  if (is.null(resp_cur)) {
    return(resp[resp$item <= 5, ])
  } else {
    # Calculate edge weights using the specified function
    edge_weights <- do.call(edge_weight_fun, 
                           c(list(adj_mat = adj_mat), edge_weight_args))
    
    # Compute distance matrix using Floyd-Warshall
    dist_mat <- Rfast::floyd(edge_weights)
    
    # Rest of the algorithm remains the same...
  }
  return(resp_new)
}
```

## Using Different Edge Weight Strategies

### Example 1: Original Inverse Weight

``` r
# Use the original inverse weight approach
results <- meow(
  select_fun = select_max_dist,
  update_fun = update_theta_mle,
  data_loader = data_simple_1pl,
  select_args = list(n_candidates = 3),
  data_args = list(N_persons = 100, N_items = 50)
)
```

### Example 2: Linear Weight (Inverted Logic)

``` r
# Use linear weights where higher co-responses = higher weights
results <- meow(
  select_fun = select_max_dist_enhanced,
  update_fun = update_theta_mle,
  data_loader = data_simple_1pl,
  select_args = list(
    n_candidates = 3,
    edge_weight_fun = edge_weight_linear
  ),
  data_args = list(N_persons = 100, N_items = 50)
)
```

### Example 3: Power Weight with Custom Parameters

``` r
# Use power transformation with beta = 0.3
results <- meow(
  select_fun = select_max_dist_enhanced,
  update_fun = update_theta_mle,
  data_loader = data_simple_1pl,
  select_args = list(
    n_candidates = 3,
    edge_weight_fun = edge_weight_power,
    edge_weight_args = list(beta = 0.3, alpha = 1)
  ),
  data_args = list(N_persons = 100, N_items = 50)
)
```

### Example 4: Exponential Weight

``` r
# Use exponential decay with lambda = 0.05
results <- meow(
  select_fun = select_max_dist_enhanced,
  update_fun = update_theta_mle,
  data_loader = data_simple_1pl,
  select_args = list(
    n_candidates = 3,
    edge_weight_fun = edge_weight_exponential,
    edge_weight_args = list(lambda = 0.05, alpha = 1)
  ),
  data_args = list(N_persons = 100, N_items = 50)
)
```

## Choosing the Right Edge Weight Strategy

### When to Use Inverse Weight (Original)

- **Goal**: Minimize exposure of items that are rarely answered together
- **Use Case**: When you want to spread item exposure across different
  item types
- **Advantage**: Simple and intuitive
- **Disadvantage**: May lead to over-exposure of certain item clusters

### When to Use Linear Weight (Inverted)

- **Goal**: Encourage selection of items that are frequently answered
  together
- **Use Case**: When you want to maintain item clusters or topic areas
- **Advantage**: More predictable exposure patterns
- **Disadvantage**: May reduce measurement efficiency

### When to Use Power Weight

- **Goal**: Fine-tune the sensitivity to co-response patterns
- **Use Case**: When you need to balance exposure control with
  measurement efficiency
- **Advantage**: Flexible parameter control
- **Disadvantage**: Requires tuning of beta parameter

### When to Use Exponential Weight

- **Goal**: Very strong exposure control
- **Use Case**: When you want to avoid any clustering of item exposure
- **Advantage**: Strongest exposure control
- **Disadvantage**: May significantly reduce measurement efficiency

## Advantages of Network-Based Selection

1.  **Whole History Consideration**: Considers all previously answered
    items, not just the last one
2.  **Flexible Pool Size**: The `n_candidates` parameter allows
    balancing exposure control vs. efficiency
3.  **Tie-Breaking**: Uses maximum information to break ties among
    equally distant items
4.  **Configurable**: Different edge weight strategies allow fine-tuning
    of behavior
5.  **Theoretically Sound**: Based on well-established graph theory
    algorithms

## Limitations and Considerations

1.  **Computational Cost**: Floyd-Warshall algorithm is
    $O\left( n^{3} \right)$ where $n$ is the number of items
2.  **Edge Weight Choice**: The choice of edge weight function
    significantly impacts results
3.  **Parameter Tuning**: Requires careful tuning of edge weight
    parameters
4.  **Interpretation**: The “distance” concept may not always align with
    intuitive notions of item similarity

## Best Practices

1.  **Start with Inverse Weight**: Use the original approach as a
    baseline
2.  **Experiment with Parameters**: Try different `n_candidates` values
    (1-5)
3.  **Consider Your Goals**: Choose edge weight strategy based on
    whether you prioritize exposure control or measurement efficiency
4.  **Monitor Results**: Track both exposure patterns and measurement
    accuracy
5.  **Compare Approaches**: Test against simpler methods like
    `select_max_info`
