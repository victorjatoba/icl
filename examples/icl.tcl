# Tcl procedures for IRT Command Language (ICL)
# http://www.b-a-h.com/software/irt/icl/
#
# Author(s): Brad Hanson (http://www.b-a-h.com/)

# global variable containing version
set icl_version "0.020301"

# global options for output
array set icl_output [list -log_file stdout -no_print 0]

# array containing item names
array set icl_item_names [list]

# I/O channel ID for log file where output is written.
# Set to standard output by default.
set icl_logfileID stdout

# set program options for output
#
# optional arguments
# 	-log_file = File to which output is written
# 	-no_print = If non-zero do not write any output (default = 0)
proc output {args} {
	global icl_output
	global icl_logfileID

	# Store current log file 
	set oldfile $icl_output(-log_file)
	
	# set option values from command arguments
	command_options icl_output $args options
	
	# close old output file
	if {$icl_logfileID != "stdout" && $icl_logfileID != "stderr"} then {close $icl_logfileID}

	# open output file
	if {$icl_output(-log_file) == "stdout" || $icl_output(-log_file) == "stderr"} then {
		set icl_logfileID stdout
	} elseif {[catch {open $icl_output(-log_file) w} icl_logfileID]} {
		error "Cannot open log file $icl_output(-log_file)"
	}
	
}

# set global program options
#
# When this function is not called the default values are those given
# in the C++ source file
#
# optional arguments
# 	-D = Logistic scaling constant for 3PL (default=1.7 makes logistic curve close to normal)
# 	-missing_resp = Examinee response that indicates the examinee did not take 
#		the item (default = .)
#	-base_group = Base examinee group for which mean and s.d. are set to zero and one.
#	-max_iter_optimize = Maximum number of iterations allowed in optimization 
#		procedure used in computing starting values and the M-step computation.
#
# The following options take a list as an argument. The first item of the list
# indicates the type of prior distribution (normal, lognormal, logistic, none),
# and the remaining items are the parameters of the prior. For the normal and
# lognormal priors there are two parameters - the mean and s.d., for the beta
# prior there are four parameters - alpha, beta, lower limit, and upper limit, and
# for none no additional arguments are used.
#	-default_prior_a = Default prior used for slope parameters of items (default = {lognormal 0.0 0.5})
#	-default_prior_b = Default prior used for threshold parameters of items
#		(default = {beta 1.01 1.01 -6.0 6.0})
#	-default_prior_c = Default prior used for lower asymptote parameter 
#		(default = {beta 5.0 17.0 0.0 1.0})
#	-default_model_dichotomous = Default model used for dichotomous items (default = 3PL).
#	-default_model_polytomous = Default model used for polytomous items (default = GPCM).
proc options {args} {

	# Changing the following values does NOT change the default values.
	# This function must be called with the appropriate argument for
	# a default value to be changed.
	array set options [list -D 1.7 -default_prior_a 0 -base_group 0 -max_iter_optimize 0 \
	-default_prior_b 0 -default_prior_c 0 -missing_resp {.} -default_model_dichotomous 3PL \
	-default_model_polytomous GPCM]

	# set option values from command arguments
	set options_set [command_options options $args "options"]
	
	# only set options that were present as arguments
	foreach opt $options_set {
		switch -glob -- $opt {
			-D {set_default_D $options($opt)}
			-default_prior_* {
				set param [string index $opt 15]
				set prior_type [lindex $options($opt) 0]
				set prior_param [lrange $options($opt) 1 end]
				set_default_prior $param $prior_type $prior_param
			}
			-default_model_dichotomous {
				set_default_model_dichotomous $options($opt)
			}
			-default_model_polytomous {
				set_default_model_polytomous $options($opt)
			}
			-missing_resp {
				set_missing_resp $options($opt)
			}
			-base_group {
				set_base_group $options($opt)
			}
			-max_iter_optimize {
				set max $options($opt)
				foreach i [seq 1 [num_items]] {
					mstep_max_iter $i $max
				}
			}
		}
	}
	
}

# Initialize information for items and latent variable distribution
#
# nitems
#	Total number of test items
#
# optional arguments
#	-models = List containing an integer for each item indicating the model to use for the item, where
#		1 = dichotomous model, >1 = polytomous model with that number of response categories.
#		(default = a dichotomous model is used for all items)
#	-models_str = String in which each character is an integer giving the model for each item
#		as in the -models argument. If this argument is present it overrides the -models argument.
#		This argument is only useful when all items have less than 10 response categories,
#		so the number of response categories can be represented with a single character.
# 	-num_latent_dist_points = Number of discrete theta points used for latent distribution (default = 40)
# 	-num_groups = Number of groups for multiple group estimation (default = 1)
#	-latent_dist_range = List giving minimum and maximum points of discrete latent variable distribution
#		(default = {-4 4})
#	-unique_points = If nonzero then different latent distribution points are used for
#		different examinee groups (default = 0)
proc allocate_items_dist {nitems args} {
	global icl_output
	global icl_logfileID
	
	# check that number of items is an integer
	if {[regexp {^\d+$} $nitems] == 0} then {
		error "Invalid value for number of items in allocate_items_dist: $nitems"
	}

	# default values for options
	array set options [list -models [rep 1 $nitems] -models_str {} -num_latent_dist_points 40 -num_groups 1 -latent_dist_range {-4 4} -unique_points 0]
	
	# set option values from command arguments
	command_options options $args start_run
	
	# check that values for options are positive integers
	if {[regexp {^\d+$} $options(-num_latent_dist_points)] == 0} then {
		error "Invalid value for option -num_latent_dist_points in irt_start: $options(-num_latent_dist_points)"
	}
	if {[regexp {^\d+$} $options(-num_groups)] == 0} then {
		error "Invalid value for option -num_groups in allocate_items_dist: $options(-num_groups)"
	}
	
	# Get model for each item from -models_str argument if it was used
	if {$options(-models_str) != ""} then {
		set options(-models) [split $options(-models_str) {}]
	}
	
	new_items_dist $nitems $options(-num_latent_dist_points) $options(-num_groups) $options(-models) $options(-latent_dist_range) $options(-unique_points)
	
	# print initial text to log file
	if {$icl_output(-no_print) == 0} then {
	
		global icl_version
		
		set ofile $icl_logfileID
	
		puts $ofile {IRT Command Language (ICL)}
		puts $ofile "Version $icl_version\n"
		puts $ofile "[clock format [clock seconds] -format {%b %d, %Y %H:%M}]\n"
		
		# print command file
		set commandfile [info script]
		if {$commandfile != {}} then {
			set divider [string repeat - 70]
			puts $ofile "Command file $commandfile"
			puts $ofile $divider
			
			if [catch {open $commandfile} fileId] {
				error "Cannot open $commandfile"
			}
	
			while {[gets $fileId line] != -1} {
				puts $ofile $line
			}
			
			close $fileId
			
			puts $ofile "$divider\n"

		}
		
		# print number of items, number of latent variable points, and number of groups
		puts $ofile "Number of items: $nitems"
		puts $ofile "Number of latent variable points: $options(-num_latent_dist_points)"
		puts $ofile "Number of examinee groups: $options(-num_groups)\n"
		
		# print default priors for item parameters
		foreach p {a b c} {
			puts $ofile "Default prior for $p-parameters:"
			puts $ofile [format_prior_str [get_default_prior_type $p] [get_default_prior_param $p]]
		}
		puts $ofile {}
	}
	
}

