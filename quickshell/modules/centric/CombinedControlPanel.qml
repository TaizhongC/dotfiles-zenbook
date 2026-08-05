import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"
import "../../components" as QsComponents
import "../bar/components" as BarComponents
import "../controlcenter/components"

Item {
    id: root
    implicitWidth: 792
    implicitHeight: 668

    readonly property var pywal: QsServices.Pywal
    readonly property var tokens: QsComponents.PanelTokens
    readonly property var config: QsConfig.Config

    signal closeRequested()

    RowLayout {
        anchors.fill: parent
        spacing: 16

        // ═══ Left Column: Quick Settings ═══
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 436
            radius: tokens.radiusRaised
            color: tokens.surface
            clip: true

            StyledFlickable {
                anchors.fill: parent
                anchors.margins: 16
                contentWidth: width
                contentHeight: leftColumn.implicitHeight

                ColumnLayout {
                    id: leftColumn
                    width: parent.width
                    spacing: 14

                    // Time & Date Header
                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            spacing: 0
                            Text {
                                id: timeText
                                text: Qt.formatTime(new Date(), "hh:mm")
                                font.family: "Inter"
                                font.pixelSize: 32
                                font.weight: Font.Black
                                color: pywal.foreground
                            }
                            Text {
                                text: Qt.formatDate(new Date(), "dddd, d MMMM")
                                font.family: "Inter"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: pywal.onSurfaceMuted
                            }
                            Timer { interval: 1000; running: true; repeat: true; onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm") }
                        }

                        Item { Layout.fillWidth: true }

                        // Power Button
                        Rectangle {
                            width: 40; height: 40; radius: 20
                            color: powerArea.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12) : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.06)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text { anchors.centerIn: parent; text: "󰐥"; font.family: "Material Design Icons"; font.pixelSize: 20; color: pywal.foreground }
                            MouseArea {
                                id: powerArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["wlogout"])
                            }
                        }
                    }

                    // Volume Slider
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: QsServices.Audio.muted ? "󰖁" : "󰕾"
                            font.family: "Material Design Icons"
                            font.pixelSize: 18
                            color: pywal.primary
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 10
                            radius: 5
                            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1)

                            Rectangle {
                                width: parent.width * Math.min(1.0, (QsServices.Audio.percentage ?? 0) / 100)
                                height: parent.height
                                radius: 5
                                color: pywal.primary
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: (mouse) => {
                                    const pct = Math.round((mouse.x / width) * 100)
                                    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", `${pct}%`])
                                }
                            }
                        }
                        Text {
                            text: `${Math.round(QsServices.Audio.percentage ?? 0)}%`
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: pywal.onSurfaceMuted
                        }
                    }

                    // Microphone Slider
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: QsServices.Audio.sourceMuted ? "󰍭" : "󰍬"
                            font.family: "Material Design Icons"
                            font.pixelSize: 18
                            color: pywal.secondary
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 10
                            radius: 5
                            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1)

                            Rectangle {
                                width: parent.width * Math.min(1.0, (QsServices.Audio.sourcePercentage ?? 0) / 100)
                                height: parent.height
                                radius: 5
                                color: pywal.secondary
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: (mouse) => {
                                    const pct = Math.round((mouse.x / width) * 100)
                                    QsServices.Audio.setSourceVolume(pct / 100)
                                }
                            }
                        }
                        Text {
                            text: `${Math.round(QsServices.Audio.sourcePercentage ?? 0)}%`
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: pywal.onSurfaceMuted
                        }
                    }

                    // Brightness Slider
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "󰃠"
                            font.family: "Material Design Icons"
                            font.pixelSize: 18
                            color: pywal.info
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 10
                            radius: 5
                            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1)

                            Rectangle {
                                width: parent.width * Math.min(1.0, (QsServices.Brightness.percentage ?? 0) / 100)
                                height: parent.height
                                radius: 5
                                color: pywal.info
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: (mouse) => {
                                    const pct = Math.max(5, Math.round((mouse.x / width) * 100))
                                    Quickshell.execDetached(["brightnessctl", "set", `${pct}%`])
                                }
                            }
                        }
                        Text {
                            text: `${Math.round(QsServices.Brightness.percentage ?? 0)}%`
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: pywal.onSurfaceMuted
                        }
                    }

                    // Quick Toggles Grid
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 10
                        columnSpacing: 10

                        // DND Toggle
                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            radius: 12
                            color: QsServices.Notifs.dnd ? pywal.primary : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.06)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8
                                Text { text: "󰂛"; font.family: "Material Design Icons"; font.pixelSize: 18; color: QsServices.Notifs.dnd ? pywal.surfaceContainerHighest : pywal.foreground }
                                Text { text: "Do Not Disturb"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Medium; color: QsServices.Notifs.dnd ? pywal.surfaceContainerHighest : pywal.foreground }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: QsServices.Notifs.dnd = !QsServices.Notifs.dnd
                            }
                        }

                        // Night Light Toggle
                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            radius: 12
                            color: QsServices.Settings.nightLightEnabled ? pywal.secondary : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.06)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8
                                Text { text: "󰌵"; font.family: "Material Design Icons"; font.pixelSize: 18; color: QsServices.Settings.nightLightEnabled ? pywal.surfaceContainerHighest : pywal.foreground }
                                Text { text: "Night Light"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Medium; color: QsServices.Settings.nightLightEnabled ? pywal.surfaceContainerHighest : pywal.foreground }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: QsServices.Settings.nightLightEnabled = !QsServices.Settings.nightLightEnabled
                            }
                        }

                        // Gaming Mode Toggle
                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            radius: 12
                            color: QsServices.GamingMode.enabled ? pywal.info : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.06)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8
                                Text { text: "󰊴"; font.family: "Material Design Icons"; font.pixelSize: 18; color: QsServices.GamingMode.enabled ? pywal.surfaceContainerHighest : pywal.foreground }
                                Text { text: "Gaming Mode"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Medium; color: QsServices.GamingMode.enabled ? pywal.surfaceContainerHighest : pywal.foreground }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: QsServices.GamingMode.enabled = !QsServices.GamingMode.enabled
                            }
                        }

                        // Idle Inhibitor Toggle
                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            radius: 12
                            color: QsServices.IdleInhibitor.enabled ? pywal.tertiary : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.06)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8
                                Text { text: "󰅶"; font.family: "Material Design Icons"; font.pixelSize: 18; color: QsServices.IdleInhibitor.enabled ? pywal.surfaceContainerHighest : pywal.foreground }
                                Text { text: "Keep Awake"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Medium; color: QsServices.IdleInhibitor.enabled ? pywal.surfaceContainerHighest : pywal.foreground }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: QsServices.IdleInhibitor.enabled = !QsServices.IdleInhibitor.enabled
                            }
                        }

                        // Power Mode Toggle
                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            radius: 12
                            color: QsServices.PowerProfiles.activeProfile === "performance" ? pywal.success : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.06)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8
                                Text {
                                    text: QsServices.PowerProfiles.getProfileIcon(QsServices.PowerProfiles.activeProfile)
                                    font.family: "Material Design Icons"
                                    font.pixelSize: 18
                                    color: QsServices.PowerProfiles.activeProfile === "performance" ? pywal.surfaceContainerHighest : pywal.foreground
                                }
                                Text {
                                    text: QsServices.PowerProfiles.getProfileLabel(QsServices.PowerProfiles.activeProfile)
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: QsServices.PowerProfiles.activeProfile === "performance" ? pywal.surfaceContainerHighest : pywal.foreground
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const profiles = QsServices.PowerProfiles.availableProfiles
                                    const index = profiles.indexOf(QsServices.PowerProfiles.activeProfile)
                                    QsServices.PowerProfiles.setProfile(profiles[(index + 1) % profiles.length])
                                }
                            }
                        }

                        // Screenshot Toggle
                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            radius: 12
                            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.06)

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8
                                Text { text: "󰹑"; font.family: "Material Design Icons"; font.pixelSize: 18; color: pywal.foreground }
                                Text { text: "Screenshot"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Medium; color: pywal.foreground }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: QsServices.Screenshot.takeScreenshot("screen")
                            }
                        }

                        // Open Captures Toggle
                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            radius: 12
                            color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.06)

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8
                                Text { text: "󰉋"; font.family: "Material Design Icons"; font.pixelSize: 18; color: pywal.foreground }
                                Text { text: "Open Captures"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Medium; color: pywal.foreground }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: QsServices.Screenshot.openScreenshotsFolder()
                            }
                        }
                    }

                    // System Stats
                    SystemStats {
                        Layout.fillWidth: true
                        systemUsage: QsServices.SystemUsage
                        pywal: root.pywal
                    }

                    // Media Player Card
                    MediaCard {
                        Layout.fillWidth: true
                        mpris: QsServices.Players
                        pywal: root.pywal
                    }
                }
            }
        }

        // ═══ Right Column: WiFi & Bluetooth Management ═══
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 340
            radius: tokens.radiusRaised
            color: tokens.surface
            clip: true

            StyledFlickable {
                anchors.fill: parent
                contentWidth: width
                contentHeight: rightColumn.implicitHeight

                ColumnLayout {
                    id: rightColumn
                    width: parent.width
                    spacing: 14

                    BarComponents.NetworkPanel {
                        id: netPanel
                        Layout.fillWidth: true
                        focus: true

                        Component.onCompleted: shouldShow = true

                        Connections {
                            function onCloseRequested() { root.closeRequested() }
                        }
                    }

                    BarComponents.BluetoothPanel {
                        id: btPanel
                        Layout.fillWidth: true

                        Component.onCompleted: shouldShow = true

                        Connections {
                            function onCloseRequested() { root.closeRequested() }
                        }
                    }
                }
            }
        }
    }
}
