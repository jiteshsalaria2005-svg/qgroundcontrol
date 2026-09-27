import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

/// Small, see-through compass with heading, pitch and roll read-outs.
Rectangle {
    id:             control
    width:          layout.implicitWidth + _margin * 2
    height:         layout.implicitHeight + _margin * 2
    radius:         height / 2
    color:          Qt.rgba(0, 0, 0, 0.35)

    property real extraInset:       0
    property real extraValuesWidth: 0

    property var  _vehicle:     globals.activeVehicle
    property real _margin:      ScreenTools.defaultFontPixelWidth * 0.75
    property real _compassSize: ScreenTools.defaultFontPixelHeight * 4.5

    function _angle(fact, signed) {
        if (!_vehicle || !fact || isNaN(fact.rawValue)) {
            return "--"
        }
        var v = fact.rawValue
        return (signed && v > 0 ? "+" : "") + v.toFixed(signed ? 1 : 0) + "°"
    }

    component Readout: Row {
        property string label
        property string value
        property color  valueColor: "white"
        spacing: ScreenTools.defaultFontPixelWidth / 2

        Text {
            width:          ScreenTools.defaultFontPixelWidth * 3.5
            text:           label
            color:          "#CFD8DC"
            font.pointSize: ScreenTools.smallFontPointSize
            font.family:    ScreenTools.normalFontFamily
            style:          Text.Outline
            styleColor:     "black"
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text:           value
            color:          valueColor
            font.pointSize: ScreenTools.defaultFontPointSize
            font.family:    ScreenTools.normalFontFamily
            font.bold:      true
            style:          Text.Outline
            styleColor:     "black"
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    DeadMouseArea { anchors.fill: parent }

    RowLayout {
        id:                 layout
        anchors.centerIn:   parent
        spacing:            ScreenTools.defaultFontPixelWidth

        QGCCompassWidget {
            size:       control._compassSize
            vehicle:    control._vehicle
        }

        Column {
            spacing: ScreenTools.defaultFontPixelHeight * 0.15
            Readout { label: qsTr("HDG"); value: _vehicle ? _angle(_vehicle.heading, false) : "--"; valueColor: "#FFD54F" }
            Readout { label: qsTr("PIT"); value: _vehicle ? _angle(_vehicle.pitch, true) : "--" }
            Readout { label: qsTr("ROL"); value: _vehicle ? _angle(_vehicle.roll, true) : "--" }
        }
    }
}
