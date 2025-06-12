#' Constructs an item pool adjacency matrix. For an item pool with $N$ items, this is an $N \times N$ matrix. The diagonal elements contain the number of times an item has been exposed. The off-diagonal elements contain the number of times the pair of items has been exposed to the same respondent. In general, this function is never called directly, but instead called within `cat_simulation()` calls.
#'
#' @param resp_cur A long-form dataframe of observed item responses.
#' @param theta_tru A vector of true respondent abilities.
#' @param diff_tru A vector of true item difficulties.
#' @returns An adjacency matrix of type `matrix`.
construct_adj_mat <- function(resp_cur, theta_tru, diff_tru) {
  resp_mat <- matrix(0, nrow = length(theta_tru), ncol = length(diff_tru))
  for (k in 1:nrow(resp_cur)) {
    i <- resp_cur$id[k]
    j <- resp_cur$item[k]
    resp_mat[i, j] <- 1
  }
  adj_mat <- t(resp_mat) %*% resp_mat
  rownames(adj_mat) <- colnames(adj_mat) <- paste0('item_', 1:length(diff_tru))
  return(adj_mat)
}


#' Conducts a full CAT simulation.
#'
#' @param select_fun A function that specifies the item selection algorithm.
#' @param update_fun A function that specifies the parameter update algorithm.
#' @param data_loader A function that specifies the data generating process.
#' @param init A list of intialization values for estimated person and item parameters. Currently accepts a named list with two entities: `theta` and `diff`, for initial estimated values of ability and difficulty, respectively. Defaults to `NULL`, which initializes all estimated parameters to zero.
#' @param fix Which estimated parameters to treat as fixed. Currently defaults to `none`, but accepts `theta`, `diff`, or `both`.`
#' @returns A list of four named entities, `results` is a dataframe with one row per iteration of the simulation. It contains three general columns, `iter` for the iteration number, a RMSE pooled across person abilities named `rmse_theta`, and the RMSE pooled across item difficulties named `rmse_diff`. Additionally there is one column per person and item, one for the associated estimated parameter (ability or difficulty) and one for the bias in that estimate. Next is a list of item-item adjacency matrices, contained in `adj_mats`. One matrix is provided per iteration of the simulation, and edge weights are the number of respondents who have responded to each pair of items. Finally, true ability and difficulty vectors are returned in `theta_tru` and `diff_tru`.
cat_simulation <- function(
  select_fun,
  update_fun,
  data_loader,
  init = NULL,
  fix = 'none',
  ... # named arguments to be passed to data_loader, select_fun, or update_fun
) {
  data <- data_loader(...)
  theta_tru <- data$theta_tru
  diff_tru <- data$diff_tru
  resp <- data$resp

  if (is.null(init)) {
    theta_est <- numeric(length(theta_tru))
    diff_est <- numeric(length(diff_tru))
  } else {
    theta_est <- init$theta
    diff_est <- init$diff
  }

  adj_mats <- list()
  adj_mat <- matrix(data = 0, nrow = length(diff_est), ncol = length(diff_est))

  if (fix %in% c('theta', 'both')) {
    theta_est <- theta_tru
  }
  if (fix %in% c('diff', 'both')) {
    diff_est <- diff_tru
  }

  resp_cur <- NULL
  resp_prev <- resp

  iter <- 1

  results <- matrix(
    0,
    nrow = 2 * length(diff_tru),
    ncol = 2 * length(c(theta_est, diff_est)) + 3
  )

  while (!identical(resp_cur, resp_prev)) {
    resp_prev <- resp_cur

    out <- update_fun(
      theta_est,
      diff_est,
      select_fun(theta_est, diff_est, resp, resp_cur, adj_mat, ...),
      ...
    )

    theta_est <- out$theta_est
    diff_est <- out$diff_est
    resp_cur <- out$resp_cur

    adj_mat <- construct_adj_mat(resp_cur, theta_tru, diff_tru)
    adj_mats[[iter]] <- adj_mat

    theta_bias <- theta_tru - theta_est
    diff_bias <- diff_tru - diff_est

    rmse_theta <- sqrt(mean((theta_bias)^2))
    rmse_diff <- sqrt(mean((diff_bias)^2))

    results[iter, ] <- c(
      iter,
      rmse_theta,
      rmse_diff,
      theta_est,
      theta_bias,
      diff_est,
      diff_bias
    )

    iter <- iter + 1
  }

  results <- results[rowSums(results) != 0, ]
  results <- data.frame(results)
  names(results) <- c(
    'iter',
    'rmse_theta',
    'rmse_diff',
    paste0('theta_', 1:length(theta_est)),
    paste0('theta_', 1:length(theta_bias), '_bias'),
    paste0('item_', 1:length(diff_est)),
    paste0('item_', 1:length(diff_bias), '_bias')
  )

  out <- list(
    results = results,
    adj_mats = adj_mats,
    diff_tru = diff_tru,
    theta_tru = theta_tru
  )

  return(out)
}
