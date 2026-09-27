import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../config"

Item {
    id: root

    property var smoothBands: []
    property var targetBands: []

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

                    if (frame.bands !== undefined) {
                        root.targetBands = frame.bands
                    }
                } catch (error) {
                }
            }
        }
    }

    Timer {
        interval: 25
        running: true
        repeat: true

        onTriggered: {
            if (!frameProcess.running)
                frameProcess.running = true
        }
    }

    Timer {
        interval: 30
        running: true
        repeat: true

        onTriggered: {
            var next = []

            for (var i = 0; i < root.targetBands.length; i++) {
                var current = root.smoothBands.length > i
                    ? root.smoothBands[i]
                    : 0

                var target = Number(root.targetBands[i])

                if (isNaN(target))
                    target = 0

                next.push(
                    current + (target - current) * 0.35
                )
            }

            root.smoothBands = next
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
                    root.smoothBands.length > 0
                        ? Math.floor(
                            index *
                            (root.smoothBands.length - 1) /
                            15
                        )
                        : 0

                property real value:
                    root.smoothBands.length > sourceIndex
                        ? Number(root.smoothBands[sourceIndex])
                        : 0

                property real peak:
                    root.smoothBands.length > 0
                        ? Math.max.apply(null, root.smoothBands)
                        : 1

                property real level:
                    peak > 0
                        ? value / peak
                        : 0

                property real wave:
                    0.75 +
                    0.25 *
                    Math.sin(
                        (index / 15) * Math.PI
                    )

                height:
                    4 +
                    level *
                    (root.height * 0.82 - 4) *
                    wave

                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter

                color: Theme.accent

                Behavior on height {
                    NumberAnimation {
                        duration: 70
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
