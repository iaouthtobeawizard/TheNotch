import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../config"

Rectangle {
    id: root

    color: Theme.background
    radius: 24

    property real brightness: 0.5
    property real volume: 0.5

    property bool wifiEnabled: false
    property string wifiSsid: ""

    property bool bluetoothEnabled: false
    property string bluetoothDevice: ""

    signal wifiRequested()
    signal bluetoothRequested()

    Process {
        id: volumeProcess

        command: [
            "notch-volume",
            String(root.volume)
        ]

        onExited: {
            console.log("Volume backend exited:", exitCode)
        }
    }

    Process {
        id: brightnessProcess

        command: [
            "notch-backend",
            "brightness",
            String(root.brightness)
        ]

        onExited: {
            console.log("Brightness backend exited:", exitCode)
        }
    }

    Process {
        id: getVolumeProcess

        command: [
            "notch-backend",
            "get-volume"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var value = parseFloat(text.trim())

                if (!isNaN(value))
                    root.volume = Math.max(0, Math.min(1, value))
            }
        }
    }

    Process {
        id: getBrightnessProcess

        command: [
            "notch-backend",
            "get-brightness"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var value = parseFloat(text.trim())

                if (!isNaN(value))
                    root.brightness = Math.max(0, Math.min(1, value))
            }
        }
    }

    Process {
        id: wifiStatusProcess

        command: [
            "nmcli",
            "-t",
            "-f",
            "WIFI",
            "radio"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled"
                wifiConnectionProcess.running = true
            }
        }
    }

    Process {
        id: wifiConnectionProcess

        command: [
            "nmcli",
            "-t",
            "-f",
            "ACTIVE,SSID",
            "device",
            "wifi",
            "list",
            "--rescan",
            "no"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                var connected = ""

                for (var i = 0; i < lines.length; i++) {
                    if (!lines[i])
                        continue

                    var parts = lines[i].split(":")

                    if (parts.length < 2)
                        continue

                    if (parts[0] === "yes") {
                        connected = parts.slice(1).join(":")
                        break
                    }
                }

                root.wifiSsid = connected
            }
        }
    }

    Process {
        id: bluetoothStatusProcess

        command: [
            "bluetoothctl",
            "show"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n")
                var enabled = false

                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim()

                    if (line.indexOf("Powered:") === 0) {
                        enabled = line.substring(8).trim() === "yes"
                        break
                    }
                }

                root.bluetoothEnabled = enabled
                bluetoothDevicesProcess.running = true
            }
        }
    }

    Process {
        id: bluetoothDevicesProcess

        command: [
            "bash",
            "-c",
            "bluetoothctl devices | while read -r type mac name; do " +
            "info=$(bluetoothctl info \"$mac\"); " +
            "connected=$(printf '%s\\n' \"$info\" | awk -F': ' '/Connected:/ {print $2}'); " +
            "if [ \"$connected\" = \"yes\" ]; then " +
            "printf '%s\\n' \"$name\"; " +
            "fi; " +
            "done"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                var connected = ""

                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].trim() !== "") {
                        connected = lines[i].trim()
                        break
                    }
                }

                root.bluetoothDevice = connected
            }
        }
    }

    function refreshWifi() {
        wifiStatusProcess.running = true
    }

    function refreshBluetooth() {
        bluetoothStatusProcess.running = true
    }

    Component.onCompleted: {
        getVolumeProcess.running = true
        getBrightnessProcess.running = true
        refreshWifi()
        refreshBluetooth()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 16
            color: Theme.surface

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 4

                Text {
                    text: "Media"
                    color: Theme.text
                    font.bold: true
                    font.pixelSize: 15
                }

                Text {
                    text: "Nothing playing"
                    color: Theme.textSecondary
                    font.pixelSize: 12
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 14

                color: root.wifiEnabled
                    ? Theme.accent
                    : Theme.surface

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: root.wifiEnabled
                            ? "󰤨"
                            : "󰤭"

                        color: root.wifiEnabled
                            ? Theme.background
                            : Theme.text

                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 17
                    }

                    Text {
                        text: !root.wifiEnabled
                            ? "OFF"
                            : root.wifiSsid !== ""
                                ? root.wifiSsid
                                : "ON"

                        color: root.wifiEnabled
                            ? Theme.background
                            : Theme.text

                        font.bold: true
                        font.pixelSize: 9
                        elide: Text.ElideRight
                        maximumLineCount: 1

                        Layout.maximumWidth: 72
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        root.wifiRequested()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 14

                color: root.bluetoothEnabled && root.bluetoothDevice !== ""
                    ? Theme.accent
                    : Theme.surface

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: root.bluetoothEnabled
                            ? "󰂯"
                            : "󰂲"

                        color: root.bluetoothEnabled && root.bluetoothDevice !== ""
                            ? Theme.background
                            : Theme.text

                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 17
                    }

                    Text {
                        text: !root.bluetoothEnabled
                            ? "OFF"
                            : root.bluetoothDevice !== ""
                                ? root.bluetoothDevice
                                : "ON"

                        color: root.bluetoothEnabled && root.bluetoothDevice !== ""
                            ? Theme.background
                            : Theme.text

                        font.bold: true
                        font.pixelSize: 9
                        elide: Text.ElideRight
                        maximumLineCount: 1

                        Layout.maximumWidth: 72
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        root.bluetoothRequested()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 14
                color: Theme.surface

                Text {
                    anchors.centerIn: parent
                    text: "Power"
                    color: Theme.text
                    font.bold: true
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            Text {
                text: "Brightness " + Math.round(root.brightness * 100) + "%"
                color: Theme.textSecondary
                font.pixelSize: 11
            }

            Rectangle {
                id: brightnessTrack

                Layout.fillWidth: true
                Layout.preferredHeight: 10
                radius: 5
                color: Theme.surface

                Rectangle {
                    width: brightnessTrack.width * root.brightness
                    height: parent.height
                    radius: parent.radius
                    color: Theme.accent
                }

                MouseArea {
                    anchors.fill: parent

                    function updateBrightness(mouseX) {
                        root.brightness = Math.max(
                            0,
                            Math.min(1, mouseX / width)
                        )

                        brightnessProcess.command = [
                            "notch-backend",
                            "brightness",
                            String(root.brightness)
                        ]

                        brightnessProcess.running = true
                    }

                    onPressed: mouse => {
                        updateBrightness(mouse.x)
                    }

                    onPositionChanged: mouse => {
                        if (pressed)
                            updateBrightness(mouse.x)
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            Text {
                text: "Volume " + Math.round(root.volume * 100) + "%"
                color: Theme.textSecondary
                font.pixelSize: 11
            }

            Rectangle {
                id: volumeTrack

                Layout.fillWidth: true
                Layout.preferredHeight: 10
                radius: 5
                color: Theme.surface

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * root.volume
                    height: parent.height
                    radius: parent.radius
                    color: Theme.accent
                }

                MouseArea {
                    anchors.fill: parent

                    function updateVolume(mouseX) {
                        root.volume = Math.max(
                            0,
                            Math.min(1, mouseX / width)
                        )

                        volumeProcess.command = [
                            "notch-volume",
                            String(root.volume)
                        ]

                        volumeProcess.running = true
                    }

                    onPressed: mouse => {
                        updateVolume(mouse.x)
                    }

                    onPositionChanged: mouse => {
                        if (pressed)
                            updateVolume(mouse.x)
                    }
                }
            }
        }
    }
}
