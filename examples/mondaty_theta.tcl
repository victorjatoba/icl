#
# mondaty_theta.tcl
#
# Compute EAP and MLE latent variable estimates for
# each examinee who took Form Y reading using the
# previously computed item parameter estimates.
# Write EAP and MLE estimates and number correct score
# for each examinee to file 'mondaty.theta'.
# Example data from Chapters 4 and 6 Kolen and 
# Brennan (1995)

# Supress written output from subsequent ICL commands
output -no_print

# 36 items to be modeled
allocate_items_dist 36

# Read examinee item responses from file mondaty.dat.
# Each record contains the responses to 
# 36 items for an examinee in columns 1-36.
read_examinees mondaty.dat 36i1

# Read previously computed item parameter estimates
read_item_param mondaty.par

# Create E-step object needed to compute
# posterior latent variable distributions for
# examinees
set estep [new_estep]

# Use E-step object to compute posterior distribution
# for each examinee. The second argument being equal to 1
# indicates the posterior will be computed for each
# examinee. The third argument being equal to 1 indicates
# that the posterior for each examinee will be stored
# with the examinee to allow the examinee_posterior_mean
# command to be used for the examinee.
estep_compute $estep 1 1

# E-step object only needed for the estep_compute command, 
# so can be deleted.
delete_estep $estep

# Open file to contain estimates
set eapfile [open mondaty.theta w]

# Write EAP and MLE estimates and number correct for each examinee on
# a separate line of the output file
for {set i 1} {$i <= [num_examinees]} {incr i} {
	
	# compute number correct
	set resp [examinee_responses $i]
	set numcorrect 0
	foreach r $resp {
		if {$r > 0} then {incr numcorrect}
	}
	
	# get examinee posterior mean (EAP estimate)
	set eap [examinee_posterior_mean $i]
	
	# get examinee MLE estimate
	set mle [examinee_theta_MLE $i -6.0 6.0]
	
	# Write EAP and MLE estimates and number correct. The first
	# argument to the format command indicates that the second and
	# third arguments to the format command will be written as
	# floating-point numbers with 6 digits after the decimal point and
	# that the fourth argument will be written as an integer, with
	# a tab character separating the numbers.
	puts $eapfile [format "%.6f\t%.6f\t%d" $eap $mle $numcorrect]
}

# close output file
close $eapfile

# end of run
release_items_dist
