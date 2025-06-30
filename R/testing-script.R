source('R/simulation-framework.R')
source('R/data-loaders.R')
source('R/select-items.R')
source('R/update-parameters.R')


tmp <- meow_sim(select_max_info, update_theta_mle, data_default, fix = 'item')
