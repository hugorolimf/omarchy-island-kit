import QtQuick
import Quickshell
import Quickshell.Io

// Asks check-updates.sh how the installed plugins compare with GitHub.
// `result` carries id -> { behind, ahead, dirty, version, failed }.
Scope {
  id: check
  readonly property bool running: proc.running
  signal result(var found)
  signal exited()

  function start(ids) {
    var script = decodeURIComponent(String(Qt.resolvedUrl("check-updates.sh")).replace(/^file:\/\//, ""))
    proc.command = ["bash", script].concat(ids)
    proc.running = true
  }
  function parse(text) {
    var found = {}
    String(text || "").split("\n").forEach(function(line) {
      var f = line.split("\t")
      if (f.length === 2 && f[1] === "error") found[f[0]] = { behind: 0, ahead: 0, dirty: false, version: "", failed: true }
      else if (f.length === 5) found[f[0]] = { behind: Number(f[1]), ahead: Number(f[2]), dirty: f[3] === "1", version: f[4], failed: false }
    })
    return found
  }

  Process {
    id: proc
    stdout: StdioCollector { onStreamFinished: check.result(check.parse(text)) }
    onExited: check.exited()
  }
}
