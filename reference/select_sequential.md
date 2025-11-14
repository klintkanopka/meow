# Item selection function that delivers the next item by item id number, simulating a fixed test form.

This function just administers the next item in a form, with the
within-person item ordering being governed by the ordering the rows in
the `resp` dataframe.

## Usage

``` r
select_sequential(pers, item, resp, resp_cur = NULL, adj_mat = NULL)
```

## Arguments

- pers:

  A dataframe of current respondent ability estimates.

- item:

  A dataframe of current item parameter estimates.

- resp:

  A long-form dataframe of all potential pre-simulated item responses.

- resp_cur:

  A long-form dataframe of administered item responses.

- adj_mat:

  An item-item adjacency matrix, where each entry is the count of
  individuals who have respondent to both item i and item j. See
  documentation for `construct_adj_mat`

## Value

A long-form dataframe of all previously administered item responses with
the new responses from this iteration appended to the end.
