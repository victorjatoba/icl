#
# mondaty_boot.tcl
#
# Bootstrap item parameter estimates using data mondaty.dat.
# For each bootstrap replication the parameter
# estimates for all items are written to
# one line of the output file.

# Number of bootstrap replications
# Probably should be at least 100 to compute
# standard errors of item parameter estimates.
set nboot 10

# Name of file to contain bootstrap parameter estimates
set boot_file mondaty_boot.out

# Do not print any output to log file
output -no_print

# 36 items
allocate_items_dist 36

# Read item responses from mondaty.dat
read_examinees mondaty.dat 36i1

# Open file to contain parameter estimates
# for each bootstrap sample.
if [catch {open $boot_file w} fileID] {
	error "Could not open $boot_file"
}

# Set seed for random number generator used
# for bootstrap
bootstrap_seed 295736287

# loop over bootstrap replications
foreach b [seq 1 $nboot] {

	# generate bootstrap sample
    bootstrap_sample
    
    # calculate starting values for item parameters
    item_3PL_starting_values
    
    # calculate item parameter estimates
    set niter [EM_steps]
    
    # Print number of EM iterations used for this sample
    puts "Bootstrap sample $b: $niter"

    # write parameter estimates for all items
    # to one line of output file separated by tabs
    foreach i [seq 1 [num_items]] {
        puts -nonewline $fileID \
           [joinf [item_get_params $i] "\t" %.6f]
        if {$i < [num_items]} {
            puts -nonewline $fileID "\t"
        } else {
            puts -nonewline $fileID "\n"}
    }
}

# close output file
close $fileID

# end of run
release_items_dist
