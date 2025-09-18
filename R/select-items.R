#' Item selection function that delivers the next item by item id number, simulating a fixed test form.
#'
#' This function just administers the next item in a form, with the within-person item ordering being governed by the ordering the rows in the `resp` dataframe.
#'
#' @param pers A dataframe of current respondent ability estimates.
#' @param item A dataframe of current item parameter estimates.
#' @param resp A long-form dataframe of all potential pre-simulated item responses.
#' @param resp_cur A long-form dataframe of administered item responses.
#' @param adj_mat An item-item adjacency matrix, where each entry is the count of individuals who have respondent to both item i and item j. See documentation for `construct_adj_mat`
#' @returns A long-form dataframe of all previously administered item responses with the new responses from this iteration appended to the end.
#'
#' @export
#' @importFrom rlang .data
select_sequential <- function(
  pers,
  item,
  resp,
  resp_cur = NULL,
  adj_mat = NULL
) {
  if (is.null(resp_cur)) {
    return(resp[resp$item <= 5, ])
  } else {
    resp_new <- dplyr::anti_join(
      resp,
      resp_cur,
      by = c('id', 'item', 'resp')
    ) |>
      dplyr::slice_head(n = 1, by = .data$id)
    resp_new <- dplyr::bind_rows(resp_cur, resp_new)
  }
  return(resp_new)
}


#' Item selection function that delivers an item an item drawn at random from the item bank to each respondent.
#'
#' Each respondent has their own next item drawn at random from the remaining items.
#'
#' @param pers A dataframe of current respondent ability estimates.
#' @param item A dataframe of current item parameter estimates.
#' @param resp A long-form dataframe of all potential pre-simulated item responses.
#' @param resp_cur A long-form dataframe of administered item responses.
#' @param adj_mat An item-item adjacency matrix, where each entry is the count of individuals who have respondent to both item i and item j. See documentation for `construct_adj_mat`
#' @param select_seed A random seed used only for item selection. Cleared each time this function is run.
#' @returns A long-form dataframe of all previously administered item responses with the new responses from this iteration appended to the end.
#'
#' @export
#' @importFrom rlang .data
select_random <- function(
  pers,
  item,
  resp,
  resp_cur = NULL,
  adj_mat = NULL,
  select_seed = NULL
) {
  # note default behavior is cleared seed, to ensure variation between runs

  set.seed(select_seed)
  if (is.null(resp_cur)) {
    return(resp[resp$item <= 5, ])
  } else {
    resp_new <- dplyr::anti_join(
      resp,
      resp_cur,
      by = c('id', 'item', 'resp')
    ) |>
      dplyr::slice_sample(n = 1, by = .data$id)
    resp_new <- dplyr::bind_rows(resp_cur, resp_new)
  }
  set.seed(NULL)
  return(resp_new)
}


#' Item selection function that delivers the the remaining item with the highest information.
#'
#' Information calculation is based upon current parameter estimates and a 2PL item response function.
#'
#' @param pers A dataframe of current respondent ability estimates.
#' @param item A dataframe of current item parameter estimates.
#' @param resp A long-form dataframe of all potential pre-simulated item responses.
#' @param resp_cur A long-form dataframe of administered item responses.
#' @param adj_mat An item-item adjacency matrix, where each entry is the count of individuals who have respondent to both item i and item j. See documentation for `construct_adj_mat`
#' @returns A long-form dataframe of all previously administered item responses with the new responses from this iteration appended to the end.
#'
#' @export
#' @importFrom rlang .data
select_max_info <- function(
  pers,
  item,
  resp,
  resp_cur = NULL,
  adj_mat = NULL
) {
  if (is.null(resp_cur)) {
    return(resp[resp$item <= 5, ])
  } else {
    resp_new <- dplyr::anti_join(
      resp,
      resp_cur,
      by = c('id', 'item', 'resp')
    ) |>
      dplyr::left_join(pers, by = 'id') |>
      dplyr::left_join(item, by = 'item') |>
      dplyr::mutate(
        info = .data$a^2 *
          stats::plogis(.data$a * (.data$theta - .data$b)) *
          (1 - stats::plogis(.data$a * (.data$theta - .data$b)))
      ) |>
      dplyr::slice_max(.data$info, n = 1, by = .data$id) |>
      dplyr::select(.data$id, .data$item, .data$resp)
    resp_new <- dplyr::bind_rows(resp_cur, resp_new)
  }
  return(resp_new)
}


