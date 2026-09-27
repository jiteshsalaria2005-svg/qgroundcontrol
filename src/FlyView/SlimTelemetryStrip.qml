import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

/// Slim, see-through telemetry strip for the bottom of the Fly view.
/// Shows battery %, battery voltage, distance to home, altitude, horizontal and vertical speed.
/// Text has a dark outline so it stays readable on any map or video.
Rectangle {
    id:             root
    implicitWidth:  row.implicitWidth + _margin * 2
    implicitHeight: row.implicitHeight + _margin
    width:          implicitWidth
    height:         implicitHeight
    radius:         height / 2
    color:          Qt.rgba(0, 0, 0, 0.35)

    property var    vehicle:    QGroundControl.multiVehicleManager.activeVehicle
    property var    _battery:   vehicle && vehicle.batteries.count > 0 ? vehicle.batteries.get(0) : null
    property real   _margin:    ScreenTools.defaultFontPixelWidth

    function _factText(fact, decimals) {
        if (!fact || isNaN(fact.rawValue)) {
            return "--"
        }
        return fact.value.toFixed(decimals) + " " + fact.units
    }

    function _batteryColor(percent) {
        if (isNaN(percent)) return "white"
        if (percent > 50)   return "#69F0AE"     // green
        if (percent > 25)   return "#FFD54F"     // amber
        return "#FF5252"                         // red
    }

    component StripValue: Row {
        property string label
        property string value
        property color  valueColor: "white"
        spacing: ScreenTools.defaultFontPixelWidth / 2

        Text {
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
        id:                 row
        anchors.centerIn:   parent
        spacing:            ScreenTools.defaultFontPixelWidth * 1.5

        StripValue {
            label:      qsTr("BAT")
            value:      _battery && !isNaN(_battery.percentRemaining.rawValue)
                            ? Math.round(_battery.percentRemaining.rawValue) + "%" : "--"
            valueColor: _batteryColor(_battery ? _battery.percentRemaining.rawValue : NaN)
        }
        StripValue {
            label:  qsTr("VOLT")
            value:  _battery ? _factText(_battery.voltage, 1) : "--"
        }
        StripValue {
            label:  qsTr("DIST")
            value:  vehicle ? _factText(vehicle.distanceToHome, 0) : "--"
        }
        StripValue {
            label:  qsTr("ALT")
            value:  vehicle ? _factText(vehicle.altitudeRelative, 1) : "--"
        }
        StripValue {
            label:  qsTr("H.SPD")
            value:  vehicle ? _factText(vehicle.groundSpeed, 1) : "--"
        }
        StripValue {
            label:  qsTr("V.SPD")
            value:  vehicle ? _factText(vehicle.climbRate, 1) : "--"
        }
    }
}
