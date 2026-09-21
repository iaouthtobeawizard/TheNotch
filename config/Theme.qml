pragma Singleton

import QtQuick
import Quickshell
import "."

Singleton {
    readonly property string source:
        Config.themeSource

    readonly property color background:
        source === "matugen" ? Matugen.background : "#0d0d12"

    readonly property color surface:
        source === "matugen" ? Matugen.surface : "#15151c"

    readonly property color text:
        source === "matugen" ? Matugen.text : "#f5f5f7"

    readonly property color textSecondary:
        source === "matugen" ? Matugen.textSecondary : "#9696a3"

    readonly property color accent:
        source === "matugen" ? Matugen.accent : "#8ab4f8"

    readonly property color outline:
        source === "matugen" ? Matugen.outline : "#303038"
}
