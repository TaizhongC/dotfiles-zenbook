pragma Singleton

import QtQuick 6.10
import "../services" as QsServices

// Unified visual tokens for every panel (centric panel, control panel,
// notification panel, calendar, wallpaper, launcher).
//
// ONE surface color for all panel backgrounds — panels are differentiated by
// shape, borders and hover states, never by a different "black".
QtObject {
    id: root

    readonly property var pywal: QsServices.Pywal

    // ─── Surfaces ───
    // The single background black used by every panel card and section.
    readonly property color surface: pywal.surfaceContainerHighest
    // Raised interactive elements (rows, inputs) — the only lighter tone.
    readonly property color surfaceRaised: pywal.surfaceContainerHigh

    // ─── Interactive overlays (applied on top of `surface`) ───
    readonly property color hover: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.08)
    readonly property color pressed: Qt.rgba(pywal.foreground.r, pywal.foreground.g, pywal.foreground.b, 0.14)
    readonly property color focus: Qt.rgba(pywal.primary.r, pywal.primary.g, pywal.primary.b, 0.18)

    // ─── Stroke & text ───
    readonly property color accent: pywal.primary
    readonly property color border: pywal.outlineVariant
    readonly property color text: pywal.foreground
    readonly property color textMuted: pywal.onSurfaceMuted

    // ─── Shape ───
    readonly property int radius: 28       // outer panel card
    readonly property int radiusRaised: 20 // nested sections / cards
    readonly property int radiusField: 16  // rows, inputs, list cells

    // ─── Mixing helper (blend a translucent overlay over an opaque base) ───
    function blend(base: color, overlay: color, alpha: real): color {
        return Qt.rgba(
            base.r * (1 - alpha) + overlay.r * alpha,
            base.g * (1 - alpha) + overlay.g * alpha,
            base.b * (1 - alpha) + overlay.b * alpha,
            base.a)
    }
}
