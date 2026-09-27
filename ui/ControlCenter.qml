import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../config"
import "./features/media"
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

    property string powerProfile: "balanced"
    property var powerProfiles: []

    signal wifiRequested()
    signal bluetoothRequested()

    readonly property string uiFont: "Noto Sans"
    readonly property string iconFont: "Symbols Nerd Font"

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

    Process {
        id: powerProfilesProcess

        command: [
            "bash",
            "-c",
            "powerprofilesctl list | " +
            "grep -E '^[[:space:]]*\\*?[[:space:]]*(performance|balanced|power-saver):' | " +
            "sed -E 's/^[[:space:]]*\\*?[[:space:]]*([^:]+):.*$/\\1/'"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                var profiles = []

                for (var i = 0; i < lines.length; i++) {
                    var profile = lines[i].trim()

                    if (profile === "")
                        continue

                    if (profiles.indexOf(profile) === -1)
                        profiles.push(profile)
                }

                root.powerProfiles = profiles
                powerProfileProcess.running = true
            }
        }
    }

    Process {
        id: powerProfileProcess

        command: [
            "powerprofilesctl",
            "get"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var value = text.trim()

                if (value !== "")
                    root.powerProfile = value
            }
        }
    }

    Process {
        id: setPowerProfileProcess

        property string targetProfile: ""

        command: [
            "powerprofilesctl",
            "set",
            targetProfile
        ]

        onExited: {
            powerProfileProcess.running = true
            powerTile.scale = 0.94
            powerChangeAnimation.restart()

            Qt.callLater(function() {
                powerTile.scale = 1
            })
        }
    }

    function refreshWifi() {
        wifiStatusProcess.running = true
    }

    function refreshBluetooth() {
        bluetoothStatusProcess.running = true
    }

    function refreshPowerProfile() {
        powerProfilesProcess.running = true
    }

    function cyclePowerProfile() {
        if (root.powerProfiles.length === 0)
            return

        var index = root.powerProfiles.indexOf(root.powerProfile)

        if (index < 0)
            index = 0
        else
            index = (index + 1) % root.powerProfiles.length

        setPowerProfileProcess.targetProfile = root.powerProfiles[index]
        setPowerProfileProcess.running = true
    }

    Component.onCompleted: {
        getVolumeProcess.running = true
        getBrightnessProcess.running = true
        refreshWifi()
        refreshBluetooth()
        refreshPowerProfile()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        Media {
            Layout.fillWidth: true
            Layout.preferredHeight: 148
            Layout.minimumHeight: 148
            Layout.maximumHeight: 148
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

                        font.family: root.iconFont
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

                        font.family: root.uiFont
                        font.weight: Font.DemiBold
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

                        font.family: root.iconFont
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

                        font.family: root.uiFont
                        font.weight: Font.DemiBold
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
                id: powerTile

                Layout.fillWidth: true
                Layout.preferredHeight: 48

                radius: 14
                color: Theme.accent

                scale: 1

                Behavior on scale {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutBack
                    }
                }

                SequentialAnimation {
                    id: powerChangeAnimation

                    PropertyAction {
                        target: powerIcon
                        property: "opacity"
                        value: 0
                    }

                    PropertyAction {
                        target: powerLabel
                        property: "opacity"
                        value: 0
                    }

                    PropertyAction {
                        target: powerIcon
                        property: "rotation"
                        value: -90
                    }

                    PauseAnimation {
                        duration: 60
                    }

                    ParallelAnimation {
                        NumberAnimation {
                            target: powerIcon
                            property: "opacity"
                            to: 1
                            duration: 180
                            easing.type: Easing.OutCubic
                        }

                        NumberAnimation {
                            target: powerIcon
                            property: "rotation"
                            to: 0
                            duration: 220
                            easing.type: Easing.OutBack
                        }

                        NumberAnimation {
                            target: powerIcon
                            property: "x"
                            to: 0
                            duration: 180
                            easing.type: Easing.OutCubic
                        }

                        NumberAnimation {
                            target: powerLabel
                            property: "opacity"
                            to: 1
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        id: powerIcon

                        text: root.powerProfile === "performance"
                            ? "󰓅"
                            : root.powerProfile === "power-saver"
                                ? "󰂄"
                                : "󰾆"

                        color: Theme.background

                        font.family: root.iconFont
                        font.pixelSize: 17

                        opacity: 1
                        rotation: 0
                        x: 0
                    }

                    Text {
                        id: powerLabel

                        text: root.powerProfile === "performance"
                            ? "Performance"
                            : root.powerProfile === "power-saver"
                                ? "Power Saver"
                                : "Balanced"

                        color: Theme.background

                        font.family: root.uiFont
                        font.weight: Font.DemiBold
                        font.pixelSize: 9

                        opacity: 1

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        root.cyclePowerProfile()
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Brightness " + Math.round(root.brightness * 100) + "%"

                color: Theme.textSecondary
                font.family: root.uiFont
                font.pixelSize: 10
            }

            Rectangle {
                id: brightnessTrack

                Layout.fillWidth: true
                Layout.preferredHeight: 14

                radius: 7
                color: Theme.surface

                Rectangle {
                    width: brightnessTrack.width * root.brightness
                    height: parent.height

                    radius: parent.radius
                    color: Theme.accent
                }

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9

                    anchors.verticalCenter: parent.verticalCenter

                    x: Math.max(
                        0,
                        Math.min(
                            brightnessTrack.width - width,
                            brightnessTrack.width * root.brightness - width / 2
                        )
                    )

                    color: Theme.text

                    Behavior on x {
                        NumberAnimation {
                            duration: 70
                            easing.type: Easing.OutCubic
                        }
                    }
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
            spacing: 6

            Text {
                text: "Volume " + Math.round(root.volume * 100) + "%"

                color: Theme.textSecondary
                font.family: root.uiFont
                font.pixelSize: 10
            }

            Rectangle {
                id: volumeTrack

                Layout.fillWidth: true
                Layout.preferredHeight: 14

                radius: 7
                color: Theme.surface

                Rectangle {
                    width: volumeTrack.width * root.volume
                    height: parent.height

                    radius: parent.radius
                    color: Theme.accent
                }

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9

                    anchors.verticalCenter: parent.verticalCenter

                    x: Math.max(
                        0,
                        Math.min(
                            volumeTrack.width - width,
                            volumeTrack.width * root.volume - width / 2
                        )
                    )

                    color: Theme.text

                    Behavior on x {
                        NumberAnimation {
                            duration: 70
                            easing.type: Easing.OutCubic
                        }
                    }
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
