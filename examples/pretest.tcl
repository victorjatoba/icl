#
# pretest.tcl
#
# Implement MMLE/Multiple-EM Cycle
# method of pretest item calibration and
# scaling described in:
#
# Ban, J., Hanson, B. A., Wang, T., Yi, Q., & Harris, D. J. (2001). A
# comparative study of on-line pretest item-calibration/scaling methods
# in computerized adaptive testing. Journal of Educational Measurement, 
# 38(3), 191-212.

# number of operational items administered
# to each examinee
set adminOperItems 30

# total number of operational items used for CAT
set totOperItems 520

# number of pretest items administered to
# each examinee
set preItems 10

# write output to log file pretest.log
output -log_file pretest.log

# Total number of items is sum of number of operational
# and pretest items
allocate_items_dist [expr {$totOperItems+$preItems}]

#  Create list of item numbers for operational items
set operItemNo [seq 1 520]

# Set priors of all operational item parameters to none, since
# operational item parameters are not estimated. This allows
# any values of the operational item parameters to be read, even
# those for which the prior density using the default prior is zero
# (an error is reported if a parameter is read for which the
# prior density is zero).

# Set priors for a-parameters to none for operational items
items_set_prior 1 none {} $operItemNo

# Set priors for b-parameters to none for operational items
items_set_prior 2 none {} $operItemNo

# Set priors for c-parameters to none for operational items
items_set_prior 3 none {} $operItemNo

# Read examinee item responses using command ReadItemResp
# from file al40cf1.txt.
# The ReadItemResp command is defined
# in file pretest_dat.tcl.
source pretest_dat.tcl
ReadItemResp al40cf1.txt

# Read item parameters for operational items
# from file pool.par
read_item_param pool.par

# Create list of item numbers for pretest items
set preItemNo [seq 521 530]

# Compute starting values for pretest items.
# The first argument (1) indicates all
# items (including those answered correctly or
# incorrectly by all examinees) and all examinees 
# (even those to get all items correct or all items
# incorrect) will be used to
# compute initial difficulties and proficiencies
# from which the starting values are computed.
# The second argument (0) indicates only
# the pretest items, rather than all items, are 
# used to compute the initial examinee proficiencies.
item_3PL_starting_values 1 0 $preItemNo

# Create E-step object used to compute
# examinee posterior distributions based
# on operational items
set eoper [new_estep $operItemNo]

# Compute examinee posterior distributions based on 
# only operation item responses, and store posteriors
# for each examinee. The second argument (1)
# indicates examinee posterior distributions
# are computed. The third argument (1)
# indicates that these posterior distributions
# are stored for each examinee. The fourth
# argument is an empty string which indicates
# that n's and r's are not updated for 
# any items - the purpose of this command
# is to compute examinee posterior distributions,
# not n's and r's for any of the items.
estep_compute $eoper 1 1 {}

# E-step object no longer needed, so delete
delete_estep $eoper

# Create E-step object used in E-step
# for computing pretest item parameter
# estimates
set eall [new_estep]

# Compute E-step for pretest items using
# examinee posteriors computed with operational
# items. The second argument (0) indicates
# that examinee posterior distributions
# are not computed. Instead, posterior
# distributions previously computed and
# stored (in estep_compute command above)
# are used. The third argument (0) indicates
# that examinee posterior distributions are
# not stored for examinees (this is redundant, 
# given the second argument is zero but must
# still be present).
estep_compute $eall 0 0 $preItemNo

# Loop over EM iterations.
# To implement the MMLE/One-EM Cycle method
# discussed in Ban, et. al. use just one
# iteration.
for {set iter 1} {$iter <= 100} {incr iter} {

	# M-step
	set maxreldiff [mstep_item_param -items $preItemNo]

	# E-step
	# Second argument to estep_compute (1) indicates
	# posterior distibutions will be computed
	# for examinees. These are used to update n's and
	# r's for items given by the item numbers
	# in the list that is the last argument.
	# The third argument to estep_compute (0) indicates
	# the examinee posterior distributions computed
	# will not be stored.
	set loglike [estep_compute $eall 1 0 $preItemNo]
	
	# Write iteration information to log file and to screen
	set iterinfo [format {%5d: %.6f %.4f} $iter $maxreldiff $loglike]
	puts_log $iterinfo
	puts $iterinfo
	
	# Quit EM iterations if convergence criterion is met
	if {$maxreldiff < 0.001} then break
}

# delete E-step object
delete_estep $eall

# Write parameter estimates for pretest items to
# log file. Uses global variable icl_logfileID
# defined in icl.tcl.
puts_log "\nItem parameter estimates for pretest items"
write_item_param_channel $icl_logfileID -format %.6f -items $preItemNo

# End of run
release_items_dist
