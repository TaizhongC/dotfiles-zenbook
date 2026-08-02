#!/usr/bin/env python3
"""Small themed layer-shell control panels opened by Waybar modules."""
import os
import re
import subprocess
import sys
from pathlib import Path

# gtk4-layer-shell only works on the Wayland backend.  Set this before GTK
# loads, including when the script is started outside the Waybar launcher.
os.environ["GDK_BACKEND"] = "wayland"

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Pango", "1.0")
from gi.repository import GLib, Gtk, Gdk, Pango


CSS = b"""
window { background: transparent; }
#panel { background: @surface; border: 1px solid @outline; border-radius: 16px; padding: 14px; }
label { color: @text; font-family: JetBrainsMono Nerd Font; font-size: 13px; }
label.title { color: @primary; font-weight: bold; font-size: 14px; }
label.status { color: @text-muted; font-size: 11px; }
button { background: @surface-high; color: @text; border: 0; border-radius: 10px; padding: 7px 10px; font-family: JetBrainsMono Nerd Font; }
button:hover { background: @surface-highest; color: @primary; }
button:disabled { background: @surface-high; color: @primary; opacity: 1; }
entry { background: @surface-low; color: @text; border: 1px solid @outline; border-radius: 9px; padding: 7px; font-family: JetBrainsMono Nerd Font; }
scale trough { background: @surface-highest; min-height: 7px; border-radius: 6px; }
scale highlight { background: @primary; border-radius: 6px; }
scale slider { background: @text; min-width: 16px; min-height: 16px; border-radius: 10px; }
list row { padding: 2px; border-radius: 8px; }
list row:hover { background: @surface-high; }
calendar { background: @surface; color: @text; }
calendar > header, calendar > grid > label { color: @text; }
calendar label:selected, calendar > grid > label:selected { background: @primary; color: @background; border-radius: 999px; }
calendar label.today, calendar > grid > label.today { border: 1px solid @primary; border-radius: 999px; color: @primary; }
calendar label.today:selected, calendar > grid > label.today:selected { background: @primary; color: @background; }
"""


