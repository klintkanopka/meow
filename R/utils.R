#' Construct an item-pool adjacency matrix.
#'
#' For an item pool with N items, this returns an N x N matrix. The diagonal
#' elements contain the number of times each item has been administered. The
#' off-diagonal element \eqn{(i, j)} contains the number of respondents who have
#' been administered both item \eqn{i} and item \eqn{j}. In general this function
#' is not called directly, but is instead called within [meow()]. It is exposed
#' to aid users who are testing item selection functions they have written.
#'
#' @param admin An administration matrix with one row per respondent and one
#'   column per item. Non-zero entries indicate that an item has been
#'   administered to a respondent (see [meow()] for details of the matrix-based
#'   simulation state). A logical matrix is also accepted.
#' @returns An item-item adjacency matrix of type `matrix`.
#'
#' @examples
#' admin <- matrix(c(1, 1, 0,
#'                   1, 0, 1), nrow = 2, byrow = TRUE)
#' construct_adj_mat(admin)
#'
#' @export
construct_adj_mat <- function(admin) {
  a <- (admin != 0) + 0
  adj_mat <- crossprod(a)
  rownames(adj_mat) <- colnames(adj_mat) <- paste0('item_', seq_len(ncol(a)))
  return(adj_mat)
}


#' Logical mask of administered items.
#'
#' A convenience helper for use inside user-written modules. Returns a logical
#' matrix that is `TRUE` wherever an item has been administered to a respondent.
#'
#' @param admin An administration matrix (see [meow()]).
#' @returns A logical matrix the same shape as `admin`.
#'
#' @examples
#' admin <- matrix(c(1L, 2L, 0L, 1L), nrow = 2)
#' meow_administered(admin)
#'
#' @export
meow_administered <- function(admin) {
  admin != 0
}


#' Convert the matrix simulation state to a long data frame of responses.
#'
#' `meow()` represents responses as a respondent-by-item matrix (`R`) together
#' with an administration matrix (`admin`). This helper returns the administered
#' responses as a long data frame with columns `id`, `item`, and `resp`, ordered
#' by respondent and then by the order in which items were administered. It is
#' the recommended bridge for module authors who prefer to work with
#' tidyverse-style long data inside their own item selection or parameter update
#' functions.
#'
#' @param R A respondent-by-item matrix of (potential) responses.
#' @param admin An administration matrix the same shape as `R`. Non-zero entries
#'   indicate administered items; positive integer entries additionally encode
#'   the order of administration.
#' @returns A long-form data frame with columns `id`, `item`, and `resp`
#'   containing only the administered responses.
#'
#' @examples
#' R <- matrix(c(1, 0, 1, 1), nrow = 2)
#' admin <- matrix(c(1L, 0L, 2L, 1L), nrow = 2)
#' meow_long(R, admin)
#'
#' @export
meow_long <- function(R, admin) {
  idx <- which(admin != 0, arr.ind = TRUE)
  if (nrow(idx) == 0) {
    return(data.frame(id = integer(0), item = integer(0), resp = numeric(0)))
  }
  id <- idx[, 1]
  item <- idx[, 2]
  ord <- order(id, admin[idx], item)
  data.frame(
    id = id[ord],
    item = item[ord],
    resp = R[idx][ord]
  )
}


#' Alternative edge weight functions for network-based item selection
#'
#' These functions provide different approaches to calculating edge weights from
#' the adjacency matrix.
#'
#' @param adj_mat The adjacency matrix where entry i,j is the number of
#'   co-responses between items i and j
#' @param alpha Smoothing parameter for avoiding division by zero
#' @param beta Exponent for power transformation
#' @param lambda Decay constant for exponential decay weighting
#' @param max_co_responses Scaling factor for linear weighting
#' @returns A matrix of edge weights for use in distance calculations
#'
#' @examples
#' adj_mat <- matrix(c(3, 1, 1, 2), nrow = 2)
#' edge_weight_inverse(adj_mat)
#'
#' @export
edge_weight_inverse <- function(adj_mat, alpha = 1) {
  # Original approach: inverse of co-response count
  # Higher co-responses = lower weights = shorter distances
  return(1 / (adj_mat + alpha))
}

#' @rdname edge_weight_inverse
#' @export
edge_weight_negative_log <- function(adj_mat, alpha = 1) {
  # Negative log transformation
  # Higher co-responses = lower weights = shorter distances
  return(-log(adj_mat + alpha))
}

#' @rdname edge_weight_inverse
#' @export
edge_weight_linear <- function(adj_mat, max_co_responses = NULL) {
  # Linear transformation: higher co-responses = higher weights = longer distances
  # This inverts the logic: items that are frequently answered together are "farther apart"
  if (is.null(max_co_responses)) {
    max_co_responses <- max(adj_mat)
  }
  return(adj_mat / max_co_responses)
}

#' @rdname edge_weight_inverse
#' @export
edge_weight_power <- function(adj_mat, beta = 0.5, alpha = 1) {
  # Power transformation with smoothing
  # beta < 1: reduces the impact of high co-response counts
  # beta > 1: amplifies the impact of high co-response counts
  return((adj_mat + alpha)^beta)
}

#' @rdname edge_weight_inverse
#' @export
edge_weight_exponential <- function(adj_mat, lambda = 0.1, alpha = 1) {
  # Exponential decay: higher co-responses = much lower weights
  return(exp(-lambda * (adj_mat + alpha)))
}
