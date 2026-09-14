import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: t
  width: 0
  height: 0
  visible: false

  property bool light: false

  readonly property color gold: light ? "#8A7340" : "#C4A35A"
  readonly property color wine: "#8B3A42"
  readonly property color candle: light ? "#6E7F62" : "#B8A878"
  readonly property color stone: light ? "#4E5F48" : "#7A8F6A"
  readonly property color paper: light ? "#2A2A2E" : "#E8E0D0"
  readonly property color muted: light ? "#5A564E" : "#8A7A68"
  readonly property color dim: light ? "#8A8680" : "#6A5E50"
  readonly property color voidBg: light ? "#F3EDE3" : "#1A1612"
  readonly property color plate: light ? "#EDE6DA" : "#1E1A14"
  readonly property color pane: light ? "#E4DCCE" : "#241E18"
  readonly property color inset: light ? "#DDD4C6" : "#141210"

  readonly property string display: "Cinzel"
  readonly property string body: "Noto Serif"

  function wash(c, a) {
    return Qt.rgba(c.r, c.g, c.b, a)
  }

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme/colors.toml"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      var txt = text() || ""
      t.light = /mode\s*=\s*"light"/.test(txt)
    }
  }
}
