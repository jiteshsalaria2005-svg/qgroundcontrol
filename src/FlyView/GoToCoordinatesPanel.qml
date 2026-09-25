import QtQuick
import QtQuick.Layouts
import QtPositioning

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView

/// Small panel on the Fly screen:
/// type Latitude + Longitude, press GO, the vehicle flies there in Guided mode
/// (keeps its current altitude). Works with ArduPilot and PX4.
Rectangle {
    id:         root
    width:      mainLayout.implicitWidth  + _margin * 2
    height:     mainLayout.implicitHeight + _margin * 2
    color:      qgcPal.toolbarBackground
    radius:     ScreenTools.defaultFontPixelHeight / 2

    property var mapControl     // FlyViewMap, used to show the "Go here" marker

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property var    _guidedController:  globals.guidedControllerFlyView
    property bool   _canGo:             _guidedController ? _guidedController.showGotoLocation : false
    property bool   _expanded:          true
    property real   _margin:            ScreenTools.defaultFontPixelHeight / 2
    property real   _fieldWidth:        ScreenTools.defaultFontPixelWidth * 16
    property string _status:            ""
    property bool   _statusIsError:     false

    QGCPalette { id: qgcPal }

    // Stop map clicks/drags from going through the panel
    DeadMouseArea { anchors.fill: parent }

    // Accepts "31.123456" or pasted "31.123456, 75.123456" in the latitude box
    function _splitPastedPair() {
        var parts = latField.text.split(/[\s,;]+/).filter(function(s) { return s.length > 0 })
        if (parts.length === 2) {
            latField.text = parts[0]
            lonField.text = parts[1]
        }
    }

    function _setStatus(text, isError) {
        _status = text
        _statusIsError = isError
    }

    function _go() {
        _splitPastedPair()

        var lat = Number(latField.text.trim())
        var lon = Number(lonField.text.trim())

        if (latField.text.trim() === "" || isNaN(lat) || lat < -90 || lat > 90) {
            _setStatus(qsTr("Latitude must be between -90 and 90"), true)
            return
        }
        if (lonField.text.trim() === "" || isNaN(lon) || lon < -180 || lon > 180) {
            _setStatus(qsTr("Longitude must be between -180 and 180"), true)
            return
        }
        if (!_activeVehicle) {
            _setStatus(qsTr("No drone connected"), true)
            return
        }
        if (!_canGo) {
            _setStatus(qsTr("Drone must be armed and flying"), true)
            return
        }

        var coord = QtPositioning.coordinate(lat, lon)
        if (_guidedController.executeAction(_guidedController.actionGoto, coord)) {
            if (mapControl) {
                mapControl.showGotoMarker(coord)
            }
            var dist = _activeVehicle.coordinate.isValid ? Math.round(_activeVehicle.coordinate.distanceTo(coord)) : -1
            _setStatus(dist >= 0 ? qsTr("Going to point (%1 m away)").arg(dist) : qsTr("Going to point"), false)
        } else {
            // Vehicle code already shows the reason (e.g. too far) as an app message
            _setStatus(qsTr("Drone did not accept the command"), true)
        }
    }

    ColumnLayout {
        id:                 mainLayout
        anchors.margins:    _margin
        anchors.top:        parent.top
        anchors.left:       parent.left
        spacing:            ScreenTools.defaultFontPixelHeight / 3

        // Header: tap to show/hide the panel
        RowLayout {
            spacing: ScreenTools.defaultFontPixelWidth

            QGCLabel {
                text:               qsTr("Go To Coordinates")
                font.bold:          true
                Layout.fillWidth:   true
            }
            QGCLabel {
                text: _expanded ? "▲" : "▼"
            }
        }

        GridLayout {
            columns:        2
            rowSpacing:     ScreenTools.defaultFontPixelHeight / 4
            columnSpacing:  ScreenTools.defaultFontPixelWidth
            visible:        _expanded

            QGCLabel { text: qsTr("Latitude") }
            QGCTextField {
                id:                     latField
                Layout.preferredWidth:  _fieldWidth
                placeholderText:        qsTr("e.g. 31.326015")
                numericValuesOnly:      true
                onEditingFinished:      _splitPastedPair()
                onTextEdited:           _status = ""
            }

            QGCLabel { text: qsTr("Longitude") }
            QGCTextField {
                id:                     lonField
                Layout.preferredWidth:  _fieldWidth
                placeholderText:        qsTr("e.g. 75.576180")
                numericValuesOnly:      true
                onTextEdited:           _status = ""
            }
        }

        QGCButton {
            Layout.fillWidth:   true
            text:               qsTr("GO")
            primary:            true
            enabled:            _canGo
            visible:            _expanded
            onClicked:          _go()
        }

        QGCLabel {
            Layout.fillWidth:       true
            Layout.maximumWidth:    _fieldWidth + ScreenTools.defaultFontPixelWidth * 10
            wrapMode:               Text.WordWrap
            font.pointSize:         ScreenTools.smallFontPointSize
            visible:                _expanded
            color:                  _statusIsError ? qgcPal.warningText : qgcPal.text
            text: {
                if (_status !== "") {
                    return _status
                }
                if (!_activeVehicle) {
                    return qsTr("Connect a drone")
                }
                return _canGo ? qsTr("Ready. Drone keeps its current height.")
                              : qsTr("Take off first, then press GO")
            }
        }
    }

    // Tap on the header row toggles the panel
    MouseArea {
        x:          0
        y:          0
        width:      root.width
        height:     _margin + ScreenTools.defaultFontPixelHeight * 1.2
        onClicked:  _expanded = !_expanded
    }
}
