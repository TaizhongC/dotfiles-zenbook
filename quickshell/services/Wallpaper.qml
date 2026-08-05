pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel

Singleton {
    id: root

    property var wallpapers: []
    readonly property string wallpaperDir: `${Quickshell.env("HOME")}/.local/share/wallpapers`

    function refresh(): void {
        listProc.exec(["sh", "-c", "find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -print | sort", "sh", wallpaperDir])
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

    Component.onCompleted: {
        refresh()
    }
}
