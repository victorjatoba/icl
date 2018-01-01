#
# mondat5.tcl
#
# Example data from Chapters 4 and 6 Kolen and 
# Brennan (1995)
# Estimate item parameters for Form Y and Form X
# items while at the same time estimating
# the mean and s.d. of the latent variable distribution
# of the group that took Form X (Group 2).

# Write output to log file mondat5.log
output -log_file mondat5.log

# 24 unique items on each of two forms and
# 12 common items for a total of 60
# items. Two groups specified
# for multiple group estimation.
# The -unique_points option allows different
# discrete latent distribution points to be
# used for the different group. This allows
# the mean and standard deviation of
# group 2 to be estimated.
allocate_items_dist 60 -num_groups 2 -unique_points

# Read examinee item responses for Form Y from
# file mondaty.dat and item responses for Form X
# from file mondatx.dat using read_examinees_missing
# command.
# Each record contains the responses to 
# items in columns 1-36. The responses
# to the 12 common items on each form are in
# columns 3, 6, 9, ..., 36, and the responses
# to the 24 unique items on each form are in
# the other columns (1, 2, 4, 5, ..., 35).

# Item numbers are assigned such that the first 24
# items are the unique items on Form Y, 
# the second 12 items are common items,
# and the last 24 items are unique items on
# Form X. 

# Item numbers for Form Y in the order in which
# they are read from file mondaty.dat. Forms
# are not read from the input record since the examinees
# who take each form are read from separate files.
# In this case integers need to be used as indices for
# forms. The index of Form Y is 1.
set items(1) [list 1 2 25 3 4 26 5 6 27 7 8 28 \
    9 10 29 11 12 30 13 14 31 15 16 32 \
    17 18 33 19 20 34 21 22 35 23 24 36]

# Item numbers for Form X in the order in which
# they are read from file mondatx.dat. Forms
# are not read from the input record since the examinees
# who take each form are read from separate files.
# In this case integers need to be used as indices for
# forms. The index of Form X is 2.
set items(2) [list 37 38 25 39 40 26 41 42 27 43 44 28 \
    45 46 29 47 48 30 49 50 31 51 52 32 \
    53 54 33 55 56 34 57 58 35 59 60 36]

# Item responses are in columns 1-36 of input record
# for both forms.
set respFmt(1) 36i1
set respFmt(2) 36i1

# Read Form Y data (group 1)
# The second argument being 1 indicates all examinees
# read took the form associated with index 1 (Form Y).
# The fifth argument being 1 indicates all examinees
# are in group 1.
read_examinees_missing mondaty.dat 1 items respFmt 1

# Read Form X data (group 2)
# The second argument being 2 indicates all examinees
# read took the form associated with index 2 (Form X).
# The fifth argument being 2 indicates all examinees
# are in group 2.
read_examinees_missing mondatx.dat 2 items respFmt 2

# Compute starting values for item parameter estimates
starting_values_dichotomous

# Perform EM iterations for computing item parameter estimates
# and mean and s.d. of latent variable distribution for
# group 2. 
EM_steps -estim_dist_mean_sd

# Print item parameter estimates and discrete latent
# variable distributions, and moments of
# latent variable distributions.
print -item_param -latent_dist -latent_dist_moments

# end of run
release_items_dist
