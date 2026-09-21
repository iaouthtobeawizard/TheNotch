pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property var data: ({})

    FileView {
        id: configFile

        path: Quickshell.env("HOME") + "/.config/notch-qs/config.json"
        preload: true
        printErrors: false

        onLoadedChanged: {
            if (!loaded)
                return

            try {
                data = JSON.parse(text())
            } catch (error) {
                data = {}
            }
        }
    }

    function value(path, fallback) {
        var current = data

        for (var i = 0; i < path.length; i++) {
            if (current === undefined || current === null || current[path[i]] === undefined)
                return fallback

            current = current[path[i]]
        }

        return current
    }
}
