import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../config"

Rectangle {
    id: root

    color: Theme.background
    radius: 24

    property string mac: ""
    property string name: ""
    property bool connected: false
    property int battery: -1

    signal backRequested()

    readonly property string uiFont: "Noto Sans"
    readonly property string iconFont: "Symbols Nerd Font"

    Process {
        id: connectProcess

        command: [
            "bluetoothctl",
            "connect",
            root.mac
        ]

        onExited: root.refresh()
    }

    Process {
        id: disconnectProcess

        command: [
            "bluetoothctl",
            "disconnect",
            root.mac
        ]

        onExited: root.refresh()
    }

    Process {
        id: forgetProcess

        command: [
            "bluetoothctl",
            "remove",
            root.mac
        ]

        onExited: root.backRequested()
    }

    Process {
        id: refreshProcess

        command: [
            "bash",
            "-c",
            "info=$(bluetoothctl info \"$1\"); " +
            "connected=$(printf '%s\\n' \"$info\" | awk -F': ' '/Connected:/ {print $2}'); " +
            "battery=$(printf '%s\\n' \"$info\" | awk -F'[()]' '/Battery Percentage:/ {print $2}'); " +
            "printf '%s\\t%s\\n' \"$connected\" \"$battery\"",
            "notch",
            root.mac
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\t")

                if (parts.length > 0)
                    root.connected = parts[0] === "yes"

                if (parts.length > 1 && parts[1] !== "") {
                    var value = parseInt(parts[1])

                    if (!isNaN(value))
                        root.battery = value
                }
            }
        }
    }

    function refresh() {
        refreshProcess.running = true
    }

    function connectDevice() {
        connectProcess.running = true
    }

    function disconnectDevice() {
        disconnectProcess.running = true
    }

    function forgetDevice() {
        forgetProcess.running = true
    }

    Component.onCompleted: refresh()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            Layout.minimumHeight: 40
            Layout.maximumHeight: 40

            radius: 14
            color: Theme.surface

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter

                text: "󰁍"
                color: Theme.text

                font.family: root.iconFont
                font.pixelSize: 17

                MouseArea {
                    anchors.fill: parent

                    onClicked: root.backRequested()
                }
            }

            Text {
                anchors.centerIn: parent

                text: "Bluetooth Details"
                color: Theme.text

                font.family: root.uiFont
                font.weight: Font.DemiBold
                font.pixelSize: 12
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 94
            Layout.minimumHeight: 94
            Layout.maximumHeight: 94

            radius: 16
            color: Theme.surface

            Text {
                id: deviceIcon

                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                text: "󰂯"

                color: root.connected
                    ? Theme.accent
                    : Theme.text

                font.family: root.iconFont
                font.pixelSize: 30
            }

            Column {
                anchors.left: deviceIcon.right
                anchors.leftMargin: 14
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter

                spacing: 3

                Text {
                    width: parent.width

                    text: root.name

                    color: Theme.text

                    font.family: root.uiFont
                    font.weight: Font.DemiBold
                    font.pixelSize: 13

                    elide: Text.ElideRight
                }

                Text {
                    text: "Bluetooth Device"

                    color: Theme.textSecondary

                    font.family: root.uiFont
                    font.pixelSize: 8
                }

                Text {
                    text: root.connected
                        ? "Connected"
                        : "Not connected"

                    color: root.connected
                        ? Theme.accent
                        : Theme.textSecondary

                    font.family: root.uiFont
                    font.pixelSize: 8
                }

                Text {
                    visible: root.battery >= 0

                    text: "Battery  •  " + root.battery + "%"

                    color: Theme.textSecondary

                    font.family: root.uiFont
                    font.pixelSize: 8
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            Layout.minimumHeight: 72
            Layout.maximumHeight: 72

            radius: 16
            color: Theme.surface

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.top: parent.top
                anchors.topMargin: 10

                text: "Device"

                color: Theme.text

                font.family: root.uiFont
                font.weight: Font.DemiBold
                font.pixelSize: 10
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12

                text: "Address"

                color: Theme.textSecondary

                font.family: root.uiFont
                font.pixelSize: 8
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12

                text: root.mac

                color: Theme.text

                font.family: root.uiFont
                font.pixelSize: 8
            }
        }

        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            Layout.minimumHeight: 38
            Layout.maximumHeight: 38

            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                Layout.minimumHeight: 38
                Layout.maximumHeight: 38

                radius: 11

                color: root.connected
                    ? Theme.outline
                    : Theme.accent

                Text {
                    anchors.centerIn: parent

                    text: root.connected
                        ? "Disconnect"
                        : "Connect"

                    color: root.connected
                        ? Theme.text
                        : Theme.background

                    font.family: root.uiFont
                    font.weight: Font.DemiBold
                    font.pixelSize: 9
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        if (root.connected)
                            root.disconnectDevice()
                        else
                            root.connectDevice()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                Layout.minimumHeight: 38
                Layout.maximumHeight: 38

                radius: 11
                color: Theme.surface

                Text {
                    anchors.centerIn: parent

                    text: "Forget Device"

                    color: Theme.textSecondary

                    font.family: root.uiFont
                    font.pixelSize: 9
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: root.forgetDevice()
                }
            }
        }
    }
}
