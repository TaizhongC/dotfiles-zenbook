pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var wallpapers: []
    readonly property string wallpaperDir: `${Quickshell.env("HOME")}/.local/share/wallpapers`

    function refresh(): void {
        listProc.exec(["sh", "-c", "find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -print | sort", "sh", wallpaperDir])
    }

    Process {
        id: listProc
        stdout: StdioCollector {
            onStreamFinished: {
                const list = text.trim().split("\n").filter(path => path.length > 0)
                root.wallpapers = list
            }
        }
    }

    Component.onCompleted: {
        refresh()
    }
}
