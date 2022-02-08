// Script for launching a rocket
// A target orbit can be achieved
@lazyglobal off.

runOncePath("library/lib_manoeuvre.ks").
runOncePath("library/lib_navigation.ks").
runOncePath("library/lib_utilities.ks").

function have_empty_tanks {
    local stage_parts is ship:partstagged("stage on empty").
    local result is false.
    for p in stage_parts {
        if p:mass = p:drymass {
            set result to true.
            break.
        }
    }
    return result.
}

function getTurnParameters {
    parameter target_altitude.

    local altParameter is target_altitude.
    if body:atm:exists {
        // Formula derived using this
        // 70_000  80_000   Kerbin
        // 140_000 200_000  Earth
        local extra_height is (5 * body:atm:height - 280_000) / 7.
        if target_altitude > body:atm:height + extra_height {
            set altParameter to body:atm:height + extra_height.
        }
    } else if target_altitude > 20_000 {
        set altParameter to 20_000.
    }

    local velParameter is sqrt(body:mu / (body:radius + altParameter)).
    return lexicon(
        "altParameter", altParameter,
        "velParameter", velParameter
    ).
}

function verticalAscent {
    parameter launch_params is lexicon(
        "turn_start_speed", 80
    ).

    lock steering to lookdirup(localVertical(), ship:facing:topvector).
    lock throttle to 1.

    wait until ship:velocity:surface:mag > launch_params["turn_start_speed"].
}

function pitchProgram2 {
    parameter launch_params is lexicon(
        "target_altitude", 80_000,
        "target_heading", { return 90. },
        "maintain_twr", 0,
        "steepness", 0.5
    ).

    local twrScale is 1.
    lock throttle to min(twrScale, 1).
    
    local turn_parameters is getTurnParameters(launch_params["target_altitude"]).
    local altParameter is turn_parameters["altParameter"].
    local velParameter is turn_parameters["velParameter"].

    // local tick is time:seconds.
    // lock steering to heading(launch_params["target_heading"]:call(), 90 - (time:seconds - tick), 0). 
    // wait 5.

    until ship:apoapsis > altParameter {
        lock steering to heading(launch_params["target_heading"]:call(), 90-(ship:apoapsis/1000), 0).
    }

    // local throttle_pid is PIDLoop(0.05, 0, 0.01, 0, 1).
    // set throttle_pid:setpoint to 120.
    // until ship:velocity:orbit:mag > velParameter - 1000 {
    //     set twrScale to throttle_pid:update(time:seconds, eta:apoapsis).
    //     wait 0.
    // }

    if body:atm:exists and ship:altitude < body:atm:height {
        local throttlePID is pidLoop(0.0001, 0, 0.00001, 0.001, 1).
        until ship:altitude > body:atm:height - 500 {
            set twrScale to throttlePID:update(time:seconds, ship:apoapsis - altParameter).
            wait 0.
        }
    }

    lock throttle to 0.
    wait 0.
}

function pitchProgram {
    parameter launch_params is lexicon(
        "target_altitude", 80_000,
        "target_heading", { return 90. },
        "maintain_twr", 0,
        "steepness", 0.5
    ).

    local twrScale is 1.
    lock throttle to min(twrScale, 1).
    
    local turn_parameters is getTurnParameters(launch_params["target_altitude"]).
    local altParameter is turn_parameters["altParameter"].
    local velParameter is turn_parameters["velParameter"].

    function altPitch {
        return ship:apoapsis / altParameter.
    }

    function velPitch {
        return vxcl(up:vector, ship:velocity:orbit):mag / velParameter.
    }

    // Initial kick
    local tick is time:seconds.
    lock steering to heading(launch_params["target_heading"]:call(), 90 - (time:seconds - tick), 0). wait 5.

    lock steering to heading(
        launch_params["target_heading"]:call(),
        90 - min(90 * ((altPitch() + velPitch()) / 2) ^ launch_params["steepness"], 2 + vang(localVertical(), surfaceTangent())),
        0
    ).
    until ship:apoapsis > altParameter {
        if launch_params["maintain_twr"] <> 0 {
            local availthrust is ship:availableThrust.
            if availthrust <> 0 {
                set twrScale to launch_params["maintain_twr"] / (availthrust / (ship:mass * constant:g0)).
            }
            else {
                set twrScale to 1.
            }
        }
        wait 0.
    }
    local throttle_pid is PIDLoop(0.05, 0, 0.01, 0, 1).
    set throttle_pid:setpoint to 120.
    until ship:velocity:orbit:mag > velParameter - 1000 {
        set twrScale to throttle_pid:update(time:seconds, eta:apoapsis).
        wait 0.
    }

    if body:atm:exists and ship:altitude < body:atm:height {
        local throttlePID is pidLoop(0.0001, 0, 0.00001, 0.001, 1).
        until ship:altitude > body:atm:height - 500 {
            set twrScale to throttlePID:update(time:seconds, ship:apoapsis - altParameter).
            wait 0.
        }
    }

    lock throttle to 0.
    wait 0.
}

