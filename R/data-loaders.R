data_existing <- function(
  resp_path = 'data/sample-resp.csv',
  theta_path = 'data/true-sample-theta.rds',
  diff_path = 'data/true-sample-diff.rds'
) {
  # the responses should be a long form .csv
  # true thetas and difficulties should be .rds vectors
  out <- list(
    resp = read.csv(resp_path),
    theta_tru = readRDS(theta_path),
    diff_tru = readRDS(diff_path)
  )
  return(out)
}

data_default <- function(N_persons = 100, N_items = 50, data_seed = 242424) {
  # note default behavior is fixed seed to ensure data consistency across runs
  set.seed(data_seed)

  theta_tru <- rnorm(N_persons)
  diff_tru <- rnorm(N_items)

  theta_mat <- matrix(
    theta_tru,
    nrow = N_persons,
    ncol = N_items,
    byrow = FALSE
  )
  diff_mat <- matrix(diff_tru, nrow = N_persons, ncol = N_items, byrow = TRUE)

  p <- plogis(theta_mat - diff_mat)
  resp <- matrix(rbinom(length(p), 1, p), nrow = N_persons, ncol = N_items) |>
    as.data.frame() |>
    dplyr::mutate(id = 1:N_persons) |>
    tidyr::pivot_longer(
      starts_with('V'),
      names_to = 'item',
      values_to = 'resp',
      names_prefix = 'V'
    ) |>
    dplyr::select(id, item, resp) |>
    dplyr::mutate(across(everything(), as.numeric))

  out <- list(resp = resp, theta_tru = theta_tru, diff_tru = diff_tru)
  set.seed(NULL)
  return(out)
}
