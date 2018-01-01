#
# pretest_dat.tcl
#
# Read simulated data for pretest example using
# simulated data from Ban, Hanson, Wang, Yi, & Harris (2000).
# Each simulated examinee received a CAT of 30 operational items
# and 10 pretest items. The 30 operational items 
# were chosen from a pool of 520 items. The 10 pretest
# items were taken by all examinees.
# Each record in the input data set consists of 
# the item numbers of the operational items
# taken by the examinee in columns 15-104 (3 digits per item)
# and the operational item responses in columns 105-134.
# The pretest item responses are in columns 145-154.
# This procedure reads a record for each examinee, creates
# an item response vector of 530 responses for the examinee
# and calls the add_examinee command using the item response
# vector.
# The argument is the file from which to read the data.
proc ReadItemResp {file} {

	# Number of items
	set adminOperItems 30
	set totOperItems 520
	set preItems 10

	# open input file
	if [catch {open $file} fileId] {
		error "Cannot open $file"
	}
	
	# loop over records
	# The gets command reads one record into variable 'line'
	while {[gets $fileId line] > 0} {

		# initialize list of all item
		set allResp [list]
		
		# Read operational item responses
		set posNum 14
		set posResp 104
		for {set i 0} {$i < $adminOperItems} {incr i 1} {
			# Read item number of operational item
			set operItemNo [string range $line $posNum [expr {$posNum+2}]]
			
			# strip leading zeros from item number
			string trimleft $operItemNo 0
			
			# Assign item response for operational item
			# to array itemResp.
			# Change 1 to 0 and 2 to 1
			# (2 indicates a correct response and 1 an
			# incorrect response in the original file)
			set r [string index $line $posResp]
			set itemResp($operItemNo) [string map {1 0 2 1} $r]
			incr posNum 3
			incr posResp
		}
		
		# write operational item responses to list of all responses
		for {set i 1} {$i <= $totOperItems} {incr i} {
			if {[info exists itemResp($i)] == 1} then {
				# add item response to list
				lappend allResp $itemResp($i)
			} else {
				# add -1 indicating the examinee did not respond to the item
				lappend allResp -1
			}
		}
		
		# Remove all elements from itemResp to initialize
		# for next examinee.
		unset itemResp

		# read pretest item responses and add them to
		# list of item responses
		set preResp [string map {1 0 2 1} [string range $line 144 153]]
		set allResp [concat $allResp [split $preResp {}]]
		
		# Add examinee to data used for estimation
		add_examinee $allResp
		
	}
	close $fileId
}
