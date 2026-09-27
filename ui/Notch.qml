import QtQuick
import QtQuick.Layouts
import "../config"
import "./features"
import "./features/wifi"
import "./features/bluetooth"

Item {
    id: root

    property bool expanded: false
    property bool wifiMenuOpen: false
    property bool bluetoothMenuOpen: false

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
            id: expandedLoader

            anchors.fill: parent

            sourceComponent: root.expanded
                ? expandedView
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

                visible: Config.visualizerEnabled
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: implicitWidth
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
        id: expandedView

        Item {
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.expanded

                onExited: {
                    root.expanded = false
                    root.wifiMenuOpen = false
                    root.bluetoothMenuOpen = false
                }
            }

            Loader {
                anchors.fill: parent

                sourceComponent:
                    root.wifiMenuOpen
                        ? wifiMenu
                        : root.bluetoothMenuOpen
                            ? bluetoothMenu
                            : controlCenter

                z: 1
            }
        }
    }

    Component {
        id: controlCenter

        ControlCenter {
            anchors.fill: parent

            onWifiRequested: {
                root.wifiMenuOpen = true
                root.bluetoothMenuOpen = false
            }

            onBluetoothRequested: {
                root.bluetoothMenuOpen = true
                root.wifiMenuOpen = false
            }
        }
    }

    Component {
        id: wifiMenu

        Wifi {
            anchors.fill: parent
        }
    }

    Component {
        id: bluetoothMenu

        Bluetooth {
            anchors.fill: parent
        }
    }
}
