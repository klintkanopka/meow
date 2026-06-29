out <- data_simple_1pl(N_persons = 8, N_items = 12, data_seed = 99)
N <- nrow(out$pers_tru)
M <- nrow(out$item_tru)
R <- matrix(NA_real_, N, M)
R[cbind(out$resp$id, out$resp$item)] <- out$resp$resp

# A mid-simulation administration matrix: first 5 items given to everyone.
admin_started <- matrix(0L, N, M)
admin_started[, 1:5] <- 1L
adj_started <- construct_adj_mat(admin_started)

empty <- matrix(0L, N, M)

test_that("selectors seed the first five items when nothing is administered", {
  expect_equal(select_sequential(out$pers_tru, out$item_tru, R, empty), {
    e <- empty; e[, 1:5] <- 1L; e
  })
  expect_equal(select_max_info(out$pers_tru, out$item_tru, R, empty), {
    e <- empty; e[, 1:5] <- 1L; e
  })
})

test_that("selectors return an administration matrix that adds exactly one item per person", {
  for (nm in c("select_sequential", "select_max_info", "select_max_dist",
               "select_max_dist_enhanced", "select_restrict_rate")) {
    fun <- get(nm)
    res <- fun(out$pers_tru, out$item_tru, R, admin_started, adj_started)
    expect_true(is.matrix(res), info = nm)
    expect_equal(dim(res), c(N, M), info = nm)
    # one new item administered to each respondent
    expect_equal(rowSums(res != 0), rep(6, N), info = nm)
    # never un-administers a previously administered item
    expect_true(all(res[admin_started != 0] != 0), info = nm)
  }
})

test_that("select_sequential administers items in increasing id order", {
  res <- select_sequential(out$pers_tru, out$item_tru, R, admin_started, adj_started)
  # next item for everyone should be item 6
  expect_true(all(res[, 6] != 0))
  expect_true(all(res[, 7] == 0))
})

test_that("select_max_info picks the most informative remaining item", {
  res <- select_max_info(out$pers_tru, out$item_tru, R, admin_started, adj_started)
  new_item <- apply(res != 0 & admin_started == 0, 1, which)
  a <- out$item_tru$a
  b <- out$item_tru$b
  theta <- out$pers_tru$theta
  for (i in seq_len(N)) {
    cand <- which(admin_started[i, ] == 0)
    p <- stats::plogis(a[cand] * (theta[i] - b[cand]))
    info <- a[cand]^2 * p * (1 - p)
    expect_equal(new_item[i], cand[which.max(info)])
  }
})

test_that("select_restrict_rate withholds over-exposed items and can skip a respondent", {
  # 4 respondents, 3 items. Respondent 1 has items 1-2 and needs item 3;
  # respondents 2-4 have items 1 and 3 and need item 2.
  admin <- rbind(
    c(1L, 1L, 0L),
    c(1L, 0L, 1L),
    c(1L, 0L, 1L),
    c(1L, 0L, 1L)
  )
  adj <- construct_adj_mat(admin)            # exposures: item1=4, item2=1, item3=3
  pers <- data.frame(id = 1:4, theta = rep(0, 4))
  item <- data.frame(item = 1:3, b = c(0, 0, 0), a = c(1, 1, 1))
  Rm <- matrix(1, 4, 3)

  # With r_max = 0.3, only item 2 (rate 1/8) is permitted; items 1 and 3 exceed it.
  res <- select_restrict_rate(pers, item, Rm, admin, adj, r_max = 0.3)

  # respondent 1's only unadministered item (3) is over-exposed -> skipped
  expect_equal(res[1, ], admin[1, ])
  # respondents 2-4 receive the only permitted item (2)
  expect_true(all(res[2:4, 2] != 0))
  # no over-exposed item is ever newly administered
  newly <- res != 0 & admin == 0
  expect_false(any(newly[, c(1, 3)]))
})

test_that("select_random is reproducible with a fixed seed", {
  r1 <- select_random(out$pers_tru, out$item_tru, R, admin_started, adj_started, select_seed = 5)
  r2 <- select_random(out$pers_tru, out$item_tru, R, admin_started, adj_started, select_seed = 5)
  expect_identical(r1, r2)
  expect_equal(rowSums(r1 != 0), rep(6, N))
})

test_that("edge weight functions return matrices", {
  adj_mat <- matrix(1:4, nrow = 2, ncol = 2)
  expect_true(is.matrix(edge_weight_inverse(adj_mat)))
  expect_true(is.matrix(edge_weight_negative_log(adj_mat)))
  expect_true(is.matrix(edge_weight_linear(adj_mat)))
  expect_true(is.matrix(edge_weight_power(adj_mat)))
  expect_true(is.matrix(edge_weight_exponential(adj_mat)))
})
