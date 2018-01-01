#
# mondat4.tcl
#
# Example data from Chapters 4 and 6 Kolen and 
# Brennan (1995)
# Estimate item parameters for Form Y and Form X
# items while at the same time estimating
# the latent variable distribution of the groups
# that took Form X and Form Y.

# Write output to log file mondat4.log
output -log_file mondat4.log

# 24 unique items on each of two forms and
# 12 common items for a total of 60
# items. Two groups specified
# for multiple group estimation
allocate_items_dist 60 -num_groups 2

# Read examinee item responses from file mondat.dat.
# Each record contains the responses to 
# 60 items for an examinee in columns 2-61.
# The first 24 items are the unique items on
# Form Y, the second 12 items are common items,
# and the last 24 items are unique items on
# Form X. An integer in column 1 gives
# the examinee group: 1 for examinees
# who took Form Y, and 2 for examinees
# who took Form X
read_examinees mondat.dat {@2 60i1} {i1}

# Compute starting values for item parameter estimates
starting_values_dichotomous

# Perform EM iterations for computing item parameter estimates
# and probabilities of latent variable distributions for
# groups 1 and 2. Points of the latent variable distribution
# will not be adjusted after each M-step so the mean and
# standard deviation of the distribution in Group 1 are
# zero and one. Allow a maximum of 200 EM iterations.
EM_steps -estim_dist -max_iter 200

# Print item parameter estimates and discrete latent
# variable distributions.
print -item_param -latent_dist -latent_dist_moments

# end of run
release_items_dist
