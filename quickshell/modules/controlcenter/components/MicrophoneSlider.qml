import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10

Item {
    id: root
    required property var audio
    property var pywal
    readonly property int value: audio.sourcePercentage
    readonly property color cText: pywal.foreground
    readonly property color cPrimary: pywal.primary
    Layout.fillWidth: true
    Layout.preferredHeight: 64
    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 24; spacing: 16
        Rectangle {
            Layout.preferredWidth: 44; Layout.preferredHeight: 44; radius: 22
            color: muteMouse.pressed ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.12) : muteMouse.containsMouse ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.08) : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }
            scale: muteMouse.pressed ? 0.92 : 1.0
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            Text { anchors.centerIn: parent; text: root.audio.sourceMuted ? "󰍭" : "󰍬"; font.family: "Material Design Icons"; font.pixelSize: 24; color: root.audio.sourceMuted ? Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.4) : root.cPrimary }
            MouseArea { id: muteMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.audio.toggleSourceMute() }
        }
        Slider {
            id: slider; Layout.fillWidth: true; Layout.fillHeight: true; from: 0; to: 100; value: root.value; live: true
            onMoved: root.audio.setSourceVolume(value / 100)
            background: Rectangle { x: slider.leftPadding; y: slider.topPadding + slider.availableHeight / 2 - height / 2; width: slider.availableWidth; height: 8; radius: 4; color: Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.1); Rectangle { width: slider.visualPosition * parent.width; height: parent.height; radius: 4; color: root.cPrimary } }
            handle: Rectangle { x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width); y: slider.topPadding + slider.availableHeight / 2 - height / 2; width: 20; height: slider.pressed ? 32 : 20; radius: 10; color: root.cPrimary; Behavior on height { NumberAnimation { duration: 80 } } }
        }
        Text { Layout.preferredWidth: 44; text: root.value + "%"; font.family: "Inter"; font.pixelSize: 15; font.weight: Font.Bold; color: root.cText; horizontalAlignment: Text.AlignRight }
    }
}