# Release memory allocated in allocate_items_dist
proc release_items_dist {} {
	global icl_logfileID
	global icl_output

	if {$icl_logfileID != "stdout"} {
		close $icl_logfileID
		set icl_logfileID stdout
		set icl_output(-log_file) stdout
	}
	
	delete_items_dist
	
}

# Set command options based on argument list given
# to command. An option name begins with a hyphen
# and can have one argument given by the next value
# in the list. If the option name is the last
# item in the list or the next item is a valid
# option name then the value of the option is
# set to one, otherwise the value of the option
# is the next item in the command argument list.
# Returns list of options that were set.
# 
# opt_array
#	Name of array containing default option values. On exit
#	default values may be overriden with values from command
#	arguments.
#
# args
#	List containing arguments passed to command which contains
#	options to set.
#
# command
#	Name of command for which options are set.
proc command_options {opt_array args command} {
	upvar $opt_array options
	
	set options_set [list]

	for {set i 0} {$i < [llength $args]} {incr i} {
	
		# check that current element of command argument list is
		# a valid option
		set a [lindex $args $i]
		if {![info exists options($a)]} then {
			error "Invalid option to $command command: $a"
		}
		
		# get next item in list
		set ap1 [lindex $args [expr {$i+1}]]
		if {$ap1 == {} || [info exists options($ap1)]} then {
			# if next item is valid option assign 1 to option
			set options($a) 1
			lappend options_set $a
		} else {
			# if next item is not a valid option assume it
			# is the argument that should be assigned to this option
			incr i
			set options($a) $ap1
			lappend options_set $a
		}
	}
	
	return $options_set
}

# Return list of messages from last optimization procedure
# used for all items
proc mstep_messages {itemno} {
	set message_list [list]
	foreach i $itemno {
		lappend message_list [mstep_message $i]
	}
	
	return $message_list
}


# Tcl wrapper for item_3PL_starting_values that handles errors
#
# optional arguments
#	-items = list of item numbers for which starting values are to be computed 
#			 All these items must be modeled by the 3PL, 2PL, or 1PL model 
#			 (default = all 3PL items).
#
#	-use_all = If non-zero all examinees and items are used to compute initial thetas
#		       used for starting values, even examinees who get all items correct or
#		       all items incorrect (default = 0).
#
# 	-ignore_error = If zero program will stop if an error occurred in computing starting values,
#					 otherwise the error is just reported and the program continues (default = 0).
proc starting_values_dichotomous {args} {

	# default values for command options
	array set opt {-items {} -use_all 0 -ignore_error 0}
	
	# set options
	command_options opt $args starting_values
	
	if {$opt(-items) == {}} then {
		set e [item_3PL_starting_values $opt(-use_all)]
	} else {
		set e [$item_3PL_starting_values $opt(-use_all) 0 $opt(-items)]
	}
	
	# assign list of item numbers for which errors occurred
	# in computing starting values
	set err_maxiter [list]
	set err_other [list]
	if {$opt(-items) == {}} then {set opt(-items) [seq 1 [num_items]]}
	foreach i $opt(-items) {
		set err [mstep_message $i]
		if {$err < 0 || $err >= 4} then {
			if {$err == 4} then {
				lappend err_maxiter $i
			} else {
				lappend err_other $i
			}
		}
	}
	
	if {[llength $err_maxiter] > 0} then {
		puts_log "Maximum number of iterations exceeded in computing starting values for items:"
		puts_log $err_maxiter
	}
	
	if {[llength $err_other] > 0} then {
		puts_log "Minimization procedure used to compute starting values failed for items:"
		puts_log $err_other

		if {$opt(-ignore_error) != 0} then {
			error "Starting values not computed for $e items in command starting_values"
		}
	}
	
}

# Compute M-step for items.
# Returns maximum relative difference in parameter from last iteration
# to current interation.
#
# Optional arguments
#
#	-items 
#		List of item numbers for items to perform M-step for (default = all items)
#	-no_max_iter_error
#		If non-zero then an error in the optimization performed in the M-step
#		is not considered an error and the calculation will continue.
proc mstep_item_param {args} {

	# default values for options
	array set options [list -no_max_iter_error 0 -items {}]
	
	# set options
	command_options options $args mstep_item_param
	
	if {$options(-items) == {}} then {
		set error_item [mstep_items $options(-no_max_iter_error)]
	} else {
		set error_item [mstep_items $options(-no_max_iter_error) $options(-items)]
	}

	if {$error_item > 0} then {
		set message [mstep_message $error_item]
		error "M-step failed for item $error_item with error number $message"
	}
	
	# Display item number for which maximum number of iterations was exceeded
	if {$error_item < 0} then {

		if {$options(-items) == {}} then {set options(-items) [seq 1 [num_items]]}
		set err_maxiter [list]
		foreach i $options(-items) {
			set err [mstep_message $i]
			if {$err == 4} then {
				lappend err_maxiter $i
			}
		}
		
		if {[llength $err_maxiter] > 0} then {
			puts_log "Maximum number of iterations exceeded in M-step calculation for items:"
			puts_log $err_maxiter
		}
	}
	
	return [mstep_max_diff]

}