function atmosphereExit {
    lock steering to lookdirup(surfaceTangent(), localVertical()).
    wait until ship:altitude > body:atm:height.
    local discard_parts is ship:partstagged("discard").
    until discard_parts:length = 0 {
        stage.
        wait until stage:ready.
        set discard_parts to ship:partstagged("discard").
        wait until stage:ready.
    }
    wait 1.
}

function circularize {
    parameter launch_params is lexicon(
        "target_altitude", 75_000
    ).
    local targetperi is launch_params["target_altitude"].
    local currentOrbitSpeed is sqrt(body:mu * (2/(body:radius + ship:apoapsis) - 1/(body:radius + ship:apoapsis/2 + ship:periapsis/2))).
    local targetOrbitSpeed is sqrt(body:mu * (2/(body:radius + ship:apoapsis) - 1/(body:radius + targetperi))).
    local deltaV is targetOrbitSpeed - currentOrbitSpeed.
    local burnTime is getBurnTime(deltaV).
    local firsthalfburntime is burntime - getBurnTime(deltaV/2).
    print "Delta V: " + deltaV.
    print "First Half-burn time: " + firsthalfburntime.
    print "Burn time: " + burnTime.
    lock steering to lookdirup(orbitTangent(), localVertical()).
    local thr is 0.
    lock throttle to thr.
    local burnstart is 0.
    on AG10 {
        set thr to 0.
        wait 0.
        stage.
        wait 0.
        wait until stage:ready.
        set currentOrbitSpeed to sqrt(body:mu * (2/(body:radius + ship:apoapsis) - 1/(body:radius + ship:apoapsis/2 + ship:periapsis/2))).
        set deltaV to targetOrbitSpeed - currentOrbitSpeed.
        set burnTime to getBurnTime(deltaV).
        set firsthalfburntime to burntime - getBurnTime(deltaV/2).
        set burnstart to time:seconds.
        return true.
    }
    print "Waiting for: " + (eta:apoapsis - firsthalfburntime - 15) + "s".
    wait eta:apoapsis - firsthalfburntime - 15.
    kuniverse:timewarp:cancelwarp().
    wait eta:apoapsis - firsthalfburntime.
    set burnstart to time:seconds.
    until time:seconds > burnstart + burnTime and ship:periapsis > targetperi {
        set thr to 1.
        wait 0.
    }
    set thr to 0.
    unlock throttle.
    unlock steering.
}

function circularize2 {
    parameter launch_params is lexicon(
        "target_altitude", 80_000
    ).

    local th is 0.
    lock throttle to th.
    local dV is ship:facing:vector:normalized.
    lock steering to lookdirup(dV, ship:facing:topvector).
    ag1 off. //ag1 to abort

    local timeout is time:seconds + 9000.
    when dV:mag < 0.05 then set timeout to time:seconds + 3.
    until ag1 or dV:mag < 0.02 or time:seconds > timeout {
        local posVec is ship:position - body:position.
        local vecNormal is vcrs(posVec,velocity:orbit).
        local vecHorizontal is -1 * vcrs(ship:position-body:position, vecNormal).
        set vecHorizontal:mag to sqrt(body:MU/(body:Radius + altitude)). //this is the desired velocity vector to obtain circular orbit at current altitude

        set dV to vecHorizontal - velocity:orbit. //deltaV as a vector

        //Debug vectors
        //set mark_n to VECDRAWARGS(ship:position, vecNormal:normalized * (velocity:orbit:mag / 100), RGB(1,0,1), "n", 1, true).
        local mark_h is VECDRAWARGS(ship:position, vecHorizontal / 100, RGB(0,1,0), "h", 1, true).
        local mark_v is VECDRAWARGS(ship:position, velocity:orbit / 100, RGB(0,0,1), "dv", 1, true).
        local mark_dv is VECDRAWARGS(ship:position + velocity:orbit / 100, dV, RGB(1,1,1), "dv", 1, true).

        //throttle control
        if vang(ship:facing:vector,dV) > 1 { set th to 0. }
        else { set th to max(0,min(1,dV:mag/10)). }
        wait 0.
    }
}

