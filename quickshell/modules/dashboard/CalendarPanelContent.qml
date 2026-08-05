import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../config" as QsConfig
import "../../services" as QsServices

ColumnLayout {
    id: root
    anchors.fill: parent
    spacing: 12

    readonly property var pywal: QsServices.Pywal
    readonly property var time: QsServices.Time

    readonly property int todayMonth: time.date.getMonth()
    readonly property int todayYear: time.date.getFullYear()
    readonly property int todayDay: time.date.getDate()

    // Interactive view state (navigable month)
    property int viewMonth: todayMonth
    property int viewYear: todayYear

    readonly property var dayLabels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    readonly property int calendarOffset: {
        const first = new Date(viewYear, viewMonth, 1).getDay()
        return (first + 6) % 7
    }
    readonly property int calendarDays: new Date(viewYear, viewMonth + 1, 0).getDate()
    readonly property var calendarCells: {
        const cells = []
        const prevMonthDays = new Date(viewYear, viewMonth, 0).getDate()
        for (let index = 0; index < 42; index++) {
            const dayNumber = index - calendarOffset + 1
            if (dayNumber < 1) {
                cells.push({ day: prevMonthDays + dayNumber, current: false, today: false })
            } else if (dayNumber > calendarDays) {
                cells.push({ day: dayNumber - calendarDays, current: false, today: false })
            } else {
                cells.push({
                    day: dayNumber,
                    current: true,
                    today: dayNumber === todayDay && viewMonth === todayMonth && viewYear === todayYear
                })
            }
        }
        return cells
    }

    function gotoToday() {
        viewMonth = todayMonth
        viewYear = todayYear
    }

    // ═══ Time & Date Header ═══
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            Text {
                id: timeText
                text: Qt.formatTime(new Date(), "hh:mm")
                font.family: "Inter"
                font.pixelSize: 34
                font.weight: Font.Black
                color: pywal.foreground
                lineHeight: 1.0
            }

            Text {
                text: Qt.formatDate(new Date(), "dddd, d MMMM yyyy")
                font.family: "Inter"
                font.pixelSize: 12
                font.weight: Font.Medium
                font.letterSpacing: 0.5
                color: pywal.onSurfaceMuted
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm")
            }
        }

        Item { Layout.fillWidth: true }

        // "Today" quick-jump
        Rectangle {
            Layout.preferredWidth: 52
            Layout.preferredHeight: 30
            radius: 15
            color: todayMouse.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1) : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.06)
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "Today"
                font.family: "Inter"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: pywal.foreground
            }

            MouseArea {
                id: todayMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.gotoToday()
            }
        }
    }

    // ═══ Month Navigation ═══
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            radius: 17
            color: prevMouse.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1) : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.06)
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "󰁍"
                font.family: "Material Design Icons"
                font.pixelSize: 16
                color: pywal.foreground
            }

            MouseArea {
                id: prevMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.viewMonth--
                    if (root.viewMonth < 0) {
                        root.viewMonth = 11
                        root.viewYear--
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: `${Qt.locale().monthName(viewMonth, Qt.locale().ShortFormat)} ${viewYear}`
            font.family: QsConfig.Config.appearance.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: pywal.foreground
        }

        Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            radius: 17
            color: nextMouse.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.1) : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.06)
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: "󰁔"
                font.family: "Material Design Icons"
                font.pixelSize: 16
                color: pywal.foreground
            }

            MouseArea {
                id: nextMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.viewMonth++
                    if (root.viewMonth > 11) {
                        root.viewMonth = 0
                        root.viewYear++
                    }
                }
            }
        }
    }

    // ═══ Calendar Grid ═══
    GridLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 7
        rowSpacing: 6
        columnSpacing: 6

        Repeater {
            model: root.dayLabels

            Text {
                id: dayHeader
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                horizontalAlignment: Text.AlignHCenter
                text: dayHeader.modelData
                font.family: QsConfig.Config.appearance.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: pywal.onSurfaceMuted
            }
        }

        Repeater {
            model: root.calendarCells

            Rectangle {
                id: dayCell
                required property var modelData
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                radius: 10
                color: dayCell.modelData.today
                    ? Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.22)
                    : dayCell.modelData.current
                        ? (cellMouse.containsMouse ? Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.08) : "transparent")
                        : Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.02)
                border.width: dayCell.modelData.today ? 1 : 0
                border.color: pywal.primary

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: `${dayCell.modelData.day}`
                    font.family: QsConfig.Config.appearance.fontFamily
                    font.pixelSize: 11
                    font.weight: dayCell.modelData.today ? Font.Bold : Font.Medium
                    color: dayCell.modelData.today ? pywal.primary : dayCell.modelData.current ? pywal.foreground : pywal.onSurfaceMuted
                    opacity: dayCell.modelData.current ? 1.0 : 0.35
                }

                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
        }
    }
}
