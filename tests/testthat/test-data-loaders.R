out <- data_default()

test_that("output is correctly formed", {
  expect_type(out, 'list')
  expect_type(out$resp, 'list')
  expect_type(out$theta_tru, 'double')
  expect_type(out$diff_tru, 'double')
})
