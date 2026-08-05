import QtQuick 6.10
import Quickshell
import Quickshell.Wayland
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
    readonly property var tokens: QsComponents.PanelTokens

    screen: Quickshell.screens[0]

    // Full-screen transparent layer. The panel card is centered on screen and
    // the layer never reserves space for windows (exclusiveZone: 0), so
    // opening any panel never squeezes hyprland windows.
    //
    // The window unmaps as soon as a panel fully closes — an always-mapped
    // full-screen layer keeps an input region and blocks clicks on windows.
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: 0

    visible: root.shouldShow || panelCard.opacity > 0
    color: "transparent"

    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Dismiss scrim — only active while a panel is open
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

    // Dynamic target width and height based on activePanel mode
    readonly property int targetWidth: {
        if (activePanel === "control") return 820
        if (activePanel === "notification") return 520
        if (activePanel === "calendar") return 440
        if (activePanel === "wallpaper") return 520
        if (activePanel === "launcher") return 560
        return 440
    }

        readonly property int targetHeight: {
            if (activePanel === "control") return 700
            if (activePanel === "notification") return 720
            if (activePanel === "calendar") return 420
            if (activePanel === "wallpaper") return 360
            if (activePanel === "launcher") return 560
            return 400
        }

        // Morphing Base Panel Surface — centered on screen
        Rectangle {
            id: panelCard
            anchors.centerIn: parent
            width: panelContent.targetWidth
            height: panelContent.targetHeight
            radius: tokens.radius
            color: tokens.surface
            clip: true

            visible: root.shouldShow || panelCard.opacity > 0

            // Unified entrance / exit motion from the screen center
            transformOrigin: Item.Center
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
            Behavior on width {
                NumberAnimation {
                    duration: QsComponents.PanelMotion.morphDuration
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: QsComponents.PanelMotion.morphDuration
                    easing.type: Easing.OutCubic
                }
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
                    Behavior on opacity { NumberAnimation { duration: QsComponents.PanelMotion.contentFade } }

                    Binding {
                        target: wallpaperLoader.item
                        property: "panelActive"
                        value: root.activePanel === "wallpaper"
                        when: wallpaperLoader.status === Loader.Ready
                        restoreMode: Binding.RestoreBinding
                    }
                }

                // 2. Notification Panel (Super + N)
                Loader {
                    id: notifLoader
                    anchors.fill: parent
                    anchors.margins: 16
                    active: root.activePanel === "notification" || opacity > 0
                    source: "../sidebar/SidebarPanelContent.qml"
                    opacity: root.activePanel === "notification" ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: QsComponents.PanelMotion.contentFade } }
                }

                // 3. Calendar Panel (Super + D / clock click)
                Loader {
                    id: calendarLoader
                    anchors.fill: parent
                    anchors.margins: 16
                    active: root.activePanel === "calendar" || opacity > 0
                    source: "../dashboard/CalendarPanelContent.qml"
                    opacity: root.activePanel === "calendar" ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: QsComponents.PanelMotion.contentFade } }
                }

                // 4. Control & Networks Combined Panel (Super + P)
                Loader {
                    id: controlLoader
                    anchors.fill: parent
                    anchors.margins: 16
                    active: root.activePanel === "control" || opacity > 0
                    source: "CombinedControlPanel.qml"
                    opacity: root.activePanel === "control" ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: QsComponents.PanelMotion.contentFade } }

                    Connections {
                        target: controlLoader.item
                        function onCloseRequested() { root.closePanel() }
                    }
                }

                // 5. App Launcher Panel (Super + Space)
                Loader {
                    id: launcherLoader
                    anchors.fill: parent
                    anchors.margins: 16
                    active: root.activePanel === "launcher" || opacity > 0
                    source: "../launcher/LauncherPanelContent.qml"
                    opacity: root.activePanel === "launcher" ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: QsComponents.PanelMotion.contentFade } }

                    Binding {
                        target: launcherLoader.item
                        property: "panelActive"
                        value: root.activePanel === "launcher"
                        when: launcherLoader.status === Loader.Ready
                        restoreMode: Binding.RestoreBinding
                    }

                    Connections {
                        target: launcherLoader.item
                        function onCloseRequested() { root.closePanel() }
                    }
                }
            }
        }
    }
}
