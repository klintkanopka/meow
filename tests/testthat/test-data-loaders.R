test_that("data_simple_1pl() output is correctly formed", {
  out <- data_simple_1pl(N_persons = 10, N_items = 8)

  expect_named(out, c("resp", "pers_tru", "item_tru"))
  expect_true(is.data.frame(out$resp))
  expect_named(out$resp, c("id", "item", "resp"))
  expect_equal(nrow(out$resp), 10 * 8)
  expect_true(all(out$resp$resp %in% c(0, 1)))

  expect_named(out$pers_tru, c("id", "theta"))
  expect_equal(nrow(out$pers_tru), 10)
  expect_named(out$item_tru, c("item", "b", "a"))
  expect_equal(nrow(out$item_tru), 8)
})

test_that("data_simple_1pl() is reproducible with a fixed seed", {
  a <- data_simple_1pl(N_persons = 10, N_items = 8, data_seed = 1)
  b <- data_simple_1pl(N_persons = 10, N_items = 8, data_seed = 1)
  expect_identical(a$resp, b$resp)
  expect_identical(a$pers_tru, b$pers_tru)
})
