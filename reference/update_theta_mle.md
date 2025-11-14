# Updated person parameters based on MLE estimates

This update function treats item parameters as fixed and known, updating
person ability estimates after each iteration according to a maximum
likelihood estimate based upon a 2PL item response function.

## Usage

``` r
update_theta_mle(pers, item, resp)
```

## Arguments

- pers:

  A dataframe of current respondent parameter estimates.

- item:

  A dataframe of item parameter values.

- resp:

  A long-form dataframe of only observed item responses.

## Value

An list of three objects, only one of which is updated from the function
input: `pers` is a dataframe with updated respondent parameter
estimates, `item` is the dataframe of item parameter values. `resp_cur`
is the dataframe of observed item responses.
