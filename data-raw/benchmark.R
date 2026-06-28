# Benchmark of the matrix-based simulation engine.
#
# This script is not part of the installed package (the data-raw/ directory is
# excluded via .Rbuildignore). It times a few representative simulations across
# problem sizes so that performance regressions are easy to spot.
#
# Usage:
#   Rscript data-raw/benchmark.R
#
# To compare against an earlier version of the package, install or load_all()
# that version under a different library and run the same scenarios.

library(meow)

scenarios <- list(
  c(N = 500,  I = 60),
  c(N = 1000, I = 100),
  c(N = 2000, I = 100)
)

bench <- function(label, sel, upd, fix) {
  cat(sprintf("\n%s\n", label))
  for (s in scenarios) {
    t <- system.time(
      meow(sel, upd, data_simple_1pl,
           data_args = list(N_persons = s["N"], N_items = s["I"]),
           fix = fix)
    )["elapsed"]
    cat(sprintf("  %4d persons x %3d items : %6.2f s\n", s["N"], s["I"], t))
  }
}

bench("max information + Elo (Maths Garden)", select_max_info, update_maths_garden, "none")
bench("network distance + Elo (Maths Garden)", select_max_dist, update_maths_garden, "none")
bench("max information + MLE ability", select_max_info, update_theta_mle, "item")
