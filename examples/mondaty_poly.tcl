#
# mondaty_poly.tcl
#
# Estimate parameters for 36 dichotomous items
# modeled using the three-parameter logistic (3PL) model,
# and four polytomous items modeled using the
# generalized partial credit model (GPCM) using
# data simulated by polysim.tcl.

# Name of file containing item responses
set resp_file sim_resp.dat

# Write output to mondaty_poly.log
output -log_file mondaty_poly.log

# Create list giving model to use for each item.
# The first 36 items are dichotomous items modeled
# using the three-parameter logistic model, and the last four items
# are 4 category polytomous items modeled by
# the generalized partial credit model.
# The variable 'model' is a list containing
# 36 1's followed by four 4's.
set model [concat [rep 1 36] [rep 4 4]]

# 40 items to be modeled
allocate_items_dist 40 -models $model

# Read examinee item responses.
# Responses to items are at the beginning
# of each record
read_examinees $resp_file 40i1

# Compute starting values for 3PL items
starting_values_dichotomous

# Perform EM iterations for computing item parameter estimates.
EM_steps

# Print item parameter estimates
print -item_param

# end of run
release_items_dist
