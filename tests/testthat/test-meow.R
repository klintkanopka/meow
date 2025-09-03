# Load test data
out <- data_simple_1pl()

test_that("meow() output is correctly formed", {
  result <- meow(
    select_fun = select_sequential,
    update_fun = update_theta_mle,
    data_loader = data_simple_1pl,
    data_args = list(N_persons = 10, N_items = 20)
  )
  
  expect_type(result, 'list')
  expect_length(result, 4)
  expect_true(all(c('results', 'adj_mats', 'pers_tru', 'item_tru') %in% names(result)))
  
  # Check results is a dataframe
  expect_true(is.data.frame(result$results))
  expect_true('iter' %in% names(result$results))
  
  # Check adj_mats is a list of matrices
  expect_type(result$adj_mats, 'list')
  expect_true(all(sapply(result$adj_mats, is.matrix)))
  
  # Check pers_tru and item_tru are dataframes
  expect_true(is.data.frame(result$pers_tru))
  expect_true(is.data.frame(result$item_tru))
  
  # Check that results has the expected structure
  expect_true(nrow(result$results) > 0)
  expect_true(ncol(result$results) > 1)
})
