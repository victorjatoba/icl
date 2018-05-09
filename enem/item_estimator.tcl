#
# item_estimator.tcl
#
# Estimate item parameters from only Enem Math items
# using data from an 1 Milion ENEM sample.
#
# Author: 	Victor Jatoba
# Date:		03/19/18 dd/mm/yy

#Go to folder location
cd enem

### Specify prior distributions used by default in BILOG

# Lognormal prior for a-parameters with mean 0 and standard
# deviation 0.5 in the underlying normal distribution
options -default_prior_a {lognormal 0.0 0.5}

# No prior for b-parameters
options -default_prior_b none

# Two-parameter beta prior is used by BILOG for the
# c-parameters when the number of response options is 4.
options -default_prior_c {beta 6.0 16.0 0.0 1.0}

###

# Write output to log file enem.out
output -log_file 2012-enem.log

# 45 items to be modeled
allocate_items_dist 45

# Read examinee item responses from file 2012-enem-responses-1M.dat
# Each record contains the responses to
# 45 items for an examinee.
read_examinees 2012-enem-responses-700k.dat 45i1

# Compute starting values for item parameter estimates
starting_values_dichotomous

# Perform EM iterations for computing item parameter estimates.
# Maximum of 200 EM iterations.
EM_steps -max_iter 200

# Print item parameter estimates, discrete latent
# variable distributions, and mean and s.d. of
# latent variable distributions.
print -item_param -latent_dist -latent_dist_moments

# Write parameter estimates with 8 digits after
# the decimal point
# write_item_param enem.par       -format %.8f   <- NOT RECOGNIZED
write_item_param 2012-enem-700k.par

# end of run
release_items_dist
