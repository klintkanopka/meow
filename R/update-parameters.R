#' Updated person parameters based on MLE estimates
#'
#' This update function treats item parameters as fixed and known, updating person ability estimates after each iteration according to a maximum likelihood estimate based upon a 2PL item response function.
#'
#' @param pers A dataframe of current respondent parameter estimates.
#' @param item A dataframe of item parameter values.
#' @param resp A long-form dataframe of only observed item responses.
#' @returns An list of three objects, only one of which is updated from the function input: `pers` is a dataframe with updated respondent parameter estimates, `item` is the dataframe of item parameter values. `resp_cur` is the dataframe of observed item responses.
#'
#' @export
update_theta_mle <- function(pers, item, resp) {
  # unidimensional 2PL MLE estimation of ability, treating item params as fixed
  theta_mle <- function(pers, item, resp) {
    loglik <- function(theta, item, resp) {
      p <- stats::plogis(
        item$a[resp$item] * (theta[resp$id] - item$b[resp$item])
      )
      ll <- sum(resp$resp * log(p) + (1 - resp$resp) * log(1 - p))
      return(ll)
    }

    est <- stats::optim(
      pers$theta,
      loglik,
      lower = -4,
      upper = 4,
      item = item,
      resp = resp,
      method = 'L-BFGS-B',
      control = list(fnscale = -1)
    )

    return(est$par)
  }

  pers$theta <- theta_mle(pers, item, resp)

  out <- list(
    pers = pers,
    item = item,
    resp_cur = resp
  )
  return(out)
}


#' Elo-style updates of person and item parameters
#'
#' This update function updates both person and item parameters according to the approach from the paper "Computer adaptive practice of Maths ability using a new item response model for on the fly ability and difficulty estimation" (Klinkenberg, Straatemeier, and van der Maas, 2011). Learning rates are tunable using supplied `K_theta` and `K_b` arguments.
#'
#' @param pers A dataframe of current respondent parameter estimates.
#' @param item A dataframe of current item parameter estimates.
#' @param resp A long-form dataframe of only observed item responses.
#' @param K_theta User supplied learning rate for person ability updates. Defaults to 0.1
#' @param K_b User supplied learning rate for item difficulty updates. Defaults to 0.1
#' @returns An list of three objects, two of which are updated from the function input: `pers` is a dataframe with updated respondent parameter estimates, `item` is the dataframe of updated item parameter estimates. `resp_cur` is the dataframe of observed item responses.
#'
#' @export
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


#' Elo-style updates of person and item parameters
#'
#' This update function updates both person and item parameters according to the approach from the paper "Psychometrics of an Elo-based large-scale online learning system" (Vermeiren, et al. 2025)
#'
#' @param pers A dataframe of current respondent parameter estimates.
#' @param item A dataframe of current item parameter estimates.
#' @param resp A long-form dataframe of only observed item responses.
#' @param K_theta User supplied learning rate for person ability updates. Defaults to 0.1
#' @param K_b User supplied learning rate for item difficulty updates. Defaults to 0.1
#' @returns An list of three objects, two of which are updated from the function input: `pers` is a dataframe with updated respondent parameter estimates, `item` is the dataframe of updated item parameter estimates. `resp_cur` is the dataframe of observed item responses.
#'
#' @export
update_prowise_learn <- function(pers, item, resp, K_theta = 0.1, K_b = 0.1) {
  # Implement the update rule from the Prowise Learn paper with paired item updates
  # to prevent rating drift

  # Initialize updated parameters
  theta_updated <- theta <- pers$theta
  diff_updated <- diff <- pers$b

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
        kappa <- 0.5 * (K_b * (s_now - e_now) - K_b * (s_prev - e_prev))
        diff_updated[item_now] <- diff_updated[item_now] + kappa
        diff_updated[item_prev] <- diff_updated[item_prev] - kappa
        update_count <- update_count + 1
      }
    }
  }
  cat("Prowise item updates triggered:", update_count, "\n")

  pers$theta <- theta_updated
  item$b <- diff_updated

  out <- list(
    pers = pers,
    item = item,
    resp_cur = resp
  )
  return(out)
}
