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
    readonly property var currentDate: time.date
    readonly property int currentMonth: currentDate.getMonth()
    readonly property int currentYear: currentDate.getFullYear()
    readonly property int currentDay: currentDate.getDate()
    readonly property var dayLabels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    readonly property int calendarOffset: {
        const first = new Date(currentYear, currentMonth, 1).getDay()
        return (first + 6) % 7
    }
    readonly property int calendarDays: new Date(currentYear, currentMonth + 1, 0).getDate()
    readonly property var calendarCells: {
        const cells = []
        const prevMonthDays = new Date(currentYear, currentMonth, 0).getDate()
        for (let index = 0; index < 42; index++) {
            const dayNumber = index - calendarOffset + 1
            if (dayNumber < 1) {
                cells.push({ day: prevMonthDays + dayNumber, current: false, today: false })
            } else if (dayNumber > calendarDays) {
                cells.push({ day: dayNumber - calendarDays, current: false, today: false })
            } else {
                cells.push({ day: dayNumber, current: true, today: dayNumber === currentDay })
            }
        }
        return cells
    }

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "Calendar"
            font.family: QsConfig.Config.appearance.fontFamily
            font.pixelSize: 16
            font.weight: Font.Bold
            color: pywal.foreground
        }
        Item { Layout.fillWidth: true }
        Text {
            text: time.format("MMMM yyyy")
            font.family: QsConfig.Config.appearance.fontFamily
            font.pixelSize: 12
            color: pywal.onSurfaceMuted
        }
    }

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
                font.weight: Font.SemiBold
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
