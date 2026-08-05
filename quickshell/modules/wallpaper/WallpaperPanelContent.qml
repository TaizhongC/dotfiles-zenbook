import QtQuick 6.10
import QtQuick.Effects
import Quickshell
import "../../services" as QsServices

Item {
    id: root
    readonly property var wallpaperService: QsServices.Wallpaper
    readonly property var wallpapers: wallpaperService.wallpapers

    GridView {
        anchors.fill: parent
        clip: true
        cellWidth: 120
        cellHeight: 108
        model: root.wallpapers

        delegate: Item {
            id: thumbItem
            required property var modelData
            width: 112
            height: 100

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: "transparent"
                border.width: thumbMouse.containsMouse ? 2 : 1
                border.color: thumbMouse.containsMouse ? QsServices.Pywal.primary : QsServices.Pywal.outlineVariant
                Behavior on border.color { ColorAnimation { duration: 150 } }
                clip: true
                layer.enabled: true

                Image {
                    anchors.fill: parent
                    source: "file://" + thumbItem.modelData
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    sourceSize.width: 240
                    sourceSize.height: 200

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: maskRect
                    }
                }

                Item {
                    id: maskRect
                    anchors.fill: parent
                    visible: false
                    layer.enabled: true
                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: "#ffffff"
                    }
                }
            }

            MouseArea {
                id: thumbMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execDetached(["wallpaperctl", "set", thumbItem.modelData])
                }
            }
        }
    }
}
