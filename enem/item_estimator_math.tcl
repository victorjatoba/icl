#
# item_estimator.tcl
#
# Estimate item parameters from only Enem Math items
# using data from an ENEM sample.
#
# Author: 	Victor Jatoba
# Date:		10/12/17 mm/dd/yy

#Go to folder location
cd enem

# Write output to log file mondaty.out
output -log_file enem_math.log

# 45 items to be modeled
allocate_items_dist 45

# Read examinee item responses from file mondaty.dat.
# Each record contains the responses to
# 45 items for an examinee.
read_examinees enem_2014.dat 45i1

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
write_item_param enem_math.par

# end of run
release_items_dist
