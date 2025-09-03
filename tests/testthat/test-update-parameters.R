# Load test data
out <- data_simple_1pl()

test_that("update_theta_mle() output is correctly formed", {
  result <- update_theta_mle(
    pers = out$pers_tru,
    item = out$item_tru,
    resp = out$resp[out$resp$item <= 5, ]
  )
  
  expect_type(result, 'list')
  expect_length(result, 3)
  expect_true(all(c('pers', 'item', 'resp_cur') %in% names(result)))
  expect_true(is.data.frame(result$pers))
  expect_true(is.data.frame(result$item))
  expect_true(is.data.frame(result$resp_cur))
})

test_that("update_maths_garden() output is correctly formed", {
  result <- update_maths_garden(
    pers = out$pers_tru,
    item = out$item_tru,
    resp = out$resp[out$resp$item <= 5, ]
  )
  
  expect_type(result, 'list')
  expect_length(result, 3)
  expect_true(all(c('pers', 'item', 'resp_cur') %in% names(result)))
  expect_true(is.data.frame(result$pers))
  expect_true(is.data.frame(result$item))
  expect_true(is.data.frame(result$resp_cur))
})

test_that("update_prowise_learn() output is correctly formed", {
  result <- update_prowise_learn(
    pers = out$pers_tru,
    item = out$item_tru,
    resp = out$resp[out$resp$item <= 5, ]
  )
  
  expect_type(result, 'list')
  expect_length(result, 3)
  expect_true(all(c('pers', 'item', 'resp_cur') %in% names(result)))
  expect_true(is.data.frame(result$pers))
  expect_true(is.data.frame(result$item))
  expect_true(is.data.frame(result$resp_cur))
})
