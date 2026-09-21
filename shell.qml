import Quickshell
import QtQuick
import "config"
import "ui"

Scope {
    PanelWindow {
        anchors {
            top: true
        }

        margins {
            top: Geometry.compactTopMargin
        }

        implicitWidth: Geometry.compactWidth
        implicitHeight: Geometry.compactHeight

        exclusiveZone: Geometry.compactExclusiveZone

        color: "transparent"

        Notch {}
    }
}
