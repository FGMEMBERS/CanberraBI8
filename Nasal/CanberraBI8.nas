
autotakeoff = func {
  ato_start();      # Initiation stuff.
  ato_mode();       # Take-off/Climb-out mode handler.
  ato_spddep();     # Speed dependent actions.
  
  # Re-schedule the next loop
  if(getprop("/autopilot/locks/auto-take-off") != "Enabled") {
    print("Auto Take-Off disabled");
  } else {
    settimer(autotakeoff, 0.5);
  }
}
#--------------------------------------------------------------------
ato_start = func {
  # This script checks that the ground-roll-heading has been reset
  # (<-999) and that the a/c is on the ground.
  if(getprop("/autopilot/settings/ground-roll-heading-deg") < -999) {
    if(getprop("/position/altitude-agl-ft") < 0.01) {
      hdgdeg = getprop("/orientation/heading-deg");
      setprop("/autopilot/settings/ground-roll-heading-deg", hdgdeg);
      setprop("/autopilot/settings/true-heading-deg", hdgdeg);
      setprop("/autopilot/settings/target-speed-kt", 350);
      setprop("/controls/flight/flaps", 0.64);
      setprop("/autopilot/locks/altitude", "ground-roll");
      setprop("/autopilot/locks/speed", "speed-with-throttle");
      setprop("/autopilot/locks/heading", "wing-leveler");
      setprop("/autopilot/locks/rudder-control", "rudder-hold");
    }
  }
}
#--------------------------------------------------------------------
ato_mode = func {
  # This script sets the auto-takeoff mode and handles the switch
  # to climb-out mode.
  agl = getprop("position/altitude-agl-ft");
  if(agl < 15) {
    if(getprop("/velocities/airspeed-kt") > 60) {
      setprop("/autopilot/locks/altitude", "take-off");
    }
  } else {
    if(agl < 100) {
      setprop("/autopilot/locks/altitude", "climb-out");
      setprop("/controls/gear/gear-down", "false");
      setprop("/autopilot/locks/rudder-control", "reset");
      interpolate("/controls/flight/rudder", 0, 10);
    }
  }
}
#--------------------------------------------------------------------
ato_spddep = func {
  # This script controls speed dependent actions.
  airspeed = getprop("/velocities/airspeed-kt");
  if(airspeed < 110) {
    # Do not do anything until airspeed > 110kt.
  } else {
    if(airspeed < 120) {
      setprop("/controls/flight/flaps", 0.48);
    } else {
      if(airspeed < 130) {
        setprop("/controls/flight/flaps", 0.32);
      } else {
        if(airspeed < 140) {
          setprop("/controls/flight/flaps", 0.16);
        } else {
          if(airspeed < 150) {
            setprop("/controls/flight/flaps", 0.08);
          } else {
            if(airspeed < 160) {
              setprop("/controls/flight/flaps", 0);
            } else {
              # Switch to true-heading-hold, switch to Mach-Hold
              # throttle mode, mach-hold-climb mode and disable
              # Take-Off mode.
              setprop("/autopilot/locks/heading", "true-heading-hold");
              setprop("/autopilot/locks/speed", "mach-with-throttle");
              setprop("/autopilot/locks/altitude", "mach-climb");
              setprop("/autopilot/locks/auto-take-off", "Disabled");
            }
          }
        }
      }
    }
  }
}
#--------------------------------------------------------------------
autoland = func {
  # Get the agl, kias, vfps & heading.
  agl = getprop("/position/altitude-agl-ft");
  hdgdeg = getprop("/orientation/heading-deg");
  
  if(agl > 60) {
    if(agl > 200) {
      # Glide Slope phase.
      atl_heading();
      atl_spddep();
#      setprop("/autopilot/locks/altitude", "gs1-hold");
      atl_glideslope();
    } else {
      setprop("/autopilot/locks/heading", "wing-leveler");
    }
  } else {
    # Touch Down Phase
    atl_touchdown();
  }
  # Re-schedule the next loop if the Landing function is enabled.
  if(getprop("/autopilot/locks/auto-landing") != "Enabled") {
    print("Auto Landing disabled");
  } else {
    settimer(autoland, 0.5);
  }
}
#--------------------------------------------------------------------
atl_glideslope = func {
  # This script handles the Glide Slope phase
  gsvfps = getprop("/radios/nav[0]/gs-rate-of-climb");
  if(gsvfps > 20) {
    setprop("/autopilot/settings/target-vfps", 20);
    setprop("/autopilot/locks/altitude", "gs1-hold-acq");
  } else {
    setprop("/autopilot/locks/altitude", "gs1-hold");
  }
}
#--------------------------------------------------------------------
atl_spddep = func {
  # This script handles the speed dependent actions.
  if(getprop("/autopilot/locks/speed") != "speed-with-throttle") {
    setprop("/autopilot/locks/speed", "speed-with-throttle");
  }

  # Set the target speed to 200 kts.
  if(getprop("/autopilot/settings/target-speed-kt") > 200) {
    setprop("/autopilot/settings/target-speed-kt", 200);
  }
  if(getprop("/controls/flight/flaps") > 0.95) {
    setprop("/autopilot/locks/auto-flap-control", "manual");
    setprop("/controls/flight/flaps", 1);
  }

  gsvfps = getprop("/radios/nav[0]/gs-rate-of-climb");
  kias = getprop("/velocities/airspeed-kt");
  if(kias < 110) {
    setprop("/autopilot/locks/approach-AoA-lock", "Engaged");
  } else {
    if(kias < 115) {
      setprop("/controls/flight/spoilers", 0);
    } else {
      if(kias < 120) {
        setprop("/controls/flight/spoilers", 0.1);
        setprop("/controls/gear/gear-down", "true");
      } else {
        if(kias < 125) {
          setprop("/controls/flight/spoilers", 0.2);
        } else {
          if(kias < 130) {
            setprop("/controls/flight/spoilers", 0.3);
          } else {
            if(kias < 140) {
              setprop("/controls/flight/spoilers", 0.4);
            } else {
              if(kias < 155) {
                setprop("/controls/flight/spoilers", 0.6);
              } else {
                if(kias < 180) {
                  setprop("/autopilot/locks/auto-flap-control", "Engaged");
                  setprop("/controls/flight/spoilers", 0.8);
                } else {
                  if(getprop("/velocities/vertical-speed-fps") < -12) {
                    if(gsvfps < 4) {
                      setprop("/autopilot/settings/target-speed-kt", 100);
                      setprop("/controls/flight/spoilers", 1.0);
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
#--------------------------------------------------------------------
atl_touchdown = func {
  # Touch Down Phase
  agl = getprop("/position/altitude-agl-ft");
  setprop("/autopilot/locks/altitude", "Touch Down");
  setprop("/autopilot/locks/auto-flap-control", "Manual");

  setprop("/autopilot/locks/heading", "wing-leveler");

  if(agl < 1.5) {
    setprop("/autopilot/locks/speed", "off");
    setprop("/controls/engines/engine[0]/throttle", 0);
    setprop("/controls/engines/engine[1]/throttle", 0);
  }
  if(agl < 0.1) {
    setprop("/autopilot/locks/heading", "off");
    setprop("/controls/flight/spoilers", 1);
  }
  if(agl < 0.01) {
    setprop("/autopilot/locks/approach-AoA-lock", "off");
    setprop("/autopilot/settings/ground-roll-heading-deg", -999.9);
    setprop("/autopilot/locks/auto-landing", "Disabled");
    setprop("/autopilot/locks/auto-take-off", "Enabled");
    setprop("/autopilot/locks/altitude", "Off");
  }
}
#--------------------------------------------------------------------
atl_heading = func {
  # This script handles heading dependent actions.
#  hdnddf = getprop("/radios/nav[0]/heading-needle-deflection");
  hdnddf = getprop("/autopilot/internal/filtered-heading-needle-deflection");
  if(hdnddf < 6) {
    if(hdnddf > -6) {
      setprop("/autopilot/locks/heading", "nav1-hold-fa");
    } else {
      setprop("/autopilot/locks/heading", "nav1-hold");
    }
  } else {
    setprop("/autopilot/locks/heading", "nav1-hold");
  }
}
#--------------------------------------------------------------------
toggle_hatch = func {
  if(getprop("/controls/hatch/hatch-pos-norm") > 0) {
    interpolate("/controls/hatch/hatch-pos-norm", 0, 0.4);
  } else {
    interpolate("/controls/hatch/hatch-pos-norm", 1, 0.4);
  }
}
#--------------------------------------------------------------------
toggle_canopy = func {
  if(getprop("/controls/canopy/canopy-pos-norm") > 0) {
    interpolate("/controls/canopy/canopy-pos-norm", 0, 3);
  } else {
    interpolate("/controls/canopy/canopy-pos-norm", 1, 3);
  }
}
#--------------------------------------------------------------------
toggle_bb_doors = func {
  if(getprop("/controls/bb-doors/bb-door-pos-norm") > 0) {
    interpolate("/controls/bb-doors/bb-door-pos-norm", 0, 3);
  } else {
    interpolate("/controls/bb-doors/bb-door-pos-norm", 1, 3);
  }
}
#--------------------------------------------------------------------
toggle_traj_mkr = func {
  if(getprop("/ai/submodels/trajectory-markers") > 0) {
    setprop("/ai/submodels/trajectory-markers", 0);
  } else {
    setprop("/ai/submodels/trajectory-markers", 1);
  }
}
#--------------------------------------------------------------------
steering = func {
	# cubed output maxing out at 60 deg
	if (rudderPos.getValue() < 0) {
		noseSteer.setDoubleValue(-1*math.exp(rudderPos.getValue()*-4.3009217)/60);
	} else {
		noseSteer.setDoubleValue(math.exp(rudderPos.getValue()*4.3009217)/60);
	}
	settimer(steering, 0.05);
}
#--------------------------------------------------------------------
beacon_dim = func {
	# beaconDim.setDoubleValue(math.sin(elapsedSec.getValue()*3)/2+0.5);
	level=math.sin(elapsedSec.getValue()*3);
	if (level<0) {
		level=0;
	}
	beaconDim.setDoubleValue(1-level);
	settimer(beacon_dim, 0.05);
}
#--------------------------------------------------------------------

init = func {
	if(getprop("/ai/submodels/trajectory-markers") == nil) {
		setprop("/ai/submodels/trajectory-markers", 0);
	}
	# noseSteer.setDoubleValue(0);
	# rudderPos.setDoubleValue(0);
	settimer(steering, 0);
	settimer(beacon_dim, 0);
}

rudderPos = props.globals.getNode("/controls/flight/rudder", 1);
noseSteer = props.globals.getNode("/controls/flight/steering", 1);
elapsedSec = props.globals.getNode("/sim/time/elapsed-sec", 1);
beaconDim = props.globals.getNode("/sim/model/CanberraBI8/lights/beacon-dim", 1);
settimer(init, 0);

