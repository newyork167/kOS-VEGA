declare parameter FairingDeployment is false, TargetAltitudeKm is 75,RelativeInclinationDegr is 0, FairingDeploymentAltitudeKm is 60.

set PitchStartVelocity to 100.			//custom value
set TargetRoll to ship:facing:roll +90.
set TargetAltitude to TargetAltitudeKm*1000.
set FairingDeploymentAltitude to FairingDeploymentAltitudeKm*1000.
set RelativeInclination to RelativeInclinationDegr.
set running to true.

clearscreen.

//display info
when running = true then {
	print "Altitude: "+round(altitude)+" m       " at(0,3).
	print "Apoapsis: "+round(apoapsis)+" m       " at (0,4).
	print "Pitch: "+round(90-vang(ship:up:forevector,ship:facing:forevector))+" degrees       " at(0,5).
	print "Orbital velocity: "+round(ship:velocity:orbit:mag)+" m/s       " at (0,6).
	print "Running: uAscent" at (0,8).
    preserve.
}


sas off.
set throttle to 1.

if maxthrust = 0 {
	stage.
}

// Handle launch clamp disengage
set n to 1.
local launchClampStage is 999.
local launchClampDisengaged is false.
FOR p in SHIP:PARTS {
    IF p:MODULES:CONTAINS("LaunchClamp") {
        IF launchClampStage = 999 SET launchClampStage TO p:STAGE.
    }
}

if launchClampStage <> 999 {
    print "Launch clamps detected...".
    print "Starting main boosters".
    wait until stage:ready.
    local twr is getShipTWR().

    print "Intial TWR is: " + twr.

    // Wait until TWR >= 1
    until twr >= 1{
        set twr to getShipTWR().
        print "Current TWR: " + twr.
        wait 0.
    }

    print "TWR nominal.".
    print "Disengaging Launch Clamps!".

    // Disengage launch clamps
    STAGE.
    set n to n + 1.
    
    set last_maxthrust to ship:maxthrustat(0).
    set last_stage to stage:number.
    set stageControl to true.
}

//staging
set InitialStageThrust to maxthrust.
when maxthrust<InitialStageThrust then {
	wait 1.
	stage.
		if maxthrust > 0 {
		print "Stage "+n+" separation. Stage "+(n+1)+" ignition." at(0,1).
		set n to n+1.
		set InitialStageThrust to maxthrust.
	}
	preserve.
}


//pitch
set steering to heading((90-RelativeInclination),90,TargetRoll).
print "Ascent Program" at (0,0).

wait until ship:velocity:surface:mag > PitchStartVelocity.
lock TargetPitch to 90-((ship:apoapsis-PitchStartAltitude)*1.4)/((TargetAltitude-PitchStartAltitude)/90).
set PitchStartAltitude to altitude.
lock steering to heading((90-RelativeInclination),TargetPitch,TargetRoll).

wait until TargetPitch < 0.
lock steering to heading(90-RelativeInclination,0,TargetRoll).


//cutoff
wait until ship:apoapsis > TargetAltitude.
	print "Engine cutoff                                  " at(0,1).
	set throttle to 0.
	lock steering to prograde.

	set warpmode to "physics".
	set warp to 3.


//fairing
if FairingDeployment = true {
	wait until ship:altitude > FairingDeploymentAltitude.
		stage.
		print "Fairing deployed                        " at(0,1).
}



wait until ship:q = 0.
	set warp to 0.
	unlock steering.
	lock throttle to 0. unlock throttle.
	set running to false.
	clearscreen.
	set ship:control:pilotmainthrottle to 0.