import QtQuick
import QtQuick.Layouts
import QtPositioning

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView

import "GridConversions.js" as Grid

/// Fly screen panel: enter Point 1 and TGT (Lat/Long, Everest grid or Custom grid),
/// then mark both on the map with a box of chosen size (metres) around TGT.
Rectangle {
    id:         root
    width:      _contentWidth + _margin * 2
    height:     Math.min(maxHeight, headerRow.height + (_expanded ? flick.contentHeight + _spacing : 0) + _margin * 2)
    color:      qgcPal.toolbarBackground
    radius:     ScreenTools.defaultFontPixelHeight / 2
    clip:       true

    property var    mapControl                      // FlyViewMap
    property real   maxHeight:      ScreenTools.defaultFontPixelHeight * 30

    property bool   _expanded:      false
    property real   _margin:        ScreenTools.defaultFontPixelHeight / 2
    property real   _spacing:       ScreenTools.defaultFontPixelHeight / 3
    property real   _fieldWidth:    ScreenTools.defaultFontPixelWidth * 14
    property real   _contentWidth:  ScreenTools.defaultFontPixelWidth * 36
    property bool   _showCustom:    false
    property string _status:        ""
    property bool   _statusIsError: false

    QGCPalette { id: qgcPal }

    DeadMouseArea { anchors.fill: parent }

    function _load(name, def) { return QGroundControl.loadGlobalSetting("PointsTarget_" + name, def) }
    function _save(name, val) { QGroundControl.saveGlobalSetting("PointsTarget_" + name, val) }

    function _customParams() {
        return {
            lat0:   Grid.parseNum(originLatField.text),
            lon0:   Grid.parseNum(originLonField.text),
            sp1:    Grid.parseNum(sp1Field.text),
            sp2:    Grid.parseNum(sp2Field.text),
            FE:     Grid.parseNum(feField.text),
            FN:     Grid.parseNum(fnField.text)
        }
    }

    function _saveAll() {
        point1Input.saveInputs()
        tgtInput.saveInputs()
        _save("originLat", originLatField.text)
        _save("originLon", originLonField.text)
        _save("sp1",       sp1Field.text)
        _save("sp2",       sp2Field.text)
        _save("fe",        feField.text)
        _save("fn",        fnField.text)
        _save("boxW",      boxWidthField.text)
        _save("boxH",      boxHeightField.text)
    }

    function _error(text) {
        _status = text
        _statusIsError = true
    }

    /// Four corners of a box centred on c: width = E-W metres, height = N-S metres
    function _boxCorners(c, width, height) {
        var north = c.atDistanceAndAzimuth(height / 2, 0)
        var south = c.atDistanceAndAzimuth(height / 2, 180)
        return [
            north.atDistanceAndAzimuth(width / 2, 270),     // NW
            north.atDistanceAndAzimuth(width / 2, 90),      // NE
            south.atDistanceAndAzimuth(width / 2, 90),      // SE
            south.atDistanceAndAzimuth(width / 2, 270)      // SW
        ]
    }

    function _showOnMap() {
        _saveAll()

        var custom = _customParams()
        var p1 = point1Input.resolve(custom)
        if (!p1.ok) { _error(p1.error); return }
        var tgt = tgtInput.resolve(custom)
        if (!tgt.ok) { _error(tgt.error); return }

        var w = Grid.parseNum(boxWidthField.text)
        var h = Grid.parseNum(boxHeightField.text)
        if (isNaN(w) || isNaN(h) || w <= 0 || h <= 0 || w > 100000 || h > 100000) {
            _error(qsTr("Box width and height must be between 1 and 100000 m"))
            return
        }

        var p1Coord  = QtPositioning.coordinate(p1.lat, p1.lon)
        var tgtCoord = QtPositioning.coordinate(tgt.lat, tgt.lon)

        if (mapControl) {
            mapControl.showPointsAndTarget(p1Coord, tgtCoord, _boxCorners(tgtCoord, w, h))
            mapControl.centerOnPoints(p1Coord, tgtCoord)
        }

        var dist = p1Coord.distanceTo(tgtCoord)
        var brg  = p1Coord.azimuthTo(tgtCoord)
        _statusIsError = false
        _status = qsTr("P1:  %1, %2").arg(p1.lat.toFixed(6)).arg(p1.lon.toFixed(6)) + "\n" +
                  qsTr("TGT: %1, %2").arg(tgt.lat.toFixed(6)).arg(tgt.lon.toFixed(6)) + "\n" +
                  (dist < 1 ? qsTr("P1 and TGT are at the same place")
                            : qsTr("P1 → TGT: %1 m, bearing %2° (true)").arg(Math.round(dist)).arg(brg.toFixed(1)))
    }

    function _clear() {
        if (mapControl) {
            mapControl.clearPointsAndTarget()
        }
        _status = ""
    }

    Component.onCompleted: {
        originLatField.text = _load("originLat", "")
        originLonField.text = _load("originLon", "")
        sp1Field.text       = _load("sp1", "")
        sp2Field.text       = _load("sp2", "")
        feField.text        = _load("fe", "")
        fnField.text        = _load("fn", "")
        boxWidthField.text  = _load("boxW", "200")
        boxHeightField.text = _load("boxH", "200")
    }

    // Header - tap to open/close
    RowLayout {
        id:                 headerRow
        anchors.top:        parent.top
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.margins:    _margin

        QGCLabel {
            text:               qsTr("Point 1 / TGT")
            font.bold:          true
            Layout.fillWidth:   true
        }
        QGCLabel { text: _expanded ? "▲" : "▼" }
    }
    MouseArea {
        anchors.fill:   headerRow
        onClicked:      _expanded = !_expanded
    }

    QGCFlickable {
        id:                 flick
        anchors.top:        headerRow.bottom
        anchors.topMargin:  _spacing
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.bottom:     parent.bottom
        anchors.leftMargin: _margin
        anchors.rightMargin: _margin
        anchors.bottomMargin: _margin
        contentHeight:      mainLayout.implicitHeight
        contentWidth:       width
        visible:            _expanded

        ColumnLayout {
            id:         mainLayout
            width:      flick.width
            spacing:    _spacing

            PointInput {
                id:                 point1Input
                Layout.fillWidth:   true
                title:              qsTr("Point 1")
                settingsPrefix:     "p1"
                fieldWidth:         _fieldWidth
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: qgcPal.text; opacity: 0.3 }

            PointInput {
                id:                 tgtInput
                Layout.fillWidth:   true
                title:              qsTr("Point 2 (TGT)")
                settingsPrefix:     "tgt"
                fieldWidth:         _fieldWidth
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: qgcPal.text; opacity: 0.3 }

            QGCLabel { text: qsTr("Box around TGT"); font.bold: true }
            GridLayout {
                columns:        2
                columnSpacing:  ScreenTools.defaultFontPixelWidth
                rowSpacing:     ScreenTools.defaultFontPixelHeight / 4

                QGCLabel { text: qsTr("Width, E–W (m)"); Layout.fillWidth: true }
                QGCTextField {
                    id:                     boxWidthField
                    Layout.preferredWidth:  _fieldWidth
                    numericValuesOnly:      true
                }
                QGCLabel { text: qsTr("Height, N–S (m)"); Layout.fillWidth: true }
                QGCTextField {
                    id:                     boxHeightField
                    Layout.preferredWidth:  _fieldWidth
                    numericValuesOnly:      true
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: qgcPal.text; opacity: 0.3 }

            // Custom grid settings (LCC, WGS84) - tap to open/close
            Item {
                Layout.fillWidth:       true
                implicitHeight:         customHeader.implicitHeight

                RowLayout {
                    id:             customHeader
                    anchors.left:   parent.left
                    anchors.right:  parent.right

                    QGCLabel {
                        text:               qsTr("Custom Grid settings (LCC, WGS 84)")
                        font.bold:          true
                        Layout.fillWidth:   true
                        wrapMode:           Text.WordWrap
                    }
                    QGCLabel { text: _showCustom ? "▲" : "▼" }
                }
                MouseArea {
                    anchors.fill:   parent
                    onClicked:      _showCustom = !_showCustom
                }
            }

            GridLayout {
                columns:        2
                columnSpacing:  ScreenTools.defaultFontPixelWidth
                rowSpacing:     ScreenTools.defaultFontPixelHeight / 4
                visible:        _showCustom

                QGCLabel { text: qsTr("Origin latitude (°)"); Layout.fillWidth: true }
                QGCTextField { id: originLatField; Layout.preferredWidth: _fieldWidth; numericValuesOnly: true }
                QGCLabel { text: qsTr("Origin longitude (°)"); Layout.fillWidth: true }
                QGCTextField { id: originLonField; Layout.preferredWidth: _fieldWidth; numericValuesOnly: true }
                QGCLabel { text: qsTr("Standard parallel 1 (°)"); Layout.fillWidth: true }
                QGCTextField { id: sp1Field; Layout.preferredWidth: _fieldWidth; numericValuesOnly: true }
                QGCLabel { text: qsTr("Standard parallel 2 (°)"); Layout.fillWidth: true }
                QGCTextField { id: sp2Field; Layout.preferredWidth: _fieldWidth; numericValuesOnly: true }
                QGCLabel { text: qsTr("False Easting (m)"); Layout.fillWidth: true }
                QGCTextField { id: feField; Layout.preferredWidth: _fieldWidth; numericValuesOnly: true }
                QGCLabel { text: qsTr("False Northing (m)"); Layout.fillWidth: true }
                QGCTextField { id: fnField; Layout.preferredWidth: _fieldWidth; numericValuesOnly: true }
            }

            RowLayout {
                Layout.fillWidth:   true
                spacing:            ScreenTools.defaultFontPixelWidth

                QGCButton {
                    Layout.fillWidth:   true
                    text:               qsTr("Show on map")
                    primary:            true
                    onClicked:          _showOnMap()
                }
                QGCButton {
                    Layout.fillWidth:   true
                    text:               qsTr("Clear")
                    onClicked:          _clear()
                }
            }

            QGCLabel {
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                visible:            _status !== ""
                text:               _status
                color:              _statusIsError ? qgcPal.warningText : qgcPal.text
                font.pointSize:     ScreenTools.smallFontPointSize
            }
        }
    }
}
