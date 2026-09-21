pragma Singleton

import Quickshell
import "."

Singleton {
    readonly property int compactWidth:
        UserConfig.value(["notch", "width"], 300)

    readonly property int compactHeight:
        UserConfig.value(["notch", "height"], 44)

    readonly property int compactTopMargin:
        UserConfig.value(["notch", "topMargin"], 8)

    readonly property int compactRadius:
        UserConfig.value(["notch", "radius"], compactHeight / 2)

    readonly property int compactExclusiveZone:
        compactHeight
}
