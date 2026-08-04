import Quickshell
import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import "components" as BarComponents
import "../../components"
import "../../components" as QsComponents
import "../../components/effects"
import "../../config" as QsConfig
import "../../services" as QsServices

Item {
    id: root
    
    property var screen
    property var barWindow
    property var controlCenter
    property var launcher
    property var sidebar
    property var dashboard
    property var wallpaper
    
    // ═══ Inline Popup State ═══
    property string activePopup: ""  // "", "bluetooth", "network"
    property string lastActivePopup: "network"
    readonly property bool hasPopup: activePopup !== ""
    readonly property bool isPopupOpen: hasPopup || popupContentWrapper.opacity > 0
    readonly property string currentPopup: hasPopup ? activePopup : lastActivePopup
    readonly property real popupAreaHeight: isPopupOpen ? popupHost.height : 0

    onActivePopupChanged: {
        if (activePopup !== "") {
            lastActivePopup = activePopup
        }
    }
    
    function togglePopup(name: string) {
        if (activePopup === name) {
            activePopup = ""
        } else {
            activePopup = name
        }
    }
    function closePopup() {
        activePopup = ""
    }

    function popupAnchorTarget() {
        const p = currentPopup
        if (p === "network" || p === "bluetooth") return connectivityPill
        if (p === "wallpapers") return leftModule
        if (p === "battery") return powerPill
        return rightPills
    }
    
    readonly property var config: QsConfig.Config
    readonly property var appearance: QsConfig.Config.appearanceTokens
    readonly property var pywal: QsServices.Pywal
    
    // ═══════════════════════════════════════════════════════════════════════
    // MINIMAL AESTHETIC BAR
    // Clean, professional, beautiful - inspired by modern Linux rice
    // ═══════════════════════════════════════════════════════════════════════
    
    // Main bar container with floating effect — pinned to top bar strip
    Item {
        id: barContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        // Match Hyprland's `gaps_out = 4` so bar islands align with windows.
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        anchors.topMargin: 1
        height: config.bar.height - 2  // bar height minus top+bottom margin
        
        // ═══════════════════════════════════════════════════════════════
        // LEFT MODULE - Workspaces
        // ═══════════════════════════════════════════════════════════════
        AuroraSurface {
            id: leftModule
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: 32
            width: leftContent.implicitWidth + 18
            
            radius: 20
            color: pywal.surfaceContainerHigh
            strokeColor: pywal.outlineVariant
            borderWidth: 0
            accentColor: pywal.primary
            elevation: 3
            
            // Smooth transitions
            Behavior on color {
                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
            }
            
            Behavior on width {
                NumberAnimation { duration: 233; easing.bezierCurve: [0.34, 1.56, 0.64, 1] }
            }
            
            RowLayout {
                id: leftContent
                anchors.centerIn: parent
                spacing: 10
                
                // Workspaces
                Loader {
                    id: workspacesLoader
                    Layout.alignment: Qt.AlignVCenter
                    asynchronous: true
                    source: "components/Workspaces.qml"
                    
                    Binding {
                        target: workspacesLoader.item
                        property: "screen"
                        value: root.screen
                        when: workspacesLoader.status === Loader.Ready && root.screen !== undefined
                        restoreMode: Binding.RestoreBinding
                    }
                }
                Item {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    Text { anchors.centerIn: parent; text: "󰸉"; font.family: "Material Design Icons"; font.pixelSize: 16; color: pywal.foreground }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (root.wallpaper) root.wallpaper.shouldShow = !root.wallpaper.shouldShow }
                }
            }
        }
        
        // ═══════════════════════════════════════════════════════════════
        // CENTER MODULE - Clock (Focal Point)
        // ═══════════════════════════════════════════════════════════════
        AuroraSurface {
            id: centerModule
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            height: 32
            width: clockLoader.implicitWidth + 22
            
            radius: 20
            color: pywal.surfaceContainerHighest
            strokeColor: pywal.outlineVariant
            borderWidth: 0
            accentColor: pywal.primary
            elevation: 4
            highlighted: true
            
            Behavior on color {
                ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
            }
            
            Loader {
                id: clockLoader
                anchors.centerIn: parent
                asynchronous: true
                source: "components/Clock.qml"

                Binding {
                    target: clockLoader.item
                    property: "launcher"
                    value: root.launcher
                    when: clockLoader.status === Loader.Ready && root.launcher !== undefined
                    restoreMode: Binding.RestoreBinding
                }

                Binding {
                    target: clockLoader.item
                    property: "controlCenter"
                    value: root.controlCenter
                    when: clockLoader.status === Loader.Ready && root.controlCenter !== undefined
                    restoreMode: Binding.RestoreBinding
                }

                Binding {
                    target: clockLoader.item
                    property: "sidebar"
                    value: root.sidebar
                    when: clockLoader.status === Loader.Ready && root.sidebar !== undefined
                    restoreMode: Binding.RestoreBinding
                }

                Binding {
                    target: clockLoader.item
                    property: "dashboard"
                    value: root.dashboard
                    when: clockLoader.status === Loader.Ready && root.dashboard !== undefined
                    restoreMode: Binding.RestoreBinding
                }
            }
        }
        
        // ═══════════════════════════════════════════════════════════════
        // RIGHT SIDE - Three Separate Pills
        // ═══════════════════════════════════════════════════════════════
        Row {
            id: rightPills
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            
            // ═══ PILL 1: Network + Bluetooth (Connectivity) ═══
            AuroraSurface {
                id: connectivityPill
                height: 32
                width: connectivityContent.implicitWidth + 18
                radius: 20
                color: pywal.surfaceContainerHigh
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.info
                elevation: 3
                
                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
                Behavior on width {
                    NumberAnimation { duration: 167; easing.type: Easing.OutCubic }
                }
                
                Row {
                    id: connectivityContent
                    anchors.centerIn: parent
                    spacing: 4
                    
                    Loader {
                        id: networkLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Network.qml"
                        
                        Binding {
                            target: networkLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: networkLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                        
                        Binding {
                            target: networkLoader.item
                            property: "bar"
                            value: root
                            when: networkLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                    
                    // Separator
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12)
                    }
                    
                    Loader {
                        id: bluetoothLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Bluetooth.qml"
                        
                        Binding {
                            target: bluetoothLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: bluetoothLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                        
                        Binding {
                            target: bluetoothLoader.item
                            property: "bar"
                            value: root
                            when: bluetoothLoader.status === Loader.Ready
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                }
            }
            
            // ═══ PILL 2: Brightness + Volume (Audio/Display) ═══
            AuroraSurface {
                id: audioPill
                height: 32
                width: audioContent.implicitWidth + 18
                radius: 20
                color: pywal.surfaceContainerHigh
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.secondary
                elevation: 3
                
                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
                Behavior on width {
                    NumberAnimation { duration: 167; easing.type: Easing.OutCubic }
                }
                
                Row {
                    id: audioContent
                    anchors.centerIn: parent
                    spacing: 6
                    
                    Loader {
                        id: brightnessLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Brightness.qml"
                        
                        Binding {
                            target: brightnessLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: brightnessLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                    
                    // Separator
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12)
                    }
                    
                    Loader {
                        id: volumeLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Volume.qml"
                        
                        Binding {
                            target: volumeLoader.item
                            property: "barWindow"
                            value: root.barWindow
                            when: volumeLoader.status === Loader.Ready && root.barWindow !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                    }
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 12; color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12) }
                    Loader { anchors.verticalCenter: parent.verticalCenter; asynchronous: true; source: "components/Microphone.qml" }
                }
            }
            
            // ═══ PILL 3: Battery + Control Center + Tray ═══
            AuroraSurface {
                id: powerPill
                height: 32
                width: powerContent.implicitWidth + 18
                radius: 20
                color: pywal.surfaceContainerHigh
                strokeColor: pywal.outlineVariant
                borderWidth: 0
                accentColor: pywal.primary
                elevation: 3
                
                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
                Behavior on width {
                    NumberAnimation { duration: 167; easing.type: Easing.OutCubic }
                }
                
                Row {
                    id: powerContent
                    anchors.centerIn: parent
                    spacing: 6
                    
                    // Status Indicators (Caffeine, DND)
                    Loader {
                        id: statusIndicatorsLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/StatusIndicators.qml"
                        visible: item?.hasActiveIndicators ?? false
                    }
                    
                    // Separator (only if status indicators visible)
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 12
                        radius: 0.5
                        color: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.12)
                        visible: statusIndicatorsLoader.item?.hasActiveIndicators ?? false
                    }
                    
                    // Battery
                    Loader {
                        id: batteryLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/Battery.qml"
                    }

                    // Control Center Toggle
                    Loader {
                        id: controlCenterLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/ControlCenterToggle.qml"
                        
                        Binding {
                            target: controlCenterLoader.item
                            property: "controlCenter"
                            value: root.controlCenter
                            when: controlCenterLoader.status === Loader.Ready && root.controlCenter !== undefined
                            restoreMode: Binding.RestoreBinding
                        }
                    }

                    
                    // System Tray (only if has items)
                    Loader {
                        id: systemTrayLoader
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        source: "components/SystemTray.qml"
                        visible: item?.hasItems ?? false
                    }
                }
            }
        }
        
        // ═══════════════════════════════════════════════════════════════
        // MEDIA MODULE - Always visible (shows "No media" when not playing)
        // ═══════════════════════════════════════════════════════════════
        AuroraSurface {
            id: mediaModule
            anchors.left: leftModule.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 32
            width: mediaPlayerLoader.implicitWidth + 18
            
            radius: 20
            color: pywal.surfaceContainerHigh
            strokeColor: pywal.outlineVariant
            borderWidth: 0
            accentColor: pywal.secondary
            elevation: 3
            
            clip: true
            
            Behavior on width {
                NumberAnimation { 
                    duration: 400
                    easing.bezierCurve: [0.34, 1.56, 0.64, 1]
                }
            }
            
            Loader {
                id: mediaPlayerLoader
                anchors.centerIn: parent
                asynchronous: true
                source: "components/MediaPlayer.qml"
                
                Binding {
                    target: mediaPlayerLoader.item
                    property: "barWindow"
                    value: root.barWindow
                    when: mediaPlayerLoader.status === Loader.Ready && root.barWindow !== undefined
                    restoreMode: Binding.RestoreBinding
                }
                
                Binding {
                    target: mediaPlayerLoader.item
                    property: "mediaPopup"
                    value: null
                    when: mediaPlayerLoader.status === Loader.Ready
                    restoreMode: Binding.RestoreBinding
                }
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // INLINE POPUP HOST — popups expand below the bar within the same window
    // ═══════════════════════════════════════════════════════════════════════
    Item {
        id: popupHost
        anchors.top: barContainer.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.isPopupOpen ? popupContentWrapper.height + 12 : 0
        clip: true

        // Match Control Center behavior: close after leaving popup focus area
        property bool mouseHasEntered: false
        property bool mouseInside: popupHoverHandler.hovered

        onVisibleChanged: {
            if (!visible) {
                mouseHasEntered = false
                popupCloseTimer.stop()
            }
        }

        Connections {
            target: root
            function onHasPopupChanged() {
                if (root.hasPopup) {
                    popupHost.mouseHasEntered = false
                    popupCloseTimer.stop()
                } else {
                    popupCloseTimer.stop()
                }
            }
        }

        Timer {
            id: popupCloseTimer
            interval: 400
            onTriggered: {
                if (!popupHost.mouseInside && popupHost.mouseHasEntered && root.hasPopup) {
                    root.closePopup()
                }
            }
        }
        
        Behavior on height {
            NumberAnimation {
                duration: 0
                easing.bezierCurve: root.appearance.anim.popup.curve
            }
        }
        
        // Click-outside scrim to dismiss popup
        MouseArea {
            anchors.fill: parent
            visible: root.hasPopup
            onClicked: root.closePopup()
        }
        
        // Popup content container — positioned below the triggering pill
        Item {
            id: popupContentWrapper
            y: 4
            x: {
                // Center popup under its trigger and clamp to host bounds
                const w = width
                const hostPadding = 12
                const anchor = root.popupAnchorTarget()

                if (anchor) {
                    const centerInHost = anchor.mapToItem(popupHost, anchor.width / 2, anchor.height).x
                    return Math.max(hostPadding, Math.min(popupHost.width - w - hostPadding, centerInHost - (w / 2)))
                }

                return Math.max(hostPadding, popupHost.width - w - hostPadding)
            }
            width: root.currentPopup === "network" ? 340 : root.currentPopup === "wallpapers" ? 520 : 320
            height: {
                if (btPanelLoader.active && btPanelLoader.item)
                    return btPanelLoader.item.implicitHeight
                if (netPanelLoader.active && netPanelLoader.item)
                    return netPanelLoader.item.implicitHeight
                if (wallpaperPanelLoader.active && wallpaperPanelLoader.item)
                    return wallpaperPanelLoader.item.implicitHeight
                return 0
            }
            
            // Entry animation using central PanelMotion module
            scale: root.hasPopup ? 1.0 : QsComponents.PanelMotion.closedScale
            opacity: root.hasPopup ? 1.0 : 0.0
            transformOrigin: Item.TopRight
            
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

            HoverHandler {
                id: popupHoverHandler
                onHoveredChanged: {
                    if (hovered) {
                        popupHost.mouseHasEntered = true
                        popupCloseTimer.stop()
                    } else if (popupHost.mouseHasEntered && root.hasPopup) {
                        popupCloseTimer.restart()
                    }
                }
            }
            
            // Bluetooth Panel
            Loader {
                id: btPanelLoader
                anchors.fill: parent
                active: root.currentPopup === "bluetooth" && root.isPopupOpen
                source: "components/BluetoothPanel.qml"
                
                onLoaded: {
                    item.shouldShow = true
                    item.forceActiveFocus()
                }
                
                Connections {
                    target: btPanelLoader.item
                    function onCloseRequested() { root.closePopup() }
                }
            }
            
            // Network Panel
            Loader {
                id: netPanelLoader
                anchors.fill: parent
                active: root.currentPopup === "network" && root.isPopupOpen
                source: "components/NetworkPanel.qml"
                
                onLoaded: {
                    item.shouldShow = true
                    item.forceActiveFocus()
                }
                
                Connections {
                    target: netPanelLoader.item
                    function onCloseRequested() { root.closePopup() }
                }
            }
            Loader {
                id: wallpaperPanelLoader
                anchors.fill: parent
                active: root.currentPopup === "wallpapers" && root.isPopupOpen
                source: "components/WallpaperPanel.qml"
                Connections { target: wallpaperPanelLoader.item; function onCloseRequested() { root.closePopup() } }
            }
        }
    }
}
