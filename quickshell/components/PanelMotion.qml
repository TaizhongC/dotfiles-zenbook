pragma Singleton

import QtQuick 6.10
import "../config" as QsConfig

QtObject {
    id: root

    readonly property var appearance: QsConfig.AppearanceConfig

    // Unified motion parameters for all shell panels (Wifi, Bluetooth, Wallpaper, Control Center, Launcher, etc.)
    readonly property int duration: (appearance && appearance.anim && appearance.anim.popup) ? appearance.anim.popup.duration : 90
    readonly property int fadeDuration: (appearance && appearance.anim && appearance.anim.popup) ? appearance.anim.popup.fadeDuration : 70
    readonly property real closedScale: (appearance && appearance.anim && appearance.anim.popup) ? appearance.anim.popup.closedScale : 0.98
    readonly property var curve: (appearance && appearance.anim && appearance.anim.popup) ? appearance.anim.popup.curve : [0.05, 0.7, 0.1, 1.0]

    // Unified close timer interval delay
    readonly property int closeDelay: duration + 10
    readonly property int offset: appearance?.anim?.popup?.offset ?? 12
}
