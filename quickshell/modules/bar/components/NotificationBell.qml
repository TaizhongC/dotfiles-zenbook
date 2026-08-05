import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../../services" as QsServices
import "../../../components/effects"

Item {
    id: root

    property var centricPanel

    readonly property var pywal: QsServices.Pywal
    readonly property var notifs: QsServices.Notifs
    readonly property bool hasUnread: notifs.unreadCount > 0
    readonly property bool isActive: (centricPanel?.activePanel ?? "") === "notification"
    readonly property bool isHovered: toggleMouse.containsMouse

    implicitWidth: bellIcon.implicitWidth + 6
    implicitHeight: bellIcon.implicitHeight

    MouseArea {
        id: toggleMouse
        anchors.fill: parent
        anchors.margins: -4  // Larger hit area
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (!centricPanel)
                return
            const opening = centricPanel.activePanel !== "notification"
            centricPanel.togglePanel("notification")
            if (opening)
                notifs.markAllRead()
        }
    }

    // Bell icon — always the same glyph, warning colored when there are
    // unread notifications, regular (battery-style) color otherwise.
    // Pixel size matches the other bar icons (Network/Volume/Bluetooth use 14).
    Text {
        id: bellIcon
        anchors.centerIn: parent
        text: "󰂚"
        font.family: "Material Design Icons"
        font.pixelSize: 14

        color: {
            if (root.hasUnread) return pywal.warning
            if (root.isActive) return pywal.primary
            if (isHovered) return pywal.primary
            // Match the other bar icons (Volume/Network/Battery all render
            // foreground at partial alpha — full alpha reads too bright).
            return Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.8)
        }

        Behavior on color {
            ColorAnimation {
                duration: Material3Anim.short3
                easing.bezierCurve: Material3Anim.standard
            }
        }

        scale: {
            if (toggleMouse.pressed) return 0.9
            if (isHovered || isActive) return 1.1
            return 1.0
        }

        Behavior on scale {
            NumberAnimation {
                duration: Material3Anim.short2
                easing.bezierCurve: Material3Anim.standard
            }
        }
    }

    // Unread dot
    Rectangle {
        visible: root.hasUnread
        anchors.top: bellIcon.top
        anchors.right: bellIcon.right
        width: 6
        height: 6
        radius: 3
        color: pywal.warning
        border.width: 1
        border.color: pywal.surfaceContainerHighest
    }
}
