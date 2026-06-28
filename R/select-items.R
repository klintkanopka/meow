# Internal helper: administer the first `n` items to every respondent.
# Used by the bundled selectors to seed the simulation on the first iteration.
.administer_initial <- function(admin, n = 5) {
  n_init <- min(n, ncol(admin))
  admin[, seq_len(n_init)] <- 1L
  admin
}

# Internal helper: 2PL item information for every respondent-item combination.
# Returns a respondents-by-items matrix of a^2 * p * (1 - p).
.info_matrix <- function(theta, a, b) {
  lin <- sweep(outer(theta, b, '-'), 2, a, '*')
  P <- stats::plogis(lin)
  sweep(P * (1 - P), 2, a^2, '*')
}

# Internal helper: network-distance item selection shared by select_max_dist()
# and select_max_dist_enhanced(). For each respondent with unadministered items,
# selects the unadministered item farthest (in the weighted item graph) from the
# items already administered, breaking ties with the maximum information
# criterion. `dist_mat` is a precomputed item-item distance matrix.
.select_by_distance <- function(pers, item, admin, dist_mat, n_candidates) {
  info <- .info_matrix(pers$theta, item$a, item$b)
  needs_item <- which(rowSums(admin == 0) > 0)
  for (i in needs_item) {
    administered <- which(admin[i, ] != 0)
    candidates <- which(admin[i, ] == 0)
    # Distance from each candidate to the nearest administered item.
    sub <- dist_mat[administered, candidates, drop = FALSE]
    cand_dist <- if (length(administered) == 1L) {
      sub[1, ]
    } else {
      Rfast::colMins(sub, value = TRUE)
    }
    if (n_candidates == 1L) {
      threshold <- max(cand_dist)
    } else {
      k <- min(n_candidates, length(cand_dist))
      threshold <- sort(cand_dist, decreasing = TRUE)[k]
    }
    pool <- candidates[cand_dist >= threshold]
    pick <- pool[which.max(info[i, pool])]
    admin[i, pick] <- 1L
  }
  admin
}


#' Item selection by item id, simulating a fixed test form.
#'
#' This function administers the next unadministered item to each respondent in
#' increasing item-id order, producing a fixed linear test form.
#'
#' @param pers A data frame of current respondent ability estimates.
#' @param item A data frame of current item parameter estimates.
#' @param R A respondent-by-item matrix of potential responses.
#' @param admin An integer administration matrix; `0` indicates an item has not
#'   been administered to a respondent. See [meow()] for details.
#' @param adj_mat An item-item adjacency matrix. See [construct_adj_mat()].
#' @returns An updated administration matrix with each respondent's next item
#'   marked as administered.
#'
#' @examples
#' sim <- meow(select_sequential, update_theta_mle, data_simple_1pl,
#'             data_args = list(N_persons = 10, N_items = 10), fix = "item")
#' nrow(sim$results)
#'
#' @export
select_sequential <- function(pers, item, R, admin, adj_mat = NULL) {
  if (!any(admin != 0)) {
    return(.administer_initial(admin))
  }
  unadmin <- admin == 0
  has <- which(rowSums(unadmin) > 0)
  if (length(has) > 0) {
    nextcol <- max.col(unadmin[has, , drop = FALSE] + 0, ties.method = 'first')
    admin[cbind(has, nextcol)] <- 1L
  }
  return(admin)
}


#' Item selection by random draw from the remaining item bank.
#'
#' Each respondent's next item is drawn at random from the items they have not
#' yet been administered.
#'
#' @inheritParams select_sequential
#' @param select_seed A random seed used only for item selection. The seed is
#'   cleared after use so that successive simulations vary unless a seed is given.
#' @returns An updated administration matrix with a random next item marked for
#'   each respondent.
#'
#' @examples
#' sim <- meow(select_random, update_theta_mle, data_simple_1pl,
#'             data_args = list(N_persons = 10, N_items = 10), fix = "item",
#'             select_args = list(select_seed = 1))
#' nrow(sim$results)
#'
#' @export
select_random <- function(pers, item, R, admin, adj_mat = NULL, select_seed = NULL) {
  # note default behavior is a cleared seed, to ensure variation between runs
  set.seed(select_seed)
  if (!any(admin != 0)) {
    set.seed(NULL)
    return(.administer_initial(admin))
  }
  for (i in which(rowSums(admin == 0) > 0)) {
    candidates <- which(admin[i, ] == 0)
    pick <- candidates[sample.int(length(candidates), 1)]
    admin[i, pick] <- 1L
  }
  set.seed(NULL)
  return(admin)
}


