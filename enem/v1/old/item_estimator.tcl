#
# item_estimator.tcl
#
# Estimate item parameters from Enem items
# using data from an ENEM 2012 sample.
#
# Author: 	Victor Jatoba
# Date:		08/09/17

#Go to folder location
cd icl_linux/enem

# Write output to log file mondaty.out
output -log_file enem.log

# 175 items to be modeled
allocate_items_dist 175

# Read examinee item responses from file mondaty.dat.
# Each record contains the responses to 
# 36 items for an examinee in columns 1-175.
read_examinees enem_2012.dat 175i1

# Compute starting values for item parameter estimates
starting_values_dichotomous

# Perform EM iterations for computing item parameter estimates.
# Maximum of 50 EM iterations.
EM_steps -max_iter 50

# Print item parameter estimates and discrete latent
# variable distribution.
print -item_param -latent_dist

# Write parameter estimates with 8 digits after
# the decimal point
# write_item_param enem.par       -format %.8f   <- NOT RECOGNIZED
write_item_param enem.par

# end of run
release_items_dist
