import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"

ColumnLayout {
    id: root
    anchors.fill: parent
    spacing: 14

    readonly property var notifs: QsServices.Notifs
    readonly property var pywal: QsServices.Pywal

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "Notifications"
            font.family: QsConfig.Config.appearance.fontFamily
            font.pixelSize: 16
            font.weight: Font.Bold
            color: pywal.foreground
        }
        Item { Layout.fillWidth: true }
        Text {
            text: `${notifs.list.length} total`
            font.family: QsConfig.Config.appearance.fontFamily
            font.pixelSize: 12
            color: pywal.onSurfaceMuted
        }
        Rectangle {
            width: 28; height: 28; radius: 14
            color: clearMouse.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1) : "transparent"
            Text { anchors.centerIn: parent; text: "󰎟"; font.family: "Material Design Icons"; font.pixelSize: 16; color: pywal.foreground }
            MouseArea {
                id: clearMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: notifs.clearAll()
            }
        }
    }

    StyledListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 10
        model: notifs.list

        delegate: NotificationCard {
            width: ListView.view.width
            notification: modelData
            pywal: root.pywal
        }
    }
}