# Compute M-step for latent distributions
# Returns maximum relative difference in latent distribution probabilities
# from last iteration to current iteration.
#
# Optional arguments.
#
# -estim_base_group
#	If non-zero estimate latent distribution for the base group
#
# -scale_points
#	If non-zero then scale points of latent distribution so mean and
#	s.d. in base group are 0 and 1, and correspondingly scale
#	item parameter estimates in multiple group estimation. This option only has an effect
#	when the -estim_base_group option is used.
proc mstep_latent_dist {estep_obj args} {

	# default values for options
	array set options [list -estim_base_group 0 -scale_points 0]
	
	# set options
	command_options options $args mstep_latent_dist
	
	set relddiff -1.0

	# Compute M-step for discrete latent variable distribution in base group
	if {$options(-estim_base_group) != 0} then {
		set relddiff [mstep_dist $estep_obj [get_base_group]]
		
		# Tranform latent variable scale so that mean and
		# s.d. of latent variable for base group are 0 and 1.
		# The points of the latent variable distribution are
		# changed to reflect the new scale as are the item
		# parameter estimates.
		if {$options(-scale_points) != 0} then {
			standardize_scale 0.0 1.0 [get_base_group]
		}
	}
	
	# Estimate distributions for group 2 through last group
	if {[num_groups] > 1} then {
		for {set j 1} {$j <= [num_groups]} {incr j} {
			if {$j != [get_base_group]} then {
				set tdiff [mstep_dist $estep_obj $j]
				if {$tdiff > $relddiff} then {set relddiff $tdiff}
			}
		}
	}
	
	return $relddiff
}

# Compute M-step to estimate mean and standard deviation of latent distributions.
# Returns maximum relative difference in the latent distribution means
# from last iteration to current iteration.
#
# Optional arguments
#
# -mean_only
#	If non-zero only estimate the latent distribution means, not the standard deviations
#
# -estim_base_group
#	If non-zero estimate latent distribution for the base group
proc mstep_latent_dist_moments {estep_obj args} {

	# default values for options
	array set options [list -mean_only 0 -estim_base_group 0]
	
	# set options
	command_options options $args mstep_latent_dist_moments
	
	# If only one group then there is nothing to estimate
	set ngroups [num_groups]
	if {$ngroups == 1} return {}
	
	# initialize differences
	set meandiff 0
	set sddiff 0
	
	# list of indices for latent distribution points
	set point_list [seq 1 [num_latent_dist_points]]

	# Compute M-step for discrete latent variable distribution in each group
	for {set g 1} {$g <= $ngroups} {incr g} {
	
		# skip base group
		if {$g == [get_base_group] && $options(-estim_base_group) == 0} continue
		
		# Compute moments based on original points
		set moments [dist_mean_sd $g]
		set oldmean [lindex $moments 0]
		set oldsd [lindex $moments 1]
		
		# store original probabilities for group
		set oldprob [dist_get_probs $g]
		
		# M-step for probabilities
		mstep_dist $estep_obj $g
		
		# Compute moments based on new probabilities
		set moments [dist_mean_sd $g]
		set mean [lindex $moments 0]
		set sd [lindex $moments 1]
		
		# Compute difference in old and new mean
		set diff [expr {abs($mean-$oldmean)}]
		if {$diff > $meandiff} {set meandiff $diff}
		
		# Compute difference in old and new s.d.
		if {$options(-mean_only) == 0} {		
			set diff [expr {abs($sd-$oldsd)}]
			if {$diff > $sddiff} {set sddiff $diff}
		}
		
		# compute slope and intercept to transform points
		# so distribution has new mean and s.d.
		if {$options(-mean_only) != 0} {
			set slope 1.0
		} else {
			set slope [expr {$sd/$oldsd}]
		}
		set intercept [expr {$mean - $slope * $oldmean}]
		
		# transform points for group distribution
		foreach i $point_list {
			set oldpoint [dist_get_point $i $g]
			dist_set_point $i [expr {$oldpoint*$slope + $intercept}] $g
		}
		
		# restore original probabilities for group
		dist_set_probs $oldprob $g

	}

	return [format {%.6f %.6f} $meandiff $sddiff]
}

# Return string containing formatted information about one EM step
#
# iter - Iteration number
# reldiff 	Maximum relative difference between item parameters in current and
# 			previous iterations.
#
# loglike	Marginal posterior mode at current parameter values
#
# relddiff	Maximum relative difference in latent distribution probabilities,
#			means, or s.d's between current and previous iterations.
proc format_iter_str {iter reldiff loglike {relddiff {}}} {

	set iter_str [format {%5d: %.6f} $iter $reldiff]
	if {$relddiff > 0.0} then {
		foreach diff $relddiff {
			append iter_str [format {  %.6f} $diff]
		}
	}
	append iter_str [format {  %.4f} $loglike]
	
	return $iter_str
}
	

