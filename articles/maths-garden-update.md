# Implementing the Maths Garden Update Algorithm

The Maths Garden update algorithm is a gradient-based parameter
estimation method specifically designed for computer adaptive testing
systems. This algorithm was developed for the Maths Garden platform, an
educational game that adapts mathematical problems to individual student
abilities in real-time.

In this vignette, we will explore the mathematical foundations of the
Maths Garden algorithm, its implementation in the `meow` framework, and
how to use and customize it for your research.

## Mathematical Foundation

### Core Update Equations

The Maths Garden algorithm implements simultaneous updates for both
person abilities ($\theta$) and item difficulties ($b$) using
gradient-based learning. The update equations are:

**Person Ability Update:**
$$\theta_{j}^{new} = \theta_{j}^{old} + K_{\theta}\sum\limits_{i \in I_{j}}\left( S_{ij} - E\left( S_{ij} \right) \right)$$

**Item Difficulty Update:**
$$b_{i}^{new} = b_{i}^{old} + K_{b}\sum\limits_{j \in J_{i}}\left( E\left( S_{ij} \right) - S_{ij} \right)$$

Where: - $\theta_{j}$ is the ability of person $j$ - $b_{i}$ is the
difficulty of item $i$ - $S_{ij}$ is the observed response (0 or 1) of
person $j$ to item $i$ - $E\left( S_{ij} \right)$ is the expected
probability of a correct response - $K_{\theta}$ and $K_{b}$ are
learning rates for abilities and difficulties respectively - $I_{j}$ is
the set of items responded to by person $j$ - $J_{i}$ is the set of
persons who responded to item $i$

### Expected Response Probability

The expected probability $E\left( S_{ij} \right)$ is calculated using
the logistic function:

$$E\left( S_{ij} \right) = P\left( S_{ij} = 1|\theta_{j},b_{i} \right) = \frac{1}{1 + e^{-{(\theta_{j} - b_{i})}}}$$

This is the 1-parameter logistic (1PL) item response model, also known
as the Rasch model.

### Intuition Behind the Updates

1.  **Person Ability Updates**: If a person performs better than
    expected (more correct responses than predicted), their ability
    estimate increases. If they perform worse than expected, their
    ability estimate decreases.

2.  **Item Difficulty Updates**: If an item is answered correctly more
    often than expected, its difficulty decreases (becomes easier). If
    it’s answered correctly less often than expected, its difficulty
    increases (becomes harder).

3.  **Learning Rates**: The $K$ parameters control how quickly the
    estimates change. Larger values lead to faster adaptation but may
    cause instability.

## Implementation in `meow`

### Function Overview

