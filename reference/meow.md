# Conduct a full CAT simulation.

`meow()` is the core function of this simulation framework. It exists to
help users compare efficiency tradeoffs across different item selection
algorithms, parameter update algorithms, and data generating processes.
It takes as arguments an item selection function, a parameter update
function, and a data loader function and uses these to carry out a
simulation of a full CAT administration. Default behavior is to proceed
until no further items are administered. Because the internal simulation
logic stops as soon as an iteration administers no new items, early
stopping conditions should be implemented within the item selection
function (by declining to administer further items).

## Usage

``` r
meow(
  select_fun,
  update_fun,
  data_loader,
  select_args = list(),
  update_args = list(),
  data_args = list(),
  init = NULL,
  fix = "none",
  keep_adj_mats = TRUE
)
```

## Arguments

- select_fun:

  A function that specifies the item selection algorithm.

- update_fun:

  A function that specifies the parameter update algorithm.

- data_loader:

  A function that specifies the data generating process.

- select_args:

  A named list of arguments to be passed to `select_fun`.

- update_args:

  A named list of arguments to be passed to `update_fun`.

- data_args:

  A named list of arguments to be passed to `data_loader`.

- init:

  A list of initialization values for estimated person and item
  parameters. Accepts a named list with two entries, `pers` and `item`,
  giving the initial estimated parameter data frames. Defaults to
  `NULL`, which initializes all estimated parameters to zero.

- fix:

  Which estimated parameters to treat as fixed at their true values. One
  of `none` (the default), `pers`, `item`, or `both`.

- keep_adj_mats:

  Logical; if `TRUE` (the default) an adjacency matrix is stored for
  every iteration. If `FALSE`, only the final adjacency matrix is
  retained, which saves memory for large item pools or long simulations.

## Value

A list of four named entities. `results` is a data frame with one row
per iteration of the simulation. It contains an `iter` column for the
iteration number and two columns per person and item parameter, one for
the estimated parameter and one for the bias in that estimate.
`adj_mats` is a list of item-item adjacency matrices, one per iteration
(or, when `keep_adj_mats = FALSE`, a single-element list with the final
matrix); edge weights count the number of respondents administered each
pair of items. `pers_tru` and `item_tru` are the true person and item
parameter data frames.

## Details

### Simulation state

For speed, `meow()` represents responses with matrices rather than long
data frames. Two matrices, each with one row per respondent and one
column per item, are passed to the user-supplied modules:

- `R` — the (potential) response of every respondent to every item. This
  is produced once from the long `resp` data frame returned by the data
  loader.

