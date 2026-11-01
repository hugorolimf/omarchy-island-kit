import QtQuick
import Quickshell
import qs.Commons
import "ui"
import "Strings.js" as Strings

// The catalog: every Island and Glass plugin, installed, updated, enabled or
// removed from one place through `omarchy plugin`. CatalogStore keeps the data
// and talks to GitHub; this file is the panel. Extras are not shell plugins;
// their row opens the install page.
Panel {
  id: root
  moduleName: "io.github.hugorolimf.kit"
  ipcTarget: "io.github.hugorolimf.kit"

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property var t: Strings.forLocale(Qt.locale().name)
  readonly property bool pt: Qt.locale().name.indexOf("pt") === 0

  // How the list compares with GitHub, first thing in the footer.
  readonly property string syncLine: catalogStore.offline ? t.offline + " "
    : catalogStore.checking ? t.checking + " "
    : catalogStore.checkFailed ? t.checkFailed + " "
    : catalogStore.lastCheck > 0 && catalogStore.updatable.length === 0 ? t.upToDate + " "
    : ""

  CatalogStore { id: catalogStore; anatomyIcons: Anatomy.icons; selfUpdateFailed: root.t.selfUpdateFailed }

  function open() {
    catalogStore.refresh()
    query = ""
    catalogStore.confirmRemove = ""
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

  // ---- search: typing with the panel open filters the list
  property string query: ""
  function fold(s) { return String(s || "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "") }
  function matches(p) {
    var q = fold(query).trim()
    return !q || fold(p.name).indexOf(q) >= 0 || fold(pt ? p.pt : p.en).indexOf(q) >= 0
  }
  readonly property bool searching: query.trim() !== ""
  function inSection(id) { return catalogStore.catalog.plugins.filter(function(p) { return p.section === id && root.matches(p) }) }

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
              text: catalogStore.installedCount + " " + root.t.installedCount + " · " + catalogStore.installable.length + " " + root.t.availableCount
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

          // ---- update what GitHub has newer, install everything that isn't there yet
          Row {
            width: parent.width
            height: visible ? Style.space(34) : 0
            spacing: Style.space(6)
            visible: !root.searching && (catalogStore.updatable.length > 0 || catalogStore.installable.length > 1)
            CatalogChip {
              anchors.verticalCenter: parent.verticalCenter
              visible: catalogStore.updatable.length > 0
              label: root.t.updateAll + " (" + catalogStore.updatable.length + ")"
              iconPath: Anatomy.icons.refresh
              accent: true
              onClicked: catalogStore.updateAll()
            }
            CatalogChip {
              anchors.verticalCenter: parent.verticalCenter
              visible: catalogStore.installable.length > 1
              label: root.t.installAll + " (" + catalogStore.installable.length + ")"
              iconPath: "M12 5v10M8 11l4 4 4-4M5 19h14"
              accent: catalogStore.updatable.length === 0
              onClicked: catalogStore.installAll()
            }
          }

          Text {
            textFormat: Text.PlainText
            visible: root.searching && catalogStore.catalog.plugins.filter(root.matches).length === 0
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
            model: catalogStore.catalog.sections
            delegate: Column {
              required property var modelData
              readonly property var rows: root.inSection(modelData.id)
              width: column.width
              visible: rows.length > 0
              CatalogSectionLabel {
                width: column.width
                text: root.pt ? modelData.pt : modelData.en
                hint: root.pt ? (modelData.hint_pt || "") : (modelData.hint_en || "")
              }
              Repeater {
                model: parent.rows
                delegate: CatalogRow {
                  required property var modelData
                  width: column.width
                  store: catalogStore
                  t: root.t
                  pt: root.pt
                  entry: modelData
                }
              }
            }
          }

          // ---- restart, after something was installed or removed
          Rectangle {
            visible: catalogStore.needsRestart
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
            CatalogChip {
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
            text: root.syncLine + root.t.footer
            color: Anatomy.muted
            font.family: Anatomy.sans
            font.pixelSize: 11
          }
        }
      }
    }
  }
}
