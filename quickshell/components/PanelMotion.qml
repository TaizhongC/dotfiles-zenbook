pragma Singleton

import QtQuick 6.10
import "../config" as QsConfig

QtObject {
    id: root

    readonly property var appearance: QsConfig.Config.appearanceTokens

    // Unified motion parameters for all base panels (Wifi, Bluetooth, Wallpaper, Control Center, Calendar, Sidebar, Launcher, etc.)
    readonly property int duration: appearance ? appearance.anim.popup.duration : 90
    readonly property int fadeDuration: appearance ? appearance.anim.popup.fadeDuration : 70
    readonly property real closedScale: appearance ? appearance.anim.popup.closedScale : 0.98
    readonly property var curve: appearance ? appearance.anim.popup.curve : [0.05, 0.7, 0.1, 1.0]
    readonly property int offset: appearance ? appearance.anim.popup.offset : 12

    // Panel-to-panel morphing (size transition of the shared card)
    readonly property int morphDuration: 220
    readonly property int contentFade: 120
}