def run(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(args, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)


def output(*args: str) -> str:
    return run(*args).stdout.strip()


def refresh_waybar_audio() -> None:
    run("pkill", "-RTMIN+8", "waybar")


class Panel(Gtk.Application):
    def __init__(self, kind: str):
        super().__init__(application_id=f"local.waybar.{kind}")
        self.kind = kind
        self.window = None
        self.status = None

    def do_activate(self):
        if self.window:
            self.window.present()
            return
        self.window = Gtk.Window(application=self, title=f"waybar-control-panel-{self.kind}")
        self.window.set_decorated(False)
        self.window.set_resizable(False)
        keys = Gtk.EventControllerKey()
        keys.connect("key-pressed", self.on_key_pressed)
        self.window.add_controller(keys)

        Gtk.Settings.get_default().set_property("gtk-application-prefer-dark-theme", True)
        provider = Gtk.CssProvider()
        colors = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "waybar/colors.css"
        provider.load_from_data(colors.read_bytes() + CSS)
        Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        panel.set_name("panel")
        panel.set_size_request(300, -1)
        panel.append(self.header())
        if self.kind == "audio":
            self.audio_panel(panel)
        elif self.kind == "wifi":
            self.wifi_panel(panel)
        elif self.kind == "bluetooth":
            self.bluetooth_panel(panel)
        else:
            self.calendar_panel(panel)
        self.status = Gtk.Label(xalign=0)
        self.status.add_css_class("status")
        self.status.set_single_line_mode(True)
        self.status.set_ellipsize(Pango.EllipsizeMode.END)
        self.status.set_width_chars(34)
        self.status.set_max_width_chars(34)
        panel.append(self.status)
        self.window.set_child(panel)
        self.window.present()

    def header(self):
        row = Gtk.Box(spacing=8)
        title = Gtk.Label(label={"audio": "Volume", "wifi": "Wi-Fi", "bluetooth": "Bluetooth", "calendar": "Calendar"}[self.kind], xalign=0, hexpand=True)
        title.add_css_class("title")
        row.append(title)
        return row

    def on_key_pressed(self, _controller, keyval, _keycode, _state):
        if keyval == Gdk.KEY_Escape:
            self.window.close()
            return True
        return False

    def set_status(self, text: str):
        self.status.set_text(text)

    def button(self, label, callback, hexpand=False):
        widget = Gtk.Button(label=label, hexpand=hexpand)
        widget.connect("clicked", callback)
        return widget

    def audio_panel(self, panel):
        value = output("wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@")
        match = re.search(r"([0-9.]+)", value)
        volume = min(float(match.group(1)) if match else 0, 1.0)
        self.volume_label = Gtk.Label(label=f"{round(volume * 100)}%", xalign=0)
        panel.append(self.volume_label)
        self.slider = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 1, 0.01)
        self.slider.set_value(volume)
        self.slider.set_draw_value(False)
        self.slider.connect("value-changed", self.set_volume)
        panel.append(self.slider)
        muted = "MUTED" in value
        self.mute = self.button("Unmute" if muted else "Mute", self.toggle_mute)
        panel.append(self.mute)

    def set_volume(self, slider):
        volume = slider.get_value()
        run("wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", f"{volume:.2f}")
        self.volume_label.set_text(f"{round(volume * 100)}%")
        refresh_waybar_audio()

    def toggle_mute(self, *_):
        result = output("wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@")
        run("wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle")
        self.mute.set_label("Unmute" if "MUTED" not in result else "Mute")
        refresh_waybar_audio()

    def wifi_panel(self, panel):
        enabled = output("nmcli", "radio", "wifi") == "enabled"
        panel.append(self.button("Turn Wi-Fi off" if enabled else "Turn Wi-Fi on", self.toggle_wifi, True))
        self.wifi_list = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE)
        panel.append(self.wifi_list)
        self.hidden_ssid = Gtk.Entry(placeholder_text="Hidden network name")
        self.password = Gtk.Entry(placeholder_text="Password (leave blank if open)", visibility=False)
        panel.append(self.hidden_ssid)
        panel.append(self.password)
        panel.append(self.button("Join hidden network", self.join_hidden, True))
        # Scan on every open, then give NetworkManager 200 ms to publish it.
        run("nmcli", "device", "wifi", "rescan")
        GLib.timeout_add(200, self.refresh_wifi)

    def clear(self, widget):
        while (child := widget.get_first_child()) is not None:
            widget.remove(child)

    def refresh_wifi(self):
        self.clear(self.wifi_list)
        connection = self.active_wifi()
        names = []
        for name in output("nmcli", "-g", "SSID", "device", "wifi", "list").splitlines():
            if name and name not in names:
                names.append(name)
        if connection in names:
            names.remove(connection)
            names.insert(0, connection)
        for name in names[:10]:
            row = Gtk.Box(spacing=6)
            row.append(Gtk.Label(label=name, xalign=0, hexpand=True))
            if name == connection:
                state = self.button("Connected", lambda *_: None)
                state.set_sensitive(False)
                row.append(state)
            else:
                row.append(self.button("Connect", lambda _, ssid=name: self.connect_wifi(ssid)))
            self.wifi_list.append(row)
        self.set_status("Select a network; enter a password only when needed.")
        return False

    def active_wifi(self):
        """Return the active SSID, including connection profiles with custom names."""
        for line in output("nmcli", "-t", "-f", "ACTIVE,SSID", "device", "wifi", "list").splitlines():
            if line.startswith("yes:"):
                return line[4:]
        device = next((parts[0] for line in output("nmcli", "-t", "-f", "DEVICE,TYPE", "device", "status").splitlines() if len(parts := line.split(":")) > 1 and parts[1] == "wifi"), "")
        connection = output("nmcli", "-g", "GENERAL.CONNECTION", "device", "show", device) if device else ""
        return "" if connection in {"", "--"} else connection

    def connect_wifi(self, ssid):
        password = self.password.get_text()
        args = ["nmcli", "device", "wifi", "connect", ssid]
        if password:
            args += ["password", password]
        result = run(*args)
        self.set_status("Connected to " + ssid if result.returncode == 0 else (result.stderr.strip() or "Could not connect"))
        if result.returncode == 0:
            self.refresh_wifi()

    def join_hidden(self, *_):
        ssid, password = self.hidden_ssid.get_text(), self.password.get_text()
        if not ssid:
            self.set_status("Enter the hidden network name.")
            return
        args = ["nmcli", "device", "wifi", "connect", ssid, "hidden", "yes"]
        if password:
            args += ["password", password]
        result = run(*args)
        self.set_status("Connected to " + ssid if result.returncode == 0 else (result.stderr.strip() or "Could not connect"))
        if result.returncode == 0:
            self.refresh_wifi()

    def toggle_wifi(self, button):
        turn_on = output("nmcli", "radio", "wifi") != "enabled"
        result = run("nmcli", "radio", "wifi", "on" if turn_on else "off")
        button.set_label("Turn Wi-Fi off" if turn_on else "Turn Wi-Fi on")
        self.set_status("Wi-Fi turned " + ("on" if turn_on else "off") if result.returncode == 0 else result.stderr.strip())

    def bluetooth_panel(self, panel):
        powered = self.bluetooth_powered()
        panel.append(self.button("Turn Bluetooth off" if powered else "Turn Bluetooth on", self.toggle_bluetooth, True))
        panel.append(self.button("Find new devices", self.scan_bluetooth, True))
        self.bluetooth_list = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE)
        panel.append(self.bluetooth_list)
        self.refresh_bluetooth()

    def bluetooth_powered(self):
        return bool(re.search(r"Powered:\s+yes", output("bluetoothctl", "show")))

    @property
    def remembered_devices(self):
        return Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "waybar/bluetooth-connected-devices"

    def toggle_bluetooth(self, button):
        if self.bluetooth_powered():
            addresses = [line.split()[1] for line in output("bluetoothctl", "devices", "Connected").splitlines() if len(line.split()) > 1]
            self.remembered_devices.parent.mkdir(parents=True, exist_ok=True)
            self.remembered_devices.write_text("\n".join(addresses))
            result = run("bluetoothctl", "power", "off")
            button.set_label("Turn Bluetooth on")
            self.set_status("Bluetooth turned off" if result.returncode == 0 else result.stderr.strip())
        else:
            result = run("bluetoothctl", "power", "on")
            button.set_label("Turn Bluetooth off")
            self.set_status("Bluetooth turned on; reconnecting previous devices…")
            GLib.timeout_add(1000, self.reconnect_bluetooth)

    def reconnect_bluetooth(self):
        if self.remembered_devices.exists():
            for address in self.remembered_devices.read_text().splitlines():
                if address:
                    run("bluetoothctl", "connect", address)
            self.remembered_devices.unlink(missing_ok=True)
        self.refresh_bluetooth()
        self.set_status("Bluetooth ready")
        return False

    def scan_bluetooth(self, *_):
        run("bluetoothctl", "scan", "on")
        self.set_status("Scanning for 8 seconds…")
        GLib.timeout_add(8000, self.stop_scan)

    def stop_scan(self):
        run("bluetoothctl", "scan", "off")
        self.refresh_bluetooth()
        self.set_status("Scan complete")
        return False

    def refresh_bluetooth(self):
        self.clear(self.bluetooth_list)
        for line in output("bluetoothctl", "devices").splitlines()[:10]:
            parts = line.split(maxsplit=2)
            if len(parts) < 3:
                continue
            address, name = parts[1], parts[2]
            row = Gtk.Box(spacing=6)
            row.append(Gtk.Label(label=name, xalign=0, hexpand=True))
            row.append(self.button("Connect", lambda _, mac=address: self.connect_bluetooth(mac)))
            self.bluetooth_list.append(row)

    def connect_bluetooth(self, address):
        result = run("bluetoothctl", "connect", address)
        self.set_status("Connected" if result.returncode == 0 else (result.stderr.strip() or "Could not connect"))

    def calendar_panel(self, panel):
        calendar = Gtk.Calendar()
        calendar.set_show_week_numbers(True)
        calendar.set_hexpand(True)
        panel.append(calendar)


if __name__ == "__main__":
    kind = sys.argv[1] if len(sys.argv) > 1 else "calendar"
    if kind not in {"audio", "wifi", "bluetooth", "calendar"}:
        raise SystemExit("Usage: control-panel.py [audio|wifi|bluetooth|calendar]")
    # `kind` is consumed above; GTK would otherwise interpret it as a file to
    # open and emit a GLib-GIO warning for every Waybar click.
    raise SystemExit(Panel(kind).run([sys.argv[0]]))
