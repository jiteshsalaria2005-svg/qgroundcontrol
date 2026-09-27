import QtQuick
import QtQuick.Layouts
import QtPositioning

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView

import "GridConversions.js" as Grid

/// Fly screen: small "GO TO" button. Tap it to open a panel where a point is entered as
/// Lat/Long, Everest grid or Custom grid. GO sends the vehicle there in Guided mode
/// (keeps its current altitude).
Item {
    id:             root
    implicitWidth:  _expanded ? panel.width : chip.width
    implicitHeight: _expanded ? panel.height : chip.height
    width:          implicitWidth
    height:         implicitHeight

    property var    mapControl                  // FlyViewMap, used to show the "Go here" marker
    property real   maxHeight:  ScreenTools.defaultFontPixelHeight * 25

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property var    _guidedController:  globals.guidedControllerFlyView
    property bool   _canGo:             _guidedController ? _guidedController.showGotoLocation : false
    property bool   _expanded:          false
    property bool   _showCustom:        false
    property real   _margin:            ScreenTools.defaultFontPixelHeight / 2
    property real   _fieldWidth:        ScreenTools.defaultFontPixelWidth * 14
    property string _status:            ""
    property bool   _statusIsError:     false

    readonly property color _bgColor:       Qt.rgba(0.05, 0.07, 0.1, 0.85)
    readonly property color _textColor:     "white"
    readonly property color _accentColor:   "#FFD54F"     // amber, readable on map and satellite
    readonly property color _errorColor:    "#FF8A80"

    function _key(name) { return "PointsTarget_" + name }   // shared with the Point 1 / TGT panel

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

    function _saveCustom() {
        QGroundControl.saveGlobalSetting(_key("originLat"), originLatField.text)
        QGroundControl.saveGlobalSetting(_key("originLon"), originLonField.text)
        QGroundControl.saveGlobalSetting(_key("sp1"),       sp1Field.text)
        QGroundControl.saveGlobalSetting(_key("sp2"),       sp2Field.text)
        QGroundControl.saveGlobalSetting(_key("fe"),        feField.text)
        QGroundControl.saveGlobalSetting(_key("fn"),        fnField.text)
    }

    function _loadCustom() {
        originLatField.text = QGroundControl.loadGlobalSetting(_key("originLat"), "")
        originLonField.text = QGroundControl.loadGlobalSetting(_key("originLon"), "")
        sp1Field.text       = QGroundControl.loadGlobalSetting(_key("sp1"), "")
        sp2Field.text       = QGroundControl.loadGlobalSetting(_key("sp2"), "")
        feField.text        = QGroundControl.loadGlobalSetting(_key("fe"), "")
        fnField.text        = QGroundControl.loadGlobalSetting(_key("fn"), "")
    }

    function _setStatus(text, isError) {
        _status = text
        _statusIsError = isError
    }

    function _go() {
        pointInput.saveInputs()
        _saveCustom()

        var r = pointInput.resolve(_customParams())
        if (!r.ok) {
            _setStatus(r.error, true)
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

        var coord = QtPositioning.coordinate(r.lat, r.lon)
        if (_guidedController.executeAction(_guidedController.actionGoto, coord)) {
            if (mapControl) {
                mapControl.showGotoMarker(coord)
            }
            var dist = _activeVehicle.coordinate.isValid ? Math.round(_activeVehicle.coordinate.distanceTo(coord)) : -1
            _setStatus((dist >= 0 ? qsTr("Going: %1 m away").arg(dist) : qsTr("Going to point")) +
                       "\n" + r.lat.toFixed(6) + ", " + r.lon.toFixed(6), false)
        } else {
            // Vehicle code already shows the reason (e.g. too far) as an app message
            _setStatus(qsTr("Drone did not accept the command"), true)
        }
    }

    Component.onCompleted: _loadCustom()

    // ---- Collapsed: small chip ----
    Rectangle {
        id:             chip
        visible:        !_expanded
        width:          chipLabel.implicitWidth + _margin * 2
        height:         ScreenTools.defaultFontPixelHeight * 1.8
        radius:         height / 2
        color:          _bgColor
        border.color:   _accentColor
        border.width:   1

        QGCLabel {
            id:                 chipLabel
            anchors.centerIn:   parent
            text:               qsTr("GO TO")
            color:              _accentColor
            font.bold:          true
        }

        QGCMouseArea {
            anchors.fill:   parent
            onClicked:      _expanded = true
        }
    }

    // ---- Expanded panel ----
    Rectangle {
        id:             panel
        visible:        _expanded
        width:          mainLayout.implicitWidth + _margin * 2
        height:         Math.min(root.maxHeight, headerRow.height + flick.contentHeight + _margin * 3)
        radius:         _margin
        color:          _bgColor
        border.color:   _accentColor
        border.width:   1
        clip:           true

        DeadMouseArea { anchors.fill: parent }

        RowLayout {
            id:                 headerRow
            anchors.top:        parent.top
            anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.margins:    _margin

            QGCLabel {
                text:               qsTr("GO TO")
                color:              _accentColor
                font.bold:          true
                Layout.fillWidth:   true
            }
            QGCLabel {
                text:       "✕"
                color:      _textColor
                font.bold:  true
            }
        }
        QGCMouseArea {
            anchors.fill:   headerRow
            onClicked:      _expanded = false
        }

        QGCFlickable {
            id:                     flick
            anchors.top:            headerRow.bottom
            anchors.topMargin:      _margin / 2
            anchors.left:           parent.left
            anchors.right:          parent.right
            anchors.bottom:         parent.bottom
            anchors.leftMargin:     _margin
            anchors.rightMargin:    _margin
            anchors.bottomMargin:   _margin
            contentHeight:          mainLayout.implicitHeight
            contentWidth:           width

            ColumnLayout {
                id:         mainLayout
                width:      flick.width
                spacing:    ScreenTools.defaultFontPixelHeight / 3

                PointInput {
                    id:                 pointInput
                    Layout.fillWidth:   true
                    title:              qsTr("Point")
                    settingsPrefix:     "goto"
                    fieldWidth:         _fieldWidth
                    labelColor:         _textColor
                }

                // Custom grid settings (shared with Point 1 / TGT panel)
                Item {
                    Layout.fillWidth:   true
                    implicitHeight:     customHeader.implicitHeight
                    visible:            pointInput._format === pointInput.formatCustom

                    RowLayout {
                        id:             customHeader
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        QGCLabel {
                            text:               qsTr("Custom Grid settings")
                            color:              _accentColor
                            Layout.fillWidth:   true
                        }
                        QGCLabel { text: _showCustom ? "▲" : "▼"; color: _accentColor }
                    }
                    QGCMouseArea {
                        anchors.fill:   parent
                        onClicked:      _showCustom = !_showCustom
                    }
                }

                GridLayout {
                    columns:        2
                    columnSpacing:  ScreenTools.defaultFontPixelWidth
                    rowSpacing:     ScreenTools.defaultFontPixelHeight / 4
                    visible:        _showCustom && pointInput._format === pointInput.formatCustom

                    QGCLabel { text: qsTr("Origin lat (°)");    color: _textColor; Layout.fillWidth: true }
                    QGCTextField { id: originLatField; Layout.preferredWidth: _fieldWidth; numericValuesOnly: true }
                    QGCLabel { text: qsTr("Origin long (°)");   color: _textColor; Layout.fillWidth: true }
                    QGCTextField { id: originLonField; Layout.preferredWidth: _fieldWidth; numericValuesOnly: true }
                    QGCLabel { text: qsTr("Std parallel 1 (°)"); color: _textColor; Layout.fillWidth: true }
                    QGCTextField { id: sp1Field; Layout.preferredWidth: _fieldWidth; numericValuesOnly: true }
                    QGCLabel { text: qsTr("Std parallel 2 (°)"); color: _textColor; Layout.fillWidth: true }
                    QGCTextField { id: sp2Field; Layout.preferredWidth: _fieldWidth; numericValuesOnly: true }
                    QGCLabel { text: qsTr("False Easting (m)");  color: _textColor; Layout.fillWidth: true }
                    QGCTextField { id: feField; Layout.preferredWidth: _fieldWidth; numericValuesOnly: true }
                    QGCLabel { text: qsTr("False Northing (m)"); color: _textColor; Layout.fillWidth: true }
                    QGCTextField { id: fnField; Layout.preferredWidth: _fieldWidth; numericValuesOnly: true }
                }

                QGCButton {
                    Layout.fillWidth:   true
                    text:               qsTr("GO")
                    primary:            true
                    enabled:            _canGo
                    onClicked:          _go()
                }

                QGCLabel {
                    Layout.fillWidth:       true
                    Layout.maximumWidth:    _fieldWidth * 2
                    wrapMode:               Text.WordWrap
                    font.pointSize:         ScreenTools.smallFontPointSize
                    color:                  _status !== "" ? (_statusIsError ? _errorColor : _accentColor) : _textColor
                    text: {
                        if (_status !== "") {
                            return _status
                        }
                        if (!_activeVehicle) {
                            return qsTr("Connect a drone")
                        }
                        return _canGo ? qsTr("Ready. Keeps current height.")
                                      : qsTr("Take off first, then press GO")
                    }
                }
            }
        }
    }
}