# Perform EM iterations until convergence criterion is satisfied.
# Returns a list containing:
#	1. 	The number of iterations used.
# 	2. 	The maximum difference between a parameter estimate from the last 
#		and second to last iteration.
#	3.	If the latent distribution is estimated, the maximum difference
#		between a probability from the last and second to last iteration.
#	4.	If the mean of the latent distribution is estimated, the maximum
#		difference between the mean from the last and second to last iteration.
#	5.	If the mean and s.d. are estimated, the maximum differences in the
#		s.d. between the last and second to last iteration.
#	6.	The value of the marginal posterior at the value of the parameter estimates
#		(this is the quantity being maximized by the EM algorithm).
#
#	Only one of 3, 4, and 5 are printed. Which is printed depends on the
#	options used.
#
#
# optional arguments
# 	-estim_dist = if non-zero estimate latent variable distribution in base group (default = 0)
# 	-max_iter n = Set maximum number of EM iterations to n (default = 100)
# 	-crit d = Set stopping criterion to d (default = 0.001)
# 	-no_print_iter = If non-zero do not print information about each iteration to stdout (default = 0)
#	-no_initial_estep = If non-zero do not compute one E-step before loop over EM iterations (default = 0)
#	-scale_points = If non-zero points of latent distribution for the base group are scaled so the mean
#		is zero and s.d. is one after the weights are estimated in multiple group estimation. The
#		item parameter estimates are also rescaled using the same scale transformation.
#		This option only has an effect if the -estim_dist option is used.
#	-no_mstep_iter_error = If non-zero then an error of the maximum of iterations being
#		exceeded in the optimization performed in the M-step
#		is not considered an error and the calculation will continue.
#	-estim_dist_mean_sd = If non-zero then the mean and standard deviation of the latent
#		variable distributions for all groups except the base group are estimated rather
#		than the discrete probabilities. To use this option the -unique_points option
#		must be used with allocate_items_dist.
#	-estim_dist_mean = If non-zero then the mean of the latent
#		variable distributions for all groups except the base group are estimated rather
#		than the discrete probabilities. The standard deviation is not estimated.
#		To use this option the -unique_points option
#		must be used with allocate_items_dist.
proc EM_steps {args} {
	global icl_output
	global icl_logfileID
	
	# default values for options
	array set options [list -max_iter 100 -crit 0.001 -estim_dist 0 -no_print_iter 0 -no_initial_estep 0 \
		-scale_points 0 -no_mstep_iter_error 0 -estim_dist_mean_sd 0 -estim_dist_mean 0]
	
	# set options
	command_options options $args EM_steps
	
	# check -max_iter is a positive integer
	if {[regexp {^\d+$} $options(-max_iter)] == 0} then {
		error "Invalid value for option -max_iter in EM_steps: $options(-max_iter)"
	}
	
	# check that -crit is a positive real number
	if {[regexp {\d*\.\d+(e\-?\d+)?} $options(-crit)] == 0} then {
		error "Invalid value for option -crit in EM_steps: $options(-crit)"
	}
	
	# check that unique distribution points have been specified if the
	# -estim_dist_mean_sd or -estim_dist_mean options have been specified
	if {$options(-estim_dist_mean_sd) != 0 || $options(-estim_dist_mean) != 0} {
		if {[dist_unique_points] == 0} {
			error "The -unique_points option must be used with allocate_items_dist in order to use -estim_dist_mean_sd or -estim_dist_mean"
		}
	}

	# create estep object using all items
	set estep_obj [new_estep]

	# first E-step
	if {$options(-no_initial_estep) == 0} then {
		estep_compute $estep_obj
	}

	# Print header for iteration output
	if {$icl_output(-no_print) == 0} then {
		puts $icl_logfileID "\nEM iterations"
		if {$options(-estim_dist_mean) != 0 || $options(-estim_dist_mean_sd) != 0} {
			puts $icl_logfileID "(iteration: parameter criterion, mean criterion, sd criterion, marginal posterior mode)"
		} elseif {$options(-estim_dist) != 0 || [num_groups] > 1} {
			puts $icl_logfileID "(iteration: parameter criterion, dist criterion, marginal posterior mode)"
		} else {
			puts $icl_logfileID "(iteration: parameter criterion, marginal posterior mode)"
		}
	}
	# EM iterations
	for {set iter 1} {$iter <= $options(-max_iter)} {incr iter} {

		# M-step for item parameters
		set reldiff [mstep_item_param -no_max_iter_error $options(-no_mstep_iter_error)]
		
		# M-step for discrete latent variable distribution
		if {$options(-estim_dist_mean) != 0 || $options(-estim_dist_mean_sd) != 0} {
			# Estimate only mean and s.d. of distribution 
			set relddiff [mstep_latent_dist_moments $estep_obj -mean_only $options(-estim_dist_mean) \
				 -estim_base_group $options(-estim_dist)]		
		} else {
			# Estimate latent distribution probabilities
			set relddiff [mstep_latent_dist $estep_obj -estim_base_group $options(-estim_dist) \
				-scale_points $options(-scale_points)]
		}

		# next E-step
		set loglike [estep_compute $estep_obj]
		
		# string containing information about iteration
		set iter_str [format_iter_str $iter $reldiff $loglike $relddiff]
			
		# print information for iteration
		if {$icl_output(-no_print) == 0} then {

			# write string to log file
			puts $icl_logfileID $iter_str
			
			# if log file is not stdout then also write string to stdout
			if {$icl_logfileID != "stdout" && $options(-no_print_iter) == 0} {
				puts $iter_str
			}
		}
		
		if {$reldiff < $options(-crit)} then break
	}

	if {$icl_output(-no_print) == 0} then {
		# Report warning if convergence criterion not met
		if {$reldiff >= $options(-crit)} then {
			puts $icl_logfileID "\nConvergence criterion not met after $options(-max_iter) EM iterations"
		}
		# Print blank like after iteration output
		puts $icl_logfileID {}
	}

	delete_estep $estep_obj
	
	# Return iteration string with leading spaces and : removed
	return [string map {: {}} [string trimleft $iter_str]]
	
}

# Set priors on one parameter for a set of items
#
# item_param
#	Index of parameter to set priors for. The association of
#	indices with parameters for the various models is:
#	3PL - 1 (a), 2 (b), 3 (c)
#	2PL - 1 (a), 2(b)
#	1PL - 1 (b)
#	GPCM - 1 (a), 2 (b1), 3 (b3), etc.
#	PCM - 1 (b1), 2 (b2), etc.
#
# type
#	Type of prior (normal, lognormal, beta, none)
#
# prior_params
#	List of parameters for prior
#
# itemnos
#	Item numbers to set prior for (default is all items)
proc items_set_prior {item_param type {prior_params {}} {itemnos {}}} {
	
	if {[llength $itemnos] == 0} then {set itemnos [seq 1 [num_items]]}
	foreach i $itemnos {
		item_set_prior $item_param $i $type $prior_params
	}
}


# Return a list of field positions (zero offset) from a format list.
# Each element of the format list is of one of three forms:
#	@#, where # is an integer
#	i#, where # is an integer
#   di#, where d and # are integers, not necessarily equal
#
# @# means to move to column # (one offset)
# i# indicates an integer to be read at the current position from # columns
# di# indicates d consecutive integers to be read at the current position,
#     where each integer is contained in # columns
proc field_pos {format} {
	set offsets [list]
	set start 0
	foreach i $format {
		if {[regexp {@(\d+)} $i match offset]} {
			set start [expr $offset-1]
		} elseif {[regexp {^[iIaA](\d+)} $i match len]} {
			lappend offsets $start
			incr start $len
		} elseif {[regexp {(\d+)[iIaA](\d+)} $i match rep len]} {
			for {set j 1} {$j <= $rep} {incr j 1} {
				lappend offsets  $start
				incr start $len
			}
		} else {
			error "Invalid format"
		}
	}
	return $offsets
}

# Return a list of field lengths from a format list.
# Each element of the format list is of one of three forms:
#	@#, where # is an integer
#	i#, where # is an integer
#   di#, where d and # are integers, not necessarily equal
#
# @# means to move to column #
# i# indicates an integer to be read contained in # columns
# di# indicates d consecutive integers each contained in # columns
proc field_len {format} {
	set lengths [list]
	foreach i $format {
		if {[regexp {@(\d+)} $i match offset]} {
			continue
		} elseif {[regexp {^[iIaA](\d+)} $i match len]} {
			lappend lengths $len
		} elseif {[regexp {(\d+)[iIaA](\d+)} $i match rep len]} {
			for {set j 1} {$j <= $rep} {incr j 1} {
				lappend lengths  $len
			}
		} else {
			error "Invalid format"
		}
	}
	return $lengths
}


