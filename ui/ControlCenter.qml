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

                if (!isNaN(value)) {
                    root.volume = Math.max(0, Math.min(1, value))
                }
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

                if (!isNaN(value)) {
                    root.brightness = Math.max(0, Math.min(1, value))
                }
            }
        }
    }

    Component.onCompleted: {
        getVolumeProcess.running = true
        getBrightnessProcess.running = true
    }

    function setVolume(value) {
        root.volume = Math.max(0, Math.min(1, value))

        volumeProcess.command = [
            "notch-volume",
            String(root.volume)
        ]

        volumeProcess.running = true
    }

    function setBrightness(value) {
        root.brightness = Math.max(0, Math.min(1, value))

        brightnessProcess.command = [
            "notch-backend",
            "brightness",
            String(root.brightness)
        ]

        brightnessProcess.running = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Text {
            text: "Control Center"
            color: Theme.text
            font.bold: true
            font.pixelSize: 18
            Layout.fillWidth: true
        }

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

            Repeater {
                model: ["WiFi", "Bluetooth", "Power"]

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: 14
                    color: Theme.surface

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: Theme.text
                        font.bold: true
                    }
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
                        root.setBrightness(
                            Math.max(
                                0,
                                Math.min(1, mouseX / width)
                            )
                        )
                    }

                    onPressed: mouse => {
                        updateBrightness(mouse.x)
                    }

                    onPositionChanged: mouse => {
                        if (pressed) {
                            updateBrightness(mouse.x)
                        }
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
                        root.setVolume(
                            Math.max(
                                0,
                                Math.min(1, mouseX / width)
                            )
                        )
                    }

                    onPressed: mouse => {
                        updateVolume(mouse.x)
                    }

                    onPositionChanged: mouse => {
                        if (pressed) {
                            updateVolume(mouse.x)
                        }
                    }
                }
            }
        }
    }
}
