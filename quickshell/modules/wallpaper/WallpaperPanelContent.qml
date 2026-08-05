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

    // Preview geometry — cropped to screen ratio
    readonly property int previewWidth: 300
    readonly property int previewHeight: Math.round(previewWidth / screenAspect)
    readonly property int delegateSpacing: 14

    // Infinite scroll: the model is the wallpaper list repeated 3 times and
    // currentIndex is always kept inside the middle copy [count, 2*count).
    // When the index walks out of the middle copy (in either direction) it is
    // silently shifted back into it — the item is visually identical, so the
    // jump is invisible and scrolling never hits an end. This also guarantees
    // the current wallpaper can always be centered (short lists otherwise pin
    // their first/last item at the edge, where it can't reach the middle).
    readonly property var listModel: count === 0 ? [] : wallpapers.concat(wallpapers, wallpapers)

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

    // Index of the current wallpaper in the (single-copy) wallpapers array.
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

    // Position the view on the current wallpaper (middle copy). currentIndex
    // must be set first — StrictlyEnforceRange otherwise keeps the old
    // current item pinned and the highlight never follows.
    function scrollToCurrent() {
        if (count === 0)
            return
        const idx = findCurrentLogicalIndex()
        if (idx >= 0) {
            list.currentIndex = count + idx
            list.positionViewAtIndex(list.currentIndex, ListView.Center)
        }
    }

    // Keep currentIndex inside the middle copy — the actual infinite scroll.
    // Model resets also land on low indexes with contentY near 0, so the
    // contentY guard separates "reset to top" from "scrolled past the seam".
    property bool wrapping: false

    function handleIndexWrap() {
        if (wrapping || count === 0)
            return
        if (list.contentY < list.height / 2)
            return
        if (list.currentIndex >= 2 * count) {
            wrapping = true
            list.currentIndex -= count
            list.positionViewAtIndex(list.currentIndex, ListView.Center)
            wrapping = false
        } else if (list.currentIndex < count) {
            wrapping = true
            list.currentIndex += count
            list.positionViewAtIndex(list.currentIndex, ListView.Center)
            wrapping = false
        }
    }

    function next() {
        if (count === 0)
            return
        list.incrementCurrentIndex()
    }

    function prev() {
        if (count === 0)
            return
        list.decrementCurrentIndex()
    }

    function applyCurrent() {
        if (count === 0)
            return
        const idx = list.currentIndex % count
        const path = wallpapers[idx]
        if (path && path !== wallpaperService.current) {
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
        model: root.listModel
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
        onCurrentIndexChanged: root.handleIndexWrap()

        delegate: Item {
            id: wrap
            required property var modelData
            required property int index

            width: root.previewWidth
            height: root.previewHeight
            anchors.horizontalCenter: parent.horizontalCenter

            // Distance from center decides dimming and scale (0 = selected)
            readonly property real centerDist: Math.abs(
                wrap.y + height / 2 - list.contentY - list.height / 2)
            readonly property bool isSelected: list.currentIndex === index
            readonly property real dim: Math.min(1, centerDist / (height + root.delegateSpacing))
            opacity: 0.35 + 0.65 * (1 - dim)

            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            scale: 1 - 0.06 * dim
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

                // Current wallpaper badge
                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 8
                    visible: wrap.modelData === wallpaperService.current
                    width: badgeText.implicitWidth + 14
                    height: 22
                    radius: 11
                    color: Qt.rgba(tokens.accent.r, tokens.accent.g, tokens.accent.b, 0.25)

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: "Current"
                        font.family: "Inter"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: tokens.accent
                    }
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
