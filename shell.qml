import Quickshell
import QtQuick
import "config"
import "ui"

Scope {
    PanelWindow {
        id: panel

        anchors {
            top: true
        }

        margins {
            top: Geometry.compactTopMargin
        }

        implicitWidth: notch.implicitWidth
        implicitHeight: notch.implicitHeight

        exclusiveZone: Geometry.compactExclusiveZone

        color: "transparent"

        Notch {
            id: notch

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }

        MouseArea {
            anchors.fill: notch
            enabled: !notch.expanded
            hoverEnabled: true

            onEntered: {
                notch.expanded = true
            }
        }
    }
}
