# Elo-style updates of person and item parameters

This update function updates both person and item parameters according
to the approach from the paper "Psychometrics of an Elo-based
large-scale online learning system" (Vermeiren, et al. 2025)

## Usage

``` r
update_prowise_learn(pers, item, resp, K_theta = 0.1, K_b = 0.1)
```

## Arguments

- pers:

  A dataframe of current respondent parameter estimates.

- item:

  A dataframe of current item parameter estimates.

- resp:

  A long-form dataframe of only observed item responses.

- K_theta:

  User supplied learning rate for person ability updates. Defaults to
  0.1

- K_b:

  User supplied learning rate for item difficulty updates. Defaults to
  0.1

## Value

An list of three objects, two of which are updated from the function
input: `pers` is a dataframe with updated respondent parameter
estimates, `item` is the dataframe of updated item parameter estimates.
`resp_cur` is the dataframe of observed item responses.
