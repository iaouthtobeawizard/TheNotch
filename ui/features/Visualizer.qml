import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../config"

Item {
    id: root

    property var smoothBands: []

    implicitWidth: bars.width
    implicitHeight: 32

    Process {
        id: frameProcess

        command: [
            "cat",
            "/tmp/notch-visualizer.json"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var frame = JSON.parse(text)

                    if (frame.bands !== undefined)
                        root.smoothBands = frame.bands
                } catch (error) {
                }
            }
        }
    }

    Timer {
        interval: 30
        running: true
        repeat: true

        onTriggered: {
            if (!frameProcess.running)
                frameProcess.running = true
        }
    }

    Row {
        id: bars

        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: 16

            Rectangle {
                width: 3

                property real sourceIndex:
                    5 + index * 14 / 15

                property real value:
                    root.smoothBands.length > 0
                        ? root.smoothBands[Math.round(sourceIndex)] || 0
                        : 0

                property real level:
                    Math.max(
                        0,
                        Math.min(1, value * 0.8 / 12)
                    )

                property real wave:
                    0.75 + 0.25 * Math.sin(
                        (index / 15) * Math.PI
                    )

                height:
                    Math.max(
                        4,
                        level * root.height * 0.82 * wave
                    )

                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.accent

                Behavior on height {
                    NumberAnimation {
                        duration: 90
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
