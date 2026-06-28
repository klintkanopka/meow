make_state <- function(N = 8, M = 12, n_admin = 5, seed = 99) {
  out <- data_simple_1pl(N_persons = N, N_items = M, data_seed = seed)
  R <- matrix(NA_real_, N, M)
  R[cbind(out$resp$id, out$resp$item)] <- out$resp$resp
  admin <- matrix(0L, N, M)
  admin[, seq_len(n_admin)] <- 1L
  list(out = out, R = R, admin = admin)
}

test_that("update_theta_mle() updates ability and leaves items unchanged", {
  s <- make_state()
  pers0 <- s$out$pers_tru
  pers0$theta <- 0
  result <- update_theta_mle(pers0, s$out$item_tru, s$R, s$admin)

  expect_named(result, c("pers", "item"))
  expect_true(is.data.frame(result$pers))
  expect_true(is.data.frame(result$item))
  expect_equal(result$item, s$out$item_tru)
  expect_true(all(result$pers$theta >= -4 & result$pers$theta <= 4))
})

test_that("update_theta_mle() recovers ability ordering on clean data", {
  # With true items fixed and many items administered, the MLE ordering of
  # estimated abilities should track the true abilities.
  s <- make_state(N = 30, M = 30, n_admin = 30, seed = 7)
  pers0 <- s$out$pers_tru
  pers0$theta <- 0
  result <- update_theta_mle(pers0, s$out$item_tru, s$R, s$admin)
  rho <- suppressWarnings(cor(result$pers$theta, s$out$pers_tru$theta))
  expect_gt(rho, 0.6)
})

test_that("update_maths_garden() updates both person and item parameters", {
  s <- make_state()
  pers0 <- s$out$pers_tru; pers0$theta <- 0
  item0 <- s$out$item_tru; item0$b <- 0
  result <- update_maths_garden(pers0, item0, s$R, s$admin, K_theta = 0.2, K_b = 0.2)

  expect_named(result, c("pers", "item"))
  # only respondents/items with administered responses change
  changed_persons <- which(result$pers$theta != 0)
  expect_true(length(changed_persons) > 0)
  # only administered items (1:5) may change; unadministered items stay put
  expect_true(all(result$item$b[6:12] == 0))
  expect_true(any(result$item$b[1:5] != 0))
})

test_that("update_maths_garden() matches a hand-computed Elo step", {
  # 2 persons, 2 items, both items administered, theta=b=0 so E = 0.5 everywhere.
  N <- 2; M <- 2
  pers <- data.frame(id = 1:2, theta = c(0, 0))
  item <- data.frame(item = 1:2, b = c(0, 0), a = c(1, 1))
  R <- matrix(c(1, 0, 1, 1), nrow = 2)  # p1: (1,1); p2: (0,1)
  admin <- matrix(1L, N, M)
  res <- update_maths_garden(pers, item, R, admin, K_theta = 0.1, K_b = 0.1)
  # theta update = K * sum(resp - 0.5): p1 -> 0.1*(0.5+0.5)=0.1; p2 -> 0.1*(-0.5+0.5)=0
  expect_equal(res$pers$theta, c(0.1, 0))
  # b update = K * sum(0.5 - resp): item1 -> 0.1*((0.5-1)+(0.5-0))=0; item2 -> 0.1*((0.5-1)+(0.5-1))=-0.1
  expect_equal(res$item$b, c(0, -0.1))
})

test_that("update_prowise_learn() runs without error and updates parameters", {
  s <- make_state()
  pers0 <- s$out$pers_tru; pers0$theta <- 0
  item0 <- s$out$item_tru; item0$b <- 0
  result <- update_prowise_learn(pers0, item0, s$R, s$admin)

  expect_named(result, c("pers", "item"))
  expect_false(anyNA(result$pers$theta))
  expect_false(anyNA(result$item$b))
  expect_true(any(result$item$b != 0))
})
