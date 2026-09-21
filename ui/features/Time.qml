import QtQuick
import "../../config"

Item {
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    property date currentTime: new Date()

    Column {
        id: content

        spacing: 0

        Text {
            visible: Config.timeEnabled
            text: Qt.formatTime(currentTime, "HH:mm")
            color: Theme.text
            font.bold: true
            font.pixelSize: 16
        }

        Text {
            visible: Config.dateEnabled
            text: Qt.formatDate(currentTime, "ddd, dd MMM")
            color: Theme.textSecondary
            font.pixelSize: 9
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: currentTime = new Date()
    }
}
