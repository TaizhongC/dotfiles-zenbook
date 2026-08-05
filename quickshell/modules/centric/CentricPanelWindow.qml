import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components" as QsComponents

PanelWindow {
    id: root

    // Active panel modes: "", "wallpaper", "notification", "calendar", "control", "launcher"
    property string activePanel: ""
    readonly property bool shouldShow: activePanel !== ""

    function togglePanel(name: string): void {
        if (activePanel === name) {
            activePanel = ""
        } else {
            activePanel = name
        }
    }

    function closePanel(): void {
        activePanel = ""
    }

    readonly property var config: QsConfig.Config
    readonly property var appearance: QsConfig.AppearanceConfig
    readonly property var pywal: QsServices.Pywal

    screen: Quickshell.screens[0]

    // Position anchoring
    anchors {
        top: true
        right: activePanel === "control" || activePanel === "notification"
        left: activePanel === "wallpaper"
    }

    margins {
        top: (config.bar.height ?? 36) + QsComponents.PanelMotion.offset
        right: (activePanel === "control" || activePanel === "notification") ? 12 : 0
        left: activePanel === "wallpaper" ? 12 : 0
    }

    // Dynamic target width and height based on activePanel mode
    readonly property int targetWidth: {
        if (activePanel === "control") return 780
        if (activePanel === "notification") return 440
        if (activePanel === "calendar") return 440
        if (activePanel === "wallpaper") return 520
        if (activePanel === "launcher") return 520
        return 440
    }

    readonly property int targetHeight: {
        if (activePanel === "control") return 540
        if (activePanel === "notification") return 720
        if (activePanel === "calendar") return 360
        if (activePanel === "wallpaper") return 360
        if (activePanel === "launcher") return 460
        return 400
    }

    implicitWidth: targetWidth
    implicitHeight: shouldShow || panelContent.opacity > 0 ? targetHeight : 0
    visible: shouldShow || panelContent.opacity > 0
    color: "transparent"

    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Dismiss scrim
    MouseArea {
        anchors.fill: parent
        z: -1
        visible: root.shouldShow
        onClicked: root.closePanel()
    }

    // Master Base Panel Container
    FocusScope {
        id: panelContent
        anchors.fill: parent
        focus: root.shouldShow

        Keys.onEscapePressed: root.closePanel()

        // Standalone entrance / exit motion using unified PanelMotion
        transformOrigin: activePanel === "wallpaper" ? Item.TopLeft : (activePanel === "control" || activePanel === "notification") ? Item.TopRight : Item.Top
        scale: root.shouldShow ? 1.0 : QsComponents.PanelMotion.closedScale
        opacity: root.shouldShow ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation {
                duration: QsComponents.PanelMotion.duration
                easing.bezierCurve: QsComponents.PanelMotion.curve
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: QsComponents.PanelMotion.fadeDuration
                easing.bezierCurve: QsComponents.PanelMotion.curve
            }
        }

        // Morphing Base Panel Surface
        Rectangle {
            id: panelCard
            anchors.centerIn: parent
            width: root.targetWidth
            height: root.targetHeight
            radius: 28
            color: pywal.surfaceContainerHighest
            border.width: 1
            border.color: pywal.outlineVariant
            clip: true

            Behavior on width {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }
            Behavior on height {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            // Inner content container with smooth cross-fade transition
            Item {
                anchors.fill: parent

                // 1. Wallpaper Panel (Super + W)
                Loader {
                    id: wallpaperLoader
                    anchors.fill: parent
                    anchors.margins: 16
                    active: root.activePanel === "wallpaper" || opacity > 0
                    source: "../wallpaper/WallpaperPanelContent.qml"
                    opacity: root.activePanel === "wallpaper" ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                // 2. Notification Panel (Super + N)
                Loader {
                    id: notifLoader
                    anchors.fill: parent
                    anchors.margins: 16
                    active: root.activePanel === "notification" || opacity > 0
                    source: "../sidebar/SidebarPanelContent.qml"
                    opacity: root.activePanel === "notification" ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                // 3. Calendar Panel (Super + D)
                Loader {
                    id: calendarLoader
                    anchors.fill: parent
                    anchors.margins: 16
                    active: root.activePanel === "calendar" || opacity > 0
                    source: "../dashboard/CalendarPanelContent.qml"
                    opacity: root.activePanel === "calendar" ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                // 4. Control & Networks Combined Panel (Super + P)
                Loader {
                    id: controlLoader
                    anchors.fill: parent
                    anchors.margins: 16
                    active: root.activePanel === "control" || opacity > 0
                    source: "CombinedControlPanel.qml"
                    opacity: root.activePanel === "control" ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                // 5. App Launcher Panel (Super + Space)
                Loader {
                    id: launcherLoader
                    anchors.fill: parent
                    anchors.margins: 16
                    active: root.activePanel === "launcher" || opacity > 0
                    source: "../launcher/LauncherPanelContent.qml"
                    opacity: root.activePanel === "launcher" ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }
            }
        }
    }
}
