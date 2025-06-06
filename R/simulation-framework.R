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

  if (fix %in% c('theta', 'both')) theta_est <- theta_tru
  if (fix %in% c('diff', 'both')) diff_est <- diff_tru

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
