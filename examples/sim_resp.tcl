#
# sim_resp.tcl
#
# Simulate responses to 36 dichotomous items
# using the three-parameter logistic (3PL) model,
# and four polytomous items using the
# generalized partial credit model (GPCM).

# Number of examinees to simulate
set num_examinees 2000

# Name of file to contain simulated responses
set sim_file sim_resp.dat

# Name of file containing item parameters for dichotomous items
set par_file mondaty.par

# Supress written output from subsequent ICL commands
output -no_print

# Set default item parameter priors to none since
# parameters are not being estimated, but only used
# to generate item responses.
options -default_prior_a none -default_prior_b none 
options -default_prior_c none

# Create list giving model to use for each item.
# The first 36 items are dichotomous items modeled
# using the three-parameter logistic model, and the last four items
# are 4 category polytomous items modeled by
# the generalized partial credit model.
# The variable 'model' is a list containing
# 36 1's followed by four 4's.
set model [concat [rep 1 36] [rep 4 4]]

# 40 items to be modeled
allocate_items_dist 40 -models $model

# Read item parameters for the 36 dichotomous items.
# These are parameter estimates produced by
# mondaty.tcl.
read_item_param $par_file

# Assign parameters for the four polytomous items.
# The order of the parameters for each item is: a, b1, b2, b3.
item_set_params 37 [list 1.0 0.5 0.0 1.0]
item_set_params 38 [list 0.75 -2.0 0.0 2.0]
item_set_params 39 [list 0.5 0.0 -0.5 -1.0]
item_set_params 40 [list 1.5 -1.0 0.5 0.0]

# Set seed of random number generator used to
# simulate item responses.
simulate_seed 4967363

# Set seed of random number generator used to
# simulate examinee thetas.
normal_seed 5630837

# Open file to contain simulated item responses
if [catch {open $sim_file w} fileID] {
	error "Could not open $sim_file"
}

# Loop over simulated examinees
for {set i 0} {$i < $num_examinees} {incr i} {

	# Simulate value of latent variable for an examinee
	set theta [rand_normal]

	# Simulate item responses for an examinee
	set r [simulate_response_str $theta]
	
	# Write simulated item responses followed by 
	# a space and the simulated theta formatted
	# to have 6 digits after the decimal point.
	puts $fileID "$r [format %.6f $theta]"
}

close $fileID

# end of run
release_items_dist
