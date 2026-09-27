import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Io
import "../../../config"

Rectangle {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: 148
    Layout.minimumHeight: 148
    Layout.maximumHeight: 148

    radius: 16
    color: "#171922"
    clip: true

    property var player: null
    property var smoothBands: []

    readonly property string uiFont: "Noto Sans"
    readonly property string iconFont: "Symbols Nerd Font"

    property real progress:
        player && player.length > 0
            ? Math.max(
                0,
                Math.min(
                    1,
                    player.position / player.length
                )
            )
            : 0

    property string currentTime:
        formatTime(player ? player.position : 0)

    property string totalTime:
        formatTime(player ? player.length : 0)

    function formatTime(seconds) {
        var value = Math.floor(seconds)

        if (isNaN(value) || value < 0)
            value = 0

        var minutes = Math.floor(value / 60)
        var remaining = value % 60

        return minutes + ":" +
            (remaining < 10 ? "0" : "") +
            remaining
    }

    function findPlayer() {
        var players = Mpris.players.values

        if (!players || players.length === 0)
            return null

        for (var i = 0; i < players.length; i++) {
            if (players[i].isPlaying)
                return players[i]
        }

        for (var j = 0; j < players.length; j++) {
            if (players[j].trackTitle !== "")
                return players[j]
        }

        return players[0]
    }

    function refreshPlayer() {
        var selected = findPlayer()

        if (selected !== root.player)
            root.player = selected
    }

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

    Timer {
        interval: 500
        running: true
        repeat: true

        onTriggered: {
            root.refreshPlayer()
        }
    }

    Timer {
        interval: 50

        running:
            root.player !== null &&
            root.player.isPlaying &&
            root.player.positionSupported

        repeat: true

        onTriggered: {
            if (root.player)
                root.player.positionChanged()
        }
    }

    Rectangle {
        anchors.fill: parent

        radius: parent.radius
        color: "#0d0d12"
        opacity: 0.45
        clip: true

        Image {
            anchors.fill: parent

            source:
                root.player &&
                root.player.trackArtUrl !== ""
                    ? root.player.trackArtUrl
                    : ""

            fillMode: Image.PreserveAspectCrop

            opacity: 0.13
            scale: 1.12

            asynchronous: true
            cache: true
        }

        Rectangle {
            anchors.fill: parent

            color: "#0d0d12"
            opacity: 0.68
        }
    }

    Rectangle {
        anchors.fill: parent

        radius: parent.radius

        color: "#0d0d12"
        opacity: 0.22
    }

    Rectangle {
        id: albumArt

        x: 14
        y: 14

        width: 62
        height: 62

        radius: 12

        color: Theme.surface

        clip: true

        Image {
            anchors.fill: parent

            source:
                root.player &&
                root.player.trackArtUrl !== ""
                    ? root.player.trackArtUrl
                    : ""

            fillMode: Image.PreserveAspectCrop

            asynchronous: true
            cache: true

            visible: source !== ""
        }

        Text {
            anchors.centerIn: parent

            visible:
                !root.player ||
                root.player.trackArtUrl === ""

            text: "󰝚"

            color: Theme.accent

            font.family: root.iconFont
            font.pixelSize: 28
        }
    }

    Column {
        id: trackInfo

        x: albumArt.x + albumArt.width + 12
        y: 16

        width: 145

        spacing: 2

        Text {
            width: parent.width

            text:
                root.player &&
                root.player.trackTitle !== ""
                    ? root.player.trackTitle
                    : "Nothing playing"

            color: Theme.text

            font.family: root.uiFont
            font.weight: Font.DemiBold
            font.pixelSize: 14

            elide: Text.ElideRight
        }

        Text {
            width: parent.width

            text:
                root.player &&
                root.player.trackArtist !== ""
                    ? root.player.trackArtist
                    : ""

            color: Theme.textSecondary

            font.family: root.uiFont
            font.pixelSize: 9

            elide: Text.ElideRight

            visible: text !== ""
        }
    }

    Row {
        id: waveform

        x: root.width - width - 18
        y: 26

        width: 145
        height: 42

        spacing: 2

        Repeater {
            model: 24

            Rectangle {
                width: 3

                property real sourceIndex:
                    root.smoothBands.length > 0
                        ? Math.floor(
                            index *
                            (root.smoothBands.length - 1) /
                            23
                        )
                        : 0

                property real value:
                    root.smoothBands.length > sourceIndex
                        ? Number(
                            root.smoothBands[sourceIndex]
                        )
                        : 0

                property real peak:
                    root.smoothBands.length > 0
                        ? Math.max.apply(
                            null,
                            root.smoothBands
                        )
                        : 1

                property real level:
                    peak > 0
                        ? value / peak
                        : 0

                height:
                    4 +
                    level *
                    32 *
                    (
                        0.65 +
                        0.35 *
                        Math.sin(
                            (index / 23) * Math.PI
                        )
                    )

                anchors.verticalCenter: parent.verticalCenter

                radius: 2

                color: Theme.accent
                opacity: 0.9

                Behavior on height {
                    NumberAnimation {
                        duration: 70
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    Rectangle {
        id: progressTrack

        x: 14
        y: 92

        width: root.width - 28
        height: 4

        radius: 2

        color: Theme.outline

        Rectangle {
            width:
                progressTrack.width *
                root.progress

            height: parent.height

            radius: parent.radius

            color: Theme.accent

            Behavior on width {
                NumberAnimation {
                    duration: 60
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            anchors.fill: parent

            enabled:
                root.player !== null &&
                root.player.canSeek &&
                root.player.positionSupported

            onClicked: mouse => {
                var ratio =
                    mouse.x /
                    progressTrack.width

                root.player.position =
                    ratio *
                    root.player.length
            }
        }
    }

    Text {
        x: 14
        y: 100

        text: root.currentTime

        color: Theme.textSecondary

        font.family: root.uiFont
        font.pixelSize: 7
    }

    Text {
        x: root.width - width - 14
        y: 100

        text: root.totalTime

        color: Theme.textSecondary

        font.family: root.uiFont
        font.pixelSize: 7
    }

    Row {
        id: controls

        anchors.horizontalCenter: parent.horizontalCenter

        y: 112

        height: 30

        spacing: 8

        Rectangle {
            width: 30
            height: 30

            radius: 15

            color: Theme.surface

            opacity:
                root.player &&
                root.player.canGoPrevious
                    ? 1
                    : 0.45

            Text {
                anchors.centerIn: parent

                text: "󰒮"

                color: Theme.text

                font.family: root.iconFont
                font.pixelSize: 14
            }

            MouseArea {
                anchors.fill: parent

                enabled:
                    root.player !== null &&
                    root.player.canGoPrevious

                onClicked: {
                    root.player.previous()
                }
            }
        }

        Rectangle {
            width: 34
            height: 34

            y: -2

            radius: 17

            color: Theme.accent

            opacity:
                root.player &&
                root.player.canTogglePlaying
                    ? 1
                    : 0.45

            Text {
                anchors.centerIn: parent

                text:
                    root.player &&
                    root.player.isPlaying
                        ? "󰏤"
                        : "󰐊"

                color: Theme.background

                font.family: root.iconFont
                font.pixelSize: 16
            }

            MouseArea {
                anchors.fill: parent

                enabled:
                    root.player !== null &&
                    root.player.canTogglePlaying

                onClicked: {
                    root.player.togglePlaying()
                }
            }
        }

        Rectangle {
            width: 30
            height: 30

            radius: 15

            color: Theme.surface

            opacity:
                root.player &&
                root.player.canGoNext
                    ? 1
                    : 0.45

            Text {
                anchors.centerIn: parent

                text: "󰒭"

                color: Theme.text

                font.family: root.iconFont
                font.pixelSize: 14
            }

            MouseArea {
                anchors.fill: parent

                enabled:
                    root.player !== null &&
                    root.player.canGoNext

                onClicked: {
                    root.player.next()
                }
            }
        }
    }

    Component.onCompleted: {
        root.refreshPlayer()
    }
}
