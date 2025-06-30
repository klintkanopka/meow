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
