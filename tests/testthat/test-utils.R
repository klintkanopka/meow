# Load test data
out <- data_simple_1pl()

test_that("construct_adj_mat() output is correctly formed", {
  # Create a simple response dataset
  resp_cur <- out$resp[out$resp$item <= 5, ]
  
  result <- construct_adj_mat(
    resp_cur = resp_cur,
    pers_tru = out$pers_tru,
    item_tru = out$item_tru
  )
  
  expect_type(result, 'double')
  expect_true(is.matrix(result))
  expect_true(isSymmetric(result))
  expect_equal(nrow(result), ncol(result))
  expect_equal(nrow(result), nrow(out$item_tru))
  expect_true(all(diag(result) >= 0))
  expect_true(all(result >= 0))
})
