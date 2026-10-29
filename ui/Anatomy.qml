pragma Singleton
import QtQuick

// "anatomy" design tokens for the hugo.* panels (approved prototype:
// ~/prototipo-barra-anatomy.html, skill ~/.claude/skills/anatomy). Grey stroke
// tones for structure, colour only for state (red alert, green ok, blue
// action/selection, amber attention), mono small caps for labels, strong
// numbers, and one easing curve for every transition.
QtObject {
  id: root

  // Surfaces.
  readonly property color page: "#0b0b0b"
  readonly property color card: "#131313"
  readonly property color face: "#1b1b1b"

  // Text.
  readonly property color text: "#a3a3a3"
  readonly property color strong: "#e6e6e6"
  readonly property color muted: "#6e6e6e"

  // Stroke tones.
  readonly property color hi: "#d4d4d4"
  readonly property color mid: "#6a6a6a"
  readonly property color lo: "#3e3e3e"
  readonly property color faint: "#2a2a2a"

  // State.
  readonly property color red: "#ff6b6b"
  readonly property color green: "#6be0a0"
  readonly property color blue: "#6b9bff"
  readonly property color amber: "#f5c26b"

  // Derived fills (alphas from the prototype CSS).
  readonly property color panelFill: Qt.rgba(11 / 255, 11 / 255, 11 / 255, 0.96)
  readonly property color rim: Qt.rgba(1, 1, 1, 0.09)          // panel outline
  readonly property color rule: Qt.rgba(1, 1, 1, 0.06)         // separators
  readonly property color controlRim: Qt.rgba(1, 1, 1, 0.08)   // inputs, chips
  readonly property color hover: Qt.rgba(1, 1, 1, 0.05)        // .rowi:hover #ffffff0d
  readonly property color pressed: Qt.rgba(1, 1, 1, 0.09)
  readonly property color selected: Qt.rgba(107 / 255, 155 / 255, 1, 0.08)     // .rowi.sel #6b9bff14
  readonly property color selectedRim: Qt.rgba(107 / 255, 155 / 255, 1, 0.35)
  readonly property color toggleOn: Qt.rgba(107 / 255, 155 / 255, 1, 0.25)     // .tog.on #6b9bff40
  readonly property color selection: Qt.rgba(107 / 255, 155 / 255, 1, 0.30)    // text selection
  readonly property color urgentFill: Qt.rgba(1, 107 / 255, 107 / 255, 0.12)

  // Geometry.
  readonly property real hairline: 0.6
  readonly property int panelRadius: 14
  readonly property int cardRadius: 8
  readonly property int rowRadius: 7
  readonly property int chipRadius: 5
  readonly property int trackHeight: 4
  readonly property int knobSize: 10

  // Type.
  readonly property string sans: "Adwaita Sans"
  readonly property string mono: "JetBrainsMono Nerd Font"
  readonly property real labelSpacing: 0.9   // ~.08em at 10-11 px

  // Motion: cubic-bezier(.32,.72,0,1) everywhere.
  readonly property var ease: [0.32, 0.72, 0, 1, 1, 1]
  readonly property int fast: 200
  readonly property int base: 300
  readonly property int slow: 450

  // Stroke icons, 24-unit grid (draw with AnatomyIcon).
  readonly property var icons: ({
    monitor: "M5 4h14a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2zM8.5 20h7M12 16v4",
    monitors: "M4.5 5h9A1.5 1.5 0 0 1 15 6.5v6a1.5 1.5 0 0 1-1.5 1.5h-9A1.5 1.5 0 0 1 3 12.5v-6A1.5 1.5 0 0 1 4.5 5z"
      + "M15 8.5h4.5A1.5 1.5 0 0 1 21 10v6a1.5 1.5 0 0 1-1.5 1.5h-9A1.5 1.5 0 0 1 9 16v-2M6 18h4M8 14v4",
    sun: "M8 12a4 4 0 1 0 8 0a4 4 0 1 0-8 0M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2"
      + "M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7l1.4-1.4M17.3 6.7l1.4-1.4",
    moon: "M19 14.5A7.5 7.5 0 0 1 9.5 5a7.5 7.5 0 1 0 9.5 9.5z",
    text: "M3.5 18L8.5 6l5 12M5.3 14h6.4M15 18l3-7 3 7M15.9 16h4.2",
    scale: "M4 9V4h5M20 15v5h-5M4 4l6 6M20 20l-6-6",
    check: "M5 12.5l4.5 4.5L19 7.5",
    chevronDown: "M6 9.5l6 6 6-6",
    close: "M6 6l12 12M18 6L6 18",
    battery: "M5.5 7.5h11A2.5 2.5 0 0 1 19 10v4a2.5 2.5 0 0 1-2.5 2.5h-11A2.5 2.5 0 0 1 3 14v-4a2.5 2.5 0 0 1 2.5-2.5zM21 10.5v3",
    bolt: "M11.8 9.2l-2 3h3l-2 3",
    cloud: "M7.5 18h9a3.5 3.5 0 0 0 .4-7A5 5 0 0 0 7.3 9.6 4.2 4.2 0 0 0 7.5 18z",
    cloudSun: "M8.5 3.5v1.6M3.7 5.6l1.1 1.1M2.5 10.5h1.6M13.3 5.6l-1.1 1.1M5.6 12.6A3.6 3.6 0 0 1 11.9 8.9"
      + "M9.5 20h7.5a3.2 3.2 0 0 0 .3-6.4A4.6 4.6 0 0 0 8.6 12.3 3.9 3.9 0 0 0 9.5 20z",
    rain: "M7.5 14.5h9a3.5 3.5 0 0 0 .4-7A5 5 0 0 0 7.3 6.1 4.2 4.2 0 0 0 7.5 14.5zM9 17l-1 2.5M13 17l-1 2.5M17 17l-1 2.5",
    snow: "M7.5 14.5h9a3.5 3.5 0 0 0 .4-7A5 5 0 0 0 7.3 6.1 4.2 4.2 0 0 0 7.5 14.5z"
      + "M8.3 18a.7 .7 0 1 0 1.4 0a.7 .7 0 1 0-1.4 0M11.3 20.5a.7 .7 0 1 0 1.4 0a.7 .7 0 1 0-1.4 0M14.3 18a.7 .7 0 1 0 1.4 0a.7 .7 0 1 0-1.4 0",
    storm: "M7.5 14.5h9a3.5 3.5 0 0 0 .4-7A5 5 0 0 0 7.3 6.1 4.2 4.2 0 0 0 7.5 14.5zM12.5 15.5l-2 3h3l-2 3",
    fog: "M4 8h16M6 12h12M4 16h16",
    pin: "M12 21s-6-5.3-6-10.5a6 6 0 0 1 12 0C18 15.7 12 21 12 21zM10 10.5a2 2 0 1 0 4 0a2 2 0 1 0-4 0",
    sparkle: "M12 3l1.6 4.4L18 9l-4.4 1.6L12 15l-1.6-4.4L6 9l4.4-1.6zM18.5 15l.7 1.8 1.8.7-1.8.7-.7 1.8-.7-1.8-1.8-.7 1.8-.7z",
    refresh: "M19.5 12a7.5 7.5 0 1 1-2.2-5.3M19.5 4.5v4h-4",
    terminal: "M6.5 4h11A2.5 2.5 0 0 1 20 6.5v11a2.5 2.5 0 0 1-2.5 2.5h-11A2.5 2.5 0 0 1 4 17.5v-11A2.5 2.5 0 0 1 6.5 4zM8 9.5l2.5 2.5L8 14.5M12.5 15h3.5",
    calendar: "M6 5h12a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2zM4 10h16M8 3v4M16 3v4",
    chevronLeft: "M14.5 6l-6 6 6 6",
    chevronRight: "M9.5 6l6 6-6 6",
    // Audio, network and Bluetooth panels (hugo.audio / hugo.network /
    // hugo.bluetooth); same paths as hugo.bar and the prototype.
    speaker: "M4 9.5h3.5L12 5.5v13l-4.5-4H4z",
    wave1: "M15.5 9.2a4 4 0 0 1 0 5.6",
    wave2: "M18 7a7 7 0 0 1 0 10",
    muteCross: "M16 9.5l5 5M21 9.5l-5 5",
    headphones: "M4 15v-3a8 8 0 0 1 16 0v3M4 15h3v5H4zM17 15h3v5h-3z",
    mic: "M12 3.5a3 3 0 0 1 3 3v5a3 3 0 0 1-6 0v-5a3 3 0 0 1 3-3zM5.5 11.5a6.5 6.5 0 0 0 13 0M12 18v2.5",
    slash: "M4 4l16 16",
    bluetooth: "M7 7l10 10-5 4V3l5 4L7 17",
    camera: "M5 7h8a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2zM15 10.5l5-3v9l-5-3",
    wifi1: "M8.9 15.5a4.3 4.3 0 0 1 6.2 0",
    wifi2: "M5.8 12.4a8.6 8.6 0 0 1 12.4 0",
    wifi3: "M2.8 9.2a13 13 0 0 1 18.4 0",
    wifiDot: "M11.1 18.6a.9 .9 0 1 0 1.8 0a.9 .9 0 1 0-1.8 0",
    ethernet: "M10 3h4a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1h-4a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z"
      + "M4 15h3a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-3a1 1 0 0 1 1-1z"
      + "M17 15h3a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1h-3a1 1 0 0 1-1-1v-3a1 1 0 0 1 1-1zM12 8v3.5M5.5 15v-3.5h13V15",
    lock: "M8 11V8a4 4 0 0 1 8 0v3M7 11h10a1 1 0 0 1 1 1v7a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1v-7a1 1 0 0 1 1-1z",
    qr: "M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h2.5v2.5H14zM17.5 17.5H20V20h-2.5zM14 20h1M20 14v1",
    gauge: "M4.6 17.5a8.5 8.5 0 1 1 14.8 0M12 13.5l3.5-4.5M11.1 13.5a.9 .9 0 1 0 1.8 0a.9 .9 0 1 0-1.8 0",
    keyboard: "M4 6.5h16a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-9a1 1 0 0 1 1-1z"
      + "M7 10h.01M10 10h.01M13 10h.01M16 10h.01M7 13.5h.01M17 13.5h.01M9.5 14h5",
    mouse: "M12 3a5 5 0 0 1 5 5v8a5 5 0 0 1-10 0V8a5 5 0 0 1 5-5zM12 7v3",
    phone: "M8 3h8a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1zM11 18h2",
    gamepad: "M7 8h10a4 4 0 0 1 4 4v1.5a3.5 3.5 0 0 1-6.3 2.1L14 14.5h-4l-.7 1.1A3.5 3.5 0 0 1 3 13.5V12a4 4 0 0 1 4-4z"
      + "M7.5 11v3M6 12.5h3M15.5 11.5h.01M17.5 13.5h.01",
    message: "M5.5 4.5h13A2.5 2.5 0 0 1 21 7v7.5a2.5 2.5 0 0 1-2.5 2.5H10l-4.5 3.5V17h0A2.5 2.5 0 0 1 3 14.5V7a2.5 2.5 0 0 1 2.5-2.5z",
    bell: "M6.5 16.5V11a5.5 5.5 0 0 1 11 0v5.5l1.5 1.5H5zM10 20.5a2 2 0 0 0 4 0"
  })

  function alpha(c, a) {
    return Qt.rgba(c.r, c.g, c.b, a)
  }

  // Text colour for a control that may be handed a theme foreground: keep
  // the caller's colour only when it was set on purpose to a state colour.
  function tone(name) {
    if (name === "red" || name === "urgent") return red
    if (name === "green") return green
    if (name === "blue") return blue
    if (name === "amber") return amber
    if (name === "muted") return muted
    if (name === "text") return text
    return strong
  }
}
