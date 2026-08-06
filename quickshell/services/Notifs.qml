pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Services.Notifications
import "." as QsServices

Singleton {
    id: root

    // Use a JS array so Array helpers (filter/slice/etc) work reliably.
    property var notifications: []
    readonly property var activeNotifications: notifications.filter(n => !!n && !n.closed)
    
    // Maximum notifications to keep in memory (lowercase to comply with QML naming rules)
    readonly property int maxNotifications: 100
    
    // Show all notifications from past 24 hours (including closed ones) - for notification center
    readonly property var recentNotifications: notifications.filter(n => {
        if (!n || !n.timestamp)
            return false
        const hoursSinceNotif = (new Date().getTime() - n.timestamp.getTime()) / (1000 * 60 * 60)
        return hoursSinceNotif < 24
    }).sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime())
    readonly property var unreadNotifications: recentNotifications.filter(n => !n.read && !n.closed)
    readonly property int unreadCount: unreadNotifications.length
    
    // Group notifications by app for better UX
    readonly property var groupedNotifications: {
        const groups = {}
        const active = activeNotifications
        for (let i = 0; i < active.length; i++) {
            const n = active[i]
            const key = n.appName || "Unknown"
            if (!groups[key]) {
                groups[key] = []
            }
            groups[key].push(n)
        }
        return groups
    }
    
    // Get notification counts per app
    readonly property var notificationCounts: {
        const counts = {}
        const grouped = groupedNotifications
        for (let app in grouped) {
            counts[app] = grouped[app].length
        }
        return counts
    }
    
    property bool dnd: false
    property double lastReadAt: 0

    PersistentProperties {
        id: persist
        property alias dnd: root.dnd
        property alias lastReadAt: root.lastReadAt
        reloadableId: "notifications-state"
    }
    
    // Cleanup timer to prevent memory leaks
    Timer {
        interval: 3600000  // Clean up every hour
        repeat: true
        running: true
        triggeredOnStart: false
        
        onTriggered: {
            const oneDayAgo = new Date().getTime() - (24 * 60 * 60 * 1000)
            const oldCount = root.notifications.length
            root.notifications = root.notifications.filter(n => n && n.timestamp && n.timestamp.getTime() > oneDayAgo)
            const cleaned = oldCount - root.notifications.length
            if (cleaned > 0) {
                QsServices.Logger.debug("Notifs", `Cleaned up ${cleaned} old notifications`)
            }
        }
    }
    
    // Add notification from external NotificationServer
    function addNotification(notif) {
        // Check DND mode
        if (dnd && notif.urgency !== NotificationUrgency.Critical) {
            QsServices.Logger.debug("Notifs", `DND active - suppressing: ${notif.summary}`)
            return;
        }

        QsServices.Logger.debug("Notifs", `Adding notification: ${notif.summary}`)
        
        const notifWrapper = notifComponent.createObject(root, {
            notification: notif
        })

        if (!notifWrapper) {
            QsServices.Logger.error("Notifs", "Failed to create notification wrapper")
            return
        }
        
        // Cap maximum notifications to prevent memory leaks
        var capped = [notifWrapper, ...root.notifications]
        var dropped = capped.slice(root.maxNotifications)
        for (var i = 0; i < dropped.length; i++) {
            if (dropped[i]) dropped[i].destroy()
        }
        root.notifications = capped.slice(0, root.maxNotifications)
        QsServices.Logger.debug("Notifs", `Total notifications: ${root.notifications.length}`)
        QsServices.Logger.debug("Notifs", `Queued: ${notifWrapper.appName ?? ""} ${notifWrapper.summary ?? ""}`)
    }

    function markAllRead() {
        const stamp = Date.now()
        lastReadAt = stamp
        notifications.forEach(notification => {
            if (notification)
                notification.read = true
        })
        // New array identity so dependent bindings (filter/slice closures in
        // recentNotifications, unreadCount, panel lists) re-evaluate.
        root.notifications = [...root.notifications]
    }

    function _actionsToArray(actionList) {
        const out = []
        if (!actionList)
            return out

        const len = actionList.length ?? 0
        for (let i = 0; i < len; i++) {
            const a = actionList[i]
            if (!a)
                continue
            out.push({
                identifier: a.identifier,
                text: a.text,
                invoke: () => a.invoke()
            })
        }
        return out
    }
    
    // Toggle DND mode
    function toggleDnd() {
        dnd = !dnd;
        QsServices.Logger.info("Notifs", `DND mode: ${dnd ? "enabled" : "disabled"}`)
    }
    
    // Clear all notifications
    function clearAll() {
        notifications.forEach(n => n.close());
        markAllRead()
        QsServices.Logger.info("Notifs", "All notifications cleared")
    }
    
    // Clear notifications from specific app
    function clearApp(appName) {
        notifications.filter(n => n.appName === appName).forEach(n => n.close());
        QsServices.Logger.info("Notifs", `Cleared notifications from: ${appName}`)
    }

    // Notification wrapper component
    component Notif: QtObject {
        id: notifWrapper
        
        property var notification
        property date timestamp: new Date()
        property bool closed: false
        property bool popupDismissed: false  // popup hid — still live in the panel
        property bool popupActive: false  // popup is showing (countdown runs)
        property real popupProgress: 1.0  // 1.0 → 0.0 over the popup timeout
        property bool read: false

        // Per-notification popup countdown. Lives on the wrapper so each
        // message has its own independent timer.
        readonly property Timer countdownTimer: Timer {
            id: popupTimer
            interval: 200
            repeat: true
            running: notifWrapper.popupActive
            onTriggered: {
                // Matches config.notifications.timeoutMs (7000). A constant —
                // importing Config here would create an import cycle.
                const step = 200 / 7000
                if (notifWrapper.popupProgress > step) {
                    notifWrapper.popupProgress -= step
                } else {
                    notifWrapper.popupProgress = 0
                    notifWrapper.popupActive = false
                }
            }
        }
        
        // Notification properties
        property string notifId: ""
        property string summary: ""
        property string body: ""
        property string appName: ""
        property string appIcon: ""
        property string image: ""
        property int urgency: NotificationUrgency.Normal
        // Use a JS array so `.length`/indexing and helpers work reliably.
        property var actions: []
        
        // Time formatting: "X minutes ago" within the first hour, then the
        // actual time ("21:28 on Thursday 6 August"). Refreshed every minute
        // so the relative → absolute transition happens on its own.
        property string timeString: formatTime()

        readonly property Timer refreshTimer: Timer {
            interval: 60000
            repeat: true
            running: true
            onTriggered: notifWrapper.timeString = notifWrapper.formatTime()
        }

        function formatTime() {
            const diff = new Date().getTime() - timestamp.getTime();
            if (diff < 60000) return "Just now";
            const minutes = Math.floor(diff / 60000);
            if (minutes < 60)
                return minutes === 1 ? "1 minute ago" : `${minutes} minutes ago`;
            return Qt.formatDateTime(timestamp, "HH:mm on dddd d MMMM");
        }
        
        // Connections to notification object
        readonly property Connections conn: Connections {
            target: notifWrapper.notification
            
            function onClosed() {
                // Daemon-initiated close (expiry, dismissal by another client).
                // The notification stays in the panel history — only its
                // popup hides. User-initiated removal uses close() directly.
                if (!notifWrapper.closed)
                    notifWrapper.popupDismissed = true;
            }
            
            function onSummaryChanged() {
                notifWrapper.summary = notifWrapper.notification.summary;
            }
            
            function onBodyChanged() {
                notifWrapper.body = notifWrapper.notification.body;
            }
            
            function onAppNameChanged() {
                notifWrapper.appName = notifWrapper.notification.appName;
            }
            
            function onAppIconChanged() {
                notifWrapper.appIcon = notifWrapper.notification.appIcon;
            }
            
            function onImageChanged() {
                notifWrapper.image = notifWrapper.notification.image;
            }
            
            function onUrgencyChanged() {
                notifWrapper.urgency = notifWrapper.notification.urgency;
            }
            
            function onActionsChanged() {
                notifWrapper.actions = root._actionsToArray(notifWrapper.notification.actions)
            }
        }
        
        function close() {
            if (closed) return;
            
            // Mark as closed but keep in history for notification center
            closed = true;
            
            // Only dismiss from the notification daemon, don't remove from list
            if (notification) {
                notification.dismiss();
            }

            // New array identity so bindings that filter on `closed` (e.g. the
            // notification panel list) re-evaluate and drop this entry.
            root.notifications = [...root.notifications]

            QsServices.Logger.debug("Notifs", `Notification closed (kept in history): ${summary}`)
        }
        
        function invokeAction(actionId) {
            const action = actions.find(a => a.identifier === actionId);
            if (action && action.invoke) {
                action.invoke();
            }
        }
        
        Component.onCompleted: {
            if (!notification)
                return;
            
            notifId = `${notification.id}`
            summary = notification.summary
            body = notification.body
            appName = notification.appName
            appIcon = notification.appIcon
            image = notification.image
            urgency = notification.urgency
            actions = root._actionsToArray(notification.actions)
            read = timestamp.getTime() <= root.lastReadAt
        }
    }
    
    Component {
        id: notifComponent
        
        Notif {}
    }
    
    // Delete a specific notification (permanently remove from history)
    function deleteNotification(notif) {
        if (root.notifications.includes(notif)) {
            root.notifications = root.notifications.filter(n => n !== notif);
            if (notif.notification) {
                notif.notification.dismiss();
            }
            notif.destroy();
            QsServices.Logger.debug("Notifs", "Notification permanently deleted")
        }
    }
}
