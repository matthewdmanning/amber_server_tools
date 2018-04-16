# The following "get_first_ts" Tcl procedure is from:
# http://www.ks.uiuc.edu/~timisgro/sample.conf
# http://www.ks.uiuc.edu/Research/namd/mailing_list/namd-l.2003-2004/0600.html

proc get_first_ts {xscfile} {
  set fd [open $xscfile r]
  gets $fd; gets $fd
  gets $fd line
  set ts [lindex $line 0]
  close $fd
  return $ts
}

# "set fd [open $xscfile r]" = open XSC file for reading
# "gets $fd; gets $fd" = read 1st & 2nd lines from channel $fd
# "gets $fd line" = read 3rd line from channel $fd, & set output to variable "l\
ine"
# "close $fd" = close channel $fd
# "return $ts" = return value of $ts from procedure
