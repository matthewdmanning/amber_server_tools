set sel [atomselect top "all"]
set minmax [measure minmax $sel]
set center [measure center $sel]
set boxsize [vecsub [lindex $minmax 1] [lindex $minmax 0]]

puts "Output: [lindex $boxsize 0] 0 0"
puts "Output: 0 [lindex $boxsize 1] 0"
puts "Output: 0 0 [lindex $boxsize 2]"
puts "Output: $center"

$sel delete
exit

