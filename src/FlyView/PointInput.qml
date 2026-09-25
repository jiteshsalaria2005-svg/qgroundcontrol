import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

import "GridConversions.js" as Grid

/// Enter one point as Lat/Long (WGS84), Everest grid (Kalianpur 1975) or Custom grid (LCC, WGS84)
ColumnLayout {
    id:         root
    spacing:    ScreenTools.defaultFontPixelHeight / 4

    property string title:          ""
    property string settingsPrefix: ""      // used to remember what was typed
    property real   fieldWidth:     ScreenTools.defaultFontPixelWidth * 14

    // Format index values
    readonly property int formatLatLon:     0
    readonly property int formatEverest:    1
    readonly property int formatCustom:     2

    property int _format: formatCombo.currentIndex

    function _key(name) { return "PointInput_" + settingsPrefix + "_" + name }

    function saveInputs() {
        QGroundControl.saveGlobalSetting(_key("format"), String(formatCombo.currentIndex))
        QGroundControl.saveGlobalSetting(_key("zone"),   String(zoneCombo.currentIndex))
        QGroundControl.saveGlobalSetting(_key("a"),      fieldA.text)
        QGroundControl.saveGlobalSetting(_key("b"),      fieldB.text)
    }

    Component.onCompleted: {
        formatCombo.currentIndex = Number(QGroundControl.loadGlobalSetting(_key("format"), "0"))
        zoneCombo.currentIndex   = Number(QGroundControl.loadGlobalSetting(_key("zone"), "1"))
        fieldA.text              = QGroundControl.loadGlobalSetting(_key("a"), "")
        fieldB.text              = QGroundControl.loadGlobalSetting(_key("b"), "")
    }

    /// Reads the fields and returns { ok, lat, lon, error } in WGS84
    ///     customParams: { lat0, lon0, sp1, sp2, FE, FN } used for Custom grid
    function resolve(customParams) {
        var a = Grid.parseNum(fieldA.text)
        var b = Grid.parseNum(fieldB.text)
        var r

        if (_format === formatLatLon) {
            if (isNaN(a) || a < -90 || a > 90) {
                return { ok: false, error: title + ": " + qsTr("Latitude must be between -90 and 90") }
            }
            if (isNaN(b) || b < -180 || b > 180) {
                return { ok: false, error: title + ": " + qsTr("Longitude must be between -180 and 180") }
            }
            return { ok: true, lat: a, lon: b }
        }

        if (isNaN(a) || isNaN(b)) {
            return { ok: false, error: title + ": " + qsTr("Enter valid Easting and Northing") }
        }

        if (_format === formatEverest) {
            r = Grid.everestToWgs84(Grid.INDIA_ZONE_KEYS[zoneCombo.currentIndex], a, b)
        } else {
            var err = Grid.checkCustomParams(customParams)
            if (err !== "") {
                return { ok: false, error: qsTr("Custom Grid: ") + err }
            }
            r = Grid.customToWgs84(customParams, a, b)
        }
        if (isNaN(r.lat) || isNaN(r.lon) || Math.abs(r.lat) > 90) {
            return { ok: false, error: title + ": " + qsTr("Grid values are out of range") }
        }
        return { ok: true, lat: r.lat, lon: r.lon }
    }

    RowLayout {
        spacing: ScreenTools.defaultFontPixelWidth

        QGCLabel {
            text:               root.title
            font.bold:          true
            Layout.fillWidth:   true
        }
        QGCComboBox {
            id:                     formatCombo
            Layout.preferredWidth:  root.fieldWidth
            model:                  [ qsTr("Lat / Long"), qsTr("Everest Grid"), qsTr("Custom Grid") ]
        }
    }

    RowLayout {
        spacing:    ScreenTools.defaultFontPixelWidth
        visible:    root._format === root.formatEverest

        QGCLabel {
            text:               qsTr("Zone (Kalianpur 1975)")
            Layout.fillWidth:   true
        }
        QGCComboBox {
            id:                     zoneCombo
            Layout.preferredWidth:  root.fieldWidth
            model:                  Grid.INDIA_ZONE_KEYS.map(function(k) { return Grid.INDIA_ZONES[k].label })
        }
    }

    GridLayout {
        columns:        2
        rowSpacing:     ScreenTools.defaultFontPixelHeight / 4
        columnSpacing:  ScreenTools.defaultFontPixelWidth

        QGCLabel {
            text:               root._format === root.formatLatLon ? qsTr("Latitude") : qsTr("Easting (m)")
            Layout.fillWidth:   true
        }
        QGCTextField {
            id:                     fieldA
            Layout.preferredWidth:  root.fieldWidth
            numericValuesOnly:      true
            placeholderText:        root._format === root.formatLatLon ? "31.326015" : "3462931"
        }

        QGCLabel {
            text:               root._format === root.formatLatLon ? qsTr("Longitude") : qsTr("Northing (m)")
            Layout.fillWidth:   true
        }
        QGCTextField {
            id:                     fieldB
            Layout.preferredWidth:  root.fieldWidth
            numericValuesOnly:      true
            placeholderText:        root._format === root.formatLatLon ? "75.576180" : "809988"
        }
    }
}
