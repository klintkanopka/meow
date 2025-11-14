# Load data from existing files

`data_existing()` is a wrapper for three separate calls to
[`read.csv()`](https://rdrr.io/r/utils/read.table.html) that packages
the output into the object used by
[`meow()`](http://klintkanopka.com/meow/reference/meow.md).

## Usage

``` r
data_existing(resp_path, pers_path, item_path)
```

## Arguments

- resp_path:

  A file path to a long form .csv file. File should have three columns,
  `id` which contains a numeric respondent identifier, `item` which
  contains a numeric item identifier, and resp which contains an item
  response. Be sure the form of the item response comports with the
  parameter update functions you choose to use.

- pers_path:

  A file path to a wide form .csv file that contains true person
  parameter values, with one person per row. Include a person index
  column, named `id`. Default column name for unidimensional person
  ability should be `theta`

- item_path:

  A file path to a wide form .csv file that contains true item parameter
  values, with one item per row. Include an item index column, named
  `item`. Default column names for difficulty should be `b` and default
  column name for discrimination should be `a`,

## Value

A list with three components: A dataframe of item response named `resp`,
a dataframe of true person parameters named `pers_tru`, and a dataframe
of true item parameters named `item_tru`
