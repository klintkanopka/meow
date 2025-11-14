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
