import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick 6.10
import "../../config" as QsConfig
import "../../services" as QsServices
import "../centric"

Scope {
    readonly property var config: QsConfig.Config

    // Unified central panel — all panels (wallpaper, notification, calendar,
    // control, launcher) live in this single morphing window.
    Loader {
        id: centricLoader
        source: "../centric/CentricPanelWindow.qml"
        asynchronous: true

        property var centricPanel: item

        onStatusChanged: {
            QsServices.Logger.debug(
                "BarWrapper",
                `Centric panel loader status: ${status === Loader.Ready ? "READY" : status === Loader.Loading ? "LOADING" : status === Loader.Error ? "ERROR" : "NULL"}`
            )
        }
    }

    // Expose the unified panel to compositor keybindings.
    // `qs ipc call shell toggleX` is used by Super+Space/W/P/N/D.
    IpcHandler {
        target: "shell"

        function toggleLauncher(): void {
            const panel = centricLoader.item
            if (!panel)
                return
            panel.togglePanel("launcher")
        }

        function toggleWallpaper(): void {
            const panel = centricLoader.item
            if (!panel)
                return
            panel.togglePanel("wallpaper")
        }

        function toggleControl(): void {
            const panel = centricLoader.item
            if (!panel)
                return
            panel.togglePanel("control")
        }

        function toggleNotifications(): void {
            const panel = centricLoader.item
            if (!panel)
                return
            panel.togglePanel("notification")
        }

        function toggleCalendar(): void {
            const panel = centricLoader.item
            if (!panel)
                return
            panel.togglePanel("calendar")
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            property var modelData

            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }

            // Fixed exclusive zone: only the bar strip reserves space for desktop windows
            exclusiveZone: config.bar.height

            implicitHeight: config.bar.height
            color: "transparent"

            // Bar content (fills window: bar strip at top, popup host below)
            Loader {
                id: barLoader
                anchors.fill: parent
                source: "Bar.qml"

                onStatusChanged: {
                    if (status === Loader.Ready) {
                        item.screen = Qt.binding(() => modelData)
                        item.barWindow = Qt.binding(() => window)
                        item.centricPanel = Qt.binding(() => centricLoader.item)
                    }
                }
            }
        }
    }
}