# Read item responses and group (if the number of groups is greater than one)
# for all examinees from an open I/O channel returned by the Tcl open command.
# Read records until the end of file is reached or until a blank line is read.
# Returns the number of examinees read.
#
# Arguments are the same as for read_examinees
#
proc read_examinees_channel {fileId respformat {groupformat 0}} {

	set flen [field_len $respformat]
	set fpos [field_pos $respformat]
	if {[llength $fpos] != [num_items]} then {
		error "Invalid format for item responses"
	}

	if {$groupformat != 0} then {
		set glen [field_len $groupformat]
		set gpos [field_pos $groupformat]
		if {[llength $gpos] != 1} then {
			error "Invalid format for group"
		}
	} elseif {[num_groups] != 1} {
		error "No input format given for examinee group"
	}
		
	set n 0
	while {[gets $fileId line] > 0} {
		# Stop if a blank line is read
		if {$line == {}} break
		set group 1
		if {$groupformat != 0} {set group [string range $line $gpos [expr {$gpos+$glen-1}]]}
		add_examinee [get_responses $line $fpos $flen] $group
		incr n
	}
	
	return $n
	
}

# Read item responses and group (if the number of groups is greater than one)
# for all examinees.
# Returns the number of examinees read.
#
# file			
#	File to read from
#
# respformat	
#	Format string indicating which columns of the input
#	record to read responses from. Format string can contain
#		@#, where # is an integer, which indicate to move to column #
#		i#, where # is an integer, which means to read an integer contained in # columns
#		di#, where # and d are integers, which means read d consecutive integers
#		each contained in # columns
#
# groupformat
#	Format string indicating which columns of the input record to read group
#	number from. Same syntax as respformat.
proc read_examinees {filename respformat {groupformat 0}} {
	global icl_output
	global icl_logfileID
		
	if [catch {open $filename} fileId] {
		error "Cannot open $file in read_examinees"
	}
	
	set n [read_examinees_channel $fileId $respformat $groupformat]
	
	if {$icl_output(-no_print) == 0} then {
		puts $icl_logfileID "Read $n examinee records from file $filename"
	}

	close $fileId
	
	return $n
}


# Read item responses and group (if the number of groups is greater than one)
# from an I/O channel returned by the Tcl open command
# for all examinees, where responses to only some items are contained in the
# input records. The responses to the remaining items are assumed to be missing.
# Returns the number of examinees read.
#
# fileID			
#	Identifier for an I/O channel returned by the Tcl open command.
#
# formFmt
#	Format string indicating which columns containing form on input record
#	If formFmt is an integer then that integer is used as the form for all
#	examinees rather than the form being read from the input record.
#	The format string can contain
#		@#, where # is an integer, which indicate to move to column #
#		i#, where # is an integer, which means to read an integer contained in # columns
#		di#, where # and d are integers, which means read d consecutive integers
#		each contained in # columns
#
# itemNos
#	Name of array containing the item numbers to be read for the examinees
#	for each form. Index of the array is a form and the values of the array
#	are lists of item numbers for each form.
#
# respFmt
#	Name of array containing formats used to read item reponses for each
#	form. Index of the array is a form and the values are format strings
#	used to read item responses for each form.
#	
# groupFmt
#	Format string indicating which columns of the input record to read group
#	indicator from.
#	If groupFmt is an integer then that integer is used as the group for all
#	examinees rather than the group being read from the input record.
#
# groupConv
#	Name of array that converts group indicator read from input record
#   to integer group number.
proc read_examinees_missing_channel {fileID formFmt itemNos respFmt {groupFmt 1} {groupConv {}}} {

	upvar $itemNos items
	upvar $respFmt formats
	if {$groupConv != {}} {upvar $groupConv groups}
	
	# Set up arrays giving positions and lengths of
	# item responses for each form
	foreach f [array names items] {
		set itemPos($f) [field_pos $formats($f)]
		set itemLen($f) [field_len $formats($f)]

		# check that the correct number of item responses are indicated in
		# format string
		if {[llength $itemPos($f)] != [llength $items($f)]} {
			error "Number of items in format string does not match number of items indicated for form $f"
		}
	}
	
	# Set beginning and ending positions of group
	# in input record, unless groupFmt is an integer
	# in which case use that integer as the group
	# for all examinees read
	if {[string is integer $groupFmt] == 0} {
		set groupBeg [field_pos $groupFmt]
		if {[llength $groupBeg] != 1} {
			error "Invalid group format in read_examinees_missing_channel"
		}
		set groupEnd [expr {$groupBeg+[field_len $groupFmt]-1}]
	} else {
		# groupBeg == -1 indicates group for all examinees is
		# given in groupFmt and is not read from record
		set groupBeg -1
	}
	
	# Set beginning and ending positions of form
	# in input record, unless formFmt is an integer
	# in which case use that integer as the form
	# for all examinees read
	if {[string is integer $formFmt] == 0} {
		set formBeg [field_pos $formFmt]
		if {[llength $formBeg] != 1} {
			error "Invalid form format in read_examinees_missing_channel"}
		set formEnd [expr {$formBeg+[field_len $formFmt]-1}]
	} else {
		# formBeg == -1 indicates the form for all examinees is
		# an integer given in formFmt and is not read from record
		set formBeg -1
	}
	
	# List containing item numbers for all items
	set allItemNos [seq 1 [num_items]]
	
	# loop over records in file
	set n 0
	while {[gets $fileID line] > 0} {
		
		# Stop if a blank line is read
		if {$line == {}} break

		incr n

		# Read examinee group
		if {$groupBeg == -1} then {
			set group $groupFmt
		} else {
			set group [string range $line $groupBeg $groupEnd]
			if {$groupConv != {}} {
				if {[info exists groups($group)] != 1} {
					error "Invalid group $group for record $n"
				}
				set group $groups($group)}
		}
		
		# Read form
		if {$formBeg == -1} then {
			set form $formFmt
		} else {
			set form [string range $line $formBeg $formEnd]
		}
		
		if {[info exists items($form)] != 1} {
			error "Invalid form $form for record $n"
		}
		
		# read item responses from line
		set allResp [get_responses_missing $line $itemPos($form) $itemLen($form) $items($form)]
		
		# add examinee to data set
		add_examinee $allResp $group
	
	}
	
	return $n
	
}

# Read item responses and group (if the number of groups is greater than one)
# for all examinees where responses to only some items are contained in the
# input records. The responses to the remaining items are assumed to be missing.
# Returns the number of examinees read
#
# filename
#	File to read item responses from
#
# The remaining arguments are the same as those for the read_examinees_missing_channel command
proc read_examinees_missing {filename formFmt itemNos respFmt {groupFmt 1} {groupConv {}}} {
		
	upvar $itemNos items
	upvar $respFmt formats
	upvar $groupConv groups

	global icl_output
	global icl_logfileID
	
	if [catch {open $filename} fileId] {
		error "Cannot open $filename in read_examinees"
	}
	
	set n [read_examinees_missing_channel $fileId $formFmt items formats $groupFmt groups]
	
	if {$icl_output(-no_print) == 0} then {
		puts $icl_logfileID "Read $n examinee records from file $filename"
	}

	close $fileId
	
	return $n
}


