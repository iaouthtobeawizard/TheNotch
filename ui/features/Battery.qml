import QtQuick
import Quickshell.Services.UPower
import "../../config"

Item {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property int percentage:
        battery ? Math.round(battery.percentage * 100) : 0

    readonly property bool charging:
        battery && (
            battery.state === UPowerDeviceState.Charging ||
            battery.state === UPowerDeviceState.PendingCharge
        )

    readonly property bool full:
        battery && battery.state === UPowerDeviceState.FullyCharged

    readonly property string batteryIcon: {
        if (charging)
            return "󰂄"

        if (full || percentage >= 95)
            return "󰁹"

        if (percentage >= 80)
            return "󰂂"

        if (percentage >= 60)
            return "󰂀"

        if (percentage >= 40)
            return "󰁾"

        if (percentage >= 20)
            return "󰁼"

        if (percentage >= 10)
            return "󰁺"

        return "󰂎"
    }

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Row {
        id: content
        spacing: 4

        Text {
            visible: Config.batteryShowIcon
            text: root.batteryIcon
            color: Theme.text
            font.family: "Symbols Nerd Font"
            font.pixelSize: 16
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: Config.batteryShowPercentage
            text: root.percentage + "%"
            color: Theme.text
            font.bold: true
            font.pixelSize: 10
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
