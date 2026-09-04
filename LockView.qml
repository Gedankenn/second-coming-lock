import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Commons
import qs.Ui

Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false

  readonly property string placeholderText: "ENTER AUTHORIZATION"
  readonly property int fieldWidth: 420
  readonly property int fieldHeight: 58
  readonly property int outlineThickness: 2
  readonly property int fieldFontSize: 15
  readonly property int passwordDotFontSize: 20
  readonly property int passwordDotLetterSpacing: 4
  readonly property real fingerprintReserve: fingerprintConfigured ? Math.round(fingerprintIcon.implicitWidth + 12) : 0
  readonly property real passwordDotScale: dotMetrics.advanceWidth > 0
    ? Math.min(1, (passwordInput.width - 4) / dotMetrics.advanceWidth)
    : 1
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0
  readonly property var inputBorderSpec: errorState
    ? Border.surfaceSpec("lock", "border-error", Color.lock.borderError, root.outlineThickness, "border-alpha")
    : Border.surfaceSpec("lock", "border-active", Color.lock.borderActive, root.outlineThickness, "border-alpha")

  readonly property color paper: "#F4F0E6"
  readonly property color muted: "#9A8B7C"
  readonly property color accent: "#FF6A00"
  readonly property color blood: "#C41E3A"
  readonly property string displayFont: "Chakra Petch"
  readonly property string bodyFont: "Nimbus Sans Narrow"

  property string weatherEmoji: ""
  property string weatherTemp: ""
  property string weatherCond: ""
  property string weatherPlace: ""
  property string locationQuery: ""
  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var activePlayer: pickPlayer()
  readonly property string trackTitle: activePlayer ? (activePlayer.trackTitle || "") : ""
  readonly property string trackArtist: activePlayer ? (activePlayer.trackArtist || "") : ""
  readonly property string trackArt: activePlayer && activePlayer.trackArtUrl ? activePlayer.trackArtUrl : ""
  readonly property bool playing: !!(activePlayer && activePlayer.isPlaying)

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  function pickPlayer() {
    var list = players || []
    for (var i = 0; i < list.length; i++) {
      if (list[i] && (list[i].trackTitle || list[i].isPlaying)) return list[i]
    }
    return list.length ? list[0] : null
  }

  function parseWeather(raw) {
    var parts = String(raw || "").replace(/\r/g, "").split("|")
    if (parts.length < 2) return
    weatherEmoji = String(parts[0] || "").trim()
    weatherTemp = String(parts[1] || "").trim().replace(/^\+/, "")
    weatherCond = String(parts[2] || "").trim()
    weatherPlace = String(parts[5] || "").trim()
  }

  onPasswordTextChanged: syncPasswordText()
  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }
  onLoadBackgroundChanged: {
    if (loadBackground) weatherProc.running = true
  }
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
    if (loadBackground) weatherProc.running = true
  }

  TextMetrics {
    id: dotMetrics
    font.family: root.displayFont
    font.pixelSize: root.passwordDotFontSize
    font.letterSpacing: root.passwordDotLetterSpacing
    text: "●".repeat(passwordInput.text.length)
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/settings/weather.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        var data = JSON.parse(text() || "{}")
        var lat = parseFloat(data.latitude)
        var lon = parseFloat(data.longitude)
        if (isFinite(lat) && isFinite(lon)) root.locationQuery = lat + "," + lon
        else root.locationQuery = String(data.name || "")
      } catch (e) {
        root.locationQuery = ""
      }
    }
  }

  Process {
    id: weatherProc
    command: ["curl", "-fsS", "-A", "magi-lock", "--max-time", "6",
      "https://wttr.in/" + (root.locationQuery ? encodeURIComponent(root.locationQuery) : "") + "?format=%c|%t|%C|%h|%w|%l&m"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseWeather(text)
    }
  }

  Timer {
    interval: 15 * 60 * 1000
    running: root.loadBackground
    repeat: true
    onTriggered: weatherProc.running = true
  }

  Rectangle {
    anchors.fill: parent
    color: "#0c0a0d"

    Image {
      id: wallpaper
      anchors.fill: parent
      source: root.loadBackground ? root.fileUrl(root.backgroundPath) : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize.width: width
      sourceSize.height: height
    }

    MultiEffect {
      anchors.fill: wallpaper
      source: wallpaper
      autoPaddingEnabled: false
      blurEnabled: root.loadBackground && wallpaper.status === Image.Ready
      blur: 1.0
      blurMax: 128
      blurMultiplier: 1.25
      contrast: -0.1
      brightness: -0.08
    }

    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0.05, 0.02, 0.03, 0.28)
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: false
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
    }

    Rectangle {
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: 16
      color: "#0c0a0d"

      Canvas {
        id: tape
        anchors.fill: parent
        onPaint: {
          var ctx = getContext("2d")
          var h = height
          var w = 18
          ctx.clearRect(0, 0, width, h)
          for (var x = -h; x < width + h; x += w) {
            ctx.fillStyle = (Math.floor((x + h) / w) % 2 === 0) ? "#FF6A00" : "#0c0a0d"
            ctx.beginPath()
            ctx.moveTo(x, 0)
            ctx.lineTo(x + w * 0.5, 0)
            ctx.lineTo(x + w * 0.5 - h, h)
            ctx.lineTo(x - h, h)
            ctx.closePath()
            ctx.fill()
          }
        }
        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
      }
    }

    Rectangle {
      anchors.top: parent.top
      anchors.topMargin: 16
      anchors.left: parent.left
      anchors.right: parent.right
      height: 2
      color: root.accent
    }

    Item {
      id: header
      anchors.top: parent.top
      anchors.topMargin: 28
      anchors.left: parent.left
      anchors.right: parent.right
      height: 36

      Text {
        anchors.left: parent.left
        anchors.leftMargin: 36
        anchors.verticalCenter: parent.verticalCenter
        text: "NERV  //  GEOFRONT"
        color: root.accent
        font.family: root.displayFont
        font.pixelSize: 16
        font.letterSpacing: 3
        font.weight: Font.Bold
      }

      Text {
        anchors.right: parent.right
        anchors.rightMargin: 36
        anchors.verticalCenter: parent.verticalCenter
        text: root.errorState ? "AUTH FAIL  " + root.failedAttempts : "MAGI-01  ONLINE"
        color: root.errorState ? root.blood : root.paper
        font.family: root.displayFont
        font.pixelSize: 14
        font.letterSpacing: 2
        font.weight: 600
      }
    }

    Column {
      id: hero
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: -36
      spacing: 10

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatTime(clock.date, "HH:mm")
        color: root.paper
        font.family: root.displayFont
        font.pixelSize: Math.max(92, Math.round(root.height * 0.14))
        font.weight: Font.Bold
        font.letterSpacing: 6
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(clock.date, "dddd  d  MMMM  yyyy").toUpperCase()
        color: root.accent
        font.family: root.displayFont
        font.pixelSize: 18
        font.letterSpacing: 4
        font.weight: 600
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.weatherTemp !== ""
        text: (root.weatherPlace ? root.weatherPlace.toUpperCase() + "   " : "")
          + (root.weatherEmoji ? root.weatherEmoji + "  " : "")
          + root.weatherTemp
          + (root.weatherCond ? "   " + root.weatherCond.toUpperCase() : "")
        color: root.muted
        font.family: root.bodyFont
        font.pixelSize: 14
        font.letterSpacing: 1.4
      }

      Item { width: 1; height: 18 }

      BorderSurface {
        id: inputField
        width: root.fieldWidth
        height: root.fieldHeight
        anchors.horizontalCenter: parent.horizontalCenter
        color: "#120e10"
        borderSpec: root.inputBorderSpec
        radius: 0
        clip: true

        Rectangle { width: 16; height: 2; color: root.errorState ? root.blood : root.accent; anchors.left: parent.left; anchors.top: parent.top }
        Rectangle { width: 2; height: 16; color: root.errorState ? root.blood : root.accent; anchors.left: parent.left; anchors.top: parent.top }
        Rectangle { width: 16; height: 2; color: root.errorState ? root.blood : root.accent; anchors.right: parent.right; anchors.top: parent.top }
        Rectangle { width: 2; height: 16; color: root.errorState ? root.blood : root.accent; anchors.right: parent.right; anchors.top: parent.top }
        Rectangle { width: 16; height: 2; color: root.errorState ? root.blood : root.accent; anchors.left: parent.left; anchors.bottom: parent.bottom }
        Rectangle { width: 2; height: 16; color: root.errorState ? root.blood : root.accent; anchors.left: parent.left; anchors.bottom: parent.bottom }
        Rectangle { width: 16; height: 2; color: root.errorState ? root.blood : root.accent; anchors.right: parent.right; anchors.bottom: parent.bottom }
        Rectangle { width: 2; height: 16; color: root.errorState ? root.blood : root.accent; anchors.right: parent.right; anchors.bottom: parent.bottom }

        TextInput {
          id: passwordInput
          anchors.fill: parent
          anchors.topMargin: inputField.borderTop
          anchors.rightMargin: inputField.borderRight + 18 + root.fingerprintReserve
          anchors.bottomMargin: inputField.borderBottom
          anchors.leftMargin: inputField.borderLeft + 18 + root.fingerprintReserve
          verticalAlignment: TextInput.AlignVCenter
          horizontalAlignment: TextInput.AlignHCenter
          activeFocusOnPress: true
          clip: true
          enabled: root.inputEnabled && !root.authenticatingPassword
          readOnly: root.authenticatingPassword
          echoMode: TextInput.Password
          passwordCharacter: "\u25CF"
          passwordMaskDelay: 0
          color: root.paper
          selectionColor: "#2a1510"
          selectedTextColor: root.paper
          font.family: root.displayFont
          font.pixelSize: text.length > 0 ? Math.max(1, Math.floor(root.passwordDotFontSize * root.passwordDotScale)) : root.fieldFontSize
          font.letterSpacing: text.length > 0 ? root.passwordDotLetterSpacing * root.passwordDotScale : 2.4
          cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
          cursorDelegate: Rectangle {
            width: 2
            color: root.accent
            visible: passwordInput.cursorVisible
          }

          onTextChanged: {
            if (!root.syncingPasswordText) root.passwordTextEdited(text)
            if (text.length > 0) root.wakeRequested()
            if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
          }

          onAccepted: {
            var submitted = root.passwordText
            root.passwordTextEdited("")
            if (submitted.length > 0) root.submitPassword(submitted)
          }

          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
              root.passwordTextEdited("")
              event.accepted = true
            }
          }
        }

        Text {
          anchors.fill: passwordInput
          text: root.authenticatingPassword
            ? "CHECKING MAGI…"
            : (root.failureMessage.length > 0 ? root.failureMessage.toUpperCase() : root.placeholderText)
          visible: passwordInput.text.length === 0
          color: root.authenticatingPassword
            ? root.paper
            : (root.failureMessage.length > 0 ? root.blood : root.muted)
          font.family: root.displayFont
          font.pixelSize: 13
          font.letterSpacing: 2.2
          font.weight: 600
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
        }

        Text {
          id: fingerprintIcon
          objectName: "fingerprintIndicator"
          anchors.right: parent.right
          anchors.rightMargin: inputField.borderRight + 18
          anchors.verticalCenter: parent.verticalCenter
          visible: root.fingerprintConfigured
          text: "󰈷"
          color: root.muted
          font.family: Style.font.family
          font.pixelSize: 18
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
        }
      }
    }

    Rectangle {
      id: calCard
      width: 250
      height: 268
      anchors.left: parent.left
      anchors.leftMargin: 36
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 48
      color: Qt.rgba(0.07, 0.04, 0.05, 0.78)
      border.width: 1
      border.color: "#FF6A00"

      Text {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.topMargin: 10
        text: "04   SACHIEL"
        color: root.accent
        font.family: root.displayFont
        font.pixelSize: 12
        font.letterSpacing: 2
        font.weight: 600
      }

      MagiCalendar {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        today: clock.date
        paper: root.paper
        muted: root.muted
        accent: root.accent
        blood: root.blood
        displayFont: root.displayFont
        fontFamily: root.bodyFont
        cellSize: 26
        interactive: false
      }
    }

    Rectangle {
      id: mediaCard
      visible: root.activePlayer !== null
      width: 280
      height: 110
      anchors.right: parent.right
      anchors.rightMargin: 36
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 48
      color: Qt.rgba(0.07, 0.04, 0.05, 0.78)
      border.width: 1
      border.color: "#FF6A00"

      Text {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.topMargin: 10
        text: "03   CASPER"
        color: root.accent
        font.family: root.displayFont
        font.pixelSize: 12
        font.letterSpacing: 2
        font.weight: 600
      }

      Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 14
        anchors.topMargin: 0
        spacing: 12

        Rectangle {
          width: 56
          height: 56
          color: "#1a1210"
          border.width: 1
          border.color: root.accent
          clip: true
          anchors.verticalCenter: parent.verticalCenter

          Image {
            anchors.fill: parent
            anchors.margins: 1
            source: root.trackArt
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: root.trackArt !== ""
          }
          Text {
            anchors.centerIn: parent
            visible: root.trackArt === ""
            text: root.playing ? "▶" : "♪"
            color: root.accent
            font.pixelSize: 18
          }
        }

        Column {
          width: parent.width - 68
          spacing: 4
          anchors.verticalCenter: parent.verticalCenter
          Text {
            width: parent.width
            text: root.trackTitle || "NO SIGNAL"
            color: root.paper
            font.family: root.bodyFont
            font.pixelSize: 14
            font.bold: true
            elide: Text.ElideRight
          }
          Text {
            width: parent.width
            text: root.trackArtist || "Casper is idle"
            color: root.muted
            font.family: root.bodyFont
            font.pixelSize: 12
            elide: Text.ElideRight
          }
        }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 18
      text: "THE FATE OF MANKIND"
      color: Qt.rgba(1, 0.42, 0, 0.55)
      font.family: root.displayFont
      font.pixelSize: 11
      font.letterSpacing: 5
      font.weight: 600
    }
  }
}
