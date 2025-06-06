select_sequential <- function(
  theta,
  diff,
  resp,
  resp_cur = NULL,
  adj_mat = NULL,
  select_seed = NULL
) {
  # note default behavior is cleared seed, to ensure variation between runs
  set.seed(select_seed)
  if (is.null(resp_cur)) return(resp[resp$item <= 5, ]) else {
    resp_new <- dplyr::anti_join(
      resp,
      resp_cur,
      by = c('id', 'item', 'resp')
    ) |>
      dplyr::slice_sample(n = 1, by = id)
    resp_new <- dplyr::bind_rows(resp_cur, resp_new)
  }
  set.seed(NULL)
  return(resp_new)
}

select_random <- function(
  theta,
  diff,
  resp,
  resp_cur = NULL,
  adj_mat = NULL,
  select_seed = NULL
) {
  # note default behavior is cleared seed, to ensure variation between runs
  set.seed(select_seed)
  if (is.null(resp_cur)) return(resp[resp$item <= 5, ]) else {
    resp_new <- dplyr::anti_join(
      resp,
      resp_cur,
      by = c('id', 'item', 'resp')
    ) |>
      dplyr::slice_sample(n = 1, by = id)
    resp_new <- dplyr::bind_rows(resp_cur, resp_new)
  }
  set.seed(NULL)
  return(resp_new)
}

select_max_info <- function(
  theta,
  diff,
  resp,
  resp_cur = NULL,
  adj_mat = NULL
) {
  require(dplyr)
  if (is.null(resp_cur)) return(resp[resp$item <= 5, ]) else {
    th <- data.frame(id = 1:length(theta), theta = theta)
    b <- data.frame(item = 1:length(diff), diff = diff)
    resp_new <- anti_join(resp, resp_cur, by = c('id', 'item', 'resp')) |>
      dplyr::left_join(th, by = 'id') |>
      dplyr::left_join(b, by = 'item') |>
      dplyr::mutate(info = abs(theta - diff)) |>
      dplyr::slice_min(info, n = 1, by = id) |>
      dplyr::select(-theta, -diff, -info)
    resp_new <- dplyr::bind_rows(resp_cur, resp_new)
  }
  return(resp_new)
}
