import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../../../services" as QsServices

Item {
    id: root
    readonly property var audio: QsServices.Audio
    readonly property bool muted: audio.sourceMuted
    readonly property int percentage: audio.sourcePercentage
    readonly property bool isHovered: mouse.containsMouse
    implicitWidth: row.implicitWidth
    implicitHeight: 20

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 3
        Text {
            text: root.muted ? "󰍭" : "󰍬"
            font.family: "Material Design Icons"
            font.pixelSize: 14
            color: root.muted ? Qt.rgba(QsServices.Pywal.foreground.r, QsServices.Pywal.foreground.g, QsServices.Pywal.foreground.b, 0.35) : root.isHovered ? QsServices.Pywal.primary : QsServices.Pywal.foreground
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        Text { text: root.percentage; font.family: "Inter"; font.pixelSize: 10; font.weight: Font.Medium; color: Qt.rgba(QsServices.Pywal.foreground.r, QsServices.Pywal.foreground.g, QsServices.Pywal.foreground.b, 0.7) }
    }
    MouseArea { id: mouse; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.ArrowCursor }
}
