import QtQuick 6.10
import Quickshell
import Quickshell.Io
import "../../../services" as QsServices

Item {
    id: root
    signal closeRequested()
    property var wallpapers: []
    readonly property string wallpaperDir: `${Quickshell.env("HOME")}/.local/share/wallpapers`
    implicitWidth: 520
    implicitHeight: 250

    Component.onCompleted: listProc.exec(["sh", "-c", "find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -print | sort", "sh", wallpaperDir])
    Process { id: listProc; stdout: StdioCollector { onStreamFinished: root.wallpapers = text.trim().split("\n").filter(path => path.length) } }

    Rectangle {
        anchors.fill: parent; radius: 20; color: QsServices.Pywal.surfaceContainerHighest
        border.width: 1; border.color: QsServices.Pywal.outlineVariant
        GridView {
            anchors.fill: parent; anchors.margins: 12; clip: true; cellWidth: 120; cellHeight: 108; model: root.wallpapers
            delegate: Item {
                required property var modelData
                width: 112; height: 100
                Image { anchors.fill: parent; source: "file://" + modelData; fillMode: Image.PreserveAspectCrop; asynchronous: true; clip: true }
                Rectangle { anchors.fill: parent; color: "transparent"; radius: 12; border.width: 1; border.color: QsServices.Pywal.outlineVariant }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Quickshell.execDetached(["wallpaperctl", "set", modelData]); root.closeRequested() } }
            }
        }
    }
}
