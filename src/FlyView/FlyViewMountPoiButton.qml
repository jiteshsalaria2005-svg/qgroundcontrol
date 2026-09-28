import QGroundControl
import QGroundControl.FlyView

// Triggers the ArduPilot mount-poi.lua script (tools/ardupilot-scripts/mount-poi.lua) on the vehicle
ToolStripAction {
    text:       qsTr("POI")
    iconSource: "/InstrumentValueIcons/location.svg"
    visible:    _activeVehicle ? _activeVehicle.apmFirmware : false

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    dropPanelComponent: Component {
        FlyViewMountPoiDropPanel {
        }
    }
}
