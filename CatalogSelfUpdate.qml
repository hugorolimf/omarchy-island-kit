import QtQuick
import Quickshell

// Updating the Kit replaces the files of this very panel, and the shell reloads
// it on the spot, so it runs detached and restarts the shell itself. If it fails,
// a notification says why, and `gaveUp` lets the catalog bring the row back.
Scope {
  id: self
  property string failedText: "Island Kit"
  property int wait: 30000
  signal gaveUp()

  function start(id) {
    giveUp.restart()
    Quickshell.execDetached(["sh", "-c",
      "if out=$(omarchy plugin update \"$1\" --yes 2>&1); then exec omarchy-restart-shell; fi; "
      + "notify-send -a 'Island Kit' -u critical \"$2\" \"$(printf '%s\\n' \"$out\" | tail -n 1)\"",
      "sh", id, failedText])
  }

  // Still here after this long: it failed, since success restarts the shell.
  Timer { id: giveUp; interval: self.wait; onTriggered: self.gaveUp() }
}
