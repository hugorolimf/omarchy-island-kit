import QtQuick
import qs.Commons
import "ui"

// One plugin: icon tile, name, what it does (or why it failed, or the version
// waiting on GitHub), the trash on hover when installed, and the action on the right.
Rectangle {
  id: row
  required property var store
  required property var t
  required property bool pt
  property var entry: ({})
  readonly property string state: store.stateOf(entry)
  readonly property string error: {
    var list = store.members(entry)
    for (var k = 0; k < list.length; k++) if (store.errors[list[k].id]) return store.errors[list[k].id]
    return ""
  }
  readonly property bool confirming: store.confirmRemove === entry.id
  readonly property bool canRemove: !entry.self && (state === "installed" || state === "disabled" || state === "updatable" || state === "blocked")
  readonly property string subtitle: {
    if (error !== "") return t.failed + error
    if (state === "updatable") {
      var version = store.newVersion(entry)
      var line = version !== "" ? t.updateTo + " " + version : t.updateReady
      return entry.self ? line + " · " + t.selfUpdateHint : line
    }
    if (state === "blocked") return t.localChangesHint
    return (pt ? entry.pt : entry.en) || ""
  }

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
      path: row.store.iconPath(row.entry)
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
      text: row.subtitle
      color: row.error !== "" ? Anatomy.red : row.state === "updatable" ? Anatomy.blue : Anatomy.muted
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
      onClicked: row.store.remove(row.entry)
    }
    PanelToolTip {
      visible: trashArea.containsMouse || row.confirming
      text: row.confirming ? row.t.confirmRemove : row.t.remove
    }
  }

  Item {
    id: action
    anchors.right: parent.right
    anchors.rightMargin: Style.space(6)
    anchors.verticalCenter: parent.verticalCenter
    width: Math.max(actionChip.width, statusText.implicitWidth)
    height: actionChip.height

    CatalogChip {
      id: actionChip
      anchors.right: parent.right
      visible: row.state === "available" || row.state === "disabled" || row.state === "view" || row.state === "updatable"
      label: row.state === "disabled" ? row.t.enable : row.state === "view" ? row.t.view : row.state === "updatable" ? row.t.update : row.t.install
      iconPath: row.state === "view" ? "M14 5h5v5M19 5l-8 8M17 14v5H5V7h5"
        : row.state === "disabled" ? ""
        : row.state === "updatable" ? Anatomy.icons.refresh
        : "M12 5v10M8 11l4 4 4-4M5 19h14"
      accent: row.state === "available" || row.state === "updatable"
      onClicked: {
        if (row.state === "view") row.store.view(row.entry)
        else if (row.state === "disabled") row.store.enable(row.entry)
        else if (row.state === "updatable") row.store.update(row.entry)
        else row.store.install(row.entry)
      }
    }
    Text {
      id: statusText
      textFormat: Text.PlainText
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      visible: !actionChip.visible
      text: row.state === "installed" ? "✓ " + row.t.installed
        : row.state === "install" ? row.t.installing
        : row.state === "update" ? row.t.updating
        : row.state === "remove" ? row.t.removing
        : row.state === "enable" ? row.t.installing
        : row.state === "self" ? row.t.thisPlugin
        : row.state === "blocked" ? row.t.localChanges
        : row.t.soon
      color: row.state === "installed" ? Anatomy.green : Anatomy.muted
      font.family: Anatomy.mono
      font.pixelSize: 10
      font.letterSpacing: Anatomy.labelSpacing
    }
  }
}
