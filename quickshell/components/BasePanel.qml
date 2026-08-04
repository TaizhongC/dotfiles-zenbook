import QtQuick 6.10
import "." as QsComponents

FocusScope {
    id: root

    property bool isOpen: false
    property var panelOrigin: Item.TopRight

    anchors.fill: parent
    transformOrigin: panelOrigin
    scale: isOpen ? 1.0 : QsComponents.PanelMotion.closedScale
    opacity: isOpen ? 1.0 : 0.0

    Behavior on scale {
        NumberAnimation {
            duration: QsComponents.PanelMotion.duration
            easing.bezierCurve: QsComponents.PanelMotion.curve
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: QsComponents.PanelMotion.fadeDuration
            easing.bezierCurve: QsComponents.PanelMotion.curve
        }
    }
}