function circularize3 {
    parameter launch_params is lexicon(
        "target_altitude", 75_000
    ).

    local WarpStopTime is 30. //custom value

    clearscreen.

    //display info
    local running is true.
    when running = true then {
        print "Apoapsis: "+round(apoapsis)+" m       " at (0,2).
        print "Periapsis: "+round(periapsis)+" m       " at (0,3).
        print "Time to apoapsis: "+round(eta:apoapsis)+"s       " at (0,4).
        print "Running: uCircToAp" at (0,6).
        preserve.
    }


    //staging
    local InitialStageThrust is maxthrust.
    when maxthrust<InitialStageThrust then {
        wait 1.
        stage.
            if maxthrust > 0 {
            set InitialStageThrust to maxthrust.
        }
        preserve.
    }


    wait until ship:q = 0.
        lock steering to prograde.
        local TargetV is ((body:mu)/(body:radius+apoapsis))^0.5.
        local ApoapsisV is (2*body:mu*((1/(body:radius+apoapsis))-(1/orbit:semimajoraxis/2)))^0.5.
        local BurnDeltaV is TargetV-ApoapsisV.
        local BurnTime is (BurnDeltaV*mass)/availablethrust.

    wait 1.
    rcs on.
    sas off.
    set warpmode to "rails".
    print "Warping to apoapsis" at (0,0).
    local BurnMoment is time:seconds + eta:apoapsis.
    warpto(BurnMoment-BurnTime/2-WarpStopTime).

    wait until vang(ship:facing:forevector,steering:forevector) <  5 and time:seconds > BurnMoment-BurnTime/2.
        set throttle to 1.
        print "Circularization burn started" at (0,0).

    wait until TargetV < ship:velocity:orbit:mag.
        set throttle to 0.
        unlock steering.
        rcs off.
        print "Circularization burn completed" at (0,0).
        lock throttle to 0. unlock throttle.
        clearscreen.

    rcs off.
    sas on.
    set running to false.
    set ship:control:pilotmainthrottle to 0.
    clearscreen.
}

declare function getShipTWR
{
    return SHIP:MAXTHRUST / (SHIP:MASS * SHIP:BODY:MU / (SHIP:ALTITUDE+SHIP:BODY:RADIUS) / (SHIP:ALTITUDE+SHIP:BODY:RADIUS)).
}

function launch {
    parameter targetAltitude is 75_000.
    parameter targetInclination is ship:latitude.
    parameter turnStartSpeed is 60.
    parameter steepness is 0.5.
    parameter maintainTWR is 0.
    
    local launch_params is lexicon(
        "target_altitude", targetAltitude,
        "target_inclination", targetInclination,
        "turn_start_speed", turnStartSpeed,
        "maintain_twr", maintainTWR,
        "steepness", steepness
    ).

    print "Launch Parameters".
    print "-----------------".
    print "Target Altitude: " + targetAltitude.
    print "Target Inclination: " + targetInclination.
    print "Maintain TWR? " + maintainTWR.
    print "Pitch program start velocity: " + turnStartSpeed.

    local stageControl is false.
    local launch_complete is false.

    local last_maxthrust is 0.
    local last_stage is stage:number.

    local g is (BODY:mass * constant:g) / (body:radius*body:radius).

    local launchClampStage is 999.
    local launchClampDisengaged is false.
    FOR p in SHIP:PARTS {
        IF p:MODULES:CONTAINS("LaunchClamp") {
            IF launchClampStage = 999 SET launchClampStage TO p:STAGE.
        }
    }

    on time:second {
        if ((ship:maxthrustat(0) <> last_maxthrust or ship:maxthrustat(0) = 0) or
            have_empty_tanks()) and stage:number > 0 and stageControl {
            if stage:number = last_stage {
                wait until stage:ready.
                stage.
                wait until stage:ready.
                set last_maxthrust to ship:maxthrustat(0).
                set last_stage to stage:number.
                if launch_complete or stage:number = 0 {
                    return false.
                }
                else {
                    return true.
                }
            }
            else {
                set last_maxthrust to ship:maxthrustat(0).
                return true.
            }
        }
        return true.
    }

    local turnParameters is getTurnParameters(launch_params["target_altitude"]).
    set launch_params["target_heading"] to { return azimuth(launch_params["target_inclination"], turnParameters["altParameter"]). }.
    kuniverse:timewarp:cancelWarp().
    print "Launching!".

    if launchClampStage = 999 {
        if SHIP:AVAILABLETHRUST = 0 {
            print "Ship available stage thrust: " + SHIP:AVAILABLETHRUST.
            lock throttle to 1.
            until ship:verticalspeed > 0.1 {
                STAGE.
                wait until stage:ready.
            }
            set last_maxthrust to ship:maxthrustat(0).
            set last_stage to stage:number.
            set stageControl to true.
        }
    } else {
        print "Launch clamps detected...".
        print "Starting main boosters".

        lock throttle to 1.

        // Launch initial boosters
        STAGE.
        wait until stage:ready.
        local twr is getShipTWR().

        print "Intial TWR is: " + twr.

         // Wait until TWR >= 1
        until twr >= 0.5 {
            set twr to getShipTWR().
            print "Current TWR: " + twr.
            wait 0.
        }

        // // Wait until TWR >= 1
        // until twr >= 1 {
        //     set twr to getShipTWR().
        //     print "Current TWR: " + twr.
        //     wait 0.
        // }

        print "TWR nominal.".
        print "Disengaging Launch Clamps!".

        // Disengage launch clamps
        STAGE.
        
        set last_maxthrust to ship:maxthrustat(0).
        set last_stage to stage:number.
        set stageControl to true.
    }

    print "Starting vertical ascent".
    verticalAscent(launch_params).
    print "Vertical ascent complete".

    print "Starting pitching program".
    // pitchProgram(launch_params).
    pitchProgram2(launch_params).
    print "Pitching program complete".

    print "Coasting to atmosphere exit, if it exists".
    atmosphereExit().
    print "Out of atmosphere".

    print "Waiting for circularization burn".
    // circularize(launch_params).
    // circularize2(launch_params).
    circularize3(launch_params).
    print "Entered orbit".

    set stageControl to false.
    lock THROTTLE to 0.
    unlock STEERING.
    unlock THROTTLE.

    print "Launch complete".
    set launch_complete to true.
}