#' Item selection by maximum Fisher information.
#'
#' Administers the remaining item with the highest information for each
#' respondent, computed from the current parameter estimates and a 2PL item
#' response function.
#'
#' @inheritParams select_sequential
#' @returns An updated administration matrix with the most informative remaining
#'   item marked for each respondent.
#'
#' @examples
#' sim <- meow(select_max_info, update_theta_mle, data_simple_1pl,
#'             data_args = list(N_persons = 10, N_items = 10), fix = "item")
#' nrow(sim$results)
#'
#' @export
select_max_info <- function(pers, item, R, admin, adj_mat = NULL) {
  if (!any(admin != 0)) {
    return(.administer_initial(admin))
  }
  info <- .info_matrix(pers$theta, item$a, item$b)
  info[admin != 0] <- -Inf
  has <- which(rowSums(admin == 0) > 0)
  if (length(has) > 0) {
    pick <- max.col(info[has, , drop = FALSE], ties.method = 'first')
    admin[cbind(has, pick)] <- 1L
  }
  return(admin)
}


#' Item selection by network distance criterion.
#'
#' Administers the item farthest in the item network from the items a respondent
#' has already answered, with edges weighted by the inverse of their entry in the
#' item-item adjacency matrix. Ties are broken using the maximum information
#' criterion.
#'
#' @inheritParams select_sequential
#' @param n_candidates The number of farthest items to assemble into a candidate
#'   pool before selecting the next item by maximum information. Allows users to
#'   trade off network density against estimation efficiency.
#' @returns An updated administration matrix with the selected item marked for
#'   each respondent.
#'
#' @examples
#' sim <- meow(select_max_dist, update_theta_mle, data_simple_1pl,
#'             data_args = list(N_persons = 10, N_items = 10), fix = "item")
#' nrow(sim$results)
#'
#' @export
select_max_dist <- function(pers, item, R, admin, adj_mat = NULL, n_candidates = 1) {
  if (!any(admin != 0)) {
    return(.administer_initial(admin))
  }
  # Edge weights can be adjusted here; the inverse of the co-response count is
  # the default. See select_max_dist_enhanced() for configurable weights.
  dist_mat <- Rfast::floyd(1 / adj_mat)
  .select_by_distance(pers, item, admin, dist_mat, n_candidates)
}


#' Network-based item selection with configurable edge weights.
#'
#' Extends [select_max_dist()] with a flexible edge weight calculation.
#'
#' @inheritParams select_max_dist
#' @param edge_weight_fun A function that computes edge weights from the
#'   adjacency matrix. See [edge_weight_inverse()].
#' @param edge_weight_args A named list of additional arguments for
#'   `edge_weight_fun`.
#' @returns An updated administration matrix with the selected item marked for
#'   each respondent.
#'
#' @examples
#' sim <- meow(select_max_dist_enhanced, update_theta_mle, data_simple_1pl,
#'             data_args = list(N_persons = 10, N_items = 10), fix = "item",
#'             select_args = list(edge_weight_fun = edge_weight_power))
#' nrow(sim$results)
#'
#' @export
select_max_dist_enhanced <- function(
  pers,
  item,
  R,
  admin,
  adj_mat = NULL,
  n_candidates = 1,
  edge_weight_fun = edge_weight_inverse,
  edge_weight_args = list()
) {
  if (!any(admin != 0)) {
    return(.administer_initial(admin))
  }
  edge_weights <- do.call(
    edge_weight_fun,
    c(list(adj_mat = adj_mat), edge_weight_args)
  )
  dist_mat <- Rfast::floyd(edge_weights)
  .select_by_distance(pers, item, admin, dist_mat, n_candidates)
}
