pragma Singleton

import QtQuick 6.10
import Quickshell
import "../config" as QsConfig

Singleton {
    readonly property real hoverOpacity: 0.08
    readonly property real pressedOpacity: 0.12
    readonly property real disabledOpacity: 0.38
    readonly property real pressedScale: 0.96

    readonly property int short1: 50
    readonly property int short2: 100
    readonly property int short3: 150
    readonly property int short4: 200
    readonly property int medium1: 250
    readonly property int medium2: 300
    readonly property int medium3: 350
    readonly property int medium4: 400

    readonly property var standard: QsConfig.AppearanceConfig.anim.curves.standard
    readonly property var standardDecelerate: QsConfig.AppearanceConfig.anim.curves.standardDecel
    readonly property var standardAccelerate: QsConfig.AppearanceConfig.anim.curves.standardAccel
    readonly property var emphasizedDecelerate: QsConfig.AppearanceConfig.anim.curves.emphasizedDecel
    readonly property var emphasizedAccelerate: QsConfig.AppearanceConfig.anim.curves.emphasizedAccel
    readonly property var springGentle: QsConfig.AppearanceConfig.anim.curves.springGentle
    readonly property var springExpressive: QsConfig.AppearanceConfig.anim.curves.springExpressive
    readonly property var springBounce: [0.5, 1.5, 0.5, 1.0]
}
