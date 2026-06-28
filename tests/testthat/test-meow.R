test_that("meow() output is correctly formed", {
  result <- meow(
    select_fun = select_sequential,
    update_fun = update_theta_mle,
    data_loader = data_simple_1pl,
    data_args = list(N_persons = 10, N_items = 20),
    fix = "item"
  )

  expect_named(result, c("results", "adj_mats", "pers_tru", "item_tru"))
  expect_true(is.data.frame(result$results))
  expect_true("iter" %in% names(result$results))
  expect_type(result$adj_mats, "list")
  expect_true(all(vapply(result$adj_mats, is.matrix, logical(1))))
  expect_true(is.data.frame(result$pers_tru))
  expect_true(is.data.frame(result$item_tru))
  expect_gt(nrow(result$results), 0)
  expect_gt(ncol(result$results), 1)
})

test_that("meow() result columns follow the documented naming scheme", {
  result <- meow(
    select_sequential, update_theta_mle, data_simple_1pl,
    data_args = list(N_persons = 4, N_items = 8), fix = "item"
  )
  nms <- names(result$results)
  expect_true("pers_theta_1_est" %in% nms)
  expect_true("pers_theta_1_bias" %in% nms)
  expect_true("item_b_1_est" %in% nms)
  expect_true("item_a_1_bias" %in% nms)
  # one est + one bias column per person/item parameter, plus iter
  n_expected <- 1 + 2 * (4 * 1 + 8 * 2)
  expect_equal(ncol(result$results), n_expected)
})

test_that("meow() runs every bundled selector/updater combination", {
  selectors <- list(select_sequential, select_max_info, select_max_dist)
  updaters <- list(update_theta_mle, update_maths_garden, update_prowise_learn)
  for (sel in selectors) {
    for (upd in updaters) {
      res <- meow(sel, upd, data_simple_1pl,
                  data_args = list(N_persons = 6, N_items = 10),
                  fix = if (identical(upd, update_theta_mle)) "item" else "none")
      expect_true(is.data.frame(res$results))
      expect_false(anyNA(res$results))
    }
  }
})

test_that("meow() administers each item at most once per respondent", {
  res <- meow(select_max_info, update_theta_mle, data_simple_1pl,
              data_args = list(N_persons = 8, N_items = 12), fix = "item")
  # final adjacency diagonal cannot exceed the number of respondents
  final_adj <- res$adj_mats[[length(res$adj_mats)]]
  expect_true(all(diag(final_adj) <= 8))
})

test_that("keep_adj_mats = FALSE retains only the final adjacency matrix", {
  res <- meow(select_sequential, update_theta_mle, data_simple_1pl,
              data_args = list(N_persons = 6, N_items = 8), fix = "item",
              keep_adj_mats = FALSE)
  expect_length(res$adj_mats, 1)
})

test_that("meow() handles a single-item pool", {
  res <- meow(select_sequential, update_theta_mle, data_simple_1pl,
              data_args = list(N_persons = 5, N_items = 1), fix = "item")
  expect_equal(nrow(res$results), 1)
})

test_that("meow() validates the fix argument", {
  expect_error(
    meow(select_sequential, update_theta_mle, data_simple_1pl,
         data_args = list(N_persons = 4, N_items = 6), fix = "nonsense")
  )
})
