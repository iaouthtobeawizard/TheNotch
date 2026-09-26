import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../config"

Rectangle {
    id: root

    color: Theme.background
    radius: 24

    property bool wifiEnabled: false
    property string connectedSsid: ""
    property int signal: 0
    property var networks: []

    property bool detailsOpen: false
    property var selectedNetwork: ({})

    readonly property string uiFont: "Inter"

    Process {
        id: statusProcess

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
                connectionProcess.running = true
            }
        }
    }

    Process {
        id: connectionProcess

        command: [
            "nmcli",
            "-t",
            "-f",
            "ACTIVE,SSID,SIGNAL,SECURITY",
            "device",
            "wifi",
            "list",
            "--rescan",
            "no"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")
                var result = []
                var activeSsid = ""
                var activeSignal = 0

                for (var i = 0; i < lines.length; i++) {
                    if (!lines[i])
                        continue

                    var parts = lines[i].split(":")

                    if (parts.length < 4)
                        continue

                    var active = parts[0]
                    var ssid = parts[1]
                    var signalValue = parseInt(parts[2])
                    var security = parts.slice(3).join(":")

                    if (ssid === "")
                        ssid = "Hidden network"

                    if (active === "yes") {
                        activeSsid = ssid
                        activeSignal = isNaN(signalValue)
                            ? 0
                            : signalValue
                    }

                    result.push({
                        ssid: ssid,
                        signal: isNaN(signalValue)
                            ? 0
                            : signalValue,
                        security: security,
                        active: active === "yes"
                    })
                }

                root.connectedSsid = activeSsid
                root.signal = activeSignal
                root.networks = result
            }
        }
    }

    Process {
        id: toggleProcess

        property bool targetState: false

        command: [
            "nmcli",
            "radio",
            "wifi",
            targetState ? "on" : "off"
        ]

        onExited: {
            statusProcess.running = true
        }
    }

    function refresh() {
        statusProcess.running = true
    }

    function toggleWifi() {
        toggleProcess.targetState = !root.wifiEnabled
        toggleProcess.running = true
    }

    function openDetails(network) {
        root.selectedNetwork = network
        root.detailsOpen = true
    }

    function closeDetails() {
        root.detailsOpen = false
        root.selectedNetwork = {}
        root.refresh()
    }

    Component.onCompleted: {
        refresh()
    }

    Loader {
        anchors.fill: parent

        sourceComponent: root.detailsOpen
            ? detailsView
            : mainView
    }

    Component {
        id: detailsView

        WifiDetails {
            anchors.fill: parent

            ssid: root.selectedNetwork.ssid || ""
            signal: root.selectedNetwork.signal || 0
            security: root.selectedNetwork.security || ""
            connected: root.selectedNetwork.active || false

            onBackRequested: {
                root.closeDetails()
            }
        }
    }

    Component {
        id: mainView

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52

                radius: 16
                color: Theme.surface

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        text: root.wifiEnabled
                            ? "󰤨"
                            : "󰤭"

                        color: Theme.text
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 19

                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: "WiFi"

                            color: Theme.text
                            font.family: root.uiFont
                            font.bold: true
                            font.pixelSize: 12
                        }

                        Text {
                            text: root.wifiEnabled
                                ? "On"
                                : "Off"

                            color: Theme.textSecondary
                            font.family: root.uiFont
                            font.pixelSize: 8
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 24
                        Layout.alignment: Qt.AlignVCenter

                        radius: 12

                        color: root.wifiEnabled
                            ? Theme.accent
                            : Theme.outline

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9

                            anchors.verticalCenter: parent.verticalCenter

                            x: root.wifiEnabled
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
                                root.toggleWifi()
                            }
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
                            text: "Available Networks"

                            color: Theme.text
                            font.family: root.uiFont
                            font.bold: true
                            font.pixelSize: 11

                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30

                            radius: 10
                            color: Theme.background


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
                        id: networkList

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        clip: true
                        model: root.networks
                        spacing: 2

                        delegate: Rectangle {
                            width: networkList.width
                            height: 44

                            radius: 11

                            color: modelData.active
                                ? Theme.outline
                                : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 7
                                anchors.rightMargin: 7
                                spacing: 7

                                Text {
                                    text: modelData.signal >= 75
                                        ? "󰤨"
                                        : modelData.signal >= 50
                                            ? "󰤥"
                                            : modelData.signal >= 25
                                                ? "󰤢"
                                                : "󰤟"

                                    color: modelData.active
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
                                        text: modelData.ssid

                                        color: Theme.text
                                        font.family: root.uiFont
                                        font.bold: modelData.active
                                        font.pixelSize: 9

                                        elide: Text.ElideRight

                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: modelData.security !== ""
                                            ? modelData.security
                                            : "Open"

                                        color: Theme.textSecondary
                                        font.family: root.uiFont
                                        font.pixelSize: 7

                                        elide: Text.ElideRight

                                        Layout.fillWidth: true
                                    }
                                }

                                Text {
                                    text: modelData.active
                                        ? "Connected"
                                        : modelData.signal + "%"

                                    color: modelData.active
                                        ? Theme.accent
                                        : Theme.textSecondary

                                    font.family: root.uiFont
                                    font.pixelSize: 7

                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent

                                onClicked: {
                                    root.openDetails(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
