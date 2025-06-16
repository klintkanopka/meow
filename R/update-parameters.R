update_theta_mle <- function(theta, diff, resp) {
  # MLE estimation of theta, treating difficulty as fixed
  theta_mle <- function(theta, diff, resp) {
    loglik <- function(theta, diff, resp) {
      p <- stats::plogis(theta[resp$id] - diff[resp$item])
      ll <- sum(resp$resp * log(p) + (1 - resp$resp) * log(1 - p))
      return(ll)
    }

    est <- stats::optim(
      theta,
      loglik,
      lower = -4,
      upper = 4,
      diff = diff,
      resp = resp,
      method = 'L-BFGS-B',
      control = list(fnscale = -1)
    )

    return(est$par)
  }

  out <- list(
    theta_est = theta_mle(theta, diff, resp),
    diff_est = diff,
    resp_cur = resp
  )
  return(out)
}


update_maths_garden <- function(theta, diff, resp) {
  # Implement the update rule from the maths garden paper
  # Theta_hat_j = theta_j + K_j (S_ij - E(S_ij))
  # Beta_hat_i = beta_i + K_i(E(S_ij)-S_ij)
  # where S_ij is the observed score and E(S_ij) is the expected probability

  # Calculate expected probabilities using logistic function
  E_Sij <- stats::plogis(theta[resp$id] - diff[resp$item])

  # Learning rates (K values) - these could be tuned
  K_theta <- 0.1 # Learning rate for ability
  K_beta <- 0.1 # Learning rate for difficulty

  # Update theta (ability) for each person
  theta_updated <- theta
  for (j in unique(resp$id)) {
    # Get responses for person j
    resp_j <- resp[resp$id == j, ]
    # Calculate update term
    update_term <- K_theta * sum(resp_j$resp - E_Sij[resp$id == j])
    theta_updated[j] <- theta[j] + update_term
  }

  # Update beta (difficulty) for each item
  beta_updated <- diff
  for (i in unique(resp$item)) {
    # Get responses for item i
    resp_i <- resp[resp$item == i, ]
    # Calculate update term
    update_term <- K_beta * sum(E_Sij[resp$item == i] - resp_i$resp)
    beta_updated[i] <- diff[i] + update_term
  }

  out <- list(
    theta_est = theta_updated,
    diff_est = beta_updated,
    resp_cur = resp
  )
  return(out)

  # out <- list(
  #   theta_est = theta,
  #   diff_est = diff,
  #   resp_cur = resp
  # )
  # return(out)
}


update_prowise_learn <- function(theta, diff, resp) {
  # Implement the update rule from the Prowise Learn paper with paired item updates
  # to prevent rating drift

  # Initialize updated parameters
  theta_updated <- theta
  diff_updated <- diff

  # Learning rates (K values) - these could be tuned
  K_theta <- 0.1 # Learning rate for ability
  K_beta <- 0.1 # Learning rate for difficulty

  # Calculate expected probabilities for all responses
  E_Sij <- stats::plogis(theta[resp$id] - diff[resp$item])

  # Update theta (ability) for each person
  for (j in unique(resp$id)) {
    resp_j <- resp[resp$id == j, ]
    update_term <- K_theta * sum(resp_j$resp - E_Sij[resp$id == j])
    theta_updated[j] <- theta[j] + update_term
  }

  # Paired item updates
  update_count <- 0
  for (person in unique(resp$id)) {
    person_idx <- which(resp$id == person)
    if (length(person_idx) >= 2) {
      for (i in 2:length(person_idx)) {
        idx_now <- person_idx[i]
        idx_prev <- person_idx[i - 1]
        item_now <- resp$item[idx_now]
        item_prev <- resp$item[idx_prev]
        s_now <- resp$resp[idx_now]
        s_prev <- resp$resp[idx_prev]
        e_now <- E_Sij[idx_now]
        e_prev <- E_Sij[idx_prev]
        kappa <- 0.5 * (K_beta * (s_now - e_now) - K_beta * (s_prev - e_prev))
        diff_updated[item_now] <- diff_updated[item_now] + kappa
        diff_updated[item_prev] <- diff_updated[item_prev] - kappa
        update_count <- update_count + 1
      }
    }
  }
  cat("Prowise item updates triggered:", update_count, "\n")

  out <- list(
    theta_est = theta_updated,
    diff_est = diff_updated,
    resp_cur = resp
  )
  return(out)
}