# join elements of list into a string using C sprintf-type format
#
# list
#	List whose elements are to be joined.
#
# sep
#	Character used to separate element in 'list'.
#
# format
#	sprintf format used to format each element of 'list' in output string.
proc joinf {list sep format} {
	set s {}
	set result {}
	foreach x $list {
		append result  $s [format $format $x]
		if {$s != $sep} then {set s $sep}
	}
	return $result
}

# Print item parameters for all items to an I/O channel opened by
# the Tcl open command.
# Item parameters for each item are printed on a separate line
# For each item the item number is printed followed by the parameters
# in the order returned by item_get_all_params. Optionally, the
# model associated with the item (3PL, 2PL, 1PL, GPCM, PCM) is printed between the item
# number and first parameter. The elements on
# each line are separated by a tab character.
#
# fileID
#	Opened I/O channel to write item parameters to
#
# Optional arguments
# -format cformat
#	Specify C sprintf-like format used when writing parameters: 
#	%[width][.prec]char, where char = f, e, or g (default = %.6f)
#
# -item_model
#	If present and non-zero then the item model is printed between the item
#	number and first parameter for each item.
#
# -items itemnos
#	Specify list of item numbers for items to be printed (default is to print parameters
#	for all items)
#
# -no_item_numbers
#	If present item numbers are not written before the parameters on each line
proc write_item_param_channel {fileID args} {

	# default values for options
	array set options [list -format 0 -item_model 0 -items 0 -no_item_numbers 0]
	
	# set options
	command_options options $args write_item_param_channel
	
	# If no item list of item numbers is specified set use all items
	if {$options(-items) == 0} then {
		set options(-items) [seq 1 [num_items]]
	}
	
	# If no format specified set default format
	if {$options(-format) == 0} then {
		set options(-format) %.6f
	}
	
	# write item parameters
	foreach i $options(-items) {
		if {$options(-no_item_numbers) == 0} then {
			set name [item_get_name $i]
			puts -nonewline $fileID "$name\t"
		}
		if {$options(-item_model) != 0} then {
			puts -nonewline $fileID "[item_get_model $i]\t" }
		puts $fileID [joinf [item_get_all_params $i] "\t" $options(-format)]
	}
		
}

# Print item parameters to a file.
# 
# fileName
#	Name of file to write item parameters to
#
# Optional arguments are the same as those for write_item_param_channel
proc write_item_param {fileName args} {

	if {[catch {open $fileName w} fileID]} {
		error "Cannot open $fileName in write_item_param"
	}
	
	if {[llength $args] > 0} then {
		write_item_param_channel $fileID $args
	} else {
		write_item_param_channel $fileID
	}
	
	
	close $fileID

}


# Read item parameters from an open I/O channel returned by the
# Tcl open command.
# Each line read is assumed to contain an item number followed
# by the parameters for that item in the order used by item_set_all_params.
# The elements in each line should be separated by one or more spaces
# and/or tabs.
#
# fileID
#	Opened I/O channel to read item parameters from
#
# -item_model
#	If present then an item model is read between the item
#	number and first parameter for each item. Valid item
#	models are 3PL, 2PL, 1PL, GPCM, and PCM
#
# -no_item_numbers
#	If present then there are no item numbers present before
#	the item parameters on each. The item number is
#	taken to be the same as the line number.
proc read_item_param_channel {fileID args} {
	
	# default values for options
	array set options [list -item_model 0 -no_item_numbers 0]
	
	# set options
	command_options options $args read_item_param_channel
	
	set nline 1
	while {[gets $fileID line] >= 0} {
	
		# If blank line quit
		if {$line == {}} break
	
		# strip leading and trailing blanks
		set line [string trimleft $line]
		set line [string trimright $line]
	
		# Replace sequences of spaces and tabs by a single tab
		regsub -all {[\t\s]+} $line "\t" fline
		
		# put elements of line into a list
		set fields [split $fline "\t"]
		
		# index of first item parameter in list of fields
		set parIndex 0
		
		if {$options(-no_item_numbers) == 0} {
			# get item number (eliminate leading zeros) and parameters
			set itemno [string trimleft [lindex $fields 0] 0]
			if {[string is integer -strict $itemno] == 0} {
				error "Invalid item number: $itemno"
			}
			incr parIndex
		} else {
			set itemno $nline
			if {$itemno > [num_items]} then {
				error "Invalid item number: $itemno"
			}
		}
		incr nline
		
		# get model for item
		if {$options(-item_model) != 0} then {
			set item_model [index $fields $parIndex]
			if {![string equal $item_model [item_get_model $itemno]]} then {
				error "Invalid model for item $itemno:: $item_model"
			}
			incr parIndex
		}

		# assign parameters to item
		set param [lrange $fields $parIndex end]
		if {[catch {item_set_all_params $itemno $param} ierr]} then {
			error "Invalid parameters for item $itemno\n$ierr"
		}
		
	}
		
}

# Read item parameters from a file.
# Each line of the file is assumed to contain an item number followed
# by the parameters for that item in the order used by item_set_all_params.
# The elements in each line should be separated by one or more spaces
# and/or tabs.
#
# filename
#	Name of file to read item parameters from
#
# -item_model
#	If present then an item model is read between the item
#	number and first parameter for each item. Valid item
#	models are 3PL, 2PL, 1PL, GPCM, and PCM
#
# -no_item_numbers
#	If present then there are no item numbers present before
#	the item parameters on each. The item number is
#	taken to be the same as the line number.
proc read_item_param {filename args} {
	
	if {[catch {open $filename} fileID]} {
		error "Cannot open $filename in read_item_param"
	}
	
	if {[llength $args] > 0} then {
		read_item_param_channel $fileID $args
	} else {
		read_item_param_channel $fileID
	}
	
	close $fileID
}