- `admin` — an integer administration matrix. An entry of `0` means the
  item has not been administered to that respondent; a positive entry
  means it has, and the value encodes the order of administration. Use
  `admin != 0` (or
  [`meow_administered()`](https://klintkanopka.com/meow/reference/meow_administered.md))
  as an administered mask.

Person and item *parameters* are kept as data frames (`pers` and
`item`), each with an identifier column (`id` and `item`, respectively)
followed by one column per parameter, so that users retain the
flexibility to add arbitrary parameters.

### Module contracts

An **item selection** function receives `pers`, `item`, `R`, `admin`,
and `adj_mat` (plus any `select_args`) and returns an administration
matrix with newly selected cells marked non-zero. The harness stamps the
order of administration, so a function need only set newly selected
cells to a positive value (or `TRUE`) while leaving previously
administered cells unchanged.

A **parameter update** function receives `pers`, `item`, `R`, and
`admin` (plus any `update_args`) and returns a list with updated `pers`
and `item` data frames.

Module authors who prefer long data frames can convert with
[`meow_long()`](https://klintkanopka.com/meow/reference/meow_long.md).

## Examples

``` r
sim <- meow(
  select_fun = select_max_info,
  update_fun = update_theta_mle,
  data_loader = data_simple_1pl,
  data_args = list(N_persons = 20, N_items = 15),
  fix = "item"
)
head(sim$results)
#>   iter pers_theta_1_est pers_theta_2_est pers_theta_3_est pers_theta_4_est
#> 1    1        1.1672247        -1.744834        1.1672247        -1.744834
#> 2    2        0.7214799        -2.323310        0.7214799        -1.316969
#> 3    3        0.3889976        -1.590715        1.0975512        -1.590722
#> 4    4        0.7008374        -1.792259        1.3497830        -1.158004
#> 5    5        0.8409483        -1.351191        1.7741792        -1.351194
#> 6    6        0.7131628        -1.040171        1.8479801        -1.510704
#>   pers_theta_5_est pers_theta_6_est pers_theta_7_est pers_theta_8_est
#> 1       0.12659553        -4.000000        1.1672247       0.12659553
#> 2      -0.16029904        -4.000000        0.7214799       0.58527037
#> 3       0.11654264        -4.000000        1.0975512       0.28819690
#> 4      -0.07004313        -2.691230        1.3497830      -0.07004272
#> 5       0.10714972        -1.948338        1.1287836       0.10714972
#> 6      -0.18600587        -1.510710        0.7131547      -0.18600587
#>   pers_theta_9_est pers_theta_10_est pers_theta_11_est pers_theta_12_est
#> 1       -1.7448341         0.1265955        0.12659553         1.1672247
#> 2       -1.3169690        -0.1602990       -0.16029904         0.7214799
#> 3       -0.9020472        -0.4952243        0.11654264         0.3889976
#> 4       -0.6030350        -0.7844273       -0.07004313         0.7008374
#> 5       -0.3641624        -0.5467689       -0.37437690         0.8409483
#> 6       -0.5781393        -0.3437141       -0.18600543         0.7131628
#>   pers_theta_13_est pers_theta_14_est pers_theta_15_est pers_theta_16_est
#> 1        0.12659553         -1.744834         0.1265955         1.1672247
#> 2       -0.16029904         -2.323310        -0.1602990         0.7214799
#> 3        0.11654264         -1.590715         0.1165426         0.3889976
#> 4       -0.07004313         -1.792259         0.4830405         0.1288223
#> 5       -0.37437690         -1.351191         0.3185142         0.3185110
#> 6       -0.62038428         -1.510704         0.4480625         0.4480625
#>   pers_theta_17_est pers_theta_18_est pers_theta_19_est pers_theta_20_est
#> 1        -0.7296929        0.12659553        -0.7296929         -1.744834
#> 2        -1.0980480       -0.16029904        -1.0980480         -1.316969
#> 3        -1.3911279       -0.49522430        -1.3911279         -1.590722
#> 4        -1.1580070       -0.24563300        -1.1580070         -1.792259
#> 5        -1.3511935       -0.05377053        -0.8462001         -1.948333
#> 6        -1.0401708       -0.33405712        -1.0401397         -2.080901
#>   pers_theta_1_bias pers_theta_2_bias pers_theta_3_bias pers_theta_4_bias
#> 1        -1.0000763         1.1395728       -0.12173213        0.05845799
#> 2        -0.5543315         1.7180488        0.32401262       -0.36940714
#> 3        -0.2218492         0.9854541       -0.05205867       -0.09565393
#> 4        -0.5336890         1.1869979       -0.30429046       -0.52837159
#> 5        -0.6737999         0.7459301       -0.72868669       -0.33518256
#> 6        -0.5460144         0.4349096       -0.80248754       -0.17567166
#>   pers_theta_5_bias pers_theta_6_bias pers_theta_7_bias pers_theta_8_bias
#> 1        0.06494335          3.078332         -1.659119        0.23682319
#> 2        0.35183793          3.078332         -1.213374       -0.22185165
#> 3        0.07499625          3.078332         -1.589446        0.07522182
#> 4        0.26158201          1.769562         -1.841677        0.43346144
#> 5        0.08438916          1.026670         -1.620678        0.25626900
#> 6        0.37754476          0.589042         -1.205049        0.54942459
#>   pers_theta_9_bias pers_theta_10_bias pers_theta_11_bias pers_theta_12_bias
#> 1        1.23877108          0.2425895         -0.6462325        -0.35575258
#> 2        0.81090595          0.5294841         -0.3593379         0.08999217
#> 3        0.39598424          0.8644093         -0.6361796         0.42247446
#> 4        0.09697202          1.1536123         -0.4495938         0.11063466
#> 5       -0.14190059          0.9159539         -0.1452601        -0.02947621
#> 6        0.07207632          0.7128991         -0.3336315         0.09830931
#>   pers_theta_13_bias pers_theta_14_bias pers_theta_15_bias pers_theta_16_bias
#> 1        -0.43221153          0.6205225          0.4735426         -0.3134943
#> 2        -0.14531695          1.1989985          0.7604372          0.1322505
#> 3        -0.42215863          0.4664037          0.4835955          0.4647327
#> 4        -0.23557287          0.6679476          0.1170977          0.7249080
#> 5         0.06876091          0.2268798          0.2816240          0.5352194
#> 6         0.31476829          0.3863928          0.1520757          0.4056678
#>   pers_theta_17_bias pers_theta_18_bias pers_theta_19_bias pers_theta_20_bias
#> 1        -0.06623821        -0.35654816        -0.18655107          0.5862458
#> 2         0.30211685        -0.06965359         0.18180399          0.1583807
#> 3         0.59519681         0.26527167         0.47488395          0.4321339
#> 4         0.36207590         0.01568037         0.24176304          0.6336709
#> 5         0.55526244        -0.17618210        -0.07004381          0.7897449
#> 6         0.24423971         0.10410449         0.12389574          0.9223131
#>   item_b_1_est item_b_2_est item_b_3_est item_b_4_est item_b_5_est item_b_6_est
#> 1   -0.6381767    0.6772661   -0.3723752   -0.5571576   -0.5595623   -0.7151954
#> 2   -0.6381767    0.6772661   -0.3723752   -0.5571576   -0.5595623   -0.7151954
#> 3   -0.6381767    0.6772661   -0.3723752   -0.5571576   -0.5595623   -0.7151954
#> 4   -0.6381767    0.6772661   -0.3723752   -0.5571576   -0.5595623   -0.7151954
#> 5   -0.6381767    0.6772661   -0.3723752   -0.5571576   -0.5595623   -0.7151954
#> 6   -0.6381767    0.6772661   -0.3723752   -0.5571576   -0.5595623   -0.7151954
#>   item_b_7_est item_b_8_est item_b_9_est item_b_10_est item_b_11_est
#> 1    -0.811634    0.7625893     0.541371    -0.6162634    -0.6266497
#> 2    -0.811634    0.7625893     0.541371    -0.6162634    -0.6266497
#> 3    -0.811634    0.7625893     0.541371    -0.6162634    -0.6266497
#> 4    -0.811634    0.7625893     0.541371    -0.6162634    -0.6266497
#> 5    -0.811634    0.7625893     0.541371    -0.6162634    -0.6266497
#> 6    -0.811634    0.7625893     0.541371    -0.6162634    -0.6266497
#>   item_b_12_est item_b_13_est item_b_14_est item_b_15_est item_a_1_est
#> 1      1.894222     -1.831164    -0.3559899      1.214029            1
#> 2      1.894222     -1.831164    -0.3559899      1.214029            1
#> 3      1.894222     -1.831164    -0.3559899      1.214029            1
#> 4      1.894222     -1.831164    -0.3559899      1.214029            1
#> 5      1.894222     -1.831164    -0.3559899      1.214029            1
#> 6      1.894222     -1.831164    -0.3559899      1.214029            1
#>   item_a_2_est item_a_3_est item_a_4_est item_a_5_est item_a_6_est item_a_7_est
#> 1            1            1            1            1            1            1
#> 2            1            1            1            1            1            1
#> 3            1            1            1            1            1            1
#> 4            1            1            1            1            1            1
#> 5            1            1            1            1            1            1
#> 6            1            1            1            1            1            1
#>   item_a_8_est item_a_9_est item_a_10_est item_a_11_est item_a_12_est
#> 1            1            1             1             1             1
#> 2            1            1             1             1             1
#> 3            1            1             1             1             1
#> 4            1            1             1             1             1
#> 5            1            1             1             1             1
#> 6            1            1             1             1             1
#>   item_a_13_est item_a_14_est item_a_15_est item_b_1_bias item_b_2_bias
#> 1             1             1             1             0             0
#> 2             1             1             1             0             0
#> 3             1             1             1             0             0
#> 4             1             1             1             0             0
#> 5             1             1             1             0             0
#> 6             1             1             1             0             0
#>   item_b_3_bias item_b_4_bias item_b_5_bias item_b_6_bias item_b_7_bias
#> 1             0             0             0             0             0
#> 2             0             0             0             0             0
#> 3             0             0             0             0             0
#> 4             0             0             0             0             0
#> 5             0             0             0             0             0
#> 6             0             0             0             0             0
#>   item_b_8_bias item_b_9_bias item_b_10_bias item_b_11_bias item_b_12_bias
#> 1             0             0              0              0              0
#> 2             0             0              0              0              0
#> 3             0             0              0              0              0
#> 4             0             0              0              0              0
#> 5             0             0              0              0              0
#> 6             0             0              0              0              0
#>   item_b_13_bias item_b_14_bias item_b_15_bias item_a_1_bias item_a_2_bias
#> 1              0              0              0             0             0
#> 2              0              0              0             0             0
#> 3              0              0              0             0             0
#> 4              0              0              0             0             0
#> 5              0              0              0             0             0
#> 6              0              0              0             0             0
#>   item_a_3_bias item_a_4_bias item_a_5_bias item_a_6_bias item_a_7_bias
#> 1             0             0             0             0             0
#> 2             0             0             0             0             0
#> 3             0             0             0             0             0
#> 4             0             0             0             0             0
#> 5             0             0             0             0             0
#> 6             0             0             0             0             0
#>   item_a_8_bias item_a_9_bias item_a_10_bias item_a_11_bias item_a_12_bias
#> 1             0             0              0              0              0
#> 2             0             0              0              0              0
#> 3             0             0              0              0              0
#> 4             0             0              0              0              0
#> 5             0             0              0              0              0
#> 6             0             0              0              0              0
#>   item_a_13_bias item_a_14_bias item_a_15_bias
#> 1              0              0              0
#> 2              0              0              0
#> 3              0              0              0
#> 4              0              0              0
#> 5              0              0              0
#> 6              0              0              0
```
