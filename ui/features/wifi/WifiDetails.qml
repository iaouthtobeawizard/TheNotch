import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../config"

Rectangle {
    id: root

    color: Theme.background
    radius: 24

    property string ssid: ""
    property int signal: 0
    property string security: ""
    property bool connected: false

    signal backRequested()

    property string interfaceName: ""
    property string connectionState: ""
    property string ipAddress: ""
    property string gateway: ""
    property string dns: ""

    Process {
        id: detailsProcess

        command: [
            "bash",
            "-c",
            "device=$(nmcli -g GENERAL.DEVICE device show | head -n1); " +
            "state=$(nmcli -g GENERAL.STATE device show | head -n1); " +
            "address=$(nmcli -g IP4.ADDRESS device show | head -n1); " +
            "gateway=$(nmcli -g IP4.GATEWAY device show | head -n1); " +
            "dns=$(nmcli -g IP4.DNS device show | paste -sd ', ' -); " +
            "printf '%s\\t%s\\t%s\\t%s\\t%s\\n' \"$device\" \"$state\" \"$address\" \"$gateway\" \"$dns\""
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\t")

                root.interfaceName = parts.length > 0 ? parts[0] : ""
                root.connectionState = parts.length > 1 ? parts[1] : ""
                root.ipAddress = parts.length > 2 ? parts[2] : ""
                root.gateway = parts.length > 3 ? parts[3] : ""
                root.dns = parts.length > 4 ? parts[4] : ""
            }
        }
    }

    Process {
        id: connectProcess

        property string targetSsid: ""

        command: [
            "nmcli",
            "device",
            "wifi",
            "connect",
            targetSsid
        ]

        onExited: root.refresh()
    }

    Process {
        id: disconnectProcess

        property string targetDevice: ""

        command: [
            "nmcli",
            "device",
            "disconnect",
            targetDevice
        ]

        onExited: root.refresh()
    }

    Process {
        id: forgetProcess

        property string targetSsid: ""

        command: [
            "bash",
            "-c",
            "uuid=$(nmcli -g UUID connection show \"$1\" 2>/dev/null | head -n1); " +
            "if [ -n \"$uuid\" ]; then nmcli connection delete uuid \"$uuid\"; fi",
            "notch",
            targetSsid
        ]

        onExited: root.backRequested()
    }

    function refresh() {
        detailsProcess.running = true
    }

    function connectNetwork() {
        connectProcess.targetSsid = root.ssid
        connectProcess.running = true
    }

    function disconnectNetwork() {
        if (root.interfaceName === "")
            return

        disconnectProcess.targetDevice = root.interfaceName
        disconnectProcess.running = true
    }

    function forgetNetwork() {
        forgetProcess.targetSsid = root.ssid
        forgetProcess.running = true
    }

    Component.onCompleted: refresh()

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Rectangle {
            width: parent.width
            height: 44

            radius: 14
            color: Theme.surface

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter

                text: "󰁍"

                color: Theme.text
                font.family: "Symbols Nerd Font"
                font.pixelSize: 17

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.backRequested()
                }
            }

            Text {
                anchors.centerIn: parent

                text: "WiFi Details"

                color: Theme.text
                font.bold: true
                font.pixelSize: 12
            }
        }

        Rectangle {
            width: parent.width
            height: 76

            radius: 16
            color: Theme.surface

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                text: "󰤨"

                color: root.connected
                    ? Theme.accent
                    : Theme.text

                font.family: "Symbols Nerd Font"
                font.pixelSize: 25
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 52
                anchors.verticalCenter: parent.verticalCenter

                spacing: 3

                Text {
                    width: parent.parent.width - 68

                    text: root.ssid

                    color: Theme.text
                    font.bold: true
                    font.pixelSize: 12

                    elide: Text.ElideRight
                }

                Text {
                    text: root.connected
                        ? "Connected"
                        : "Not connected"

                    color: root.connected
                        ? Theme.accent
                        : Theme.textSecondary

                    font.pixelSize: 8
                }

                Text {
                    text: root.security !== ""
                        ? root.security + "  •  " + root.signal + "%"
                        : "Open  •  " + root.signal + "%"

                    color: Theme.textSecondary
                    font.pixelSize: 7
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 132

            radius: 16
            color: Theme.surface

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.top: parent.top
                anchors.topMargin: 10

                text: "Connection"

                color: Theme.text
                font.bold: true
                font.pixelSize: 10
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 32
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                spacing: 0

                Item {
                    width: parent.width
                    height: 23

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: "Interface"

                        color: Theme.textSecondary
                        font.pixelSize: 8
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        text: root.interfaceName !== ""
                            ? root.interfaceName
                            : "Unavailable"

                        color: Theme.text
                        font.pixelSize: 8
                    }
                }

                Item {
                    width: parent.width
                    height: 23

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: "IP Address"

                        color: Theme.textSecondary
                        font.pixelSize: 8
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        text: root.ipAddress !== ""
                            ? root.ipAddress
                            : "Not connected"

                        color: Theme.text
                        font.pixelSize: 8
                    }
                }

                Item {
                    width: parent.width
                    height: 23

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: "Gateway"

                        color: Theme.textSecondary
                        font.pixelSize: 8
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        text: root.gateway !== ""
                            ? root.gateway
                            : "Not connected"

                        color: Theme.text
                        font.pixelSize: 8
                    }
                }

                Item {
                    width: parent.width
                    height: 23

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: "DNS"

                        color: Theme.textSecondary
                        font.pixelSize: 8
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        text: root.dns !== ""
                            ? root.dns
                            : "Not connected"

                        color: Theme.text
                        font.pixelSize: 8

                        elide: Text.ElideLeft
                    }
                }
            }
        }

        Row {
            width: parent.width
            height: 38

            spacing: 8

            Rectangle {
                width: (parent.width - 8) / 2
                height: 38

                radius: 11

                color: root.connected
                    ? Theme.outline
                    : Theme.accent

                Text {
                    anchors.centerIn: parent

                    text: root.connected
                        ? "Disconnect"
                        : "Connect"

                    color: root.connected
                        ? Theme.text
                        : Theme.background

                    font.bold: true
                    font.pixelSize: 8
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        if (root.connected)
                            root.disconnectNetwork()
                        else
                            root.connectNetwork()
                    }
                }
            }

            Rectangle {
                width: (parent.width - 8) / 2
                height: 38

                radius: 11
                color: Theme.surface

                Text {
                    anchors.centerIn: parent

                    text: "Forget Network"

                    color: Theme.textSecondary
                    font.pixelSize: 8
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.forgetNetwork()
                }
            }
        }
    }
}
