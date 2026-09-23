import QtQuick
import Quickshell
import Quickshell.Io
import "../../config"

Item {
    id: root

    property var smoothBands: []

    implicitWidth: 72
    implicitHeight: 28

    Process {
        id: visualizerProcess

        command: [
            Quickshell.env("HOME") + "/.local/bin/notch-visualizer-stream"
        ]

        stdout: StdioCollector {
            onStreamFinished: {


                try {
                    var frame = JSON.parse(text.trim())



                    if (frame.bands)
                        root.smoothBands = frame.bands
                } catch (error) {

                }

                restartTimer.start()
            }
        }
    }

    Timer {
        id: restartTimer

        interval: 33
        repeat: false

        onTriggered: {
            visualizerProcess.running = true
        }
    }

    Component.onCompleted: {
        visualizerProcess.running = true
    }

    Row {
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: Math.min(16, root.smoothBands.length)

            Rectangle {
                width: 3

                property real sourceIndex:
                    5 + index * 14 / Math.max(1, 15)

                property real value:
                    root.smoothBands[Math.round(sourceIndex)] || 0

                property real level:
                    Math.max(0, Math.min(1, value * 0.8 / 12))

                property real wave:
                    0.75 + 0.25 * Math.sin(
                        (index / Math.max(1, 15)) * Math.PI
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
