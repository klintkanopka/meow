# Constructs an item pool adjacency matrix.

For an item pool with N items, this is an NxN matrix. The diagonal
elements contain the number of times an item has been exposed. The
off-diagonal elements contain the number of times the pair of items has
been exposed to the same respondent. In general, this function is never
called directly, but instead called within
[`meow()`](http://klintkanopka.com/meow/reference/meow.md) calls. That
said, it is exposed to the user to aid with testing other functions they
may write.

## Usage

``` r
construct_adj_mat(resp_cur, pers_tru, item_tru)
```

## Arguments

- resp_cur:

  A long-form dataframe of observed item responses.

- pers_tru:

  A dataframe of true respondent abilities.

- item_tru:

  A dataframe of true item parameters.

## Value

An adjacency matrix of type `matrix`.
