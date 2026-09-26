import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../config"

Rectangle {
    id: root

    color: Theme.background
    radius: 24

    property bool bluetoothEnabled: false
    property var devices: []

    Process {
        id: statusProcess

        command: ["bluetoothctl", "show"]

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n")
                var powered = false

                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()

                    if (line.indexOf("Powered:") === 0) {
                        powered = line.substring(8).trim() === "yes"
                        break
                    }
                }

                root.bluetoothEnabled = powered
                devicesProcess.running = true
            }
        }
    }

    Process {
        id: devicesProcess

        command: [
            "bash",
            "-c",
            "bluetoothctl devices | while read -r type mac name; do " +
            "info=$(bluetoothctl info \"$mac\"); " +
            "connected=$(printf '%s\\n' \"$info\" | awk -F': ' '/Connected:/ {print $2}'); " +
            "battery=$(printf '%s\\n' \"$info\" | awk -F'[()]' '/Battery Percentage:/ {print $2}'); " +
            "printf '%s\\t%s\\t%s\\t%s\\n' \"$mac\" \"$name\" \"$connected\" \"$battery\"; " +
            "done"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                var result = []

                for (var i = 0; i < lines.length; i++) {
                    if (!lines[i])
                        continue

                    var parts = lines[i].split("\t")

                    if (parts.length < 4)
                        continue

                    result.push({
                        mac: parts[0],
                        name: parts[1],
                        connected: parts[2] === "yes",
                        battery: parts[3] !== ""
                            ? parseInt(parts[3])
                            : -1
                    })
                }

                root.devices = result
            }
        }
    }

    Process {
        id: powerProcess

        property bool targetState: false

        command: [
            "bluetoothctl",
            "power",
            targetState ? "on" : "off"
        ]

        onExited: root.refresh()
    }

    Process {
        id: connectProcess

        property string address: ""

        command: [
            "bluetoothctl",
            "connect",
            address
        ]

        onExited: root.refresh()
    }

    Process {
        id: disconnectProcess

        property string address: ""

        command: [
            "bluetoothctl",
            "disconnect",
            address
        ]

        onExited: root.refresh()
    }

    function refresh() {
        statusProcess.running = true
    }

    function toggleBluetooth() {
        powerProcess.targetState = !root.bluetoothEnabled
        powerProcess.running = true
    }

    function toggleDevice(mac, connected) {
        if (connected) {
            disconnectProcess.address = mac
            disconnectProcess.running = true
        } else {
            connectProcess.address = mac
            connectProcess.running = true
        }
    }

    Component.onCompleted: refresh()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52

            radius: 16
            color: Theme.surface

            Text {
                id: bluetoothIcon

                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter

                text: root.bluetoothEnabled
                    ? "󰂯"
                    : "󰂲"

                color: root.bluetoothEnabled
                    ? Theme.accent
                    : Theme.text

                font.family: "Symbols Nerd Font"
                font.pixelSize: 19
            }

            Column {
                anchors.left: bluetoothIcon.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                spacing: 0

                Text {
                    text: "Bluetooth"
                    color: Theme.text
                    font.bold: true
                    font.pixelSize: 12
                }

                Text {
                    text: root.bluetoothEnabled
                        ? "On"
                        : "Off"

                    color: Theme.textSecondary
                    font.pixelSize: 8
                }
            }

            Rectangle {
                id: bluetoothToggle

                width: 46
                height: 24

                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                radius: 12

                color: root.bluetoothEnabled
                    ? Theme.accent
                    : Theme.outline

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9

                    anchors.verticalCenter: parent.verticalCenter

                    x: root.bluetoothEnabled
                        ? parent.width - width - 3
                        : 3

                    color: Theme.background

                    Behavior on x {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        root.toggleBluetooth()
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: 16
            color: Theme.surface

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32

                    Text {
                        text: "Paired Devices"

                        color: Theme.text
                        font.bold: true
                        font.pixelSize: 11

                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        Layout.alignment: Qt.AlignVCenter

                        radius: 10
                        color: Theme.background

                        Text {
                            anchors.centerIn: parent

                            text: "󰑐"

                            color: Theme.text
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 14
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                root.refresh()
                            }
                        }
                    }
                }

                ListView {
                    id: deviceList

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    clip: true
                    model: root.devices
                    spacing: 2

                    delegate: Rectangle {
                        width: deviceList.width
                        height: 48

                        radius: 11

                        color: modelData.connected
                            ? Theme.outline
                            : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 7
                            anchors.rightMargin: 7
                            spacing: 7

                            Text {
                                text: "󰂱"

                                color: modelData.connected
                                    ? Theme.accent
                                    : Theme.text

                                font.family: "Symbols Nerd Font"
                                font.pixelSize: 16

                                Layout.alignment: Qt.AlignVCenter
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    text: modelData.name

                                    color: Theme.text
                                    font.bold: modelData.connected
                                    font.pixelSize: 9

                                    elide: Text.ElideRight

                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: modelData.connected
                                        ? "Connected"
                                        : "Paired"

                                    color: modelData.connected
                                        ? Theme.accent
                                        : Theme.textSecondary

                                    font.pixelSize: 7
                                }
                            }

                            Text {
                                visible: modelData.battery >= 0

                                text: modelData.battery + "%"

                                color: modelData.connected
                                    ? Theme.accent
                                    : Theme.textSecondary

                                font.pixelSize: 7

                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: modelData.connected
                                    ? "Connected"
                                    : "Connect"

                                color: modelData.connected
                                    ? Theme.accent
                                    : Theme.textSecondary

                                font.pixelSize: 7

                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            enabled: root.bluetoothEnabled

                            onClicked: {
                                root.toggleDevice(
                                    modelData.mac,
                                    modelData.connected
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
