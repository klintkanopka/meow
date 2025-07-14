#' Conducts a full CAT simulation.
#'
#' `meow()` is the core function of this simulation framework and exists to help users compare efficiency tradeoffs across different item selection algorithms, parameter update algorithms, and data generating processes. It takes as arguments an item selection function, a parameter update function, and a data loader function and uses these to carry out a simulation of a full CAT administration. Default behavior is proceed until all items have been administered. Since internal simulation logic checks to see if additional items are being administered, early stopping conditions should be implemented within the item selection functions. Internal parameters are passed around as dataframes for maximum flexibility.
#'
#' @param select_fun A function that specifies the item selection algorithm.
#' @param update_fun A function that specifies the parameter update algorithm.
#' @param data_loader A function that specifies the data generating process.
#' @param select_args A named list of arguments to be passed to `select_fun`.
#' @param update_args A named list of arguments to be passed to `update_fun`.
#' @param data_args A named list of arguments to be passed to `data_loader`.
#' @param init A list of initialization values for estimated person and item parameters. Currently accepts a named list with two entities: `pers` and `item`, for initial estimated values of ability and difficulty, respectively. Defaults to `NULL`, which initializes all estimated parameters to zero.
#' @param fix Which estimated parameters to treat as fixed. Currently defaults to `none`, but accepts `pers`, `item`, or `both`.`
#' @returns A list of four named entities, `results` is a dataframe with one row per iteration of the simulation. It contains one `iter` for the iteration number and two columns per person and item parameter, one for the associated estimated parameter and one for the bias in that estimate. Next is a list of item-item adjacency matrices, contained in `adj_mats`. One matrix is provided per iteration of the simulation, and edge weights are the number of respondents who have responded to each pair of items. Finally, true ability and difficulty dataframes are returned in `pers_tru` and `item_tru`.
#'
#' @export
meow <- function(
  select_fun,
  update_fun,
  data_loader,
  select_args = list(),
  update_args = list(),
  data_args = list(),
  init = NULL,
  fix = 'none'
) {
  data <- do.call(data_loader, data_args)
  pers_tru <- data$pers_tru
  item_tru <- data$item_tru
  resp <- data$resp

  if (is.null(init)) {
    pers_est <- pers_tru
    for (i in 2:ncol(pers_tru)) {
      pers_est[[i]] <- 0
    }
    item_est <- item_tru
    for (i in 2:ncol(item_tru)) {
      item_est[[i]] <- 0
    }
  } else {
    pers_est <- init$pers
    item_est <- init$item
  }

  adj_mats <- list()
  adj_mat <- matrix(data = 0, nrow = nrow(item_tru), ncol = nrow(item_tru))

  if (fix %in% c('pers', 'both')) {
    pers_est <- pers_tru
  }
  if (fix %in% c('item', 'both')) {
    item_est <- item_tru
  }

  resp_cur <- NULL
  resp_prev <- resp

  iter <- 1

  results <- matrix(
    0,
    nrow = 2 * nrow(item_tru), # this depends on no repeat items
    ncol = 1 +
      2 *
        (nrow(pers_est) *
          (ncol(pers_est) - 1) +
          nrow(item_est) * (ncol(item_est) - 1))
  )

  while (!identical(resp_cur, resp_prev)) {
    resp_prev <- resp_cur

    if (length(select_args) > 0) {
      temp_resp <- do.call(
        select_fun,
        c(
          pers = pers_est,
          item = item_est,
          resp = resp,
          resp_cur = resp_cur,
          adj_mat = adj_mat,
          select_args
        )
      )
    } else {
      temp_resp <- do.call(
        select_fun,
        list(
          pers = pers_est,
          item = item_est,
          resp = resp,
          resp_cur = resp_cur,
          adj_mat = adj_mat
        )
      )
    }

    if (length(update_args) > 0) {
      out <- do.call(
        update_fun,
        c(
          pers = pers_est,
          item = item_est,
          resp = temp_resp,
          update_args
        )
      )
    } else {
      out <- do.call(
        update_fun,
        list(
          pers = pers_est,
          item = item_est,
          resp = temp_resp
        )
      )
    }

    pers_est <- out$pers_est
    item_est <- out$item_est
    resp_cur <- out$resp_cur

    adj_mat <- construct_adj_mat(resp_cur, pers_tru, item_tru)
    adj_mats[[iter]] <- adj_mat

    p_est <- as.vector(as.matrix(dplyr::select(pers_est, -.data$id)))
    p_tru <- as.vector(as.matrix(dplyr::select(pers_tru, -.data$id)))
    i_est <- as.vector(as.matrix(dplyr::select(item_est, -.data$item)))
    i_tru <- as.vector(as.matrix(dplyr::select(item_tru, -.data$item)))

    # rethink this result forming...
    p_bias <- p_tru - p_est
    i_bias <- i_tru - i_est

    results[iter, ] <- c(
      iter,
      p_est,
      p_bias,
      i_est,
      i_bias
    )

    iter <- iter + 1
  }

  results <- results[rowSums(results) != 0, ]
  results <- data.frame(results)
  p_names <- tidyr::expand_grid(par = names(pers_est)[-1], id = pers_est$id)
  i_names <- tidyr::expand_grid(par = names(item_est)[-1], item = item_est$item)

  names(results) <- c(
    'iter',
    paste('pers', p_names$par, p_names$id, 'est', sep = '_'),
    paste('pers', p_names$par, p_names$id, 'bias', sep = '_'),
    paste('item', i_names$par, i_names$item, 'est', sep = '_'),
    paste('item', i_names$par, i_names$item, 'bias', sep = '_')
  )

  out <- list(
    results = results,
    adj_mats = adj_mats,
    pers_tru = pers_tru,
    item_tru = item_tru
  )

  return(out)
}
