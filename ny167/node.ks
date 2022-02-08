set nd to nextnode.
//we only need to lock throttle once to a certain variable in the beginning of the loop, and adjust only the variable itself inside it
set tset to 0.
lock throttle to tset.

set done to False.
//initial deltav
set dv0 to nd:deltav.
SET nd TO NEXTNODE.

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

UNTIL MAXTHRUST > 0
{
	PRINT "No active engine. Staging.".
	STAGE.
	WAIT 3.
}

PRINT "Node in " + ROUND(NEXTNODE:ETA) + " s. Delta V: " + ROUND(NEXTNODE:DELTAV:MAG) + " m/s.".

LOCK max_acc TO AVAILABLETHRUST / SHIP:MASS.
IF NOT (DEFINED BD) OR (BD = 0)
{ SET BD TO NEXTNODE:DELTAV:MAG / max_acc. }
PRINT "Estimated burn duration: " + ROUND(BD) + " s".

WAIT UNTIL NEXTNODE:ETA <= BD / 2 + 60.
wait until nd:eta <= 0.1.

until done
{
    //recalculate current max_acceleration, as it changes while we burn through fuel
    set max_acc to ship:maxthrust/ship:mass.

    if have_empty_tanks() {
        if stage:number = last_stage {
            wait until stage:ready.
            stage.
            wait until stage:ready.
        }
    }

    //throttle is 100% until there is less than 1 second of time left to burn
    //when there is less than 1 second - decrease the throttle linearly
    set tset to min(nd:deltav:mag/max_acc, 1).

    //here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
    //this check is done via checking the dot product of those 2 vectors
    if vdot(dv0, nd:deltav) < 0
    {
        print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
        lock throttle to 0.
        break.
    }

    //we have very little left to burn, less then 0.1m/s
    if nd:deltav:mag < 0.1
    {
        print "Finalizing burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
        //we burn slowly until our node vector starts to drift significantly from initial vector
        //this usually means we are on point
        wait until vdot(dv0, nd:deltav) < 0.5.

        lock throttle to 0.
        print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
        set done to True.
    }
}
unlock steering.
unlock throttle.
wait 1.

//we no longer need the maneuver node
remove nd.

//set throttle to 0 just in case.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.