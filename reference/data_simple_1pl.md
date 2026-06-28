# A default data generation function that simulates normally distributed respondent abilities and item difficulties

`data_simple_1pl()` constructs data according to a simple one parameter
logistic IRT model. The user may specify a number of persons, a number
of items, and a random seed for reproducibility. Person abilities and
item difficulties are both drawn from a standard normal.

## Usage

``` r
data_simple_1pl(N_persons = 100, N_items = 50, data_seed = 242424)
```

## Arguments

- N_persons:

  Number of respondents to simulate

- N_items:

  Number of items to simulate

- data_seed:

  A random seed for generating reproducible data. This seed is
  re-initialized at the end of the data generation process

## Value

A list with three components: A dataframe of item response named `resp`,
a dataframe of true person parameters named `pers_tru`, and a dataframe
of true item parameters named `item_tru`

## Examples

``` r
data <- data_simple_1pl(N_persons = 10, N_items = 8)
str(data)
#> List of 3
#>  $ resp    :'data.frame':    80 obs. of  3 variables:
#>   ..$ id  : int [1:80] 1 1 1 1 1 1 1 1 2 2 ...
#>   ..$ item: int [1:80] 1 2 3 4 5 6 7 8 1 2 ...
#>   ..$ resp: int [1:80] 1 0 0 1 0 0 0 1 1 0 ...
#>  $ pers_tru:'data.frame':    10 obs. of  2 variables:
#>   ..$ id   : int [1:10] 1 2 3 4 5 6 7 8 9 10
#>   ..$ theta: num [1:10] 0.167 -0.605 1.045 -1.686 0.192 ...
#>  $ item_tru:'data.frame':    8 obs. of  3 variables:
#>   ..$ item: int [1:8] 1 2 3 4 5 6 7 8
#>   ..$ b   : num [1:8] -0.52 0.811 -0.306 -1.124 0.6 ...
#>   ..$ a   : num [1:8] 1 1 1 1 1 1 1 1
```