The
[`update_maths_garden()`](http://klintkanopka.com/meow/reference/update_maths_garden.md)
function implements this algorithm:

``` r
update_maths_garden <- function(pers, item, resp, K_theta = 0.1, K_b = 0.1) {
  # Implement the update rule from the maths garden paper
  # Theta_hat_j = theta_j + K_j (S_ij - E(S_ij))
  # Beta_hat_i = beta_i + K_i(E(S_ij)-S_ij)
  # where S_ij is the observed score and E(S_ij) is the expected probability

  # Calculate expected probabilities using logistic function
  E_Sij <- stats::plogis(pers$theta[resp$id] - item$b[resp$item])

  # Update theta (ability) for each person
  theta_updated <- pers$theta
  for (j in unique(resp$id)) {
    # Get responses for person j
    resp_j <- resp[resp$id == j, ]
    # Calculate update term
    update_term <- K_theta * sum(resp_j$resp - E_Sij[resp$id == j])
    theta_updated[j] <- pers$theta[j] + update_term
  }

  pers$theta <- theta_updated

  # Update beta (difficulty) for each item
  b_updated <- item$b
  for (i in unique(resp$item)) {
    # Get responses for item i
    resp_i <- resp[resp$item == i, ]
    # Calculate update term
    update_term <- K_b * sum(E_Sij[resp$item == i] - resp_i$resp)
    b_updated[i] <- item$b[i] + update_term
  }

  item$b <- b_updated

  out <- list(
    pers = pers,
    item = item,
    resp_cur = resp
  )
  return(out)
}
```

### Step-by-Step Breakdown

#### 1. Expected Probability Calculation

``` r
E_Sij <- stats::plogis(theta[resp$id] - diff[resp$item])
```

This calculates the expected probability of a correct response for each
person-item combination using the logistic function.

#### 2. Person Ability Updates

``` r
for (j in unique(resp$id)) {
  resp_j <- resp[resp$id == j, ]
  update_term <- K_theta * sum(resp_j$resp - E_Sij[resp$id == j])
  theta_updated[j] <- theta[j] + update_term
}
```

For each person, this: - Collects all responses from that person -
Calculates the sum of prediction errors (observed - expected) -
Multiplies by the learning rate - Updates the ability estimate

#### 3. Item Difficulty Updates

``` r
for (i in unique(resp$item)) {
  resp_i <- resp[resp$item == i, ]
  update_term <- K_beta * sum(E_Sij[resp$item == i] - resp_i$resp)
  beta_updated[i] <- diff[i] + update_term
}
```

For each item, this: - Collects all responses to that item - Calculates
the sum of prediction errors (expected - observed) - Multiplies by the
learning rate - Updates the difficulty estimate

## Using the Maths Garden Algorithm

### Basic Usage

``` r
# Run simulation with Maths Garden updates
results <- meow(
  select_fun = select_max_info,
  update_fun = update_maths_garden,
  data_loader = data_simple_1pl,
  data_args = list(N_persons = 100, N_items = 50)
)
```

### Customizing Learning Rates

You can modify the learning rates by creating a wrapper function:

``` r
update_maths_garden_custom <- function(theta, diff, resp, K_theta = 0.05, K_beta = 0.05) {
  # Calculate expected probabilities using logistic function
  E_Sij <- stats::plogis(theta[resp$id] - diff[resp$item])

  # Update theta (ability) for each person
  theta_updated <- theta
  for (j in unique(resp$id)) {
    resp_j <- resp[resp$id == j, ]
    update_term <- K_theta * sum(resp_j$resp - E_Sij[resp$id == j])
    theta_updated[j] <- theta[j] + update_term
  }

  # Update beta (difficulty) for each item
  beta_updated <- diff
  for (i in unique(resp$item)) {
    resp_i <- resp[resp$item == i, ]
    update_term <- K_beta * sum(E_Sij[resp$item == i] - resp_i$resp)
    beta_updated[i] <- diff[i] + update_term
  }

  out <- list(
    theta_est = theta_updated,
    diff_est = beta_updated,
    resp_cur = resp
  )
  return(out)
}

# Use with custom learning rates
results <- meow(
  select_fun = select_max_info,
  update_fun = update_maths_garden_custom,
  data_loader = data_simple_1pl,
  update_args = list(K_theta = 0.05, K_beta = 0.05),
  data_args = list(N_persons = 100, N_items = 50)
)
```

## Advantages and Limitations

### Advantages

1.  **Simplicity**: The algorithm is straightforward to implement and
    understand
2.  **Real-time Updates**: Both person and item parameters are updated
    simultaneously
3.  **No Iteration Required**: Updates are computed directly without
    iterative optimization
4.  **Computational Efficiency**: Fast computation suitable for
    real-time applications
5.  **Interpretable**: The update rules have clear intuitive meaning

### Limitations

1.  **Fixed Learning Rates**: The algorithm uses constant learning rates
    that don’t adapt to data
2.  **No Uncertainty Quantification**: Doesn’t provide confidence
    intervals or standard errors
3.  **Potential Instability**: Large learning rates can cause parameter
    estimates to oscillate
4.  **Assumes 1PL Model**: Based on the Rasch model, may not fit data
    requiring 2PL or 3PL models
5.  **No Prior Information**: Doesn’t incorporate prior knowledge about
    parameters

## Extensions and Modifications

### Adaptive Learning Rates

You can implement adaptive learning rates that change based on the
amount of data:

``` r
update_maths_garden_adaptive <- function(theta, diff, resp) {
  E_Sij <- stats::plogis(theta[resp$id] - diff[resp$item])

  # Adaptive learning rates based on number of responses
  for (j in unique(resp$id)) {
    resp_j <- resp[resp$id == j, ]
    n_responses <- nrow(resp_j)
    
    # Decrease learning rate with more responses
    K_theta_adaptive <- 0.1 / (1 + n_responses * 0.1)
    
    update_term <- K_theta_adaptive * sum(resp_j$resp - E_Sij[resp$id == j])
    theta[j] <- theta[j] + update_term
  }

  for (i in unique(resp$item)) {
    resp_i <- resp[resp$item == i, ]
    n_responses <- nrow(resp_i)
    
    # Decrease learning rate with more responses
    K_beta_adaptive <- 0.1 / (1 + n_responses * 0.1)
    
    update_term <- K_beta_adaptive * sum(E_Sij[resp$item == i] - resp_i$resp)
    diff[i] <- diff[i] + update_term
  }

  out <- list(
    theta_est = theta,
    diff_est = diff,
    resp_cur = resp
  )
  return(out)
}
```

### Constrained Updates

You can add constraints to prevent extreme parameter values:

``` r
update_maths_garden_constrained <- function(theta, diff, resp, 
                                          theta_bounds = c(-4, 4), 
                                          diff_bounds = c(-4, 4)) {
  E_Sij <- stats::plogis(theta[resp$id] - diff[resp$item])

  # Update theta with constraints
  for (j in unique(resp$id)) {
    resp_j <- resp[resp$id == j, ]
    update_term <- 0.1 * sum(resp_j$resp - E_Sij[resp$id == j])
    theta[j] <- theta[j] + update_term
    
    # Apply constraints
    theta[j] <- max(theta_bounds[1], min(theta_bounds[2], theta[j]))
  }

  # Update diff with constraints
  for (i in unique(resp$item)) {
    resp_i <- resp[resp$item == i, ]
    update_term <- 0.1 * sum(E_Sij[resp$item == i] - resp_i$resp)
    diff[i] <- diff[i] + update_term
    
    # Apply constraints
    diff[i] <- max(diff_bounds[1], min(diff_bounds[2], diff[i]))
  }

  out <- list(
    theta_est = theta,
    diff_est = diff,
    resp_cur = resp
  )
  return(out)
}
```

## Best Practices

1.  **Start with Small Learning Rates**: Begin with
    $K_{\theta} = K_{b} = 0.1$ and adjust based on results
2.  **Monitor Convergence**: Check if parameter estimates stabilize over
    iterations
3.  **Use Constraints**: Implement bounds on parameter values to prevent
    extreme estimates
4.  **Consider Adaptive Rates**: Use decreasing learning rates for more
    stable long-term estimates
5.  **Validate Results**: Compare with other estimation methods when
    possible
6.  **Test with Different Data**: Ensure the algorithm works well with
    your specific data characteristics

## Example: Complete Workflow

``` r
# Load required packages
library(meow)

# Define custom Maths Garden function with adaptive rates
update_maths_garden_improved <- function(theta, diff, resp) {
  E_Sij <- stats::plogis(theta[resp$id] - diff[resp$item])

  # Adaptive learning rates
  for (j in unique(resp$id)) {
    resp_j <- resp[resp$id == j, ]
    n_responses <- nrow(resp_j)
    K_theta_adaptive <- 0.1 / (1 + n_responses * 0.05)
    
    update_term <- K_theta_adaptive * sum(resp_j$resp - E_Sij[resp$id == j])
    theta[j] <- theta[j] + update_term
    theta[j] <- max(-4, min(4, theta[j]))  # Constraints
  }

  for (i in unique(resp$item)) {
    resp_i <- resp[resp$item == i, ]
    n_responses <- nrow(resp_i)
    K_beta_adaptive <- 0.1 / (1 + n_responses * 0.05)
    
    update_term <- K_beta_adaptive * sum(E_Sij[resp$item == i] - resp_i$resp)
    diff[i] <- diff[i] + update_term
    diff[i] <- max(-4, min(4, diff[i]))  # Constraints
  }

  out <- list(
    theta_est = theta,
    diff_est = diff,
    resp_cur = resp
  )
  return(out)
}

# Run simulation
results <- meow(
  select_fun = select_max_info,
  update_fun = update_maths_garden_improved,
  data_loader = data_simple_1pl,
  data_args = list(N_persons = 100, N_items = 50, data_seed = 123)
)

# Analyze results
print(head(results$results))
```
