out <- data_simple_1pl()

test_that("data_simple_1pl() output is correctly formed", {
  expect_type(out, 'list')
  expect_type(out$resp, 'list')
  expect_type(out$pers_tru, 'list')
  expect_type(out$item_tru, 'list')
})
