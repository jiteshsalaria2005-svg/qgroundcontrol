import QGroundControl
import QGroundControl.FlyView

GuidedToolStripAction {
    text:       qsTr("Launch")
    iconSource: "/res/takeoff.svg"
    visible:    true
    enabled:    _guidedController.showTakeoff
    actionID:   _guidedController.actionTakeoff
}
