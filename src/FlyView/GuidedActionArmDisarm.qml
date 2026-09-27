import QGroundControl
import QGroundControl.FlyView

// Arm / Disarm button for the Fly view tool strip.
// Uses the normal confirm slider, so the vehicle only arms/disarms after sliding.
GuidedToolStripAction {
    property bool _armed: _guidedController._vehicleArmed

    text:       _armed ? qsTr("Disarm") : qsTr("Arm")
    iconSource: _armed ? "/qmlimages/Disarmed.svg" : "/qmlimages/Armed.svg"
    visible:    true
    enabled:    _armed ? _guidedController.showDisarm : _guidedController.showArm
    actionID:   _armed ? _guidedController.actionDisarm : _guidedController.actionArm
}
