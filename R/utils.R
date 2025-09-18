#' Constructs an item pool adjacency matrix.
#'
#' For an item pool with N items, this is an NxN matrix. The diagonal elements contain the number of times an item has been exposed. The off-diagonal elements contain the number of times the pair of items has been exposed to the same respondent. In general, this function is never called directly, but instead called within `meow()` calls. That said, it is exposed to the user to aid with testing other functions they may write.
#'
#' @param resp_cur A long-form dataframe of observed item responses.
#' @param pers_tru A dataframe of true respondent abilities.
#' @param item_tru A dataframe of true item parameters.
#'
#' @export
#' @returns An adjacency matrix of type `matrix`.
construct_adj_mat <- function(resp_cur, pers_tru, item_tru) {
  resp_mat <- matrix(0, nrow = nrow(pers_tru), ncol = nrow(item_tru))
  for (k in 1:nrow(resp_cur)) {
    i <- resp_cur$id[k]
    j <- resp_cur$item[k]
    resp_mat[i, j] <- 1
  }
  adj_mat <- t(resp_mat) %*% resp_mat
  rownames(adj_mat) <- colnames(adj_mat) <- paste0('item_', 1:nrow(item_tru))
  return(adj_mat)
}

#' Alternative edge weight functions for network-based item selection
#'
#' These functions provide different approaches to calculating edge weights from the adjacency matrix.
#'
#' @param adj_mat The adjacency matrix where entry i,j is the number of co-responses between items i and j
#' @param alpha Smoothing parameter for avoiding division by zero
#' @param beta Exponent for power transformation
#' @param lambda Decay constant for exponential decay weighting
#' @param max_co_responses Scaling factor for linear weighting
#' @returns A matrix of edge weights for use in distance calculations
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
