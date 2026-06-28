#' Update person ability via maximum likelihood estimation.
#'
#' This update function treats item parameters as fixed and known and updates
#' person ability estimates after each iteration with a maximum likelihood
#' estimate based on a 2PL item response function.
#'
#' @param pers A data frame of current respondent parameter estimates.
#' @param item A data frame of item parameter values.
#' @param R A respondent-by-item matrix of potential responses.
#' @param admin An integer administration matrix; non-zero entries indicate
#'   administered items. See [meow()] for details.
#' @returns A list with two entries: `pers`, a data frame with updated respondent
#'   ability estimates, and `item`, the unchanged data frame of item parameters.
#'
#' @examples
#' data <- data_simple_1pl(N_persons = 10, N_items = 10)
#' admin <- matrix(0L, 10, 10)
#' admin[, 1:5] <- 1L
#' R <- matrix(data$resp$resp, nrow = 10, byrow = TRUE)
#' upd <- update_theta_mle(data$pers_tru, data$item_tru, R, admin)
#' head(upd$pers)
#'
#' @export
update_theta_mle <- function(pers, item, R, admin) {
  idx <- which(admin != 0, arr.ind = TRUE)
  person <- idx[, 1]
  itm <- idx[, 2]
  resp <- R[idx]

  loglik <- function(theta) {
    p <- stats::plogis(item$a[itm] * (theta[person] - item$b[itm]))
    sum(resp * log(p) + (1 - resp) * log(1 - p))
  }

  est <- stats::optim(
    pers$theta,
    loglik,
    lower = -4,
    upper = 4,
    method = 'L-BFGS-B',
    control = list(fnscale = -1)
  )

  pers$theta <- est$par
  list(pers = pers, item = item)
}


#' Elo-style updates of person and item parameters (Maths Garden).
#'
#' Updates both person and item parameters following Klinkenberg, Straatemeier,
#' and van der Maas (2011), "Computer adaptive practice of Maths ability using a
#' new item response model for on the fly ability and difficulty estimation."
#' Learning rates are tunable through `K_theta` and `K_b`.
#'
#' @inheritParams update_theta_mle
#' @param item A data frame of current item parameter estimates.
#' @param K_theta Learning rate for person ability updates. Defaults to 0.1.
#' @param K_b Learning rate for item difficulty updates. Defaults to 0.1.
#' @returns A list with two entries: `pers` and `item`, the data frames of
#'   updated respondent and item parameter estimates.
#'
#' @examples
#' data <- data_simple_1pl(N_persons = 10, N_items = 10)
#' admin <- matrix(0L, 10, 10)
#' admin[, 1:5] <- 1L
#' R <- matrix(data$resp$resp, nrow = 10, byrow = TRUE)
#' upd <- update_maths_garden(data$pers_tru, data$item_tru, R, admin)
#'
#' @export
update_maths_garden <- function(pers, item, R, admin, K_theta = 0.1, K_b = 0.1) {
  # Theta_hat_j = theta_j + K_theta * (S_ij - E(S_ij))
  # Beta_hat_i  = beta_i  + K_b     * (E(S_ij) - S_ij)
  idx <- which(admin != 0, arr.ind = TRUE)
  person <- idx[, 1]
  itm <- idx[, 2]
  resp <- R[idx]

  E_Sij <- stats::plogis(pers$theta[person] - item$b[itm])

  dtheta <- tapply(resp - E_Sij, person, sum)
  pers$theta[as.integer(names(dtheta))] <-
    pers$theta[as.integer(names(dtheta))] + K_theta * dtheta

  db <- tapply(E_Sij - resp, itm, sum)
  item$b[as.integer(names(db))] <-
    item$b[as.integer(names(db))] + K_b * db

  list(pers = pers, item = item)
}


#' Elo-style updates with paired item comparisons (Prowise Learn).
#'
#' Updates both person and item parameters following Vermeiren et al. (2025),
#' "Psychometrics of an Elo-based large-scale online learning system." Item
#' difficulties are updated using paired comparisons of consecutively
#' administered items, which controls the rating drift that can occur with naive
#' Elo updates.
#'
#' @inheritParams update_maths_garden
#' @returns A list with two entries: `pers` and `item`, the data frames of
#'   updated respondent and item parameter estimates.
#'
#' @examples
#' data <- data_simple_1pl(N_persons = 10, N_items = 10)
#' admin <- matrix(0L, 10, 10)
#' admin[, 1:5] <- 1L
#' R <- matrix(data$resp$resp, nrow = 10, byrow = TRUE)
#' upd <- update_prowise_learn(data$pers_tru, data$item_tru, R, admin)
#'
#' @export
update_prowise_learn <- function(pers, item, R, admin, K_theta = 0.1, K_b = 0.1) {
  # Responses in administration order (by respondent, then order administered).
  long <- meow_long(R, admin)
  E_Sij <- stats::plogis(pers$theta[long$id] - item$b[long$item])

  # Ability update (as in Maths Garden).
  dtheta <- tapply(long$resp - E_Sij, long$id, sum)
  pers$theta[as.integer(names(dtheta))] <-
    pers$theta[as.integer(names(dtheta))] + K_theta * dtheta

  # Paired item updates over consecutively administered items for each person.
  n <- nrow(long)
  if (n >= 2) {
    nxt <- 2:n
    prv <- 1:(n - 1)
    pair <- which(long$id[nxt] == long$id[prv])
    if (length(pair) > 0) {
      now <- nxt[pair]
      pre <- prv[pair]
      kappa <- 0.5 *
        (K_b * (long$resp[now] - E_Sij[now]) -
          K_b * (long$resp[pre] - E_Sij[pre]))
      add_now <- tapply(kappa, long$item[now], sum)
      add_pre <- tapply(-kappa, long$item[pre], sum)
      item$b[as.integer(names(add_now))] <-
        item$b[as.integer(names(add_now))] + add_now
      item$b[as.integer(names(add_pre))] <-
        item$b[as.integer(names(add_pre))] + add_pre
    }
  }

  list(pers = pers, item = item)
}
