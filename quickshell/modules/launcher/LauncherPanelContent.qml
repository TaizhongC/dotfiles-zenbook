import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10 as QQC
import Quickshell
import Quickshell.Widgets
import "../../config" as QsConfig
import "../../services" as QsServices
import "../../components" as QsComponents

ColumnLayout {
    id: root
    anchors.fill: parent
    spacing: 12

    // Set by the centric panel when this is the active mode
    property bool panelActive: false
    // A Return key can be seen by both a focused TextField and an ancestor
    // during focus transitions. Keep launchEntry idempotent while the panel
    // closes so one selection always starts at most one process.
    property bool launchInProgress: false
    signal closeRequested()

    property string query: ""
    property int selectedIndex: 0

    readonly property var pywal: QsServices.Pywal
    readonly property var tokens: QsComponents.PanelTokens
    readonly property var config: QsConfig.Config
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

    onPanelActiveChanged: {
        if (panelActive) {
            launchInProgress = false
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

    Component.onCompleted: {
        if (panelActive)
            Qt.callLater(() => searchField.forceActiveFocus())
    }

    function launchEntry(entry) {
        if (!entry || launchInProgress)
            return

        if (entry.type === "search") {
            query = entry.name
            selectedIndex = 0
            Qt.callLater(() => searchField.forceActiveFocus())
            return
        }

        if (entry.type === "action") {
            launchInProgress = true
            entry.onTriggered()
            closeRequested()
            return
        }

        launchInProgress = true
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

        closeRequested()
    }

    Keys.onDownPressed: root.selectedIndex = Math.min(root.selectedIndex + 1, root.visibleEntries.length - 1)
    Keys.onUpPressed: root.selectedIndex = Math.max(root.selectedIndex - 1, 0)

    // Search bar
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 52
        radius: tokens.radiusField
        color: tokens.surface

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Text {
                text: query.trim().startsWith(">") ? "󰘳" : "󰍉"
                font.family: "Material Design Icons"
                font.pixelSize: 20
                color: pywal.primary
            }

            QQC.TextField {
                id: searchField
                Layout.fillWidth: true
                color: pywal.foreground
                font.family: "Inter"
                font.pixelSize: 14
                placeholderText: 'Search apps or type ">" for actions'
                placeholderTextColor: pywal.onSurfaceMuted
                background: Item {}
                selectByMouse: true

                onTextChanged: {
                    root.query = text
                    root.selectedIndex = 0
                }

                onAccepted: root.launchEntry(root.visibleEntries[root.selectedIndex])
            }

            Text {
                visible: query.length > 0
                text: "Esc"
                font.family: "Inter"
                font.pixelSize: 11
                color: pywal.onSurfaceMuted
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: query.trim().startsWith(">") ? "Quick actions" : (query.trim().length ? "Best matches" : "Favorites")
            font.family: QsConfig.Config.appearance.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: pywal.foreground
        }

        Item { Layout.fillWidth: true }

        Text {
            text: `${root.visibleEntries.length} item${root.visibleEntries.length === 1 ? "" : "s"}`
            font.family: QsConfig.Config.appearance.fontFamily
            font.pixelSize: 11
            color: pywal.onSurfaceMuted
        }
    }

    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentWidth: width
        contentHeight: listColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        QQC.ScrollBar.vertical: QQC.ScrollBar {
            policy: QQC.ScrollBar.AsNeeded
        }

        Column {
            id: listColumn
            width: root.width - 24
            spacing: 8

            Repeater {
                model: root.visibleEntries

                Rectangle {
                    id: delegateRoot
                    required property var modelData
                    required property int index

                    width: listColumn.width
                    height: 60
                    radius: tokens.radiusField
                    color: root.selectedIndex === index
                        ? tokens.focus
                        : hovered.hovered
                            ? tokens.blend(tokens.surfaceRaised, root.pywal.foreground, 0.10)
                            : tokens.surfaceRaised
                    scale: hovered.hovered ? 1.02 : 1.0

                    Behavior on color { ColorAnimation { duration: 160 } }
                    Behavior on scale { NumberAnimation { duration: 180; easing.bezierCurve: [0.22, 1.0, 0.36, 1.0] } }

                    HoverHandler { id: hovered }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: 13
                            color: Qt.rgba(root.pywal.primary.r, root.pywal.primary.g, root.pywal.primary.b, delegateRoot.modelData.type === "action" ? 0.14 : 0.10)

                            Text {
                                anchors.centerIn: parent
                                text: delegateRoot.modelData.type === "action"
                                    ? (delegateRoot.modelData.glyph ?? "󰣆")
                                    : ((delegateRoot.modelData.name ?? "?").slice(0, 1).toUpperCase())
                                font.family: delegateRoot.modelData.type === "action"
                                    ? "Material Design Icons"
                                    : QsConfig.Config.appearance.fontFamily
                                font.pixelSize: delegateRoot.modelData.type === "action" ? 18 : 15
                                font.weight: Font.DemiBold
                                color: root.pywal.primary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: delegateRoot.modelData.name ?? "Unknown"
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: root.pywal.foreground
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: delegateRoot.modelData.comment || delegateRoot.modelData.genericName || delegateRoot.modelData.execString || "Launch"
                                font.family: QsConfig.Config.appearance.fontFamily
                                font.pixelSize: 10
                                color: root.pywal.onSurfaceMuted
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            visible: root.selectedIndex === index
                            text: "󰁔"
                            font.family: "Material Design Icons"
                            font.pixelSize: 16
                            color: root.pywal.primary
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
        color: pywal.onSurfaceMuted
    }
}
