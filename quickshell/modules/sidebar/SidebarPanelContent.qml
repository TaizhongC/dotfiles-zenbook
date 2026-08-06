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
    // Closed notifications stay in the 24h history (for popup dismissal state)
    // but must leave the panel — otherwise the close button appears dead.
    readonly property var visibleNotifications: (notifs.recentNotifications ?? [])
        .filter(n => !!n && !n.closed)
        .slice(0, QsConfig.Config.sidebar.maxHistory)

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
            text: `${visibleNotifications.length} total`
            font.family: QsConfig.Config.appearance.fontFamily
            font.pixelSize: 12
            color: pywal.onSurfaceMuted
        }
        Rectangle {
            width: 28; height: 28; radius: 14
            color: clearMouse.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1) : "transparent"
            Text { anchors.centerIn: parent; text: "󰆴"; font.family: "Material Design Icons"; font.pixelSize: 16; color: pywal.foreground }
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
        spacing: 4
        model: root.visibleNotifications

        delegate: Rectangle {
            id: notifDelegate
            required property var modelData

            width: ListView.view.width
            // Explicit height — children with anchors.fill do not size their
            // parent, so delegates otherwise collapse to 0 and every
            // notification overlaps the first one.
            height: Math.max(72, notifCard.implicitHeight + 10)
            radius: 16
            color: notifDelegate.modelData.read
                ? "transparent"
                : Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.08)
            Behavior on color { ColorAnimation { duration: 150 } }

            NotificationCard {
                id: notifCard
                anchors.fill: parent
                notification: notifDelegate.modelData
                pywal: root.pywal
                showTimestamp: true
            }
        }
    }
}
