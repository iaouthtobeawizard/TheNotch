import QtQuick
import Quickshell
import Quickshell.Io
import "../../config"

Item {
    id: root

    property bool active: rms > 0.001
    property var bands: []
    property var smoothBands: []
    property real rms: 0
    property real peak: 0

    implicitWidth: active ? 86 : 0
    implicitHeight: parent ? parent.height : 0 
    visible: Config.visualizerEnabled && active

    Process {
        id: backend

        command: [
            "notch-backend"
        ]

        running: true

        stdout: SplitParser {
            onRead: function(data) {
                var lines = data.split("\n")

                for (var i = 0; i < lines.length; i++) {
                    if (!lines[i].trim())
                        continue

                    try {
                        var frame = JSON.parse(lines[i])

                        if (frame.version !== 1)
                            continue

                        root.bands = frame.bands || []
                        root.rms = frame.rms || 0
                        root.peak = frame.peak || 0
                    } catch (error) {
                    }
                }
            }
        }
    }

    Timer {
        interval: 16
        running: true
        repeat: true

        onTriggered: {
            var count = Math.min(20, root.bands.length)

            if (count === 0) {
                root.smoothBands = []
                return
            }

            var next = []

            for (var i = 0; i < count; i++) {
                var target = root.bands[i] || 0
                var current = root.smoothBands[i] || 0

                var attack = 0.32
                var decay = 0.12
                var factor = target > current ? attack : decay

                next.push(current + (target - current) * factor)
            }

            root.smoothBands = next
        }
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
                        3,
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
