# Load test data
out <- data_simple_1pl()

test_that("select_sequential() output is correctly formed", {
  result <- select_sequential(
    pers = out$pers_tru,
    item = out$item_tru,
    resp = out$resp
  )
  
  expect_type(result, 'list')
  expect_true(is.data.frame(result))
  expect_true(all(c('id', 'item', 'resp') %in% names(result)))
})

test_that("select_random() output is correctly formed", {
  result <- select_random(
    pers = out$pers_tru,
    item = out$item_tru,
    resp = out$resp
  )
  
  expect_type(result, 'list')
  expect_true(is.data.frame(result))
  expect_true(all(c('id', 'item', 'resp') %in% names(result)))
})

test_that("select_max_info() output is correctly formed", {
  result <- select_max_info(
    pers = out$pers_tru,
    item = out$item_tru,
    resp = out$resp
  )
  
  expect_type(result, 'list')
  expect_true(is.data.frame(result))
  expect_true(all(c('id', 'item', 'resp') %in% names(result)))
})

test_that("select_max_dist() output is correctly formed", {
  # Create a simple adjacency matrix for testing
  adj_mat <- matrix(1, nrow = nrow(out$item_tru), ncol = nrow(out$item_tru))
  diag(adj_mat) <- 0
  
  result <- select_max_dist(
    pers = out$pers_tru,
    item = out$item_tru,
    resp = out$resp,
    adj_mat = adj_mat
  )
  
  expect_type(result, 'list')
  expect_true(is.data.frame(result))
  expect_true(all(c('id', 'item', 'resp') %in% names(result)))
})

test_that("select_max_dist_enhanced() output is correctly formed", {
  # Create a simple adjacency matrix for testing
  adj_mat <- matrix(1, nrow = nrow(out$item_tru), ncol = nrow(out$item_tru))
  diag(adj_mat) <- 0
  
  result <- select_max_dist_enhanced(
    pers = out$pers_tru,
    item = out$item_tru,
    resp = out$resp,
    adj_mat = adj_mat
  )
  
  expect_type(result, 'list')
  expect_true(is.data.frame(result))
  expect_true(all(c('id', 'item', 'resp') %in% names(result)))
})

test_that("edge weight functions return matrices", {
  adj_mat <- matrix(1:4, nrow = 2, ncol = 2)
  
  expect_true(is.matrix(edge_weight_inverse(adj_mat)))
  expect_true(is.matrix(edge_weight_negative_log(adj_mat)))
  expect_true(is.matrix(edge_weight_linear(adj_mat)))
  expect_true(is.matrix(edge_weight_power(adj_mat)))
  expect_true(is.matrix(edge_weight_exponential(adj_mat)))
})
