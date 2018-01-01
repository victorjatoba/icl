#
# mergedat.tcl
#
# Combine separate data files mondatx.dat and mondaty.dat for
# Forms X and Y into a single data file (mondat.dat) where each line
# contains the responses of the unique items for Form Y,
# the common items, and the unique items for Form X.
# Responses to items an examinee did not take are indicated
# by a period.


# Convert item responses from file for one form
# to format used for combined file.
#
# Arguments
#   file	Name of file containing item responses for one form
#	outID	Open file channel of output file
#	group	Group number for this data (1 or 2)
proc WriteResponses {file outID group} {

	# try to open input file
	if {[catch {open $file} inId]} {
		error "Cannot open $file"
	}
	
	# set string of missing responses to 24 unique
	# items on the form not taken
	set missing [string repeat . 24]
	
	# read records in input file
	while {[gets $inId line] > 0} {
	
		# initialize strings containing common and
		# unique items
		set common {}
		set unique {}
		
		# put item responses in string allresp
		# item responses are in columns 1-36
		set allresp [string range $line 0 35]
		
		# loop over item responses for separate
		# common and unique items
		set itemno 1
		foreach i [split $allresp {}] {
			if {$itemno % 3 == 0} then {
				append common $i
			} else {
				append unique $i
			}
			incr itemno
		}
		
		# Unique items for form taken by group 1
		# are written first, followed by common items,
		# then unique items for form taken by
		# group 2
		puts -nonewline $outID $group
		if {$group == 1} then {
			puts $outID "$unique$common$missing"
		} else {
			puts $outID "$missing$common$unique"
		}
	}
	
	close $inId
}

# open output file
if {[catch {open mondat.dat w} out]} {
	error "Could not open output file"
}

# write Form Y data
WriteResponses mondaty.dat $out 1

# write Form X data
WriteResponses mondatx.dat $out 2

# close output file
close $out