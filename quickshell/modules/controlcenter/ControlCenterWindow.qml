import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../services" as QsServices
import "../../config" as QsConfig
import "../../components"
import "../../components/effects"
import "components"

PanelWindow {
    id: root

    readonly property var pywal: QsServices.Pywal
    readonly property var appearance: QsConfig.AppearanceConfig
    readonly property var network: QsServices.Network
    readonly property var bluetooth: QsServices.Bluetooth
    readonly property var audio: QsServices.Audio
    readonly property var brightness: QsServices.Brightness
    readonly property var mpris: QsServices.Players
    readonly property var notifs: QsServices.Notifs
    readonly property var systemUsage: QsServices.SystemUsage
    readonly property var powerProfiles: QsServices.PowerProfiles
    readonly property var settings: QsServices.Settings
    readonly property var screenshot: QsServices.Screenshot

    property bool shouldShow: false
    property bool notificationsOnly: false

    function cyclePowerProfile() {
        const profiles = ["performance", "balanced", "power-saver"]
        const index = profiles.indexOf(powerProfiles.activeProfile)
        powerProfiles.setProfile(profiles[(index + 1) % profiles.length])
    }

    screen: Quickshell.screens[0]
    anchors { top: true; right: true }
    margins { right: 12; top: (QsConfig.Config.bar.height ?? 34) + appearance.anim.popup.offset }
    
    implicitWidth: 440
    implicitHeight: Math.min(860, screen.height - 40)
    color: "transparent"
    visible: shouldShow || panelContent.opacity > 0

    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Process { id: settingsProcess; command: ["nm-connection-editor"] }
    Process { id: lockProcess; command: ["loginctl", "lock-session"] }
    Process { id: powerProcess; command: ["wlogout"] }
    Process {
        id: screenshotsProcess
        command: ["kitty", "-e", "yazi", root.screenshot.screenshotsDir]
        onStarted: root.shouldShow = false
    }

    // M3 Solid Color Tokens
    readonly property color cSurface: pywal.surface
    readonly property color cSurfaceContainer: pywal.surfaceContainer
    readonly property color cSurfaceContainerHigh: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cSecondary: pywal.secondary
    readonly property color cOnSurface: pywal.foreground
    readonly property color cOnSurfaceVariant: pywal.onSurfaceMuted

    FocusScope {
        id: panelContent
        anchors.fill: parent

        transformOrigin: Item.TopRight
        scale: root.shouldShow ? 1.0 : appearance.anim.popup.closedScale
        opacity: root.shouldShow ? 1.0 : 0.0

        focus: true
        Keys.onEscapePressed: root.shouldShow = false

        HoverHandler {
            id: hoverHandler
            onHoveredChanged: {
                if (hovered) closeTimer.stop()
                else if (root.shouldShow) closeTimer.restart()
            }
        }

        Timer { id: closeTimer; interval: 600; onTriggered: if (!hoverHandler.hovered) root.shouldShow = false }

        MouseArea { anchors.fill: parent; z: -1; onClicked: root.shouldShow = false }

        Behavior on scale { NumberAnimation { duration: appearance.anim.popup.duration; easing.bezierCurve: appearance.anim.popup.curve } }
        Behavior on opacity { NumberAnimation { duration: appearance.anim.popup.fadeDuration; easing.bezierCurve: appearance.anim.popup.curve } }

        Rectangle {
            id: panel
            anchors.fill: parent
            radius: 28
            color: root.cSurface
            clip: true

            MouseArea { anchors.fill: parent; onClicked: (mouse) => mouse.accepted = true }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 24

                // Header - M3 Expressive Typography
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    ColumnLayout {
                        spacing: 0
                        Text {
                            id: timeText
                            text: Qt.formatTime(new Date(), "hh:mm")
                            font.family: "Inter"
                            font.pixelSize: 42
                            font.weight: Font.Black
                            color: root.cOnSurface
                            lineHeight: 0.9
                        }
                        Text {
                            text: Qt.formatDate(new Date(), "dddd, d MMMM yyyy")
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: root.cOnSurfaceVariant
                            font.letterSpacing: 1.5
                        }
                        Timer { interval: 1000; running: true; repeat: true; onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm") }
                    }
                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 8

                        Rectangle {
                            width: 48; height: 48; radius: 24
                            color: settingsBtnMouse.pressed ? Qt.rgba(root.cOnSurface.r, root.cOnSurface.g, root.cOnSurface.b, 0.12) : settingsBtnMouse.containsMouse ? Qt.rgba(root.cOnSurface.r, root.cOnSurface.g, root.cOnSurface.b, 0.08) : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            scale: settingsBtnMouse.pressed ? 0.95 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100; easing.bezierCurve: Material3Anim.springGentle } }

                            Text { anchors.centerIn: parent; text: root.notificationsOnly ? "󰒓" : "󰂚"; font.family: "Material Design Icons"; font.pixelSize: 24; color: root.cOnSurfaceVariant }
                            MouseArea { id: settingsBtnMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: root.notificationsOnly = !root.notificationsOnly }
                        }

                        Rectangle {
                            width: 48; height: 48; radius: 24
                            color: powerBtnMouse.pressed ? Qt.rgba(root.cOnSurface.r, root.cOnSurface.g, root.cOnSurface.b, 0.12) : powerBtnMouse.containsMouse ? Qt.rgba(root.cOnSurface.r, root.cOnSurface.g, root.cOnSurface.b, 0.08) : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            scale: powerBtnMouse.pressed ? 0.95 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100; easing.bezierCurve: Material3Anim.springGentle } }

                            Text { anchors.centerIn: parent; text: "󰐥"; font.family: "Material Design Icons"; font.pixelSize: 24; color: root.cOnSurfaceVariant }
                            MouseArea { id: powerBtnMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: powerProcess.running = true }
                        }
                    }
                }

                StyledFlickable {
                    id: contentFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: contentColumn.height
                    clip: true

                    ColumnLayout {
                        id: contentColumn
                        width: contentFlick.width
                        spacing: 20

                        // Quick Toggles Grid
                        GridLayout {
                            Layout.fillWidth: true
                            visible: !root.notificationsOnly
                            columns: 2
                            rowSpacing: 12
                            columnSpacing: 12

                            QuickToggle { Layout.fillWidth: true; icon: "󰖩"; label: "Wi-Fi"; subLabel: root.network.connected ? root.network.ssid : "Off"; active: root.network.wifiEnabled; activeColor: root.cPrimary; onClicked: root.network.toggleWifi() }
                            QuickToggle { Layout.fillWidth: true; icon: "󰂯"; label: "Bluetooth"; subLabel: root.bluetooth.powered ? "On" : "Off"; active: root.bluetooth.powered; activeColor: root.cPrimary; onClicked: root.bluetooth.togglePower() }
                            QuickToggle { Layout.fillWidth: true; icon: "󰔎"; label: "Do Not Disturb"; subLabel: root.notifs.dnd ? "On" : "Off"; active: root.notifs.dnd; activeColor: pywal.warning; onClicked: root.notifs.toggleDnd() }
                            QuickToggle { Layout.fillWidth: true; icon: "󰾴"; label: "Power Mode"; subLabel: powerProfiles.getProfileLabel(powerProfiles.activeProfile); active: powerProfiles.activeProfile === "performance"; activeColor: pywal.success; onClicked: root.cyclePowerProfile() }
                            QuickToggle { Layout.fillWidth: true; icon: "󰹑"; label: "Screenshot"; subLabel: "Capture Screen"; active: false; activeColor: root.cSecondary; onClicked: root.screenshot.takeScreenshot("screen") }
                            QuickToggle { Layout.fillWidth: true; icon: "󰉋"; label: "Open Captures"; subLabel: "Screenshots & recordings"; active: false; activeColor: root.cSecondary; onClicked: screenshotsProcess.running = true }
                        }

                        // Sliders Container
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: !root.notificationsOnly
                            spacing: 0

                            VolumeSlider { Layout.fillWidth: true; audio: root.audio; pywal: root.pywal }
                            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(root.cOnSurface.r, root.cOnSurface.g, root.cOnSurface.b, 0.05) }
                            MicrophoneSlider { Layout.fillWidth: true; audio: root.audio; pywal: root.pywal }
                            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(root.cOnSurface.r, root.cOnSurface.g, root.cOnSurface.b, 0.05) }
                            BrightnessSlider { Layout.fillWidth: true; brightness: root.brightness; pywal: root.pywal }
                        }

                        SystemStats { Layout.fillWidth: true; visible: !root.notificationsOnly; systemUsage: root.systemUsage; pywal: root.pywal }
                        MediaCard { Layout.fillWidth: true; visible: !root.notificationsOnly; mpris: root.mpris; pywal: root.pywal }
                        NotificationList { Layout.fillWidth: true; Layout.fillHeight: root.notificationsOnly; Layout.preferredHeight: root.notificationsOnly ? root.height - 150 : 0; visible: root.notificationsOnly; notifs: root.notifs; pywal: root.pywal }

                        Item { Layout.preferredHeight: 4 }
                    }
                }
            }
        }
    }
}