# Print latent variable distribution points and weights for
# selected groups to an I/O channel returned by the Tcl open command.
#
# fileID
#	Opened I/O channel to write latent distribution to
#
# Optional arguments
# -point_format format
#	C sprintf-like format (%[width][.prec]char, where char = f, e, or g)
#	to use for the points (default = %.6f)
#
# -weight_format format
#	C sprintf-like format (%[width][.prec]char, where char = f, e, or g)
#	to use for the weights (default = %.6e)
#
# -groups list
#	List of group numbers of groups for which weights are to be printed
#   (default is to print weights for all groups)
proc write_latent_dist_channel {fileID args} {

	# default values for options
	array set options [list -point_format 0 -weight_format 0 -groups 0]
	
	# set options
	command_options options $args write_latent_dist_channel
	
	# If no weight format specified set default format
	if {$options(-weight_format) == 0} then {
		set options(-weight_format) %.6e
	}
	
	# If no point format specified set default format
	if {$options(-point_format) == 0} then {
		set options(-point_format) %.6f
	}
	
	# If no groups are specified use all groups
	if {$options(-groups) == 0} then {
		set options(-groups) [seq 1 [num_groups]]
	}

	# Distribution for only one group can be written if
	# the distributions for each group have unique points
	if {[llength $options(-groups)] > 1 && [dist_unique_points]} {
		error "The write_latent_dist_channel command cannot be used with more than one group if
different latent distribution points are used for each group"
	}
	
	# Get points for first group
	set points [dist_get_points [lindex $options(-groups) 0]]
	
	# Get weights for each group
	foreach g $options(-groups) {
		set weights($g) [dist_get_probs $g]
	}
	
	set i 0
	foreach p $points {
		# print point
		puts -nonewline $fileID [format $options(-point_format) $p]
		
		#print weights
		foreach g $options(-groups)  {
			puts -nonewline $fileID [format "\t$options(-weight_format)" [lindex $weights($g) $i]]
		}
		puts $fileID {}
		incr i
	}
		
}

# Print latent variable distribution points and weights for
# selected groups.
#
# filename
#	Name of file to write latent distribution to. File is created if
#	it does not exist, and overwritten if it does exist.
#
# Optional arguments are the same as those for write_latent_dist_channel
proc write_latent_dist {filename args} {
	
	if {[catch {open $filename w} fileID]} {
		error "Cannot open $filename in write_latent_dist"
	}
	
	if {[llength $args] > 0} then {
		write_latent_dist_channel $fileID $args
	} else {
		write_latent_dist_channel $fileID
	}
	
	close $fileID
}

# Read points and weights of discrete latent variable distributions
# for all groups of examinees or a single group of examinees from an I/O
# channel returned by the Tcl open command.
# Each line of file is assumed to contain a point value followed
# by the weights corresponding to that point for examinee groups 1,
# 2, ... [num_groups].
# The elements in each line should be separated by one or more spaces
# and/or tabs.
# In the case in which there are different points for different examinee
# groups the same set of points is assigned to all groups.
#
# fileID
#	Open I/O channel to read item parameters from as returned by the Tcl open command.
#
# -group groupno
#	Read points and weights for one group given by groupno. When this option is used
#	the first number on each line is read as a point, and the
#	second number is read as a weight for the group.
proc read_latent_dist_channel {fileID args} {
	
	# default values for options
	array set options [list -group 0]
	
	# set options
	command_options options $args read_latent_dist_channel

	# initialize lists to hold weights
	set groupno $options(-group)
	if {$groupno == 0} then {
		set groupno [seq 1 [num_groups]]
		foreach g $groupno {
			set weights($g) [list]
		}
	} else {
		if {$groupno < 1 || $groupno > [num_groups]} then {
			error "Invalid group number: $groupno"
		}
		set weights($groupno) [list]
	}
	
	# initialize list to hold points
	set points [list]

	for {set i 0} {$i < [num_latent_dist_points]} {incr i} {
	
		if {[gets $fileID line] < 0} {
			error "Not enough lines read for latent variable distribution" }
	
		# Replace sequences of spaces and tabs by a single tab
		regsub -all {[\t\s]+} $line "\t" fline
		
		# put elements of line into a list
		set fields [split $fline "\t"]
		
		# get point
		set point [lindex $fields 0]
		lappend points $point
		
		# get weights
		if {$options(-group) == 0} then {
			set weight [lrange $fields 1 end]
			if {[llength $weight] != [num_groups]} then {
				error "Invalid number of weights for point $point."
			}
		} else {
			set weight [lindex $fields 1]
		}
		
		foreach g $groupno  w $weight {
			lappend weights($g) $w
		}
		
	}
		
	# assign points
	if {[dist_unique_points] != 0} {
		foreach g $groupno {
			dist_set_points $points $g
		}
	} else {
		dist_set_points $points
	}
	
	# assign weights
	foreach g $groupno {
		dist_set_probs $weights($g) $g
	}

}

# Read points and weights of discrete latent variable distributions
# for all groups of examinees or a single group of examinees from a file.
# The format in which the points and weights are read is
# the same as for the read_latent_dist_channel command.
#
# filename
#	Name of file to read item parameters from.
#
# -group groupno
#	Read points and weights for one group given by groupno. When this option is used
#	the first number on each line is read as a point, and the
#	second number is read as a weight for the group.
proc read_latent_dist {filename args} {

	if {[catch {open $filename} fileID]} {
		error "Cannot open $filename in read_latent_dist"
	}
	
	if {[llength $args] > 0} then {
		read_latent_dist_channel $fileID $args
	} else {
		read_latent_dist_channel $fileID
	}
	
	close $fileID
}

# Print selected results to log file
# optional arguments
#	-item_param		Print item parameter estimates for all items
#	-latent_dist	Print discrete latent variable distributions for all groups
#	-latent_dist_moments	Print mean and s.d. of latent variable distributions for all groups
# 	-no_heading		If present do not print heading for item parameter and theta distribution
#	-format			C printf format to use for item parameters, probabilities of latent distributions,
#					and moments
# 	-item_model		If present then the item model is printed between the item
#					number and first parameter for each item.
#	-items			Item numbers for which item parameters are printed (has no effect unless
#					-item_param option is also used).
proc print {args} {
	global icl_logfileID

	# default values for command options
	array set opt {-item_param 0 -latent_dist 0 -latent_dist_moments 0 -no_heading 0 \
		-item_model 0 -format 0 -items 0}
	
	# set options
	command_options opt $args print

	
	if {$opt(-item_param) != 0} {
		if {$opt(-no_heading) == 0} {
			puts $icl_logfileID "Item Parameter Estimates"
			puts $icl_logfileID "(a, b, c for 3PL, 2PL, 1PL; a, b1, b2, ... for GPCM, PCM)"
		}
		write_item_param_channel $icl_logfileID -format $opt(-format) -item_model $opt(-item_model) -items $opt(-items)
		# print blank line
		if {$opt(-no_heading) == 0} {puts $icl_logfileID {}}
	}
			
	if {$opt(-latent_dist) != 0} {
		if {[dist_unique_points] == 0} {
			# Points are the same for all groups so write points followed by
			# weights for all groups
			if {$opt(-no_heading) == 0} {
				puts $icl_logfileID "Discrete Latent Variable Distributions"
				puts $icl_logfileID "(point, probability for group 1, 2, etc)"
			}
			write_latent_dist_channel $icl_logfileID -weight_format $opt(-format)
			# print blank line
			if {$opt(-no_heading) == 0} {puts $icl_logfileID {}}
		} else {
			# Print each distribution separately
			foreach grp  [seq 1 [num_groups]] {
				if {$opt(-no_heading) == 0} {
					puts $icl_logfileID "Discrete Latent Variable Distribution for Group $grp"
				}
				write_latent_dist_channel $icl_logfileID -weight_format $opt(-format) -groups [list $grp]
				# print blank line
				if {$opt(-no_heading) == 0} {puts $icl_logfileID {}}
			}
		}
	}
			
	if {$opt(-latent_dist_moments) != 0} {
		if {$opt(-format) != 0} {set mformat $opt(-format)} {set mformat %.6f}
		set mean [list]
		set sd [list]
		for {set g 1} {$g <= [num_groups]} {incr g} {
			set moments [dist_mean_sd $g]
			lappend mean [lindex $moments 0]
			lappend sd [lindex $moments 1]
			#puts $icl_logfileID "Moments of Latent Variable Distribution for Group $g"
			#puts $icl_logfileID [format "Mean: $mformat  s.d.: $mformat\n" [lindex $moments 0] [lindex $moments 1]]
		}
		puts_log {Moments of Latent Variable Distributions (group 1, 2, etc)}
		puts_log -nonewline "Mean:\t"
		puts_log [joinf $mean "\t" $mformat]
		puts_log -nonewline "s.d.:\t"
		puts_log [joinf $sd "\t" $mformat]
		puts_log {}
		
	}

}

