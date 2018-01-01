#
# mondaty.tcl
#
# Estimate item parameters for Form Y items
# using data for examinees who took Form Y.
# Example data from Chapters 4 and 6 Kolen and 
# Brennan (1995)

# Write output to log file mondaty.out
output -log_file mondaty.log

# 36 items to be modeled
allocate_items_dist 36

# Read examinee item responses from file mondaty.dat.
# Each record contains the responses to 
# 36 items for an examinee in columns 1-36.
read_examinees mondaty.dat 36i1

# Compute starting values for item parameter estimates
starting_values_dichotomous

# Perform EM iterations for computing item parameter estimates.
# Maximum of 50 EM iterations.
EM_steps -max_iter 50

# Print item parameter estimates and discrete latent
# variable distribution.
print -item_param -latent_dist

# end of run
release_items_dist
