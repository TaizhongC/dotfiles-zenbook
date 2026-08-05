import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../../../services" as QsServices
import "../../../config" as QsConfig
import "../../../components"

// ═══════════════════════════════════════════════════════════════════════════
// Material 3 Expressive Notification Popups — Revamped
// ═══════════════════════════════════════════════════════════════════════════
PanelWindow {
    id: root

    readonly property var pywal: QsServices.Pywal
    readonly property var notifs: QsServices.Notifs
    readonly property var logger: QsServices.Logger
    readonly property var config: QsConfig.Config

    // ── Color Tokens (semantic, from Pywal) ──
    readonly property color m3Surface: pywal.background
    readonly property color m3SurfaceContainer: pywal.surfaceContainer
    readonly property color m3SurfaceContainerHigh: pywal.surfaceContainerHigh
    readonly property color m3Primary: pywal.primary
    readonly property color m3OnSurface: pywal.foreground
    readonly property color m3OnSurfaceVariant: Qt.rgba(m3OnSurface.r, m3OnSurface.g, m3OnSurface.b, 0.55)
    readonly property color m3Error: pywal.error
    readonly property color m3Warning: pywal.warning
    readonly property color m3Success: pywal.success
    readonly property color m3Border: Qt.rgba(m3OnSurface.r, m3OnSurface.g, m3OnSurface.b, 0.06)

    // Swipe dismiss threshold (fraction of popup width)
    readonly property real swipeThreshold: 0.30

    function _urgencyColor(u) {
        if (u === NotificationUrgency.Critical) return m3Error
        if (u === NotificationUrgency.Low) return m3OnSurfaceVariant
        return m3Primary
    }

    // Active popups — newest first, capped to maxVisible. Timeout-dismissed
    // cards are excluded so they never re-materialize from the model (e.g.
    // after a config reload) — they remain live in the notification panel.
    readonly property var activePopups: (notifs.notifications || [])
        .filter(n => !!n && !n.closed && !n.popupDismissed)
        .slice(0, config.notifications.maxVisible)

    // ── Window Setup ──
    screen: Quickshell.screens[0]
    anchors { top: true; right: true }
    margins { top: config.notifications.margin; right: config.notifications.margin }
    visible: activePopups.length > 0
    color: "transparent"
    implicitWidth: config.notifications.popupWidth
    implicitHeight: notifColumn.implicitHeight

    Behavior on implicitHeight {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // NOTIFICATION STACK
    // ═══════════════════════════════════════════════════════════════════════
    Column {
        id: notifColumn
        width: parent.width
        spacing: config.notifications.spacing

        move: Transition {
            NumberAnimation {
                properties: "y"
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Repeater {
            model: root.activePopups

            // ───────────────────────────────────────────────────────────────
            // NOTIFICATION CARD
            // ───────────────────────────────────────────────────────────────
            Item {
                id: notifCard

                required property var modelData
                required property int index

                width: config.notifications.popupWidth
                height: cardWrapper.height
                clip: true

                // ── State ──
                property bool isVisible: true
                property bool isHovered: false
                property bool isDragging: false
                property bool isExpanded: false
                property real dragX: 0
                // Progress lives on the wrapper — recreated cards must not
                // restart another message's countdown.
                property real timeoutProgress: modelData.popupProgress

                Component.onCompleted: {
                    modelData.popupActive = true
                    // This card may be a fresh instance for a message whose
                    // countdown already finished while the previous card was
                    // destroyed (the Repeater recreates cards on every model
                    // change). OnXChanged handlers don't fire for the initial
                    // binding value, so the timeout would never be noticed.
                    // The write is deferred — doing it synchronously re-enters
                    // the activePopups binding evaluation (Repeater creation)
                    // and triggers a binding loop warning.
                    if (modelData.popupProgress <= 0 && !modelData.popupDismissed) {
                        Qt.callLater(() => { modelData.popupDismissed = true })
                        return
                    }
                    // Entrance state animates on the wrapper — a card recreated
                    // mid-animation (model churn) displays the current values
                    // instead of restarting the motion.
                    if (!modelData.hasAnimated) {
                        modelData.hasAnimated = true
                        modelData.popupStagger = notifCard.index * 35
                        modelData.entranceAnim.start()
                    }
                }

                // ── Exit: swipe right ──
                SequentialAnimation {
                    id: exitRight

                    ParallelAnimation {
                        NumberAnimation {
                            target: notifCard; property: "dragX"
                            to: config.notifications.popupWidth + 60
                            duration: 180; easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: modelData; property: "popupEntryRotation"
                            to: 4; duration: 180; easing.type: Easing.InQuad
                        }
                        NumberAnimation {
                            target: modelData; property: "popupEntryOpacity"
                            to: 0.3; duration: 180; easing.type: Easing.InQuad
                        }
                    }
                    NumberAnimation {
                        target: notifCard; property: "height"
                        to: 0; duration: 120; easing.type: Easing.InCubic
                    }
                    ScriptAction { script: modelData.close() }
                }

                // ── Exit: swipe left ──
                SequentialAnimation {
                    id: exitLeft

                    ParallelAnimation {
                        NumberAnimation {
                            target: notifCard; property: "dragX"
                            to: -(config.notifications.popupWidth + 60)
                            duration: 180; easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: modelData; property: "popupEntryRotation"
                            to: -4; duration: 180; easing.type: Easing.InQuad
                        }
                        NumberAnimation {
                            target: modelData; property: "popupEntryOpacity"
                            to: 0.3; duration: 180; easing.type: Easing.InQuad
                        }
                    }
                    NumberAnimation {
                        target: notifCard; property: "height"
                        to: 0; duration: 120; easing.type: Easing.InCubic
                    }
                    ScriptAction { script: modelData.close() }
                }

                // ── Snap back (spring) ──
                ParallelAnimation {
                    id: snapBack

                    NumberAnimation {
                        target: notifCard; property: "dragX"
                        to: 0; duration: 280
                        easing.type: Easing.OutBack; easing.overshoot: 1.3
                    }
                    NumberAnimation {
                        target: modelData; property: "popupEntryRotation"
                        to: 0; duration: 200; easing.type: Easing.OutCubic
                    }
                }

                // ── Standard dismiss (scale + fade) ──
                // Only hides the popup — the notification is NOT closed so it
                // stays in the notification panel (unread history).
                SequentialAnimation {
                    id: dismissAnim

                    ParallelAnimation {
                        NumberAnimation {
                            target: modelData; property: "popupEntryScale"
                            to: 0.88; duration: 160; easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: modelData; property: "popupEntryOpacity"
                            to: 0; duration: 160; easing.type: Easing.InQuad
                        }
                    }
                    NumberAnimation {
                        target: notifCard; property: "height"
                        to: 0; duration: 100; easing.type: Easing.InCubic
                    }
                    ScriptAction { script: modelData.popupDismissed = true }
                }

                function dismiss() {
                    isVisible = false
                    modelData.popupActive = false
                    dismissAnim.start()
                }

                function swipeDismiss(direction) {
                    isVisible = false
                    modelData.popupActive = false
                    if (direction > 0) exitRight.start()
                    else exitLeft.start()
                }

                // Wrapper countdown hit zero — time this card out
                onTimeoutProgressChanged: {
                    if (notifCard.timeoutProgress <= 0 && notifCard.isVisible)
                        notifCard.dismiss()
                }

                // ───────────────────────────────────────────────────────────
                // CARD WRAPPER (holds swipe transforms)
                // ───────────────────────────────────────────────────────────
                Item {
                    id: cardWrapper
                    width: parent.width
                    height: cardBg.height
                    x: notifCard.dragX
                    scale: modelData.popupEntryScale
                    opacity: modelData.popupEntryOpacity
                    transformOrigin: Item.Top

                    // Physics-feel rotation during drag
                    rotation: modelData.popupEntryRotation +
                              (notifCard.isDragging ? notifCard.dragX * 0.015 : 0)

                    transform: Translate { y: modelData.popupEntryY }

                    // ── Swipe indicator (behind card) ──
                    Rectangle {
                        anchors.fill: cardBg
                        radius: cardBg.radius
                        visible: Math.abs(notifCard.dragX) > 20
                        opacity: Math.min(0.85,
                            Math.abs(notifCard.dragX) /
                            (config.notifications.popupWidth * root.swipeThreshold * 1.5))

                        color: notifCard.dragX > 0
                            ? Qt.rgba(root.m3Error.r, root.m3Error.g, root.m3Error.b, 0.06)
                            : Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.06)

                        Text {
                            anchors.centerIn: parent
                            text: notifCard.dragX > 0 ? "󰅖" : "󰄬"
                            font.family: "Material Design Icons"
                            font.pixelSize: 26
                            color: notifCard.dragX > 0 ? root.m3Error : root.m3Primary
                            opacity: 0.55
                        }
                    }

                    // ═══════════════════════════════════════════════════════
                    // CARD BACKGROUND
                    // ═══════════════════════════════════════════════════════
                    Rectangle {
                        id: cardBg
                        width: parent.width
                        height: contentCard.implicitHeight + 34
                        radius: 18
                        color: root.m3Surface

                        // Hover-responsive border
                        border.width: 0
                        border.color: {
                            if (notifCard.isHovered)
                                return Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.2)
                            if (modelData.urgency === NotificationUrgency.Critical)
                                return Qt.rgba(root.m3Error.r, root.m3Error.g, root.m3Error.b, 0.2)
                            return root.m3Border
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: 250; easing.type: Easing.OutCubic }
                        }

                        // Elevation shadow — lifts on hover
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: Qt.rgba(0, 0, 0,
                                notifCard.isHovered ? 0.28 : 0.16)
                            shadowBlur: notifCard.isHovered ? 0.9 : 0.55
                            shadowVerticalOffset: notifCard.isHovered ? 8 : 4
                        }

                        // ── Hover glow overlay ──
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: root.m3OnSurface
                            opacity: notifCard.isHovered && !notifCard.isDragging ? 0.035 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                        }

                        // ── Urgency tint (low / critical only) ──
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            z: -1
                            visible: modelData.urgency !== NotificationUrgency.Normal
                            color: {
                                const c = root._urgencyColor(modelData.urgency)
                                if (modelData.urgency === NotificationUrgency.Critical)
                                    return Qt.rgba(c.r, c.g, c.b, 0.08)
                                return Qt.rgba(c.r, c.g, c.b, 0.04)
                            }
                        }

                        // ── Progress bar (bottom sweep) ──
                        Rectangle {
                            id: progressTrack
                            anchors {
                                bottom: parent.bottom
                                left: parent.left
                                right: parent.right
                                bottomMargin: 7
                                leftMargin: 18
                                rightMargin: 18
                            }
                            height: 2
                            radius: 1
                            color: Qt.rgba(root.m3OnSurface.r, root.m3OnSurface.g,
                                           root.m3OnSurface.b, 0.04)
                            visible: notifCard.isVisible && !notifCard.isHovered
                            clip: true

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                width: progressTrack.width * notifCard.timeoutProgress
                                radius: parent.radius
                                color: {
                                    const c = root._urgencyColor(modelData.urgency)
                                    return Qt.rgba(c.r, c.g, c.b, 0.45)
                                }
                            }
                        }

                        // Pause the countdown on hover / drag
                        Connections {
                            target: notifCard
                            function onIsHoveredChanged() {
                                modelData.popupActive = !(notifCard.isHovered || notifCard.isDragging)
                            }
                            function onIsDraggingChanged() {
                                modelData.popupActive = !(notifCard.isHovered || notifCard.isDragging)
                            }
                        }

                        // ═══════════════════════════════════════════════════
                        // GESTURE AREA
                        // ═══════════════════════════════════════════════════
                        MouseArea {
                            id: gestureArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                            property real startX: 0
                            property bool gestureStarted: false
                            property real scrollAccum: 0
                            property bool isScrolling: false

                            onEntered: notifCard.isHovered = true
                            onExited: {
                                if (!pressed && !isScrolling)
                                    notifCard.isHovered = false
                            }

                            // ── Two-finger swipe (trackpad) ──
                            onWheel: wheel => {
                                if (Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y)) {
                                    wheel.accepted = true
                                    scrollAccum += wheel.angleDelta.x * 0.5
                                    notifCard.dragX = scrollAccum
                                    isScrolling = true
                                    notifCard.isDragging = true
                                    scrollTimer.restart()

                                    const thresh = config.notifications.popupWidth * root.swipeThreshold
                                    if (Math.abs(scrollAccum) > thresh) {
                                        scrollTimer.stop()
                                        isScrolling = false
                                        notifCard.swipeDismiss(scrollAccum)
                                        scrollAccum = 0
                                    }
                                }
                            }

                            Timer {
                                id: scrollTimer
                                interval: 300
                                onTriggered: {
                                    gestureArea.isScrolling = false
                                    notifCard.isDragging = false
                                    const thresh = config.notifications.popupWidth * root.swipeThreshold
                                    if (Math.abs(gestureArea.scrollAccum) > thresh)
                                        notifCard.swipeDismiss(gestureArea.scrollAccum)
                                    else
                                        snapBack.start()
                                    gestureArea.scrollAccum = 0
                                }
                            }

                            // ── Drag gesture ──
                            onPressed: mouse => {
                                startX = mouse.x
                                gestureStarted = false
                                notifCard.isDragging = false
                                scrollAccum = 0
                            }

                            onPositionChanged: mouse => {
                                if (!pressed) return
                                const dx = mouse.x - startX
                                if (!gestureStarted && Math.abs(dx) > 10) {
                                    gestureStarted = true
                                    notifCard.isDragging = true
                                }
                                if (notifCard.isDragging)
                                    notifCard.dragX = dx * 0.8
                            }

                            onReleased: mouse => {
                                notifCard.isDragging = false
                                if (!containsMouse) notifCard.isHovered = false
                                const thresh = config.notifications.popupWidth * root.swipeThreshold
                                if (Math.abs(notifCard.dragX) > thresh)
                                    notifCard.swipeDismiss(notifCard.dragX)
                                else
                                    snapBack.start()
                            }

                            onClicked: mouse => {
                                if (mouse.button === Qt.MiddleButton) {
                                    notifCard.dismiss()
                                } else if (!gestureStarted) {
                                    // Single action → invoke; else toggle expand
                                    if (modelData.actions && modelData.actions.length === 1) {
                                        modelData.actions[0].invoke()
                                        notifCard.dismiss()
                                    } else {
                                        notifCard.isExpanded = !notifCard.isExpanded
                                    }
                                }
                            }
                        }

                        NotificationCard {
                            id: contentCard
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 16
                                topMargin: 18
                            }
                            notification: modelData
                            pywal: root.pywal
                            showCloseButton: true
                            showTimestamp: false
                            showActions: true
                            showBody: true
                            showAppIcon: true

                            primaryColor: root.m3Primary
                            onSurfaceColor: root.m3OnSurface
                            onSurfaceVariantColor: root.m3OnSurfaceVariant
                            errorColor: root.m3Error
                            surfaceContainerHighColor: root.m3SurfaceContainerHigh
                        }
                    }
                }
            }
        }
    }
}
