#
# theta_estimator.tcl
#
# Estimate examinees theta hability
# using data from an 1 Milion ENEM 2012 sample.
#
# Author: 	Victor Jatoba
# Date:		03/19/18

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



# Supress written output from subsequent ICL commands
output -no_print

# 45 items to be modeled
allocate_items_dist 45

# Read examinee item responses from file 2012-enem-responses-1M.dat.
# Each record contains the responses to
# 45 items for an examinee in columns 1-45.
read_examinees 2012-enem-responses-1M.dat 45i1

# Read previously computed item parameter estimates
read_item_param enem-spenassato.par

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
set eapfile [open enem.theta w]

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
	#set mle [examinee_theta_MLE $i -6.0 6.0]

	# Write EAP and MLE estimates and number correct. The first
	# argument to the format command indicates that the second and
	# third arguments to the format command will be written as
	# floating-point numbers with 6 digits after the decimal point and
	# that the fourth argument will be written as an integer, with
	# a tab character separating the numbers.
	puts $eapfile [format "%.6f" $eap]
}

# close output file
close $eapfile

# end of run
release_items_dist
