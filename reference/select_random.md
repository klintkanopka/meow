# Item selection function that delivers an item an item drawn at random from the item bank to each respondent.

Each respondent has their own next item drawn at random from the
remaining items.

## Usage

``` r
select_random(
  pers,
  item,
  resp,
  resp_cur = NULL,
  adj_mat = NULL,
  select_seed = NULL
)
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

- select_seed:

  A random seed used only for item selection. Cleared each time this
  function is run.

## Value

A long-form dataframe of all previously administered item responses with
the new responses from this iteration appended to the end.
