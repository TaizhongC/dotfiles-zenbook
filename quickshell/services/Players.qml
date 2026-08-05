pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick 6.10

Singleton {
    id: root

    readonly property var list: Mpris.players.values
    
    // Consumer visibility control - set to false to pause polling when UI is hidden
    property bool visible: true
    
    property var active: null
    
    // React to MPRIS player changes via Connections (event-driven)
    Connections {
        target: Mpris.players
        
        function onValuesChanged() {
            root.updateActivePlayer()
        }
    }
    
    function updateActivePlayer() {
        var newActive = null
        
        // 1. Find the first playing player
        for (var i = 0; i < list.length; i++) {
            if (list[i]?.isPlaying) {
                newActive = list[i]
                break
            }
        }
        
        // 2. If no player is currently playing, preserve current active player if still available in list
        if (!newActive && active) {
            for (var j = 0; j < list.length; j++) {
                if (list[j] === active) {
                    newActive = active
                    break
                }
            }
        }
        
        // 3. Fallback to first available player if current active player was destroyed/closed
        if (!newActive && list.length > 0) {
            newActive = list[0]
        }
        
        // Update active if changed
        if (active !== newActive) {
            active = newActive
        }
    }
    
    Component.onCompleted: updateActivePlayer()
    
    // Fallback timer for edge cases (only runs when visible)
    Timer {
        interval: 2000  // Increased from 1000ms since we have event-driven updates
        running: root.visible && list.length > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateActivePlayer()
    }

    function getTargetPlayer(playerName = ""): string {
        if (playerName && playerName.length > 0 && !playerName.includes(" ")) return playerName
        if (active) {
            if (active.desktopEntry && active.desktopEntry.length > 0) return active.desktopEntry
            if (active.dbusName && active.dbusName.length > 0) {
                var parts = active.dbusName.split(".")
                var lastPart = parts[parts.length - 1]
                if (lastPart) return lastPart
            }
        }
        return ""
    }

    function togglePlaying(playerName = "") {
        if (!playerName && active) {
            if (typeof active.playPause === "function") { active.playPause(); return; }
            if (typeof active.togglePlaying === "function") { active.togglePlaying(); return; }
        }
        var target = getTargetPlayer(playerName)
        if (target)
            ctrlProc.exec(["playerctl", "--player", target, "play-pause"])
        else
            ctrlProc.exec(["playerctl", "play-pause"])
    }

    function next(playerName = "") {
        if (!playerName && active && typeof active.next === "function") { active.next(); return; }
        var target = getTargetPlayer(playerName)
        if (target)
            ctrlProc.exec(["playerctl", "--player", target, "next"])
        else
            ctrlProc.exec(["playerctl", "next"])
    }

    function previous(playerName = "") {
        if (!playerName && active && typeof active.previous === "function") { active.previous(); return; }
        var target = getTargetPlayer(playerName)
        if (target)
            ctrlProc.exec(["playerctl", "--player", target, "previous"])
        else
            ctrlProc.exec(["playerctl", "previous"])
    }

    function stop(playerName = "") {
        if (!playerName && active && typeof active.stop === "function") { active.stop(); return; }
        var target = getTargetPlayer(playerName)
        if (target)
            ctrlProc.exec(["playerctl", "--player", target, "stop"])
        else
            ctrlProc.exec(["playerctl", "stop"])
    }

    Process {
        id: ctrlProc
    }

    function setPosition(microseconds, playerName = "") {
        var target = getTargetPlayer(playerName)
        var args = ["playerctl", "position", String(Math.floor(microseconds))]
        if (target)
            args = ["playerctl", "--player", target, "position", String(Math.floor(microseconds))]
        ctrlProc.exec(args)
    }

    function getIdentity(player: var): string {
        return player?.identity ?? "Unknown";
    }
}
