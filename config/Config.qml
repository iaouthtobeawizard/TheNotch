pragma Singleton

import Quickshell
import "."

Singleton {
    readonly property bool timeEnabled:
        UserConfig.value(["features", "time"], true)

    readonly property bool dateEnabled:
        UserConfig.value(["features", "date"], true)

    readonly property bool batteryEnabled:
        UserConfig.value(["features", "battery"], true)

    readonly property bool visualizerEnabled:
        UserConfig.value(["features", "visualizer"], true)

    readonly property bool batteryShowIcon:
        UserConfig.value(["battery", "showIcon"], true)

    readonly property bool batteryShowPercentage:
        UserConfig.value(["battery", "showPercentage"], true)

    readonly property string themeSource:
        UserConfig.value(["theme", "source"], "default")
}
