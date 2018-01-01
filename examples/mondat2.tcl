#
# mondat2.tcl
#
# Estimate item parameters for Form Y and Form X
# items fixing the latent variable distribution of
# the group that took Form X at a discrete approximation
# to a standard normal distribution and estimating
# the latent variable distribution of the group
# that took Form Y.
# Example data from Chapters 4 and 6 Kolen and 
# Brennan (1995)

# Write output to log file mondat2.log
output -log_file mondat2.log

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
# and probabilities of latent variable distribution for
# group 2.
EM_steps

# Print item parameter estimates, discrete latent
# variable distributions, and mean and s.d. of
# latent variable distributions.
print -item_param -latent_dist -latent_dist_moments

# end of run
release_items_dist
