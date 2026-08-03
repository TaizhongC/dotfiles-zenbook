import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10 as QQC
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components"

PanelWindow {
    id: root

    property bool shouldShow: false
    property string query: ""
    property int selectedIndex: 0

    readonly property var config: QsConfig.Config
    readonly property var appearance: QsConfig.AppearanceConfig
    readonly property var pywal: QsServices.Pywal
    readonly property color cSurface: pywal.surfaceContainerHighest
    readonly property color cSurfaceContainer: pywal.surfaceContainerHigh
    readonly property color cSurfaceContainerHigh: pywal.surfaceContainerHigh
    readonly property color cPrimary: pywal.primary
    readonly property color cText: pywal.foreground
    readonly property color cSubText: pywal.onSurfaceMuted
    readonly property color cBorder: pywal.outlineVariant
    readonly property var terminalCommand: Array.isArray(config.launcher.terminalCommand) && config.launcher.terminalCommand.length > 0
        ? config.launcher.terminalCommand
        : ["foot"]

    readonly property var actionEntries: [
        {
            id: "action-terminal",
            name: "Open Terminal",
            comment: "Launch your configured terminal",
            glyph: "󰆍",
            type: "action",
            onTriggered: () => Quickshell.execDetached(terminalCommand)
        },
        {
            id: "action-files",
            name: "Open Files",
            comment: "Open your home directory",
            glyph: "󰉋",
            type: "action",
            onTriggered: () => Quickshell.execDetached(["xdg-open", Quickshell.env("HOME")])
        },
        {
            id: "action-screenshots",
            name: "Open Captures",
            comment: "Browse screenshots and recordings",
            glyph: "󰄄",
            type: "action",
            onTriggered: () => QsServices.Screenshot.openScreenshotsFolder()
        },
        {
            id: "action-network",
            name: "Network Settings",
            comment: "Open nm-connection-editor",
            glyph: "󰖩",
            type: "action",
            onTriggered: () => Quickshell.execDetached(["nm-connection-editor"])
        },
        {
            id: "action-wallpaper",
            name: "Next Wallpaper",
            comment: "Switch wallpaper and regenerate shell colors",
            glyph: "󰸉",
            type: "action",
            onTriggered: () => Quickshell.execDetached(["wallpaperctl", "next"])
        }
    ]

    readonly property var recentSearches: (QsServices.Settings.launcherHistory ?? [])

    readonly property var appEntries: {
        const apps = DesktopEntries.applications.values ?? []
        const q = query.trim().toLowerCase()

        function score(entry) {
            const name = (entry.name ?? "").toLowerCase()
            const genericName = (entry.genericName ?? "").toLowerCase()
            const comment = (entry.comment ?? "").toLowerCase()
            const execString = (entry.execString ?? "").toLowerCase()
            const id = (entry.id ?? "").toLowerCase()
            let rank = 0

            if (name === q)
                rank = 1000
            else if (name.startsWith(q))
                rank = 900
            else if (genericName.startsWith(q) || id.startsWith(q))
                rank = 760
            else if (name.includes(q))
                rank = 680
            else if (genericName.includes(q) || comment.includes(q))
                rank = 520
            else if (execString.includes(q))
                rank = 420

            return rank
        }

        const filtered = apps
            .map(entry => ({ entry, rank: score(entry) }))
            .filter(item => item.rank > 0)
            .sort((left, right) => {
                if (right.rank !== left.rank)
                    return right.rank - left.rank
                return (left.entry.name ?? "").localeCompare(right.entry.name ?? "")
            })
            .slice(0, config.launcher.maxResults)
            .map(item => item.entry)

        if (!q.length && filtered.length === 0)
            return (apps ?? []).slice(0, config.launcher.maxResults)

        return filtered
    }

    readonly property var visibleEntries: {
        const q = query.trim()
        if (q.startsWith(">")) {
            const actionQuery = q.slice(1).trim().toLowerCase()
            return actionEntries.filter(entry => {
                if (!actionQuery.length)
                    return true
                return entry.name.toLowerCase().includes(actionQuery) || entry.comment.toLowerCase().includes(actionQuery)
            })
        }

        if (!q.length)
            return recentSearches.slice(0, config.launcher.maxResults).map(item => ({
                type: "search",
                name: item.query,
                comment: `${item.count} search${item.count === 1 ? "" : "es"}`,
                glyph: "󰍉"
            }))

        return appEntries
    }

    function closeLauncher() {
        shouldShow = false
        query = ""
        selectedIndex = 0
    }

    function openLauncher() {
        shouldShow = true
        searchField.text = ""
        query = ""
        selectedIndex = 0
        searchField.forceActiveFocus()
    }

    function launchEntry(entry) {
        if (!entry)
            return

        if (entry.type === "search") {
            query = entry.name
            selectedIndex = 0
            Qt.callLater(() => searchField.forceActiveFocus())
            return
        }

        if (entry.type === "action") {
            entry.onTriggered()
            closeLauncher()
            return
        }

        QsServices.Settings.rememberLauncherSearch(query)

        if (entry.runInTerminal) {
            Quickshell.execDetached({
                command: [...terminalCommand, ...entry.command],
                workingDirectory: entry.workingDirectory
            })
        } else {
            Quickshell.execDetached({
                command: entry.command,
                workingDirectory: entry.workingDirectory
            })
        }

        closeLauncher()
    }

    onShouldShowChanged: {
        if (shouldShow) {
            searchField.text = ""
            query = ""
            selectedIndex = 0
            Qt.callLater(() => searchField.forceActiveFocus())
        }
    }

    onVisibleEntriesChanged: {
        if (selectedIndex >= visibleEntries.length)
            selectedIndex = Math.max(0, visibleEntries.length - 1)
    }

    screen: Quickshell.screens[0]
    anchors {
        top: true
        left: true
    }
    margins {
        top: (config.bar.height ?? 34) + appearance.anim.popup.offset
        // The launcher belongs to Super+Space and sits beneath the centred
        // clock island, independent of the right-aligned control panel.
        left: Math.max(0, Math.round((screen.width - root.implicitWidth) / 2))
    }
    implicitWidth: 440
    implicitHeight: shouldShow || panel.opacity > 0 ? panelColumn.implicitHeight + 40 : 0
    color: "transparent"
    visible: config.launcher.enabled && (shouldShow || panel.opacity > 0)

    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    FocusScope {
        id: panel
        anchors.fill: parent
        transformOrigin: Item.Top
        scale: shouldShow ? 1.0 : appearance.anim.popup.closedScale
        opacity: shouldShow ? 1.0 : 0.0
        focus: root.shouldShow

        Keys.onEscapePressed: root.closeLauncher()
        Keys.onDownPressed: root.selectedIndex = Math.min(root.selectedIndex + 1, root.visibleEntries.length - 1)
        Keys.onUpPressed: root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
        Keys.onReturnPressed: root.launchEntry(root.visibleEntries[root.selectedIndex])
        Keys.onEnterPressed: root.launchEntry(root.visibleEntries[root.selectedIndex])

        Behavior on scale {
            NumberAnimation { duration: appearance.anim.popup.duration; easing.bezierCurve: appearance.anim.popup.curve }
        }

        Behavior on opacity {
            NumberAnimation { duration: appearance.anim.popup.fadeDuration; easing.bezierCurve: appearance.anim.popup.curve }
        }


        AuroraSurface {
            anchors.fill: parent
            radius: 28
            color: root.cSurface
            strokeColor: root.cBorder
            accentColor: root.cPrimary
            elevation: 4
            highlighted: root.shouldShow

            ColumnLayout {
                id: panelColumn
                anchors.fill: parent
                anchors.margins: 18
                spacing: 16

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    radius: 22
                    color: root.cSurfaceContainer
                    border.width: 1
                    border.color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.18)

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.04)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Text {
                            text: query.trim().startsWith(">") ? "󰘳" : "󰍉"
                            font.family: "Material Design Icons"
                            font.pixelSize: 22
                            color: root.cPrimary
                        }

                        QQC.TextField {
                            id: searchField
                            Layout.fillWidth: true
                            color: root.cText
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 15
                            placeholderText: 'Search apps or type ">" for actions'
                            placeholderTextColor: root.cSubText
                            background: Item {}
                            selectByMouse: true

                            onTextChanged: {
                                root.query = text
                                root.selectedIndex = 0
                            }
                        }

                        Text {
                            visible: query.length > 0
                            text: "Esc"
                            font.family: QsConfig.Config.appearance.fontFamily
                            font.pixelSize: 11
                            color: root.cSubText
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: query.trim().startsWith(">") ? "Quick actions" : (query.trim().length ? "Best matches" : "Favorites")
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: root.cText
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: `${root.visibleEntries.length} item${root.visibleEntries.length === 1 ? "" : "s"}`
                        font.family: QsConfig.Config.appearance.fontFamily
                        font.pixelSize: 11
                        color: root.cSubText
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(520, listColumn.implicitHeight + 12)
                    clip: true
                    contentWidth: width
                    contentHeight: listColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    QQC.ScrollBar.vertical: QQC.ScrollBar {
                        policy: QQC.ScrollBar.AsNeeded
                    }

                    Column {
                        id: listColumn
                        width: root.width - 48
                        spacing: 8

                        Repeater {
                            model: root.visibleEntries

                            Rectangle {
                                id: delegateRoot
                                required property var modelData
                                required property int index

                                width: listColumn.width
                                height: 66
                                radius: 20
                                color: root.selectedIndex === index
                                    ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.18)
                                    : hovered.hovered
                                        ? root.cSurfaceContainerHigh
                                        : root.cSurfaceContainer
                                border.width: 1
                                border.color: root.selectedIndex === index
                                    ? Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.34)
                                    : Qt.rgba(root.cText.r, root.cText.g, root.cText.b, 0.10)
                                scale: hovered.hovered ? 1.02 : 1.0

                                Behavior on color { ColorAnimation { duration: 160 } }
                                Behavior on border.color { ColorAnimation { duration: 160 } }
                                Behavior on scale { NumberAnimation { duration: 180; easing.bezierCurve: [0.22, 1.0, 0.36, 1.0] } }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, root.selectedIndex === index ? 0.05 : hovered.hovered ? 0.03 : 0)
                                }

                                HoverHandler { id: hovered }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    Rectangle {
                                        Layout.preferredWidth: 40
                                        Layout.preferredHeight: 40
                                        radius: 14
                                        color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, delegateRoot.modelData.type === "action" ? 0.14 : 0.10)

                                        Text {
                                            anchors.centerIn: parent
                                            text: delegateRoot.modelData.type === "action"
                                                ? (delegateRoot.modelData.glyph ?? "󰣆")
                                                : ((delegateRoot.modelData.name ?? "?").slice(0, 1).toUpperCase())
                                            font.family: delegateRoot.modelData.type === "action"
                                                ? "Material Design Icons"
                                                : QsConfig.Config.appearance.fontFamily
                                            font.pixelSize: delegateRoot.modelData.type === "action" ? 20 : 16
                                            font.weight: Font.DemiBold
                                            color: root.cPrimary
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            Layout.fillWidth: true
                                            text: delegateRoot.modelData.name ?? "Unknown"
                                            font.family: QsConfig.Config.appearance.fontFamily
                                            font.pixelSize: 14
                                            font.weight: Font.Medium
                                            color: root.cText
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: delegateRoot.modelData.comment || delegateRoot.modelData.genericName || delegateRoot.modelData.execString || "Launch"
                                            font.family: QsConfig.Config.appearance.fontFamily
                                            font.pixelSize: 11
                                            color: root.cSubText
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Text {
                                        visible: root.selectedIndex === index
                                        text: "󰁔"
                                        font.family: "Material Design Icons"
                                        font.pixelSize: 18
                                        color: root.cPrimary
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.selectedIndex = delegateRoot.index
                                    onClicked: root.launchEntry(delegateRoot.modelData)
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.visibleEntries.length === 0
                    text: query.trim().startsWith(">") ? "No actions matched." : "No applications matched your search."
                    horizontalAlignment: Text.AlignHCenter
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: 12
                    color: root.cSubText
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.closeLauncher()
            }
        }
    }
}
