import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView
import QGroundControl.FlightMap

// To implement a custom overlay copy this code to your own control in your custom code source. Then override the
// FlyViewCustomLayer.qml resource with your own qml. See the custom example and documentation for details.
Item {
    id: _root

    property var parentToolInsets               // These insets tell you what screen real estate is available for positioning the controls in your overlay
    property var totalToolInsets:   _toolInsets // These are the insets for your custom overlay additions
    property var mapControl

    // since this file is a placeholder for the custom layer in a standard build, we will just pass through the parent insets
    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeTopInset:       parentToolInsets.leftEdgeTopInset
        leftEdgeCenterInset:    parentToolInsets.leftEdgeCenterInset
        leftEdgeBottomInset:    parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset:   parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset:   parentToolInsets.rightEdgeBottomInset
        topEdgeLeftInset:       parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset:     parentToolInsets.topEdgeCenterInset
        topEdgeRightInset:      parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset:    parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  parentToolInsets.bottomEdgeCenterInset
        bottomEdgeRightInset:   parentToolInsets.bottomEdgeRightInset
    }

    // Left side panels: Go To Coordinates + Point 1 / TGT
    Column {
        id:                 leftPanels
        anchors.left:       parent.left
        anchors.top:        parent.top
        anchors.leftMargin: parentToolInsets.leftEdgeTopInset + ScreenTools.defaultFontPixelWidth
        anchors.topMargin:  parentToolInsets.topEdgeCenterInset + ScreenTools.defaultFontPixelWidth
        spacing:            ScreenTools.defaultFontPixelWidth

        // Type coordinates + press GO -> drone flies there
        GoToCoordinatesPanel {
            id:         goToPanel
            mapControl: _root.mapControl
            visible:    !!QGroundControl.multiVehicleManager.activeVehicle
        }

        // Point 1 + TGT with box, shown on the map
        PointsTargetPanel {
            mapControl: _root.mapControl
            maxHeight:  _root.height - leftPanels.anchors.topMargin - (goToPanel.visible ? goToPanel.height + leftPanels.spacing : 0) - parentToolInsets.bottomEdgeLeftInset - ScreenTools.defaultFontPixelWidth
        }
    }
}
