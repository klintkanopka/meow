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
