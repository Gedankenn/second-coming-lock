# second-coming-lock

Second Coming lock screen for [Omarchy](https://omarchy.org): a [Quickshell](https://quickshell.outfoxxed.me/) (QML) session-lock plugin with a liturgical HUD (Scripture verses, weather, calendar, media and Catholic-themed plates), the companion to [second-coming](https://github.com/Gedankenn/second-coming).

## Features

- **Session lock service** (`Service.qml`): locks via Quickshell's session-lock API and refuses to lock when no PAM password configuration is found.
- **Authentication**: password through PAM (`Quickshell.Services.Pam`), plus fingerprint when it is configured.
- **Lock view** (`LockView.qml`):
  - password field (placeholder *"INTROIBO AD ALTARE DEI"*) with failed-attempt feedback
  - current wallpaper from Omarchy's `~/.local/state/omarchy/current/background`
  - rotating Scripture verses
  - current weather from the [Open-Meteo](https://open-meteo.com) API (temperature, humidity, wind). Coordinates and place name are hard-coded in `LockView.qml`.
  - MPRIS media player info
  - MAGI-style calendar and glyphs (`MagiCalendar.qml`, `MagiIcon.qml`, `MagiSeg.qml`, colors in `MagiTheme.qml`)
- Plays a bell (`assets/bell.ogg`) when the screen locks.

## Install

As an Omarchy plugin (`manifest.json`: id `sabinho.lock`, a `service` entry point, cloned from `omarchy.lock`):

```bash
omarchy plugin add https://github.com/Gedankenn/second-coming-lock.git --enable --yes
```

Disable the stock `omarchy.lock` if the two fight over the lock target.

## Files

| File | Purpose |
|------|---------|
| `manifest.json` | Omarchy plugin manifest |
| `Service.qml` | Lock lifecycle, PAM password/fingerprint authentication |
| `LockView.qml` | The lock-screen UI |
| `Magi*.qml` | Calendar, icons, segment display and theme colors |
| `assets/bell.ogg` | Bell played on lock |
