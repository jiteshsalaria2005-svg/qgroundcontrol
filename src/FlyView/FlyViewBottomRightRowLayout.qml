import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView

RowLayout {
    // Slim see-through strip: battery, voltage, distance, altitude, speeds
    SlimTelemetryStrip {
        Layout.alignment:       Qt.AlignBottom
    }

    FlyViewInstrumentPanel {
        id:                 instrumentPanel
        Layout.alignment:   Qt.AlignBottom
        visible:            QGroundControl.corePlugin.options.flyView.showInstrumentPanel && _showSingleVehicleUI
    }
}
