declare parameter FairingDeployment is false, TargetAltitudeKm is 75,RelativeInclinationDegr is 0, FairingDeploymentAltitudeKm is 60.

runpath("testing/countdown").

runpath("testing/liftoff").

runpath("testing/ascent",FairingDeployment,TargetAltitudeKm,RelativeInclinationDegr,FairingDeploymentAltitudeKm).

runpath("testing/circtoap").