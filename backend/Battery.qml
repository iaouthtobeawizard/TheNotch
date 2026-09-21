import QtQuick

QtObject {
    property int percentage: 0
    property bool charging: false

    function update() {
        var capacity = Quickshell.execDetached(["cat", "/sys/class/power_supply/BAT0/capacity"])
    }
}
