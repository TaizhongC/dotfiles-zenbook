import QtQuick 6.10
import QtQuick.Effects
import Quickshell
import "../../services" as QsServices
import "../../config" as QsConfig
import "../../components" as QsComponents

Item {
    id: root
    anchors.fill: parent

    // Set by the centric panel when this is the active mode
    property bool panelActive: false

    readonly property var wallpaperService: QsServices.Wallpaper
    readonly property var wallpapers: wallpaperService.wallpapers
    readonly property var tokens: QsComponents.PanelTokens
    readonly property int count: wallpapers.length

    // Screen aspect ratio for the crop preview (monitor 0 is the panel screen)
    readonly property real screenAspect: 16 / 10

    // Preview geometry — cropped to screen ratio. Sized so the preview nearly
    // fills the card width (640) with only a small gap to the panel edge.
    readonly property int previewWidth: 560
    readonly property int previewHeight: Math.round(previewWidth / screenAspect)
    readonly property int delegateSpacing: 14

    onPanelActiveChanged: {
        if (panelActive) {
            wallpaperService.refresh()
            scrollToCurrent()
            // Re-center once the card morph (height animation) has settled —
            // centering mid-morph puts the item at the wrong spot.
            settleTimer.restart()
            Qt.callLater(() => root.forceActiveFocus())
        }
    }

    // `current` resolves asynchronously (readlink) — re-center whenever it lands
    Connections {
        target: wallpaperService
        function onCurrentChanged() {
            scrollToCurrent()
        }
    }

    Component.onCompleted: {
        wallpaperService.refresh()
        scrollToCurrent()
    }

    Timer {
        id: settleTimer
        interval: 420
        onTriggered: scrollToCurrent()
    }

    // Index of the current wallpaper in the wallpapers array.
    // Falls back to a basename match — the state file may point at a symlink
    // or an equivalent path that doesn't string-equal the listed one.
    function findCurrentLogicalIndex() {
        const cur = wallpaperService.current
        if (!cur)
            return -1
        let i = wallpapers.indexOf(cur)
        if (i >= 0)
            return i
        const base = cur.split("/").pop()
        return wallpapers.findIndex(p => p.split("/").pop() === base)
    }

    // Position the view on the current wallpaper. currentIndex must be set
    // first — StrictlyEnforceRange otherwise keeps the old current item
    // pinned and the highlight never follows. The highlight animation is
    // disabled during the initial positioning: for the first/last items the
    // view clamps at the edge and an animated move visibly pushes and
    // bounces back.
    function scrollToCurrent() {
        if (count === 0)
            return
        const idx = findCurrentLogicalIndex()
        if (idx >= 0) {
            const prevDuration = list.highlightMoveDuration
            const prevVelocity = list.highlightMoveVelocity
            list.highlightMoveDuration = 0
            list.highlightMoveVelocity = 0
            list.currentIndex = idx
            list.positionViewAtIndex(idx, ListView.Center)
            list.highlightMoveDuration = prevDuration
            list.highlightMoveVelocity = prevVelocity
        }
    }

    function next() {
        if (count === 0)
            return
        if (list.currentIndex < count - 1)
            list.incrementCurrentIndex()
    }

    function prev() {
        if (count === 0)
            return
        if (list.currentIndex > 0)
            list.decrementCurrentIndex()
    }

    function applyCurrent() {
        const idx = list.currentIndex
        const path = wallpapers[idx]
        if (idx >= 0 && path && path !== wallpaperService.current) {
            Quickshell.execDetached(["wallpaperctl", "set", path])
            wallpaperService.current = path
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_J) {
            root.next()
            event.accepted = true
        } else if (event.key === Qt.Key_K) {
            root.prev()
            event.accepted = true
        }
    }
    Keys.onDownPressed: root.next()
    Keys.onUpPressed: root.prev()
    Keys.onReturnPressed: root.applyCurrent()

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        model: root.wallpapers
        spacing: root.delegateSpacing
        boundsBehavior: Flickable.StopAtBounds

        // Snap the current item firmly into the center
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (height - root.previewHeight) / 2
        preferredHighlightEnd: preferredHighlightBegin
        highlightMoveDuration: 260
        highlightMoveVelocity: 1400

        onCountChanged: scrollToCurrent()

        delegate: Item {
            id: wrap
            required property var modelData
            required property int index

            // Outer item spans the viewport width; the preview is centered
            // inside it via anchors.centerIn — a valid parent anchor that
            // cannot hit null during delegate teardown (anchoring to
            // parent.horizontalCenter warned on model rebuilds).
            width: list.width
            height: root.previewHeight

            // Distance from center decides dimming and scale (0 = selected).
            // The selected item is never dimmed — at the list ends it cannot
            // reach the center, but it must stay the highlighted one.
            readonly property real centerDist: Math.abs(
                wrap.y + height / 2 - list.contentY - list.height / 2)
            readonly property bool isSelected: list.currentIndex === index
            readonly property real dim: wrap.isSelected
                ? 0
                : Math.min(1, centerDist / (height + root.delegateSpacing))

            Item {
                id: preview
                anchors.centerIn: parent
                width: root.previewWidth
                height: root.previewHeight

                opacity: 0.35 + 0.65 * (1 - wrap.dim)
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                scale: 1 - 0.06 * wrap.dim
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                transformOrigin: Item.Center

                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: tokens.surfaceRaised
                    border.width: 0
                    clip: true
                    layer.enabled: true

                    Image {
                        anchors.fill: parent
                        source: "file://" + wrap.modelData
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize.width: 600
                        sourceSize.height: 400

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
                            radius: 18
                            color: "#ffffff"
                        }
                    }

                    // Selection border — drawn above the image (a border on the
                    // background rect is covered by the filling image)
                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: "transparent"
                        border.width: wrap.isSelected ? 2 : 0
                        border.color: tokens.accent
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        list.currentIndex = wrap.index
                        list.positionViewAtIndex(wrap.index, ListView.Center)
                        root.applyCurrent()
                    }
                }
            }
        }
    }
}
