import QtQuick 6.10
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../../../services" as QsServices
import "../../../config" as QsConfig
import "../../../components"

// ═══════════════════════════════════════════════════════════════════════════
// Material 3 Notification Popups — simple, smooth motion
//
// Cards are managed imperatively (no Repeater / model churn): every card is
// created/destroyed explicitly and positioned with a `Behavior on y`, so
// sliding and fading can never be interrupted by a delegate being recreated.
// Entrance = gentle fade + scale. Exit = fade + collapse in parallel, while
// the cards below slide up over the vacated space.
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

    // ── Single-card queue state ──
    property var currentCard: null   // the card on screen (if any)
    property var exitingCard: null   // card animating out (still fading)
    property int liveCards: 0        // drives window visibility
    property real totalHeight: 0

    // Popup-worthy wrappers, newest first. Only the OLDEST pending message is
    // shown at a time (FIFO queue); the rest wait for their turn.
    function pending() {
        return (notifs.notifications || [])
            .filter(n => !!n && !n.closed && !n.popupDismissed)
            .slice(0, config.notifications.maxVisible)
    }

    // Window height: the visible card plus any card still animating out.
    function layout() {
        var h = 0
        if (currentCard) h += currentCard.cardHeight
        if (exitingCard) h += exitingCard.height
        totalHeight = h
    }

    function showCard(wrapper) {
        if (currentCard) return
        currentCard = cardComponent.createObject(cardLayer, { wrapper: wrapper })
        if (!currentCard) return
        // Size the window BEFORE showing it: the first card is created while
        // the window is still hidden, and a window that grows into place
        // (Behavior on implicitHeight) while the entrance plays is what made
        // the first popup look jagged.
        layout()
        liveCards = 1
        // Defer the entrance one tick: the layer surface only maps after this
        // JS frame, and starting the animation earlier would lose the opening
        // frames of the first card.
        Qt.callLater(currentCard.startEntrance)
    }

    // Start the fade + scale-out of the current card; `swipeX` adds a
    // horizontal slide-out (nonzero when dismissed by swiping).
    function exitCard(closeAfterExit, swipeX) {
        const card = currentCard
        if (!card || card.exiting) return
        card.exiting = true
        card.isVisible = false
        card.closeAfterExit = closeAfterExit
        card.wrapper.popupActive = false
        currentCard = null
        exitingCard = card
        layout()
        card.startExit(swipeX || 0)
    }

    function dismissCard() { exitCard(false, 0) }
    function swipeDismiss(direction) { exitCard(true, direction) }

    function cardExited(card) {
        const w = card.wrapper
        exitingCard = null
        card.destroy()
        if (card.closeAfterExit) {
            if (w && !w.closed) w.close()
        } else if (w) {
            w.popupDismissed = true
        }
        // Show the next queued message (if any) — this also keeps the window
        // visible across the swap.
        syncPopups()
        layout()
    }

    // Advance the queue: when nothing is showing, display the oldest pending
    // message; otherwise wait.
    function syncPopups() {
        const queue = root.pending()
        if (!currentCard && !exitingCard) {
            if (queue.length > 0) showCard(queue[queue.length - 1])
            else liveCards = 0
        }
    }

    Connections {
        target: notifs
        function onNotificationsChanged() { root.syncPopups() }
    }

    // ── Window Setup ──
    screen: Quickshell.screens[0]
    anchors { top: true; right: true }
    margins { top: config.notifications.margin; right: config.notifications.margin }
    visible: liveCards > 0
    color: "transparent"
    implicitWidth: config.notifications.popupWidth
    implicitHeight: root.totalHeight
    // No Behavior on implicitHeight: the window snaps to its content size.
    // A growing window combined with the card entrance is what made the
    // first popup look jagged.

    Component.onCompleted: syncPopups()

    // Container for the cards. Cards must be created with a QQuickItem parent
    // (not the window itself) or Qt's auto-parenting fails and they never
    // render.
    Item {
        id: cardLayer
        width: root.width
        height: root.height
    }

    // ═══════════════════════════════════════════════════════════════════════
    // NOTIFICATION CARD
    // ═══════════════════════════════════════════════════════════════════════
    Component {
        id: cardComponent

        Item {
            id: card

            required property var wrapper

            // ── Motion state ──
            property bool isVisible: true
            property bool isHovered: false
            property bool isDragging: false
            property bool exiting: false
            property bool closeAfterExit: false
            readonly property real cardHeight: cardBg.height

            width: config.notifications.popupWidth
            height: cardBg.height
            clip: true
            transformOrigin: Item.TopRight

            // ── Entrance: gentle fade + scale from the top-right corner ──
            // Driven by an explicit animation (not bindings/Behaviors): it
            // starts with the card fully transparent and animates in.
            ParallelAnimation {
                id: entranceAnim

                NumberAnimation {
                    target: card; property: "opacity"
                    from: 0; to: 1; duration: 140; easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: card; property: "scale"
                    from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic
                }
            }

            // ── Countdown (lives on the wrapper) ──
            property real timeoutProgress: wrapper.popupProgress

            Component.onCompleted: wrapper.popupActive = true

            function startEntrance() {
                if (!card.exiting)
                    entranceAnim.start()
            }

            onTimeoutProgressChanged: {
                if (card.timeoutProgress <= 0 && card.isVisible)
                    root.dismissCard()
            }

            // Daemon closed this notification while it was showing — move on
            // to the next queued message right away.
            Connections {
                target: wrapper
                function onPopupDismissedChanged() {
                    if (wrapper.popupDismissed && card.isVisible)
                        root.dismissCard()
                }
            }

            // ── Exit: fade + scale toward the top-right corner + collapse
            // (+ optional slide out) ──
            ParallelAnimation {
                id: exitAnim

                NumberAnimation {
                    target: card; property: "opacity"
                    to: 0; duration: 140; easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: card; property: "scale"
                    to: 0; duration: 180; easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: card; property: "height"
                    to: 0; duration: 180; easing.type: Easing.InCubic
                }
                NumberAnimation {
                    id: exitXAnim
                    target: card; property: "x"
                    to: 0; duration: 160; easing.type: Easing.InCubic
                }
                onFinished: root.cardExited(card)
            }

            function startExit(swipeX) {
                if (swipeX !== 0) {
                    exitXAnim.to = swipeX > 0
                        ? config.notifications.popupWidth + 60
                        : -(config.notifications.popupWidth + 60)
                    exitXAnim.duration = 160
                } else {
                    exitXAnim.to = card.x   // no-op — keep x in place
                    exitXAnim.duration = 0
                }
                exitAnim.start()
            }

            // ── Snap back after an aborted swipe ──
            ParallelAnimation {
                id: snapBack

                NumberAnimation {
                    target: card; property: "x"
                    to: 0; duration: 280
                    easing.type: Easing.OutBack; easing.overshoot: 1.2
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // CARD BODY
            // ═══════════════════════════════════════════════════════════════
            Rectangle {
                id: cardBg
                width: parent.width
                height: contentCard.implicitHeight + 34
                radius: 18
                color: root.m3Surface

                // Hover-responsive border
                border.width: 0
                border.color: {
                    if (card.isHovered)
                        return Qt.rgba(root.m3Primary.r, root.m3Primary.g, root.m3Primary.b, 0.2)
                    if (wrapper.urgency === NotificationUrgency.Critical)
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
                    shadowColor: Qt.rgba(0, 0, 0, card.isHovered ? 0.28 : 0.16)
                    shadowBlur: card.isHovered ? 0.9 : 0.55
                    shadowVerticalOffset: card.isHovered ? 8 : 4
                }

                // ── Hover glow overlay ──
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: root.m3OnSurface
                    opacity: card.isHovered && !card.isDragging ? 0.035 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }

                // ── Urgency tint (low / critical only) ──
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    z: -1
                    visible: wrapper.urgency !== NotificationUrgency.Normal
                    color: {
                        const c = root._urgencyColor(wrapper.urgency)
                        if (wrapper.urgency === NotificationUrgency.Critical)
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
                    visible: card.isVisible && !card.isHovered
                    clip: true

                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: progressTrack.width * card.timeoutProgress
                        radius: parent.radius
                        color: {
                            const c = root._urgencyColor(wrapper.urgency)
                            return Qt.rgba(c.r, c.g, c.b, 0.45)
                        }
                    }
                }

                // Pause the countdown on hover / drag
                Connections {
                    target: card
                    function onIsHoveredChanged() {
                        wrapper.popupActive = !(card.isHovered || card.isDragging)
                    }
                    function onIsDraggingChanged() {
                        wrapper.popupActive = !(card.isHovered || card.isDragging)
                    }
                }

                // ═══════════════════════════════════════════════════════════
                // GESTURE AREA
                // ═══════════════════════════════════════════════════════════
                MouseArea {
                    id: gestureArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                    property real startX: 0
                    property bool gestureStarted: false
                    property real scrollAccum: 0
                    property bool isScrolling: false

                    onEntered: card.isHovered = true
                    onExited: {
                        if (!pressed && !isScrolling)
                            card.isHovered = false
                    }

                    // ── Two-finger swipe (trackpad) ──
                    onWheel: wheel => {
                        if (Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y)) {
                            wheel.accepted = true
                            scrollAccum += wheel.angleDelta.x * 0.5
                            card.x = scrollAccum
                            isScrolling = true
                            card.isDragging = true
                            scrollTimer.restart()

                            const thresh = config.notifications.popupWidth * root.swipeThreshold
                            if (Math.abs(scrollAccum) > thresh) {
                                scrollTimer.stop()
                                isScrolling = false
                                root.swipeDismiss(scrollAccum > 0 ? 1 : -1)
                                scrollAccum = 0
                            }
                        }
                    }

                    Timer {
                        id: scrollTimer
                        interval: 300
                        onTriggered: {
                            gestureArea.isScrolling = false
                            card.isDragging = false
                            const thresh = config.notifications.popupWidth * root.swipeThreshold
                            if (Math.abs(gestureArea.scrollAccum) > thresh)
                                root.swipeDismiss(gestureArea.scrollAccum > 0 ? 1 : -1)
                            else
                                snapBack.start()
                            gestureArea.scrollAccum = 0
                        }
                    }

                    // ── Drag gesture ──
                    onPressed: mouse => {
                        startX = mouse.x
                        gestureStarted = false
                        card.isDragging = false
                        scrollAccum = 0
                    }

                    onPositionChanged: mouse => {
                        if (!pressed) return
                        const dx = mouse.x - startX
                        if (!gestureStarted && Math.abs(dx) > 10) {
                            gestureStarted = true
                            card.isDragging = true
                        }
                        if (card.isDragging)
                            card.x = dx * 0.8
                    }

                    onReleased: mouse => {
                        card.isDragging = false
                        if (!containsMouse) card.isHovered = false
                        const thresh = config.notifications.popupWidth * root.swipeThreshold
                        if (Math.abs(card.x) > thresh)
                            root.swipeDismiss(card.x > 0 ? 1 : -1)
                        else
                            snapBack.start()
                    }

                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) {
                            root.dismissCard()
                        } else if (!gestureStarted) {
                            // Single action → invoke, then dismiss
                            if (wrapper.actions && wrapper.actions.length === 1) {
                                wrapper.actions[0].invoke()
                                root.dismissCard()
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
                    notification: wrapper
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
