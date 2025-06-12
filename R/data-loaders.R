#' Load data from existing files
#'
#' @param resp_path A file path to a long form .csv file. File should have three columns, `id` which contains a numeric respondent identifier, `item` which contains a numeric item identifier, and resp which contains an item response. Be sure the form of the item response comports with the parameter update functions you choose to use.
#' @param theta_path A file path to a .rds file that contains a vector of true theta vales.
#' @param diff_path A file path to a .rds file that contains a vector of true item difficulty vales.
#' @returns A list with three components: A dataframe of item response named `resp`, a vector of true respondent abilities named `theta_tru`, and a vector of true item difficulties named `diff_tru`
data_existing <- function(
  resp_path = 'data/sample-resp.csv',
  theta_path = 'data/true-sample-theta.rds',
  diff_path = 'data/true-sample-diff.rds'
) {
  out <- list(
    resp = read.csv(resp_path),
    theta_tru = readRDS(theta_path),
    diff_tru = readRDS(diff_path)
  )
  return(out)
}

#' A default data generation function that simulates normally distributed respondent abilities and item difficulties
#'
#' @param N_persons Number of respondents to simulate
#' @param N_items Number of items to simulate
#' @param data_seed A random seed for generating reproducible data. This seed is re-initialized at the end of the data generation process
#' @returns A list with three components: A dataframe of item response named `resp`, a vector of true respondent abilities named `theta_tru`, and a vector of true item difficulties named `diff_tru`
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
