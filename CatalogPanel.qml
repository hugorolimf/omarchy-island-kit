import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "ui"
import "Strings.js" as Strings

// The catalog: every Island and Glass plugin, installed, enabled or removed
// from one place through `omarchy plugin`. The list comes from the Kit's
// repository (so new plugins show up without updating the Kit), falling back
// to the catalog.json shipped with it when offline. Extras are not shell
// plugins; their row opens the install page.
Panel {
  id: root
  moduleName: "io.github.hugorolimf.kit"
  ipcTarget: "io.github.hugorolimf.kit"

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property var t: Strings.forLocale(Qt.locale().name)
  readonly property bool pt: Qt.locale().name.indexOf("pt") === 0
  readonly property string remoteUrl: "https://raw.githubusercontent.com/hugorolimf/omarchy-island-kit/main/catalog.json"
  readonly property string localPath: decodeURIComponent(String(Qt.resolvedUrl("catalog.json")).replace(/^file:\/\//, ""))

  property var catalog: ({ version: 0, sections: [], plugins: [] })
  property bool offline: false
  property var installedList: []

  // id -> "install" | "remove" while `omarchy plugin` runs; id -> message on failure
  property var busy: ({})
  property var errors: ({})
  property var queue: []
  property string confirmRemove: ""
  property bool needsRestart: false

  function open() {
    refresh()
    query = ""
    confirmRemove = ""
    root.controller.show()
  }
  function openFromHotkey() { open() }
  function close() { root.controller.hide() }
  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }
  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function refresh() {
    if (!localProc.running) localProc.running = true
    if (!remoteProc.running) remoteProc.running = true
    if (!listProc.running) listProc.running = true
  }
  function useCatalog(text, fromRemote) {
    var c = null
    try { c = JSON.parse(String(text || "")) } catch (e) { c = null }
    if (!c || !Array.isArray(c.plugins)) return false
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
    for (var i = 0; i < pack.length; i++) list.push(pack[i])
    return list
  }
  function stateOf(p) {
    if (p.self) return "self"
    var list = members(p), on = 0, off = 0
    for (var k = 0; k < list.length; k++) {
      if (busy[list[k].id]) return busy[list[k].id]
      var i = info(list[k].id)
      if (i) { if (i.enabled === true) on++; else off++ }
    }
    if (on === list.length) return "installed"
    if (on + off === list.length) return "disabled"
    if (on + off > 0 && p.status === "published") return "available"
    if (p.status !== "published") return "soon"
    return p.external ? "view" : "available"
  }
  readonly property var installable: catalog.plugins.filter(function(p) { return root.stateOf(p) === "available" })
  readonly property int installedCount: catalog.plugins.filter(function(p) {
    var s = root.stateOf(p); return s === "installed" || s === "disabled" || s === "self" }).length

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
  function runNext() {
    if (actionProc.running || queue.length === 0) return
    var job = queue[0]
    queue = queue.slice(1)
    actionProc.job = job
    actionProc.command = job.kind === "install"
      ? ["omarchy", "plugin", "add", job.repo, "--enable", "--yes"]
      : job.kind === "remove"
        ? ["omarchy", "plugin", "remove", job.id, "--yes"]
        : job.kind === "disable"
          ? ["omarchy", "plugin", "disable", job.id]
          : ["omarchy", "plugin", "enable", job.id]
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
  Timer { id: confirmTimer; interval: 3000; onTriggered: root.confirmRemove = "" }

  // ---- search: typing with the panel open filters the list
  property string query: ""
  function fold(s) { return String(s || "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "") }
  function matches(p) {
    var q = fold(query).trim()
    return !q || fold(p.name).indexOf(q) >= 0 || fold(pt ? p.pt : p.en).indexOf(q) >= 0
  }
  readonly property bool searching: query.trim() !== ""
  function inSection(id) { return catalog.plugins.filter(function(p) { return p.section === id && root.matches(p) }) }
  function iconPath(p) {
    var icon = String(p.icon || "")
    return icon.charAt(0) === "@" ? (Anatomy.icons[icon.slice(1)] || "") : icon
  }

  Process {
    id: localProc
    command: ["cat", root.localPath]
    stdout: StdioCollector { onStreamFinished: root.useCatalog(text, false) }
  }
  Process {
    id: remoteProc
    command: ["curl", "-fsSL", "--max-time", "6", root.remoteUrl]
    stdout: StdioCollector { onStreamFinished: root.offline = !root.useCatalog(text, true) }
  }
  Process {
    id: listProc
    command: ["omarchy", "plugin", "list", "--json"]
    stdout: StdioCollector {
      onStreamFinished: {
        var list = null
        try { list = JSON.parse(String(text || "").trim()) } catch (e) { list = null }
        if (Array.isArray(list)) root.installedList = list
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
        root.setBusy(job.id, "")
        if (code !== 0) {
          var lines = (String(actionErr.text || "") + "\n" + String(actionOut.text || "")).trim().split("\n")
          root.setError(job.id, lines[lines.length - 1] || ("exit " + code))
        } else if (job.kind !== "enable") {
          root.needsRestart = true
        }
      }
      listProc.running = true
      root.runNext()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: false
    focusTarget: searchInput
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: column
          width: parent.width
          spacing: 2

          Item {
            width: parent.width
            height: Style.space(30)
            Text {
              textFormat: Text.PlainText
              anchors.verticalCenter: parent.verticalCenter
              text: root.t.title
              color: Anatomy.strong
              font.family: Anatomy.sans
              font.pixelSize: 15
              font.weight: Font.DemiBold
            }
            Text {
              textFormat: Text.PlainText
              anchors.right: parent.right
              anchors.rightMargin: Style.space(2)
              anchors.verticalCenter: parent.verticalCenter
              text: root.installedCount + " " + root.t.installedCount + " · " + root.installable.length + " " + root.t.availableCount
              color: Anatomy.muted
              font.family: Anatomy.mono
              font.pixelSize: 9
              font.letterSpacing: Anatomy.labelSpacing
            }
          }

          // ---- search: shows up as soon as you type
          Rectangle {
            width: parent.width
            height: root.searching ? Style.space(32) : 0
            opacity: root.searching ? 1 : 0
            Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.Bezier; easing.bezierCurve: Anatomy.ease } }
            Behavior on opacity { NumberAnimation { duration: 140 } }
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.06)
            border.width: Anatomy.hairline
            border.color: Qt.rgba(1, 1, 1, 0.12)
            AnatomyIcon {
              id: searchIcon
              x: Style.space(11)
              anchors.verticalCenter: parent.verticalCenter
              size: 13
              color: Anatomy.muted
              path: "M10.5 4.5a6 6 0 1 0 0 12a6 6 0 1 0 0-12zM15 15l4.5 4.5"
            }
            TextInput {
              id: searchInput
              anchors.left: searchIcon.right
              anchors.leftMargin: Style.space(8)
              anchors.right: parent.right
              anchors.rightMargin: Style.space(12)
              anchors.verticalCenter: parent.verticalCenter
              color: Anatomy.strong
              selectionColor: Anatomy.selection
              font.family: Anatomy.sans
              font.pixelSize: 13
              clip: true
              text: root.query
              onTextEdited: root.query = text
              Keys.onEscapePressed: {
                if (text !== "") { root.query = ""; text = "" }
                else root.close()
              }
              Keys.onTabPressed: root.switchPanel(1)
              Keys.onBacktabPressed: root.switchPanel(-1)
            }
          }

          // ---- install everything that isn't there yet
          Item {
            width: parent.width
            height: visible ? Style.space(34) : 0
            visible: !root.searching && root.installable.length > 1
            Chip {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              label: root.t.installAll + " (" + root.installable.length + ")"
              iconPath: "M12 5v10M8 11l4 4 4-4M5 19h14"
              accent: true
              onClicked: root.installAll()
            }
          }

          Text {
            textFormat: Text.PlainText
            visible: root.searching && root.catalog.plugins.filter(root.matches).length === 0
            width: parent.width
            topPadding: Style.space(14)
            bottomPadding: Style.space(14)
            horizontalAlignment: Text.AlignHCenter
            text: root.t.nothingFor + " “" + root.query.trim() + "”"
            color: Anatomy.muted
            font.family: Anatomy.sans
            font.pixelSize: 12
          }

          Repeater {
            model: root.catalog.sections
            delegate: Column {
              required property var modelData
              readonly property var rows: root.inSection(modelData.id)
              width: column.width
              visible: rows.length > 0
              SectionLabel {
                text: root.pt ? modelData.pt : modelData.en
                hint: root.pt ? (modelData.hint_pt || "") : (modelData.hint_en || "")
              }
              Repeater {
                model: parent.rows
                delegate: CatalogRow {
                  required property var modelData
                  entry: modelData
                }
              }
            }
          }

          // ---- restart, after something was installed or removed
          Rectangle {
            visible: root.needsRestart
            width: parent.width
            height: visible ? Style.space(44) : 0
            radius: Anatomy.rowRadius
            color: Anatomy.selected
            border.width: Anatomy.hairline
            border.color: Anatomy.selectedRim
            Text {
              textFormat: Text.PlainText
              anchors.left: parent.left
              anchors.leftMargin: Style.space(10)
              anchors.right: restartChip.left
              anchors.rightMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              text: root.t.restartHint
              wrapMode: Text.Wrap
              color: Anatomy.text
              font.family: Anatomy.sans
              font.pixelSize: 11
            }
            Chip {
              id: restartChip
              anchors.right: parent.right
              anchors.rightMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              label: root.t.restart
              iconPath: Anatomy.icons.refresh
              accent: true
              onClicked: Quickshell.execDetached(["omarchy-restart-shell"])
            }
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            topPadding: Style.space(10)
            bottomPadding: Style.space(2)
            wrapMode: Text.Wrap
            text: (root.offline ? root.t.offline + " " : "") + root.t.footer
            color: Anatomy.muted
            font.family: Anatomy.sans
            font.pixelSize: 11
          }
        }
      }
    }
  }

  // Small caps section title, with a hint on the right.
  component SectionLabel: Item {
    property alias text: label.text
    property string hint: ""
    width: column.width
    height: Style.space(28)
    Rectangle { width: parent.width; height: 1; color: Anatomy.rule; anchors.top: parent.top; anchors.topMargin: Style.space(4) }
    Text {
      id: label
      textFormat: Text.PlainText
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Style.space(4)
      color: Anatomy.muted
      font.family: Anatomy.mono
      font.pixelSize: 10
      font.weight: Font.DemiBold
      font.letterSpacing: Anatomy.labelSpacing
    }
    Text {
      textFormat: Text.PlainText
      visible: parent.hint !== ""
      anchors.right: parent.right
      anchors.rightMargin: Style.space(2)
      anchors.baseline: label.baseline
      text: parent.hint
      color: Anatomy.muted
      font.family: Anatomy.mono
      font.pixelSize: 9
      font.letterSpacing: Anatomy.labelSpacing
    }
  }

  // Pill button: icon + label, accent for the main action.
  component Chip: Rectangle {
    id: chip
    property string label: ""
    property string iconPath: ""
    property bool accent: false
    property bool enabledChip: true
    signal clicked()
    height: Style.space(26)
    width: chipRow.implicitWidth + Style.space(18)
    radius: height / 2
    color: !chip.enabledChip ? "transparent" : chipArea.containsMouse ? (chip.accent ? Anatomy.toggleOn : Anatomy.hover) : (chip.accent ? Anatomy.selected : "transparent")
    border.width: Anatomy.hairline
    border.color: chip.accent && chip.enabledChip ? Anatomy.selectedRim : Anatomy.controlRim
    Behavior on color { ColorAnimation { duration: Anatomy.fast } }
    Row {
      id: chipRow
      anchors.centerIn: parent
      spacing: Style.space(5)
      AnatomyIcon {
        visible: chip.iconPath !== ""
        anchors.verticalCenter: parent.verticalCenter
        size: 12
        path: chip.iconPath
        color: chip.accent && chip.enabledChip ? Anatomy.blue : Anatomy.muted
      }
      Text {
        textFormat: Text.PlainText
        anchors.verticalCenter: parent.verticalCenter
        text: chip.label
        color: chip.enabledChip ? Anatomy.text : Anatomy.muted
        font.family: Anatomy.sans
        font.pixelSize: 12
      }
    }
    MouseArea {
      id: chipArea
      anchors.fill: parent
      enabled: chip.enabledChip
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: chip.clicked()
    }
  }

  // One plugin: icon tile, name, what it does (or why it failed), the trash
  // on hover when installed, and the action on the right.
  component CatalogRow: Rectangle {
    id: row
    property var entry: ({})
    readonly property string state: root.stateOf(entry)
    readonly property string error: {
      var list = root.members(entry)
      for (var k = 0; k < list.length; k++) if (root.errors[list[k].id]) return root.errors[list[k].id]
      return ""
    }
    readonly property bool confirming: root.confirmRemove === entry.id
    readonly property bool canRemove: (state === "installed" || state === "disabled")

    width: column.width
    height: Style.space(48)
    radius: Anatomy.rowRadius
    color: rowArea.containsMouse ? Anatomy.hover : "transparent"
    Behavior on color { ColorAnimation { duration: Anatomy.fast } }

    MouseArea { id: rowArea; anchors.fill: parent; hoverEnabled: true }

    Rectangle {
      id: tile
      x: Style.space(6)
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(30)
      height: width
      radius: Anatomy.cardRadius
      color: Anatomy.card
      border.width: Anatomy.hairline
      border.color: Anatomy.controlRim
      opacity: row.state === "soon" ? 0.5 : 1
      AnatomyIcon {
        anchors.centerIn: parent
        size: 17
        path: root.iconPath(row.entry)
        color: Anatomy.hi
      }
    }

    Column {
      anchors.left: tile.right
      anchors.leftMargin: Style.space(10)
      anchors.right: trashButton.left
      anchors.rightMargin: Style.space(6)
      anchors.verticalCenter: parent.verticalCenter
      spacing: 1
      opacity: row.state === "soon" ? 0.6 : 1
      Text {
        textFormat: Text.PlainText
        width: parent.width
        text: row.entry.name || ""
        color: Anatomy.strong
        font.family: Anatomy.sans
        font.pixelSize: 13
        font.weight: Font.DemiBold
        elide: Text.ElideRight
      }
      Text {
        textFormat: Text.PlainText
        width: parent.width
        text: row.error !== "" ? root.t.failed + row.error : (root.pt ? row.entry.pt : row.entry.en) || ""
        color: row.error !== "" ? Anatomy.red : Anatomy.muted
        font.family: Anatomy.sans
        font.pixelSize: 11
        elide: Text.ElideRight
      }
    }

    // remove from the system; a second click within 3 s confirms
    Item {
      id: trashButton
      anchors.right: action.left
      anchors.rightMargin: Style.space(4)
      anchors.verticalCenter: parent.verticalCenter
      width: row.canRemove ? Style.space(20) : 0
      height: Style.space(20)
      visible: row.canRemove
      opacity: row.confirming || rowArea.containsMouse || trashArea.containsMouse ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: Anatomy.fast } }
      Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: row.confirming ? Anatomy.urgentFill : trashArea.containsMouse ? Anatomy.hover : "transparent"
      }
      AnatomyIcon {
        anchors.centerIn: parent
        size: 12
        path: "M5 7h14M10 7V5h4v2M7 7l1 12h8l1-12M10.5 10.5v5M13.5 10.5v5"
        color: row.confirming || trashArea.containsMouse ? Anatomy.red : Anatomy.muted
      }
      MouseArea {
        id: trashArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.remove(row.entry)
      }
      PanelToolTip {
        visible: trashArea.containsMouse || row.confirming
        text: row.confirming ? root.t.confirmRemove : root.t.remove
      }
    }

    Item {
      id: action
      anchors.right: parent.right
      anchors.rightMargin: Style.space(6)
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(actionChip.width, statusText.implicitWidth)
      height: actionChip.height

      Chip {
        id: actionChip
        anchors.right: parent.right
        visible: row.state === "available" || row.state === "disabled" || row.state === "view"
        label: row.state === "disabled" ? root.t.enable : row.state === "view" ? root.t.view : root.t.install
        iconPath: row.state === "view" ? "M14 5h5v5M19 5l-8 8M17 14v5H5V7h5" : row.state === "disabled" ? "" : "M12 5v10M8 11l4 4 4-4M5 19h14"
        accent: row.state === "available"
        onClicked: {
          if (row.state === "view") root.view(row.entry)
          else if (row.state === "disabled") root.enable(row.entry)
          else root.install(row.entry)
        }
      }
      Text {
        id: statusText
        textFormat: Text.PlainText
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: !actionChip.visible
        text: row.state === "installed" ? "✓ " + root.t.installed
          : row.state === "install" ? root.t.installing
          : row.state === "remove" ? root.t.removing
          : row.state === "enable" ? root.t.installing
          : row.state === "self" ? root.t.thisPlugin
          : root.t.soon
        color: row.state === "installed" ? Anatomy.green : Anatomy.muted
        font.family: Anatomy.mono
        font.pixelSize: 10
        font.letterSpacing: Anatomy.labelSpacing
      }
    }
  }
}
