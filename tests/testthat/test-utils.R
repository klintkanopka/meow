test_that("construct_adj_mat() counts exposures and co-exposures", {
  # person 1 gets items 1 and 2; person 2 gets item 2 only
  admin <- matrix(0L, nrow = 2, ncol = 3)
  admin[1, c(1, 2)] <- 1L
  admin[2, 2] <- 1L

  result <- construct_adj_mat(admin)

  expect_true(is.matrix(result))
  expect_true(isSymmetric(result))
  expect_equal(dim(result), c(3, 3))
  expect_equal(diag(result), c(item_1 = 1, item_2 = 2, item_3 = 0))
  # only person 1 took both item 1 and item 2
  expect_equal(result[1, 2], 1)
  expect_true(all(result >= 0))
})

test_that("construct_adj_mat() accepts logical and integer admin matrices", {
  admin_int <- matrix(c(1L, 2L, 0L, 1L), nrow = 2)
  admin_log <- admin_int != 0
  expect_equal(
    unname(construct_adj_mat(admin_int)),
    unname(construct_adj_mat(admin_log))
  )
})

test_that("meow_administered() returns a logical mask", {
  admin <- matrix(c(0L, 3L, 1L, 0L), nrow = 2)
  m <- meow_administered(admin)
  expect_type(m, "logical")
  expect_equal(m, matrix(c(FALSE, TRUE, TRUE, FALSE), nrow = 2))
})

test_that("meow_long() returns administered responses in administration order", {
  R <- matrix(c(1, 0, 1, 1), nrow = 2)
  admin <- matrix(c(1L, 0L, 2L, 1L), nrow = 2)
  long <- meow_long(R, admin)

  expect_named(long, c("id", "item", "resp"))
  expect_equal(nrow(long), 3)
  # person 1 answered item 1 (stamp 1) then item 2 (stamp 2)
  expect_equal(long$id, c(1, 1, 2))
  expect_equal(long$item, c(1, 2, 2))
  expect_equal(long$resp, c(R[1, 1], R[1, 2], R[2, 2]))
})

test_that("meow_long() handles an empty administration matrix", {
  R <- matrix(0, nrow = 2, ncol = 2)
  admin <- matrix(0L, nrow = 2, ncol = 2)
  long <- meow_long(R, admin)
  expect_equal(nrow(long), 0)
  expect_named(long, c("id", "item", "resp"))
})

test_that("edge weight functions return matrices", {
  adj_mat <- matrix(1:4, nrow = 2, ncol = 2)

  expect_true(is.matrix(edge_weight_inverse(adj_mat)))
  expect_true(is.matrix(edge_weight_negative_log(adj_mat)))
  expect_true(is.matrix(edge_weight_linear(adj_mat)))
  expect_true(is.matrix(edge_weight_power(adj_mat)))
  expect_true(is.matrix(edge_weight_exponential(adj_mat)))
})
