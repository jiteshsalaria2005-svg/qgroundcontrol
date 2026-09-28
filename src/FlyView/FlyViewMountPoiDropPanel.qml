import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

ColumnLayout {
    spacing: ScreenTools.defaultFontHeight / 2

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    QGCButton {
        Layout.fillWidth:   true
        text:               qsTr("Mark POI")
        enabled:            !!_activeVehicle

        onClicked: {
            _activeVehicle.triggerMountPoi(false)
            dropPanel.hide()
        }
    }

    QGCButton {
        Layout.fillWidth:   true
        text:               qsTr("Mark POI + Lock Gimbal")
        enabled:            !!_activeVehicle

        onClicked: {
            _activeVehicle.triggerMountPoi(true)
            dropPanel.hide()
        }
    }
}