# Print string to log file
# optional argument
#	-nonewline	Do not print newline character at end of line.
#		  		This argument must be the first argument.
proc puts_log {args} {
global icl_logfileID
	if {[llength $args] == 1} {
		puts $icl_logfileID [lindex $args 0]
	} elseif {[llength $args] == 2} {
		puts -nonewline $icl_logfileID [lindex $args 1]
	} else {
		error "Invalid argument to puts_log command"
	}

}

# Return formatted string containing prior distribution
# corresponding to type 'priorType' with parameters
# 'priorParam'
proc format_prior_str {priorType priorParam} {

	switch -glob -- $priorType {
		beta {
			set a [lindex $priorParam 0]
			set b [lindex $priorParam 1]
			set l [lindex $priorParam 2]
			set u [lindex $priorParam 3]
			return [format " beta  a: %-7.3f b: %-7.3f lower limit: %-8.3f upper limit: %-7.3f" \
				$a $b $l $u]
		}
		*normal {
			set mean [lindex $priorParam 0]
			set sd [lindex $priorParam 1]
			return [format " %s  Mean: %-9.3f s.d. %-8.3f" $priorType $mean $sd]
		}
		none {return none}
		default {error "Invalid prior distribution $priorType in format_prior_str"}
	}
}

# Transform scale of latent variable using a specified linear
# transformation. Latent variable points for all groups and item parameters are
# transformed.
#
# Arguments
#	slope		Slope of linear scale transformation.
#	intercept	Intercept of linear scale transformation.
#   ignorePrior If nonzero then do not report an error if a transformed parameter
#			    has zero density in the prior used for that parameter.
proc transform_scale {slope intercept {ignorePrior 0}} {

	# Transform points of latent variable distribution
	dist_transform $slope $intercept

	# Transform item parameters using scale transformation computed
	# for points of latent variable distribution
	foreach j [seq 1 [num_items]] {
		if {[item_scale_params $j $slope $intercept $ignorePrior] != 0} {
			error "Transformation would result in an invalid parameter for item $j"
		}
	}
}

# Standardize scale of latent variable so that the
# mean and standard deviation are equal to specific
# values in one examinee group. Item parameters
# for all items are correspondingly transformed.
# If different latent variable points are used for different
# groups, the points for all groups are transformed to be on the
# new scale.

# Arguments
#	mean	Target mean of latent variable distribution.
#	s.d.	Target standard deviation of latent variable distribution
#	group	Number of group in which mean and s.d. of latent variable distribution
#			should be equal to target values. (1, 2, ...)
#   ignorePrior If nonzero then do not report an error if a transformed parameter
#			    has zero density in the prior used for that parameter.
proc standardize_scale {mean sd {group 1} {ignorePrior 0}} {

	# check for valid s.d.
	if {$sd <= 0} {error "Invalid standard deviation: $sd"}
	
	# Find transformation of points of latent distribution that
	# will give the specified mean and s.d.
	set trans [dist_scale $mean $sd $group]
	set slope [lindex $trans 0]
	set intercept [lindex $trans 1]
	
	# Transform item parameters using scale transformation computed
	# for points of latent variable distribution
	foreach j [seq 1 [num_items]] {
		if {[item_scale_params $j $slope $intercept $ignorePrior] != 0} {
			error "Transformation would result in an invalid parameter for item $j"
		}
	}
	
	# Return slope and intercept of scale transformation
	return [list $slope $intercept]
	
}

# command to set the name of item corresponding to item
# number 'itemno'
proc item_set_name {itemno name} {
	global icl_item_names
	
	set icl_item_names($itemno) $name
}

# command to set names of items corresponding to
# item numbers in 'itemnos'. If 'itemnos' is
# not given then assign names to items 1, 2, ...
proc items_set_names {names {itemnos {}}} {
	global icl_item_names
	
	if {$itemnos != {}} {
		if {[llength $names] != [llength $itemnos]} {
			error "Number of names and item numbers do not match in item_names_set"
		}
		foreach i $itemnos n $names {
			set icl_item_names($i) $n
		}
	} else {
		set i 1
		foreach n $names {
			set icl_item_names($i) $n
			incr i
		}
	}
}

# Return name associated with item with item number 'itemno'
# If name does not exist for that item return item number
proc item_get_name {itemno} {
	global icl_item_names
	
	if {[info exists icl_item_names($itemno)] != 0} {
		set name $icl_item_names($itemno)
	} else {
		set name $itemno
	}
	
	return $name
}


# Return a list that contains one value repeated a certain number of times
# value - value contained in list
# number - number of time value is repeated in list (size of list)
proc rep {value number} {
	return [split [string repeat $value $number] {}]
}

# Return a list containing an increasing sequence of numbers.
# first - first number in sequence
# last - largest value such that first + inc*n <= last for any positive n
# inc - increment between consecutive numbers in sequence
proc seq {first last {inc 1}} {
	set sequence [list]
	while {$first <= $last} {
		lappend sequence $first
		incr first $inc
	}
	return $sequence
}