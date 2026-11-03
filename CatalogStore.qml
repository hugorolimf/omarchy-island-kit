import QtQuick
import Quickshell
import Quickshell.Io
import "CatalogSanitize.js" as Sanitize

// What the catalog knows and does: the list from the Kit's repository (the
// catalog.json shipped with it when offline), what's installed, what GitHub has
// that isn't here yet, and one `omarchy plugin` command at a time.
Scope {
  id: store

  readonly property string remoteUrl: "https://raw.githubusercontent.com/hugorolimf/omarchy-island-kit/main/catalog.json"
  readonly property string localPath: filePath("catalog.json")
  function filePath(name) { return decodeURIComponent(String(Qt.resolvedUrl(name)).replace(/^file:\/\//, "")) }

  property var catalog: ({ version: 0, sections: [], plugins: [] })
  property bool offline: false
  property var installedList: []

  // id -> "install" | "update" | "remove" while `omarchy plugin` runs; id -> message on failure
  property var busy: ({})
  property var errors: ({})
  property var queue: []
  property string confirmRemove: ""
  property bool needsRestart: false
  // The Kit updates itself last: see startSelfUpdate().
  property string selfUpdateId: ""
  property string selfUpdateFailed: "Island Kit"
  property int selfUpdateWait: 30000

  // id -> { behind, ahead, dirty, version, failed }, from check-updates.sh
  property var updates: ({})
  property bool checkAgain: false
  property bool forceCheck: false
  property real lastCheck: 0
  readonly property bool checking: checkProc.running
  readonly property bool checkFailed: Object.keys(updates).some(function(id) { return store.updates[id].failed === true })

  function refresh() {
    if (!localProc.running) localProc.running = true
    if (!remoteProc.running) remoteProc.running = true
    if (!listProc.running) listProc.running = true
  }
  function useCatalog(text, fromRemote) {
    var c = Sanitize.parse(text)
    if (!c) return false
    if (!fromRemote && catalog.plugins.length > 0) return true
    if (fromRemote && (c.version || 0) < (catalog.version || 0)) return true
    catalog = c
    return true
  }

  // ---- installed state
  function info(id) {
    for (var i = 0; i < installedList.length; i++) if (installedList[i].id === id) return installedList[i]
    return null
  }
  // A pack (Island Panels) is several plugins installed and removed together.
  // A row's entry comes through the Repeater's modelData, where `pack` is a
  // QVariantList that Array.isArray rejects: test for a length instead.
  function members(p) {
    var pack = p ? p.pack : null
    if (!pack || typeof pack.length !== "number" || pack.length === 0) return [p]
    var list = []
    for (var i = 0; i < Math.min(pack.length, Sanitize.MAX_PACK); i++) list.push(pack[i])
    return list
  }
  function stateOf(p) {
    var list = members(p), on = 0, off = 0
    for (var k = 0; k < list.length; k++) {
      if (busy[list[k].id]) return busy[list[k].id]
      var i = info(list[k].id)
      if (i) { if (i.enabled === true) on++; else off++ }
    }
    var pending = updateStateOf(p)
    if (p.self) return pending || "self"
    if (on === list.length) return pending || "installed"
    if (on + off === list.length) return "disabled"
    if (on + off > 0 && p.status === "published") return "available"
    if (p.status !== "published") return "soon"
    return p.external ? "view" : "available"
  }
  readonly property var installable: catalog.plugins.filter(function(p) { return store.stateOf(p) === "available" })
  readonly property int installedCount: catalog.plugins.filter(function(p) {
    var s = store.stateOf(p)
    return s === "installed" || s === "disabled" || s === "self" || s === "updatable" || s === "blocked" }).length

  // ---- updates: only a clean checkout that GitHub is ahead of can move forward;
  // local changes or local commits are never touched.
  function canUpdate(u) { return !!u && u.behind > 0 && !u.dirty && u.ahead === 0 }
  function updateStateOf(p) {
    var list = members(p), blocked = false
    for (var k = 0; k < list.length; k++) {
      var u = updates[list[k].id]
      if (canUpdate(u)) return "updatable"
      if (u && u.behind > 0) blocked = true
    }
    return blocked ? "blocked" : ""
  }
  function newVersion(p) {
    var list = members(p)
    for (var k = 0; k < list.length; k++) {
      var u = updates[list[k].id]
      if (canUpdate(u)) return u.version || ""
    }
    return ""
  }
  readonly property var updatable: catalog.plugins.filter(function(p) { return store.updateStateOf(p) === "updatable" })
  function checkUpdates(force) {
    if (force) forceCheck = true
    if (checkProc.running) { checkAgain = true; return }
    if (actionProc.running || queue.length > 0) return
    if (!forceCheck && Date.now() - lastCheck < 120000) return
    var ids = []
    catalog.plugins.forEach(function(p) {
      members(p).forEach(function(m) { if (info(m.id)) ids.push(m.id) })
    })
    if (ids.length === 0) return
    forceCheck = false
    lastCheck = Date.now()
    checkProc.start(ids)
  }

  // ---- actions, one `omarchy plugin` at a time
  function setBusy(id, what) {
    var b = Object.assign({}, busy)
    if (what) b[id] = what
    else delete b[id]
    busy = b
  }
  function setError(id, message) {
    var e = Object.assign({}, errors)
    if (message) e[id] = message
    else delete e[id]
    errors = e
  }
  function enqueue(job) {
    setError(job.id, "")
    setBusy(job.id, job.kind)
    queue = queue.concat([job])
    runNext()
  }
  function commandFor(job) {
    if (job.kind === "install") return ["omarchy", "plugin", "add", job.repo, "--enable", "--yes"]
    if (job.kind === "update") return ["omarchy", "plugin", "update", job.id, "--yes"]
    if (job.kind === "remove") return ["omarchy", "plugin", "remove", job.id, "--yes"]
    if (job.kind === "disable") return ["omarchy", "plugin", "disable", job.id]
    return ["omarchy", "plugin", "enable", job.id]
  }
  function runNext() {
    if (actionProc.running || checkProc.running) return
    if (queue.length === 0) {
      if (selfUpdateId !== "") startSelfUpdate()
      return
    }
    var job = queue[0]
    queue = queue.slice(1)
    actionProc.job = job
    actionProc.command = commandFor(job)
    actionProc.running = true
  }
  // A plugin that does a built-in's job lists it in "takesOver": installing
  // it switches the built-in off, removing it switches it back on.
  function takesOver(entry) { return Array.isArray(entry.takesOver) ? entry.takesOver : [] }
  function install(p) {
    var list = members(p)
    for (var k = 0; k < list.length; k++) {
      if (info(list[k].id)) continue
      enqueue({ id: list[k].id, kind: "install", repo: list[k].repo })
      var over = takesOver(list[k])
      for (var j = 0; j < over.length; j++) enqueue({ id: String(over[j]), kind: "disable" })
    }
  }
  function installAll() {
    var list = installable
    for (var i = 0; i < list.length; i++) install(list[i])
  }
  function update(p) {
    var list = members(p)
    for (var k = 0; k < list.length; k++) {
      if (!canUpdate(updates[list[k].id]) || busy[list[k].id]) continue
      if (p.self) {
        selfUpdateId = p.id
        setError(p.id, "")
        setBusy(p.id, "update")
        runNext()
      } else {
        enqueue({ id: list[k].id, kind: "update" })
      }
    }
  }
  function updateAll() {
    var list = updatable
    for (var i = 0; i < list.length; i++) update(list[i])
  }
  function startSelfUpdate() {
    var id = selfUpdateId
    selfUpdateId = ""
    selfUpdater.start(id)
  }
  function enable(p) {
    var list = members(p)
    for (var k = 0; k < list.length; k++) {
      var i = info(list[k].id)
      if (i && i.enabled !== true) enqueue({ id: list[k].id, kind: "enable" })
    }
  }
  function remove(p) {
    if (confirmRemove !== p.id) {
      confirmRemove = p.id
      confirmTimer.restart()
      return
    }
    confirmRemove = ""
    var list = members(p)
    for (var k = 0; k < list.length; k++) {
      if (!info(list[k].id)) continue
      enqueue({ id: list[k].id, kind: "remove" })
      var over = takesOver(list[k])
      for (var j = 0; j < over.length; j++) enqueue({ id: String(over[j]), kind: "enable" })
    }
  }
  function view(p) { Qt.openUrlExternally(p.repo) }
  function iconPath(p) {
    var icon = String(p.icon || "")
    return icon.charAt(0) === "@" ? (store.anatomyIcons[icon.slice(1)] || "") : icon
  }
  property var anatomyIcons: ({})

  Timer { id: confirmTimer; interval: 3000; onTriggered: store.confirmRemove = "" }
  CatalogSelfUpdate {
    id: selfUpdater
    failedText: store.selfUpdateFailed
    wait: store.selfUpdateWait
    onGaveUp: {
      store.busy = ({})
      store.checkUpdates(true)
    }
  }

  Process {
    id: localProc
    command: ["cat", store.localPath]
    stdout: StdioCollector { onStreamFinished: store.useCatalog(text, false) }
  }
  Process {
    id: remoteProc
    command: ["sh", "-c", "curl -fsSL --max-time 6 \"$1\" | head -c 262144", "sh", store.remoteUrl]
    stdout: StdioCollector {
      onStreamFinished: {
        store.offline = !store.useCatalog(text, true)
        store.checkUpdates(false)
      }
    }
  }
  Process {
    id: listProc
    command: ["omarchy", "plugin", "list", "--json"]
    stdout: StdioCollector {
      onStreamFinished: {
        var list = null
        try { list = JSON.parse(String(text || "").trim()) } catch (e) { list = null }
        if (Array.isArray(list)) store.installedList = list
        store.checkUpdates(false)
      }
    }
  }
  CatalogUpdateCheck {
    id: checkProc
    onResult: function(found) { store.updates = found }
    onExited: {
      store.runNext()
      if (store.checkAgain) {
        store.checkAgain = false
        store.checkUpdates(true)
      }
    }
  }
  Process {
    id: actionProc
    property var job: null
    stdout: StdioCollector { id: actionOut }
    stderr: StdioCollector { id: actionErr }
    onExited: function(code) {
      var job = actionProc.job
      if (job) {
        store.setBusy(job.id, "")
        if (code !== 0) {
          var lines = (String(actionErr.text || "") + "\n" + String(actionOut.text || "")).trim().split("\n")
          store.setError(job.id, lines[lines.length - 1] || ("exit " + code))
        } else if (job.kind !== "enable") {
          store.needsRestart = true
        }
      }
      store.forceCheck = true
      listProc.running = true
      store.runNext()
    }
  }
}
