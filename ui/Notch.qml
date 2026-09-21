import QtQuick
import QtQuick.Layouts
import "../config"
import "./features"

Rectangle {
    anchors.fill: parent

    radius: Geometry.compactRadius
    color: Theme.background

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14

        spacing: 2

        Time {
            visible: Config.timeEnabled
            Layout.alignment: Qt.AlignVCenter
        }

        Item {
            Layout.fillWidth: true
        }

        Visualizer {
            id: visualizer

            visible: Config.visualizerEnabled && active
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: active ? implicitWidth : 0
            Layout.fillHeight: true
        }

        Item {
            Layout.fillWidth: true
        }

        Battery {
            visible: Config.batteryEnabled
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
