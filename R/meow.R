#' Conduct a full CAT simulation.
#'
#' `meow()` is the core function of this simulation framework. It exists to help
#' users compare efficiency tradeoffs across different item selection algorithms,
#' parameter update algorithms, and data generating processes. It takes as
#' arguments an item selection function, a parameter update function, and a data
#' loader function and uses these to carry out a simulation of a full CAT
#' administration. Default behavior is to proceed until no further items are
#' administered. Because the internal simulation logic stops as soon as an
#' iteration administers no new items, early stopping conditions should be
#' implemented within the item selection function (by declining to administer
#' further items).
#'
#' @details
#' ## Simulation state
#'
#' For speed, `meow()` represents responses with matrices rather than long data
#' frames. Two matrices, each with one row per respondent and one column per
#' item, are passed to the user-supplied modules:
#'
#' * `R` --- the (potential) response of every respondent to every item. This is
#'   produced once from the long `resp` data frame returned by the data loader.
#' * `admin` --- an integer administration matrix. An entry of `0` means the item
#'   has not been administered to that respondent; a positive entry means it has,
#'   and the value encodes the order of administration. Use `admin != 0` (or
#'   [meow_administered()]) as an administered mask.
#'
#' Person and item *parameters* are kept as data frames (`pers` and `item`), each
#' with an identifier column (`id` and `item`, respectively) followed by one
#' column per parameter, so that users retain the flexibility to add arbitrary
#' parameters.
#'
#' ## Module contracts
#'
#' An **item selection** function receives `pers`, `item`, `R`, `admin`, and
#' `adj_mat` (plus any `select_args`) and returns an administration matrix with
#' newly selected cells marked non-zero. The harness stamps the order of
#' administration, so a function need only set newly selected cells to a positive
#' value (or `TRUE`) while leaving previously administered cells unchanged.
#'
#' A **parameter update** function receives `pers`, `item`, `R`, and `admin`
#' (plus any `update_args`) and returns a list with updated `pers` and `item`
#' data frames.
#'
#' Module authors who prefer long data frames can convert with [meow_long()].
#'
#' @param select_fun A function that specifies the item selection algorithm.
#' @param update_fun A function that specifies the parameter update algorithm.
#' @param data_loader A function that specifies the data generating process.
#' @param select_args A named list of arguments to be passed to `select_fun`.
#' @param update_args A named list of arguments to be passed to `update_fun`.
#' @param data_args A named list of arguments to be passed to `data_loader`.
#' @param init A list of initialization values for estimated person and item
#'   parameters. Accepts a named list with two entries, `pers` and `item`, giving
#'   the initial estimated parameter data frames. Defaults to `NULL`, which
#'   initializes all estimated parameters to zero.
#' @param fix Which estimated parameters to treat as fixed at their true values.
#'   One of `none` (the default), `pers`, `item`, or `both`.
#' @param keep_adj_mats Logical; if `TRUE` (the default) an adjacency matrix is
#'   stored for every iteration. If `FALSE`, only the final adjacency matrix is
#'   retained, which saves memory for large item pools or long simulations.
#' @returns A list of four named entities. `results` is a data frame with one row
#'   per iteration of the simulation. It contains an `iter` column for the
#'   iteration number and two columns per person and item parameter, one for the
#'   estimated parameter and one for the bias in that estimate. `adj_mats` is a
#'   list of item-item adjacency matrices, one per iteration (or, when
#'   `keep_adj_mats = FALSE`, a single-element list with the final matrix); edge
#'   weights count the number of respondents administered each pair of items.
#'   `pers_tru` and `item_tru` are the true person and item parameter data
#'   frames.
#'
#' @examples
#' sim <- meow(
#'   select_fun = select_max_info,
#'   update_fun = update_theta_mle,
#'   data_loader = data_simple_1pl,
#'   data_args = list(N_persons = 20, N_items = 15),
#'   fix = "item"
#' )
#' head(sim$results)
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
  fix = 'none',
  keep_adj_mats = TRUE
) {
  fix <- match.arg(fix, c('none', 'pers', 'item', 'both'))

  data <- do.call(data_loader, data_args)
  pers_tru <- data$pers_tru
  item_tru <- data$item_tru
  resp <- data$resp

  N_persons <- nrow(pers_tru)
  N_items <- nrow(item_tru)

  # Build the respondent-by-item response matrix once, up front.
  R <- matrix(NA_real_, nrow = N_persons, ncol = N_items)
  R[cbind(resp$id, resp$item)] <- resp$resp

  # Initialize estimated parameters (kept as data frames for flexibility).
  if (is.null(init)) {
    pers_est <- pers_tru
    if (ncol(pers_tru) >= 2) {
      for (i in 2:ncol(pers_tru)) pers_est[[i]] <- 0
    }
    item_est <- item_tru
    if (ncol(item_tru) >= 2) {
      for (i in 2:ncol(item_tru)) item_est[[i]] <- 0
    }
  } else {
    pers_est <- init$pers
    item_est <- init$item
  }

  if (fix %in% c('pers', 'both')) pers_est <- pers_tru
  if (fix %in% c('item', 'both')) item_est <- item_tru

  admin <- matrix(0L, nrow = N_persons, ncol = N_items)
  adj_mat <- matrix(0, nrow = N_items, ncol = N_items)
  adj_mats <- list()

  # Pre-compute true-parameter vectors and result dimensions.
  p_tru <- as.vector(as.matrix(pers_tru[, -1, drop = FALSE]))
  i_tru <- as.vector(as.matrix(item_tru[, -1, drop = FALSE]))
  n_cols <- 1 + 2 * (length(p_tru) + length(i_tru))
  results <- matrix(0, nrow = N_items + 1L, ncol = n_cols)

  iter <- 1L
  repeat {
    admin_ret <- do.call(
      select_fun,
      c(
        list(
          pers = pers_est,
          item = item_est,
          R = R,
          admin = admin,
          adj_mat = adj_mat
        ),
        select_args
      )
    )

    # Newly administered cells are those that were 0 and are now non-zero.
    new_cells <- (admin_ret != 0) & (admin == 0)
    if (!any(new_cells)) break # no new items administered: simulation is done
    admin[new_cells] <- iter

    out <- do.call(
      update_fun,
      c(
        list(
          pers = pers_est,
          item = item_est,
          R = R,
          admin = admin
        ),
        update_args
      )
    )
    pers_est <- out$pers
    item_est <- out$item

    adj_mat <- construct_adj_mat(admin)
    if (keep_adj_mats) adj_mats[[iter]] <- adj_mat

    p_est <- as.vector(as.matrix(pers_est[, -1, drop = FALSE]))
    i_est <- as.vector(as.matrix(item_est[, -1, drop = FALSE]))

    if (iter > nrow(results)) {
      results <- rbind(results, matrix(0, nrow = N_items, ncol = n_cols))
    }
    results[iter, ] <- c(iter, p_est, p_tru - p_est, i_est, i_tru - i_est)

    iter <- iter + 1L
  }

  n_done <- iter - 1L
  results <- as.data.frame(results[seq_len(n_done), , drop = FALSE])

  p_names <- expand.grid(
    id = pers_est$id,
    par = names(pers_est)[-1],
    stringsAsFactors = FALSE
  )
  i_names <- expand.grid(
    item = item_est$item,
    par = names(item_est)[-1],
    stringsAsFactors = FALSE
  )

  names(results) <- c(
    'iter',
    paste('pers', p_names$par, p_names$id, 'est', sep = '_'),
    paste('pers', p_names$par, p_names$id, 'bias', sep = '_'),
    paste('item', i_names$par, i_names$item, 'est', sep = '_'),
    paste('item', i_names$par, i_names$item, 'bias', sep = '_')
  )

  if (!keep_adj_mats) adj_mats <- list(adj_mat)

  out <- list(
    results = results,
    adj_mats = adj_mats,
    pers_tru = pers_tru,
    item_tru = item_tru
  )

  return(out)
}
