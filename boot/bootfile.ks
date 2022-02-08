//General boot file for all crafts.
//Actual instructions to be written in update_<ship name>_<core tag>.ks

@LAZYGLOBAL OFF.

wait until ship:unpacked and ship:loaded.
//core:doaction("open terminal", true).

// local flist is list().
// list FILES in flist.

print "Checking for connection to KSC.".
if not HOMECONNECTION:ISCONNECTED {
    print "No connection. Waiting.".
    wait until HOMECONNECTION:ISCONNECTED.
}

if not(exists("/library")) {
    createDir("/library").
}
copyPath("0:/library/lib_manoeuvre.ks", "library/").
copyPath("0:/library/lib_navigation.ks", "library/").
copyPath("0:/library/lib_utilities.ks", "library/").
copyPath("0:/library/lib_math.ks", "library/").

copyPath("0:/launch.ks", "launch.ks").
copyPath("0:/landing.ks", "landing.ks").
copyPath("0:/ny167/node.ks", "node.ks").

print "Files copied.".
// switch to 0.

if Career():CANDOACTIONS {
    core:doaction("open terminal", true).
}

switch to 0.
