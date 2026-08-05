import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../config" as QsConfig
import "../../services" as QsServices

ColumnLayout {
    id: root
    anchors.fill: parent
    spacing: 14

    readonly property var pywal: QsServices.Pywal
    readonly property var config: QsConfig.Config

    Rectangle {
        Layout.fillWidth: true
        height: 48
        radius: 16
        color: pywal.surfaceContainerHigh
        border.width: 1
        border.color: pywal.outlineVariant

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Text { text: "󰍉"; font.family: "Material Design Icons"; font.pixelSize: 20; color: pywal.primary }

            TextInput {
                id: searchInput
                Layout.fillWidth: true
                font.family: "Inter"
                font.pixelSize: 14
                color: pywal.foreground
                focus: true
            }
        }
    }

    Text {
        text: "Quick Applications"
        font.family: "Inter"
        font.pixelSize: 12
        font.weight: Font.SemiBold
        color: pywal.onSurfaceMuted
    }

    GridView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        cellWidth: 120
        cellHeight: 90

        model: [
            { name: "Terminal", icon: "󰆍", cmd: ["foot"] },
            { name: "Files", icon: "󰉋", cmd: ["xdg-open", Quickshell.env("HOME")] },
            { name: "Browser", icon: "󰈹", cmd: ["firefox"] },
            { name: "Code", icon: "󰨞", cmd: ["code"] },
            { name: "Settings", icon: "󰒓", cmd: ["nwg-displays"] },
            { name: "System", icon: "󰄨", cmd: ["btop"] }
        ]

        delegate: Rectangle {
            width: 110
            height: 80
            radius: 14
            color: appMouse.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.08) : pywal.surfaceContainerHigh
            border.width: 1
            border.color: appMouse.containsMouse ? pywal.primary : pywal.outlineVariant
            Behavior on color { ColorAnimation { duration: 150 } }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6
                Text { Layout.alignment: Qt.AlignHCenter; text: modelData.icon; font.family: "Material Design Icons"; font.pixelSize: 28; color: pywal.primary }
                Text { Layout.alignment: Qt.AlignHCenter; text: modelData.name; font.family: "Inter"; font.pixelSize: 11; color: pywal.foreground }
            }

            MouseArea {
                id: appMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(modelData.cmd)
            }
        }
    }
}
