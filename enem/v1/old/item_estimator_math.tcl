#
# item_estimator.tcl
#
# Estimate item parameters from only Enem Math items
# using data from an ENEM 2012 sample.
#
# Author: 	Victor Jatoba
# Date:		10/12/17 mm/dd/yy

#Go to folder location
cd icl_linux/enem

# Write output to log file mondaty.out
output -log_file enem_math.log

# 175 items to be modeled
allocate_items_dist 45

# Read examinee item responses from file mondaty.dat.
# Each record contains the responses to
# 45 items for an examinee in columns 91-136.
read_examinees enem_2012.dat {@91 45i1}

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
write_item_param enem_math.par

# end of run
release_items_dist
