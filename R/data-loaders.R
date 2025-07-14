#' Load data from existing files
#'
#' `data_existing()` is a wrapper for three separate calls to `read.csv()` that packages the output into the object used by `meow()`.
#'
#' @param resp_path A file path to a long form .csv file. File should have three columns, `id` which contains a numeric respondent identifier, `item` which contains a numeric item identifier, and resp which contains an item response. Be sure the form of the item response comports with the parameter update functions you choose to use.
#' @param pers_path A file path to a wide form .csv file that contains true person parameter values, with one person per row. Include a person index column, named `id`. Default column name for unidimensional person ability should be `theta`
#' @param item_path A file path to a wide form .csv file that contains true item parameter values, with one item per row. Include an item index column, named `item`. Default column names for difficulty should be `b` and default column name for discrimination should be `a`,
#' @returns A list with three components: A dataframe of item response named `resp`, a dataframe of true person parameters named `pers_tru`, and a dataframe of true item parameters named `item_tru`
#'
#' @export
data_existing <- function(resp_path, pers_path, item_path) {
  out <- list(
    resp = utils::read.csv(resp_path),
    pers_tru = utils::read.csv(pers_path),
    item_tru = utils::read.csv(item_path)
  )
  return(out)
}


#' A default data generation function that simulates normally distributed respondent abilities and item difficulties
#'
#' `data_simple_1pl()` constructs data according to a simple one parameter logistic IRT model. The user may specify a number of persons, a number of items, and a random seed for reproducibility. Person abilities and item difficulties are both drawn from a standard normal.
#'
#' @param N_persons Number of respondents to simulate
#' @param N_items Number of items to simulate
#' @param data_seed A random seed for generating reproducible data. This seed is re-initialized at the end of the data generation process
#' @returns A list with three components: A dataframe of item response named `resp`, a dataframe of true person parameters named `pers_tru`, and a dataframe of true item parameters named `item_tru`
#'
#' @export
#' @importFrom rlang .data
data_simple_1pl <- function(
  N_persons = 100,
  N_items = 50,
  data_seed = 242424
) {
  # note default behavior is fixed seed to ensure data consistency across runs
  set.seed(data_seed)

  pers_tru <- data.frame(id = 1:N_persons, theta = stats::rnorm(N_persons))
  item_tru <- data.frame(item = 1:N_items, b = stats::rnorm(N_items), a = 1)

  theta_mat <- matrix(
    pers_tru$theta,
    nrow = N_persons,
    ncol = N_items,
    byrow = FALSE
  )
  diff_mat <- matrix(item_tru$b, nrow = N_persons, ncol = N_items, byrow = TRUE)
  disc_mat <- matrix(item_tru$a, nrow = N_persons, ncol = N_items, byrow = TRUE)

  p <- stats::plogis(disc_mat * (theta_mat - diff_mat))
  resp <- matrix(
    stats::rbinom(length(p), 1, p),
    nrow = N_persons,
    ncol = N_items
  ) |>
    as.data.frame() |>
    dplyr::mutate(id = 1:N_persons) |>
    tidyr::pivot_longer(
      tidyselect::starts_with('V'),
      names_to = 'item',
      values_to = 'resp',
      names_prefix = 'V'
    ) |>
    dplyr::select(.data$id, .data$item, .data$resp) |>
    dplyr::mutate(dplyr::across(tidyselect::everything(), as.numeric))

  out <- list(resp = resp, pers_tru = pers_tru, item_tru = item_tru)
  set.seed(NULL)
  return(out)
}