#' Item selection function based on network distance criterion.
#'
#' This item selection function delivers the item farthest in the network from the items a respondent has already answered, with edges weighted by the inverse of their entry in the item-item adjacency matrix. Ties are broken using the maximum information criterion.
#'
#' @param pers A dataframe of current respondent ability estimates.
#' @param item A dataframe of current item parameter estimates.
#' @param resp A long-form dataframe of all potential pre-simulated item responses.
#' @param resp_cur A long-form dataframe of administered item responses.
#' @param adj_mat An item-item adjacency matrix, where each entry is the count of individuals who have respondent to both item i and item j. See documentation for `construct_adj_mat`
#' @param n_candidates A parameter that allows the assembly of a pool of $N$ farthest items, before selecting the next item according to maximum information. Allows users to balance exposure patterns away from increased network density and toward more efficient estimation.
#' @returns A long-form dataframe of all previously administered item responses with the new responses from this iteration appended to the end.
#'
#' @export
#' @importFrom rlang .data
select_max_dist <- function(
  pers,
  item,
  resp,
  resp_cur = NULL,
  adj_mat = NULL,
  n_candidates = 1
) {
  if (is.null(resp_cur)) {
    return(resp[resp$item <= 5, ])
  } else {
    # here is where you can adjust edge weights in the distance calculation
    dist_mat <- Rfast::floyd(1 / adj_mat)

    local_items <- resp_cur |>
      dplyr::select(.data$id, .data$item) |>
      dplyr::group_by(.data$id) |>
      dplyr::mutate(seq = 1:dplyr::n()) |>
      dplyr::ungroup() |>
      tidyr::pivot_wider(
        id_cols = .data$id,
        names_from = .data$seq,
        names_prefix = 'item_',
        values_from = .data$item
      ) |>
      dplyr::arrange(.data$id) |>
      dplyr::select(-.data$id) |>
      as.matrix()

    get_distance <- function(id, item, dist_mat, local_items) {
      dist <- min(dist_mat[local_items[id, ], item])
      return(dist)
    }

    resp_new <- dplyr::anti_join(
      resp,
      resp_cur,
      by = c('id', 'item', 'resp')
    )

    if (nrow(resp_new) > 0) {
      resp_new <- resp_new |>
        dplyr::rowwise() |>
        dplyr::mutate(
          distance = get_distance(.data$id, .data$item, dist_mat, local_items)
        ) |>
        dplyr::ungroup() |>
        dplyr::slice_max(.data$distance, n = n_candidates, by = .data$id) |>
        dplyr::left_join(pers, by = 'id') |>
        dplyr::left_join(item, by = 'item') |>
        dplyr::mutate(
          info = .data$a^2 *
            stats::plogis(.data$a * (.data$theta - .data$b)) *
            (1 - stats::plogis(.data$a * (.data$theta - .data$b)))
        ) |>
        dplyr::slice_max(.data$info, n = 1, by = .data$id) |>
        dplyr::select(.data$id, .data$item, .data$resp)
    }
    resp_new <- dplyr::bind_rows(resp_cur, resp_new)
  }
  return(resp_new)
}


#' Enhanced network-based item selection with configurable edge weights
#'
#' This function extends `select_max_dist` with flexible edge weight calculations.
#'
#' @param pers A dataframe of current respondent ability estimates.
#' @param item A dataframe of current item parameter estimates.
#' @param resp A long-form dataframe of all potential pre-simulated item responses.
#' @param resp_cur A long-form dataframe of administered item responses.
#' @param adj_mat An item-item adjacency matrix.
#' @param n_candidates Number of farthest items to consider before applying information criterion.
#' @param edge_weight_fun Function to calculate edge weights from adjacency matrix.
#' @param edge_weight_args Additional arguments for the edge weight function.
#' @returns A long-form dataframe of all previously administered item responses with the new responses from this iteration appended to the end.
#'
#' @export
#' @importFrom rlang .data
select_max_dist_enhanced <- function(
  pers,
  item,
  resp,
  resp_cur = NULL,
  adj_mat = NULL,
  n_candidates = 1,
  edge_weight_fun = edge_weight_inverse,
  edge_weight_args = list()
) {
  if (is.null(resp_cur)) {
    return(resp[resp$item <= 5, ])
  } else {
    # Calculate edge weights using the specified function
    edge_weights <- do.call(
      edge_weight_fun,
      c(list(adj_mat = adj_mat), edge_weight_args)
    )

    # Compute distance matrix using Floyd-Warshall
    dist_mat <- Rfast::floyd(edge_weights)

    local_items <- resp_cur |>
      dplyr::select(.data$id, .data$item) |>
      dplyr::group_by(.data$id) |>
      dplyr::mutate(seq = 1:dplyr::n()) |>
      dplyr::ungroup() |>
      tidyr::pivot_wider(
        id_cols = .data$id,
        names_from = .data$seq,
        names_prefix = 'item_',
        values_from = .data$item
      ) |>
      dplyr::arrange(.data$id) |>
      dplyr::select(-.data$id) |>
      as.matrix()

    get_distance <- function(id, item, dist_mat, local_items) {
      dist <- min(dist_mat[local_items[id, ], item])
      return(dist)
    }

    resp_new <- dplyr::anti_join(
      resp,
      resp_cur,
      by = c('id', 'item', 'resp')
    )

    if (nrow(resp_new) > 0) {
      resp_new <- resp_new |>
        dplyr::rowwise() |>
        dplyr::mutate(
          distance = get_distance(.data$id, .data$item, dist_mat, local_items)
        ) |>
        dplyr::ungroup() |>
        dplyr::slice_max(.data$distance, n = n_candidates, by = .data$id) |>
        dplyr::left_join(pers, by = 'id') |>
        dplyr::left_join(item, by = 'item') |>
        dplyr::mutate(
          info = .data$a^2 *
            stats::plogis(.data$a * (.data$theta - .data$b)) *
            (1 - stats::plogis(.data$a * (.data$theta - .data$b)))
        ) |>
        dplyr::slice_max(.data$info, n = 1, by = .data$id) |>
        dplyr::select(.data$id, .data$item, .data$resp)
    }
    resp_new <- dplyr::bind_rows(resp_cur, resp_new)
  }
  return(resp_new)
}
