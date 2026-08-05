pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel

Singleton {
    id: root

    property var wallpapers: []
    property string current: ""
    readonly property string wallpaperDir: `${Quickshell.env("HOME")}/.local/share/wallpapers`
    readonly property string currentStatePath: `${Quickshell.env("HOME")}/.local/state/ricing/current-wallpaper`

    function refresh(): void {
        // Never re-exec while a run is in flight — restarting a Process
        // aborts it mid-run, which loses the output and can leave the list
        // permanently empty.
        if (!listProc.running)
            listProc.exec(["sh", "-c", "find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -print | sort", "sh", wallpaperDir])
        if (!currentProc.running)
            currentProc.exec(["sh", "-c", "readlink -f \"$1\" 2>/dev/null || true", "sh", currentStatePath])
    }

    // Inotify file watcher for the wallpaper directory
    FolderListModel {
        id: folderWatcher
        folder: `file://${root.wallpaperDir}`
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.JPEG", "*.PNG", "*.WEBP"]
        showDirs: false
        onCountChanged: root.refresh()
        onRowsInserted: root.refresh()
        onRowsRemoved: root.refresh()
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

    Process {
        id: currentProc
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim()
                root.current = path.length > 0 ? path : ""
            }
        }
    }

    Component.onCompleted: {
        refresh()
    }
}
