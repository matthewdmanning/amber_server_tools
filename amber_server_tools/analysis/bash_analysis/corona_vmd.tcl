### VMD script for high-throughput analysis of NP ligand corona

# Support functions from http://www.ks.uiuc.edu/Research/vmd/script_library/scripts/geometry/geometry.tcl

proc reset_geometry_cache { } {
  global geometry_molid geometry_segid geometry_cache geometry_frame
  set geometry_molid -1
}

proc set_geometry_cache { molid segid } {
  global geometry_molid geometry_segid geometry_cache geometry_frame
  set frame [molinfo top get frame]
  if { [info exists geometry_molid]
    && [info exists geometry_segid]
    && [info exists geometry_frame] } {
    if { $molid == $geometry_molid
      && $segid == $geometry_segid
      && $frame == $geometry_frame } {
      return
    }
  }
  set geometry_molid $molid
  set geometry_segid $segid
  set geometry_frame $frame

  catch { unset geometry_cache }

  set nz [atomselect $molid "segid $segid and type nz" ]
  set ss [atomselect $molid "segid $segid and type ss" ]
  set gold [atomselect $molid "segid $segid and type Au" ]

  foreach resid [$nz get resid] xyz [$nz get {x y z}] {
    set geometry_cache($resid,nz) $xyz
  }
  foreach resid [$ss get resid] xyz [$ss get {x y z}] {
    set geometry_cache($resid,ss) $xyz
  }
  foreach resid [$gold get resid] xyz [$gold get {x y z}] {
    set geometry_cache($resid,gold) $xyz
  }
}

proc signed_angle { a b c } {
  set amag [veclength $a]
  set bmag [veclength $b]
  set dotprod [vecdot $a $b]

  set crossp [veccross $a $b]
  set sign [vecdot $crossp $c]
  if { $sign < 0 } {
    set sign -1
  } else {
    set sign 1
  }
  return [expr $sign * 57.2958 * acos($dotprod / ($amag * $bmag))]
}

