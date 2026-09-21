import QtQuick
import QtQuick.Layouts
import "../config"
import "./features"

Item {
    id: root

    property bool expanded: false

    readonly property real compactWidth: Geometry.compactWidth
    readonly property real compactHeight: Geometry.compactHeight
    readonly property real expandedWidth: 420
    readonly property real expandedHeight: 320

    implicitWidth: expanded ? expandedWidth : compactWidth
    implicitHeight: expanded ? expandedHeight : compactHeight

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent

        radius: root.expanded ? 24 : Geometry.compactRadius
        color: Theme.background

        Behavior on radius {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        Loader {
            anchors.fill: parent
            sourceComponent: root.expanded
                ? controlCenter
                : compact
        }
    }

    Component {
        id: compact

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 2

            Time {
                visible: Config.timeEnabled
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
            }

            Visualizer {
                id: visualizer

                visible: Config.visualizerEnabled && active
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: active ? implicitWidth : 0
                Layout.fillHeight: true
            }

            Item {
                Layout.fillWidth: true
            }

            Battery {
                visible: Config.batteryEnabled
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    Component {
        id: controlCenter

        Item {
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.expanded

                onExited: {
                    root.expanded = false
                }
            }

            ControlCenter {
                anchors.fill: parent
                z: 1
            }
        }
    }
}
