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

  MagiTheme { id: magi }

  readonly property string placeholderText: "INTROIBO AD ALTARE DEI"
  readonly property int fieldWidth: 440
  readonly property int fieldHeight: 56
  readonly property int outlineThickness: 1
  readonly property int fieldFontSize: 14
  readonly property int passwordDotFontSize: 18
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

  readonly property color paper: magi.paper
  readonly property color muted: magi.muted
  readonly property color accent: magi.gold
  readonly property color blood: magi.wine
  readonly property color stone: magi.stone
  readonly property color candle: magi.candle
  readonly property color pane: magi.plate
  readonly property string displayFont: magi.display
  readonly property string bodyFont: magi.body
  readonly property var pt: Qt.locale("pt_BR")

  readonly property string weatherGlyph: {
    var s = (String(weatherCond || "") + " " + String(weatherEmoji || "")).toLowerCase()
    if (/thunder|storm|trovoada/.test(s)) return "storm"
    if (/snow|sleet|blizzard|ice|neve/.test(s)) return "snow"
    if (/rain|drizzle|shower|chuva/.test(s)) return "rain"
    if (/fog|mist|haze|smoke|neblina|névoa/.test(s)) return "fog"
    if (/sun|clear|fair|sol|céu limpo/.test(s)) return "sun"
    if (/cloud|overcast|nublado|nuvem/.test(s)) return "cloud"
    return weatherCond ? "cloud" : "sun"
  }

  property string weatherEmoji: ""
  property string weatherTemp: ""
  property string weatherCond: ""
  property string weatherHum: ""
  property string weatherWind: ""
  property string weatherPlace: ""
  property string locationQuery: ""
  property real cpuUsage: 0
  property real memUsage: 0
  property real diskUsage: 0
  property string cpuTemp: ""
  property string gpuTemp: ""
  property string gpuUsage: ""
  property string cpuModel: ""
  property string hostName: ""
  property string uptimeText: ""
  property string loadAvg: ""
  property string diskFree: ""
  property var prevCpu: null

  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var activePlayer: pickPlayer()
  readonly property string trackTitle: activePlayer ? (activePlayer.trackTitle || "") : ""
  readonly property string trackArtist: activePlayer ? (activePlayer.trackArtist || "") : ""
  readonly property string trackArt: activePlayer && activePlayer.trackArtUrl ? activePlayer.trackArtUrl : ""
  readonly property bool playing: !!(activePlayer && activePlayer.isPlaying)

  readonly property string assetRoot: Quickshell.env("HOME") + "/.config/omarchy/plugins/sabinho.second-coming/assets"
  readonly property var templumPlates: [
    { file: "templum/west-front.jpg", name: "WEST FRONT" },
    { file: "templum/benedict.jpg", name: "CRUX SANCTI PATRIS" },
    { file: "templum/monstrance.jpg", name: "OSTENSORIUM" },
    { file: "templum/altar.jpg", name: "ALTAR MAIUS" },
    { file: "templum/crucifix.jpg", name: "CRUX FIDELIS" }
  ]
  readonly property var rosaPlates: [
    { file: "rosa/chi-rho.jpg", name: "ROSE WINDOW" },
    { file: "rosa/michael.jpg", name: "SANCTE MICHAEL" },
    { file: "rosa/mystica.jpg", name: "ROSA MYSTICA" },
    { file: "rosa/keys.jpg", name: "CLAVES PETRI" },
    { file: "rosa/agnus.jpg", name: "AGNUS DEI" }
  ]
  readonly property int plateTick: Math.floor(clock.date.getTime() / 45000)
  readonly property var templumPlate: templumPlates[plateTick % templumPlates.length]
  readonly property var rosaPlate: rosaPlates[(plateTick + 2) % rosaPlates.length]

  readonly property var verses: [
    { ref: "João 14,6", text: "Eu sou o caminho, a verdade e a vida. Ninguém vai ao Pai senão por mim." },
    { ref: "Apocalipse 22,20", text: "Aquele que dá testemunho destas coisas diz: «Sim, venho em breve.» Amém. Vem, Senhor Jesus!" },
    { ref: "João 1,14", text: "E o Verbo se fez carne e habitou entre nós, e vimos a sua glória." },
    { ref: "Salmo 23,1", text: "O Senhor é o meu pastor: nada me faltará." },
    { ref: "Mateus 11,28", text: "Vinde a mim, todos os que estais cansados e oprimidos, e eu vos aliviarei." },
    { ref: "João 8,12", text: "Eu sou a luz do mundo; quem me segue não andará nas trevas." },
    { ref: "João 11,25", text: "Eu sou a ressurreição e a vida. Quem crê em mim, ainda que morra, viverá." },
    { ref: "Lucas 1,38", text: "Eis aqui a serva do Senhor; faça-se em mim segundo a tua palavra." },
    { ref: "Mateus 24,30", text: "Então aparecerá no céu o sinal do Filho do Homem, e todas as tribos da terra se lamentarão." },
    { ref: "João 3,16", text: "Deus amou de tal modo o mundo, que lhe deu o seu Filho unigênito." },
    { ref: "Filipenses 4,13", text: "Tudo posso naquele que me fortalece." },
    { ref: "Apocalipse 21,4", text: "Ele enxugará toda lágrima dos seus olhos, e não haverá mais morte." },
    { ref: "Salmo 27,1", text: "O Senhor é a minha luz e a minha salvação; a quem temerei?" },
    { ref: "Isaías 9,5", text: "Porque um menino nos nasceu, um filho se nos deu; e o principado está sobre os seus ombros." },
    { ref: "Mateus 5,14", text: "Vós sois a luz do mundo. Não se pode esconder uma cidade situada sobre um monte." },
    { ref: "João 19,30", text: "Quando Jesus tomou o vinagre, disse: «Tudo está consumado.» E, inclinando a cabeça, entregou o espírito." },
    { ref: "Lucas 22,19", text: "Isto é o meu corpo, que é dado por vós. Fazei isto em memória de mim." },
    { ref: "Mateus 28,20", text: "Eis que eu estou convosco todos os dias, até a consumação dos séculos." },
    { ref: "Salmo 46,11", text: "Aquietai-vos, e sabei que eu sou Deus." },
    { ref: "1 Coríntios 13,13", text: "Agora, pois, permanecem a fé, a esperança e a caridade, estas três; mas a maior delas é a caridade." }
  ]
  readonly property int verseIndex: Math.floor(clock.date.getTime() / 28000) % verses.length
  readonly property var verse: verses[verseIndex]

  readonly property string hudDate: pt.toString(clock.date, "dddd, d 'de' MMMM 'de' yyyy").toUpperCase()
  readonly property string placeLabel: {
    var p = String(weatherPlace || "").trim()
    if (!p || /^-?\d/.test(p)) return "PATO BRANCO"
    return p.toUpperCase()
  }

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  function plateUrl(rel) {
    return fileUrl(assetRoot + "/" + rel)
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
    try {
      var data = JSON.parse(String(raw || ""))
      var cur = data.current || {}
      if (cur.temperature_2m === undefined) return
      weatherTemp = Math.round(Number(cur.temperature_2m)) + "°C"
      weatherHum = Math.round(Number(cur.relative_humidity_2m || 0)) + "%"
      weatherWind = Math.round(Number(cur.wind_speed_10m || 0)) + " km/h"
      var c = Number(cur.weather_code)
      weatherCond = c === 0 ? "Clear" : c <= 3 ? "Cloudy" : c <= 48 ? "Fog" : c <= 67 ? "Rain" : c <= 77 ? "Snow" : c >= 95 ? "Thunder" : "Rain"
      weatherPlace = "Pato Branco"
    } catch (e) {}
  }

  function parseStats(raw) {
    var map = {}
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var cut = lines[i].indexOf("=")
      if (cut < 0) continue
      map[lines[i].slice(0, cut)] = lines[i].slice(cut + 1)
    }
    var c = String(map.cpu || "").trim().split(/\s+/)
    if (c.length >= 8) {
      var idle = parseInt(c[4]) || 0
      var total = (parseInt(c[1]) || 0) + (parseInt(c[2]) || 0) + (parseInt(c[3]) || 0)
        + idle + (parseInt(c[5]) || 0) + (parseInt(c[6]) || 0) + (parseInt(c[7]) || 0)
      if (prevCpu) {
        var dT = total - prevCpu.total
        var dI = idle - prevCpu.idle
        cpuUsage = dT > 0 ? Math.max(0, Math.min(1, 1 - dI / dT)) : 0
      }
      prevCpu = { total: total, idle: idle }
    }
    var mt = 0, ma = 0
    var mems = String(map.mem || "").match(/MemTotal:\s*\d+|MemAvailable:\s*\d+/g) || []
    for (var m = 0; m < mems.length; m++) {
      var bits = mems[m].split(/\s+/)
      if (bits[0] === "MemTotal:") mt = parseInt(bits[1]) || 0
      else if (bits[0] === "MemAvailable:") ma = parseInt(bits[1]) || 0
    }
    memUsage = mt > 0 ? Math.max(0, Math.min(1, (mt - ma) / mt)) : 0
    diskUsage = Math.max(0, Math.min(1, (parseInt(map.disk) || 0) / 100))
    cpuTemp = map.tcpu || ""
    gpuTemp = map.tgpu || ""
    gpuUsage = map.gpu || ""
    cpuModel = String(map.cpu_model || "").trim()
    hostName = String(map.host || "").trim()
    uptimeText = String(map.up || "").replace(/^up\s+/, "").trim()
    loadAvg = String(map.load || "").trim()
    diskFree = String(map.diskfree || "").trim()
  }

  function pct(v) {
    return Math.round((Number(v) || 0) * 100) + "%"
  }

  onPasswordTextChanged: syncPasswordText()
  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }
  onLoadBackgroundChanged: {
    if (loadBackground) {
      weatherProc.running = true
      if (!statsProc.running) statsProc.running = true
    }
  }
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
    if (loadBackground) {
      weatherProc.running = true
      if (!statsProc.running) statsProc.running = true
    }
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
        else root.locationQuery = String(data.name || "Pato Branco")
      } catch (e) {
        root.locationQuery = "Pato Branco"
      }
    }
  }

  Process {
    id: weatherProc
    command: ["curl", "-fsSL", "--max-time", "8",
      "https://api.open-meteo.com/v1/forecast?latitude=-26.22861&longitude=-52.67056&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&timezone=America%2FSao_Paulo"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseWeather(text)
    }
  }

  Process {
    id: statsProc
    command: ["sh", "-c",
      "echo cpu=$(grep '^cpu ' /proc/stat); " +
      "echo mem=$(awk '/MemTotal:|MemAvailable:/{print}' /proc/meminfo); " +
      "echo disk=$(df -P / | awk 'NR==2{print $5}'); " +
      "echo diskfree=$(df -hP / | awk 'NR==2{print $4}'); " +
      "echo tcpu=$(sensors 2>/dev/null | awk '/k10temp/{f=1;next} f&&/Tctl:/{gsub(/[^0-9.]/,\"\",$2); print $2; exit}'); " +
      "echo tgpu=$(sensors 2>/dev/null | awk '/amdgpu/{f=1;next} f&&/edge:/{gsub(/[^0-9.]/,\"\",$2); print $2; exit}'); " +
      "echo gpu=$(cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null || cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null); " +
      "echo cpu_model=$(awk -F: '/model name/{gsub(/^[ \\t]+/,\"\",$2); print $2; exit}' /proc/cpuinfo); " +
      "echo host=$(hostname); " +
      "echo up=$(uptime -p); " +
      "echo load=$(cut -d' ' -f1-3 /proc/loadavg)"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseStats(text)
    }
  }

  Timer {
    interval: 15 * 60 * 1000
    running: root.loadBackground
    repeat: true
    onTriggered: weatherProc.running = true
  }

  Timer {
    interval: 2000
    running: root.loadBackground
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!statsProc.running) statsProc.running = true
  }

  component GoldCorners: Item {
    property color ink: root.accent
    property int arm: 14
    property int thick: 2
    anchors.fill: parent
    Rectangle { width: parent.arm; height: parent.thick; color: parent.ink; anchors.left: parent.left; anchors.top: parent.top }
    Rectangle { width: parent.thick; height: parent.arm; color: parent.ink; anchors.left: parent.left; anchors.top: parent.top }
    Rectangle { width: parent.arm; height: parent.thick; color: parent.ink; anchors.right: parent.right; anchors.top: parent.top }
    Rectangle { width: parent.thick; height: parent.arm; color: parent.ink; anchors.right: parent.right; anchors.top: parent.top }
    Rectangle { width: parent.arm; height: parent.thick; color: parent.ink; anchors.left: parent.left; anchors.bottom: parent.bottom }
    Rectangle { width: parent.thick; height: parent.arm; color: parent.ink; anchors.left: parent.left; anchors.bottom: parent.bottom }
    Rectangle { width: parent.arm; height: parent.thick; color: parent.ink; anchors.right: parent.right; anchors.bottom: parent.bottom }
    Rectangle { width: parent.thick; height: parent.arm; color: parent.ink; anchors.right: parent.right; anchors.bottom: parent.bottom }
  }

  component MeterRow: Item {
    property string label: ""
    property real value: 0
    property string tail: ""
    property color bar: root.accent
    width: parent ? parent.width : 220
    height: 28
    Text {
      anchors.left: parent.left
      anchors.top: parent.top
      text: parent.label
      color: root.muted
      font.family: root.displayFont
      font.pixelSize: 10
      font.letterSpacing: 1.6
      font.weight: 600
    }
    Text {
      anchors.right: parent.right
      anchors.top: parent.top
      text: parent.tail
      color: root.paper
      font.family: root.bodyFont
      font.pixelSize: 11
    }
    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: 4
      color: magi.wash(root.accent, 0.18)
      Rectangle {
        width: Math.max(2, parent.width * Math.max(0, Math.min(1, parent.parent.value)))
        height: parent.height
        color: parent.parent.bar
      }
    }
  }

  component PlateCard: Rectangle {
    property string title: ""
    property string source: ""
    width: 268
    height: 168
    color: magi.wash(root.pane, 0.82)
    border.width: 1
    border.color: magi.wash(root.accent, 0.55)
    clip: true

    Image {
      anchors.fill: parent
      anchors.margins: 1
      source: parent.source
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: true
    }
    Rectangle {
      anchors.fill: parent
      gradient: Gradient {
        GradientStop { position: 0.0; color: "transparent" }
        GradientStop { position: 0.62; color: "transparent" }
        GradientStop { position: 1.0; color: Qt.rgba(0.08, 0.07, 0.05, 0.78) }
      }
    }
    Text {
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.margins: 10
      text: parent.title
      color: root.paper
      font.family: root.displayFont
      font.pixelSize: 11
      font.letterSpacing: 1.8
      font.weight: 600
    }
    GoldCorners { arm: 12; thick: 1 }
  }

  Rectangle {
    anchors.fill: parent
    color: magi.voidBg

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
      blurMax: 96
      blurMultiplier: 1.1
      contrast: -0.06
      brightness: -0.12
    }

    Rectangle {
      anchors.fill: parent
      color: magi.wash(magi.voidBg, 0.42)
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
      height: 2
      color: root.accent
    }
    Rectangle {
      anchors.top: parent.top
      anchors.topMargin: 4
      anchors.left: parent.left
      anchors.right: parent.right
      height: 1
      color: magi.wash(root.accent, 0.45)
    }

    Item {
      id: header
      anchors.top: parent.top
      anchors.topMargin: 18
      anchors.left: parent.left
      anchors.right: parent.right
      height: 28

      Text {
        anchors.left: parent.left
        anchors.leftMargin: 36
        anchors.verticalCenter: parent.verticalCenter
        text: "ECCLESIA   ·   PAROUSIA   ·   CURIA"
        color: root.accent
        font.family: root.displayFont
        font.pixelSize: 13
        font.letterSpacing: 3.2
        font.weight: Font.Bold
      }

      Text {
        anchors.right: parent.right
        anchors.rightMargin: 36
        anchors.verticalCenter: parent.verticalCenter
        text: root.errorState
          ? "AUTH FAIL  ·  " + root.failedAttempts
          : ("VIGILIA  ·  " + (root.hostName || "ARCHLORD").toUpperCase())
        color: root.errorState ? root.blood : root.paper
        font.family: root.displayFont
        font.pixelSize: 12
        font.letterSpacing: 2.2
        font.weight: 600
      }
    }

    Column {
      id: hero
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: -28
      spacing: 8

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "☧"
        color: magi.wash(root.accent, 0.85)
        font.pixelSize: 22
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatTime(clock.date, "HH:mm")
        color: root.paper
        font.family: root.displayFont
        font.pixelSize: Math.max(72, Math.round(root.height * 0.11))
        font.letterSpacing: 6
        font.weight: Font.Bold
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.hudDate
        color: root.candle
        font.family: root.displayFont
        font.pixelSize: 14
        font.letterSpacing: 2.4
        font.weight: 600
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.weatherTemp !== ""
        spacing: 10

        MagiIcon {
          width: 22
          height: 22
          kind: root.weatherGlyph
          stroke: root.stone
          accent: root.candle
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.placeLabel + "   ·   " + root.weatherTemp
            + (root.weatherCond ? "   " + root.weatherCond.toUpperCase() : "")
          color: root.muted
          font.family: root.bodyFont
          font.pixelSize: 13
          font.letterSpacing: 1.1
        }
      }

      Item { width: 1; height: 14 }

      BorderSurface {
        id: inputField
        width: root.fieldWidth
        height: root.fieldHeight
        anchors.horizontalCenter: parent.horizontalCenter
        color: magi.wash(magi.inset, 0.92)
        borderSpec: root.inputBorderSpec
        radius: 0
        clip: true

        GoldCorners {
          ink: root.errorState ? root.blood : root.accent
          arm: 16
          thick: 2
        }

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
          selectionColor: magi.wash(root.accent, 0.28)
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
            ? "CONFITEOR…"
            : (root.failureMessage.length > 0 ? root.failureMessage.toUpperCase() : root.placeholderText)
          visible: passwordInput.text.length === 0
          color: root.authenticatingPassword
            ? root.paper
            : (root.failureMessage.length > 0 ? root.blood : root.muted)
          font.family: root.displayFont
          font.pixelSize: 12
          font.letterSpacing: 2.0
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

    Column {
      id: leftCol
      anchors.left: parent.left
      anchors.leftMargin: 32
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 52
      spacing: 12
      width: 268

      PlateCard {
        title: root.templumPlate.name
        source: root.plateUrl(root.templumPlate.file)
      }

      Rectangle {
        width: parent.width
        height: 292
        color: magi.wash(root.pane, 0.86)
        border.width: 1
        border.color: magi.wash(root.accent, 0.55)

        GoldCorners { arm: 12; thick: 1 }

        Text {
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.leftMargin: 14
          anchors.topMargin: 12
          text: "KALENDARIUM"
          color: root.accent
          font.family: root.displayFont
          font.pixelSize: 11
          font.letterSpacing: 2.4
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
          cellSize: 28
          interactive: false
        }
      }
    }

    Column {
      id: rightCol
      anchors.right: parent.right
      anchors.rightMargin: 32
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 52
      spacing: 12
      width: 268

      PlateCard {
        title: root.rosaPlate.name
        source: root.plateUrl(root.rosaPlate.file)
      }

      Rectangle {
        width: parent.width
        height: (root.gpuUsage !== "" || root.gpuTemp !== "") ? 248 : 214
        color: magi.wash(root.pane, 0.86)
        border.width: 1
        border.color: magi.wash(root.accent, 0.55)

        GoldCorners { arm: 12; thick: 1 }

        Column {
          anchors.fill: parent
          anchors.margins: 14
          spacing: 8

          Text {
            text: "OFFICIUM"
            color: root.accent
            font.family: root.displayFont
            font.pixelSize: 11
            font.letterSpacing: 2.4
            font.weight: 600
          }

          Text {
            width: parent.width
            text: (root.cpuModel || "PROCESSADOR").toUpperCase()
            color: root.paper
            font.family: root.bodyFont
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            maximumLineCount: 2
          }

          MeterRow {
            label: "CPU"
            value: root.cpuUsage
            tail: root.pct(root.cpuUsage) + (root.cpuTemp ? "  ·  " + root.cpuTemp + "°" : "")
            bar: root.accent
          }
          MeterRow {
            label: "MEM"
            value: root.memUsage
            tail: root.pct(root.memUsage)
            bar: root.candle
          }
          MeterRow {
            label: "DISK"
            value: root.diskUsage
            tail: root.pct(root.diskUsage) + (root.diskFree ? "  ·  " + root.diskFree + " livre" : "")
            bar: root.stone
          }
          MeterRow {
            visible: root.gpuUsage !== "" || root.gpuTemp !== ""
            label: "GPU"
            value: (parseFloat(root.gpuUsage) || 0) / 100
            tail: (root.gpuUsage ? root.gpuUsage + "%" : "—") + (root.gpuTemp ? "  ·  " + root.gpuTemp + "°" : "")
            bar: root.blood
          }

          Text {
            width: parent.width
            color: root.muted
            font.family: root.bodyFont
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            text: (root.uptimeText ? "uptime  " + root.uptimeText : "")
              + (root.loadAvg ? "   ·   load  " + root.loadAvg : "")
          }
        }
      }

      Rectangle {
        visible: root.playing || root.trackArt !== ""
        width: parent.width
        height: 78
        color: magi.wash(root.pane, 0.86)
        border.width: 1
        border.color: magi.wash(root.candle, 0.5)

        Row {
          anchors.fill: parent
          anchors.margins: 12
          spacing: 10

          Rectangle {
            width: 54
            height: 54
            color: magi.inset
            border.width: 1
            border.color: magi.wash(root.accent, 0.4)
            clip: true
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
              color: root.candle
              font.pixelSize: 16
            }
          }

          Column {
            width: parent.width - 64
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter
            Text {
              text: "CANTICUM"
              color: root.accent
              font.family: root.displayFont
              font.pixelSize: 9
              font.letterSpacing: 1.8
              font.weight: 600
            }
            Text {
              width: parent.width
              text: root.trackTitle || "silêncio"
              color: root.paper
              font.family: root.bodyFont
              font.pixelSize: 13
              font.bold: true
              elide: Text.ElideRight
            }
            Text {
              width: parent.width
              text: root.trackArtist || ""
              color: root.muted
              font.family: root.bodyFont
              font.pixelSize: 11
              elide: Text.ElideRight
            }
          }
        }
      }
    }

    Rectangle {
      id: caelum
      width: 268
      height: 86
      anchors.left: parent.left
      anchors.leftMargin: 32
      anchors.bottom: leftCol.top
      anchors.bottomMargin: 12
      visible: leftCol.y > 220
      color: magi.wash(root.pane, 0.86)
      border.width: 1
      border.color: magi.wash(root.stone, 0.55)

      GoldCorners { arm: 10; thick: 1 }

      Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 4
        Text {
          text: "CAELUM"
          color: root.stone
          font.family: root.displayFont
          font.pixelSize: 11
          font.letterSpacing: 2.4
          font.weight: 600
        }
        Text {
          width: parent.width
          text: (root.weatherTemp || "—") + (root.weatherCond ? "  ·  " + root.weatherCond : "")
          color: root.paper
          font.family: root.bodyFont
          font.pixelSize: 14
          elide: Text.ElideRight
        }
        Text {
          width: parent.width
          text: (root.weatherHum ? "umidade  " + root.weatherHum : "")
            + (root.weatherWind ? "   vento  " + root.weatherWind : "")
          color: root.muted
          font.family: root.bodyFont
          font.pixelSize: 11
          elide: Text.ElideRight
        }
      }
    }

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 18
      spacing: 6
      width: Math.min(720, parent.width - 640)

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: "« " + root.verse.text + " »"
        color: root.paper
        font.family: root.bodyFont
        font.pixelSize: 14
        font.italic: true
      }
      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.verse.ref.toUpperCase() + "   ·   VENI DOMINE IESU"
        color: root.accent
        font.family: root.displayFont
        font.pixelSize: 10
        font.letterSpacing: 2.4
        font.weight: 600
      }
    }
  }
}
