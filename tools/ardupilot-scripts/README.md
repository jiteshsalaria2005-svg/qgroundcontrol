# ArduPilot Lua scripts

Scripts that run on the ArduPilot flight controller (not inside QGroundControl).

## mount-poi.lua

Copy of [ArduPilot `mount-poi.lua`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AP_Scripting/applets/mount-poi.lua)
(GPLv3, ArduPilot project). It finds the point on the ground that the gimbal is looking at and sends it to the GCS.

Install on the vehicle:

1. Set `SCR_ENABLE = 1` and reboot.
2. Copy `mount-poi.lua` to `APM/scripts/` on the flight controller SD card (or upload it with MAVFTP) and reboot.
3. Terrain data must be available (`TERRAIN_ENABLE = 1`).

Use from QGroundControl: in the Fly view tool strip press **POI**, then

- **Mark POI** — sends aux function 300 (Scripting1). The POI shows in Messages and as a camera-trigger dot on the map.
- **Mark POI + Lock Gimbal** — sends aux function 301 (Scripting2). Also points the gimbal at the POI.

An RC switch with `RCx_OPTION = 300` or `301` still works as well.
