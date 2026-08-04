import QtQuick 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"
import "../../components" as QsComponents

PanelWindow {
    id: root

    property bool shouldShow: false
    readonly property var wallpaperService: QsServices.Wallpaper
    readonly property var wallpapers: wallpaperService.wallpapers
    readonly property var appearance: QsConfig.AppearanceConfig

    screen: Quickshell.screens[0]
    anchors { top: true; left: true }
    margins { top: (QsConfig.Config.bar.height ?? 34) + appearance.anim.popup.offset; left: 4 }
    implicitWidth: 440
    implicitHeight: shouldShow || panel.opacity > 0 ? 360 : 0
    visible: shouldShow || panel.opacity > 0
    color: "transparent"

    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusScope {
        id: panel
        anchors.fill: parent
        transformOrigin: Item.Top
        scale: root.shouldShow ? 1 : QsComponents.PanelMotion.closedScale
        opacity: root.shouldShow ? 1 : 0
        focus: root.shouldShow

        Keys.onEscapePressed: root.shouldShow = false

        HoverHandler {
            id: hoverHandler
            onHoveredChanged: {
                if (hovered) closeTimer.stop()
                else if (root.shouldShow) closeTimer.restart()
            }
        }
        Timer { id: closeTimer; interval: 600; onTriggered: if (!hoverHandler.hovered) root.shouldShow = false }

        Behavior on scale { NumberAnimation { duration: QsComponents.PanelMotion.duration; easing.bezierCurve: QsComponents.PanelMotion.curve } }
        Behavior on opacity { NumberAnimation { duration: QsComponents.PanelMotion.fadeDuration; easing.bezierCurve: QsComponents.PanelMotion.curve } }

        Rectangle {
            anchors.fill: parent
            radius: 28
            color: QsServices.Pywal.surfaceContainerHighest
            border.width: 1
            border.color: QsServices.Pywal.outlineVariant

            GridView {
                anchors.fill: parent
                anchors.margins: 16
                clip: true
                cellWidth: 136
                cellHeight: 108
                model: root.wallpapers

                delegate: Item {
                    id: thumbItem
                    required property var modelData
                    width: 128
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
                            sourceSize.width: 256
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
                            root.shouldShow = false
                        }
                    }
                }
            }
        }
    }
}
