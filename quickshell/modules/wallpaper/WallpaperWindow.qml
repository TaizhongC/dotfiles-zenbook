import QtQuick 6.10
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"
import "../../components" as QsComponents

PanelWindow {
    id: root
    property bool shouldShow: false
    property var wallpapers: []
    readonly property var appearance: QsConfig.AppearanceConfig
    readonly property string wallpaperDir: `${Quickshell.env("HOME")}/.local/share/wallpapers`
    screen: Quickshell.screens[0]
    anchors { top: true; left: true }
    // The left island is pinned to the Hyprland outer gap; this centers the
    // selector below its wallpaper button rather than against the screen edge.
    margins { top: (QsConfig.Config.bar.height ?? 34) + appearance.anim.popup.offset; left: 4 }
    implicitWidth: 440
    implicitHeight: shouldShow || panel.opacity > 0 ? 360 : 0
    visible: shouldShow || panel.opacity > 0
    color: "transparent"
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    Component.onCompleted: listProc.exec(["sh", "-c", "find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -print | sort", "sh", wallpaperDir])
    Process { id: listProc; stdout: StdioCollector { onStreamFinished: root.wallpapers = text.trim().split("\n").filter(path => path.length) } }
    FocusScope {
        id: panel; anchors.fill: parent; transformOrigin: Item.Top
        scale: root.shouldShow ? 1 : QsComponents.PanelMotion.closedScale
        opacity: root.shouldShow ? 1 : 0
        focus: root.shouldShow
        Keys.onEscapePressed: root.shouldShow = false
        HoverHandler {
            id: hoverHandler
            onHoveredChanged: {
                if (hovered) closeTimer.stop()
                else if (root.shouldShow) closeTimer.restart()
            }
        }
        Timer { id: closeTimer; interval: 600; onTriggered: if (!hoverHandler.hovered) root.shouldShow = false }
        Behavior on scale { NumberAnimation { duration: QsComponents.PanelMotion.duration; easing.bezierCurve: QsComponents.PanelMotion.curve } }
        Behavior on opacity { NumberAnimation { duration: QsComponents.PanelMotion.fadeDuration; easing.bezierCurve: QsComponents.PanelMotion.curve } }
        Rectangle {
            anchors.fill: parent; radius: 28; color: QsServices.Pywal.surfaceContainerHighest; clip: true
            GridView {
                anchors.fill: parent; anchors.margins: 16; clip: true; cellWidth: 136; cellHeight: 108; model: root.wallpapers
                delegate: Item {
                    required property var modelData; width: 128; height: 100
                    Image { anchors.fill: parent; source: "file://" + modelData; fillMode: Image.PreserveAspectCrop; asynchronous: true; clip: true }
                    Rectangle { anchors.fill: parent; radius: 14; color: "transparent"; border.width: 1; border.color: QsServices.Pywal.outlineVariant }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Quickshell.execDetached(["wallpaperctl", "set", modelData]); root.shouldShow = false } }
                }
            }
        }
    }
}