function primitive_launch {
    parameter targetAltitude is 80000.
    parameter targetHeading is 90.
    parameter turnStartSpeed is 60.
    
    local stageControl is false.

    when STAGE:NUMBER > 0 and stageControl = true then {
        if needsStaging() {
            wait 0.5.
            STAGE.
            wait until STAGE:READY.
        }
        if STAGE:NUMBER = 0 {
            return false.
        }
        else {
            return true.
        }
    }

    kuniverse:timewarp:cancelWarp().
    wait 2.
    print "Launching now".

    set stageControl to true.
    if SHIP:AVAILABLETHRUST = 0 {
        STAGE.
    }

    verticalAscent(targetHeading, turnStartSpeed).
    lock STEERING to HEADING(targetHeading, 85).
    
    wait until SHIP:ALTITUDE > 2_000.
    lock STEERING to HEADING(targetHeading, 75).

    wait until SHIP:ALTITUDE > 5_000.
    lock STEERING to HEADING(targetHeading, 70).

    wait until SHIP:ALTITUDE > 8_000.
    lock STEERING to HEADING(targetHeading, 60).

    wait until SHIP:ALTITUDE > 11_000.
    lock STEERING to HEADING(targetHeading, 50).

    wait until SHIP:ALTITUDE > 14_000.
    lock STEERING to HEADING(targetHeading, 45).

    wait until SHIP:ALTITUDE > 20_000.
    lock STEERING to HEADING(targetHeading, 40).

    wait until SHIP:ALTITUDE > 30_000.
    lock STEERING to HEADING(targetHeading, 30).

    wait until SHIP:ORBIT:APOAPSIS > 50_000.
    lock STEERING to HEADING(targetHeading, 15).

    wait until SHIP:ORBIT:APOAPSIS > 70_000.
    lock STEERING to HEADING(targetHeading, 0).

    wait until SHIP:ORBIT:APOAPSIS > targetAltitude.
    lock THROTTLE to 0.
    
    print "Coasting to atmosphere exit, if it exists.".
    atmosphereExit().
    print "Out of atmosphere".

    print "Waiting for circularization burn".
    circularize().
    print "Entered orbit".

    set stageControl to false.
    lock THROTTLE to 0.
    unlock STEERING.
    unlock THROTTLE.

    print "Launch complete".
}

// run to_minmus.ks.
// Launch Parameters
// -----------------
// Target Altitude: 80000
// Target Inclination: -0.0971908643841743
// Maintain TWR? 0
// Pitch program start velocity: 60
// Launching now
// Ship available stage thrust: 0
// Starting vertical ascent

