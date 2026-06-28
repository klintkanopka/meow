## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Klint Kanopka <klint.kanopka@gmail.com>'
  New submission

This note is expected for a first-time submission.

## Test environments

* local macOS, R 4.5.2 -- R CMD check --as-cran: 0 errors, 0 warnings, 0 notes
* win-builder (R-release, R 4.6.1) -- 0 errors, 0 warnings, 1 note (New submission)
* (to be completed before submission: win-builder R-devel)

## Notes

* This is a new submission.
* The package's vignettes use the knitr engine. Suggested packages (`ggplot2`,
  `rmarkdown`) are used conditionally and guarded so that checks pass when they
  are unavailable.
